import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/token_store.dart';

typedef WsCallback = void Function(dynamic data);

/// Session Socket testable (single-flight, token ephemere, logout lock, rooms).
class SocketAuthSession {
  String? userId;
  String? lastSocketToken;
  bool logoutLocked = false;
  bool socketAuthenticated = false;
  int tokenFetchCount = 0;
  int authRetryCount = 0;
  /// Invalide toute réponse async (socket-token) d'une session précédente.
  int connectGeneration = 0;
  final Set<String> joinedConversations = {};
  final List<String> tokensIssued = [];

  bool get hasSessionUser =>
      !logoutLocked && userId != null && userId!.isNotEmpty;

  void bumpGeneration() => connectGeneration++;

  void clearEphemeralToken() {
    lastSocketToken = null;
    socketAuthenticated = false;
  }

  void resetForLogout() {
    bumpGeneration();
    logoutLocked = true;
    userId = null;
    lastSocketToken = null;
    socketAuthenticated = false;
    authRetryCount = 0;
    joinedConversations.clear();
    tokensIssued.clear();
  }

  void unlockForLogin(String newUserId) {
    bumpGeneration();
    if (userId != null && userId != newUserId) {
      joinedConversations.clear();
      tokensIssued.clear();
      lastSocketToken = null;
      socketAuthenticated = false;
      authRetryCount = 0;
    }
    logoutLocked = false;
    userId = newUserId;
  }

  Future<String?> fetchFreshSocketToken(
    Future<String> Function() fetcher, {
    bool force = true,
  }) async {
    if (logoutLocked) return null;
    if (!force &&
        lastSocketToken != null &&
        lastSocketToken!.isNotEmpty) {
      return lastSocketToken;
    }
    final gen = connectGeneration;
    tokenFetchCount++;
    final token = await fetcher();
    // Réponse en vol après logout / login B → ignorer.
    if (logoutLocked || gen != connectGeneration) return null;
    lastSocketToken = token;
    tokensIssued.add(token);
    return token;
  }
}

/// Singleton WebSocket — ne jamais [disconnect]/[dispose] depuis un ecran.
/// Seul le logout ([disconnectForLogout]) coupe la connexion globale.
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  final SocketAuthSession _session = SocketAuthSession();

  Future<void>? _connectFlight;
  Future<void>? _authFlight;

  bool get isConnected => _isConnected && !_session.logoutLocked;
  IO.Socket? get socket => _socket;
  String? get currentUserId => _session.userId;

  final List<WsCallback> _onNewMessage = [];
  final List<WsCallback> _onMessageNotification = [];
  final List<WsCallback> _onOrderStatusUpdated = [];
  final List<WsCallback> _onOrderUpdate = [];
  final List<WsCallback> _onNotification = [];
  final List<WsCallback> _onUserTyping = [];
  final List<WsCallback> _onMessageError = [];
  final List<WsCallback> _onOrderError = [];

  /// Hook tests : remplace POST /socket-token.
  @visibleForTesting
  static Future<String> Function()? debugSocketTokenFetcher;

  /// Mode tests : pas de Socket.IO reel (orchestre seulement session/token).
  @visibleForTesting
  static bool debugSkipRealSocket = false;

  @visibleForTesting
  SocketAuthSession get debugSession => _session;

  @visibleForTesting
  int get debugTokenFetchCount => _session.tokenFetchCount;

  @visibleForTesting
  List<String> get debugTokensIssued =>
      List<String>.unmodifiable(_session.tokensIssued);

  @visibleForTesting
  Set<String> get debugJoinedConversations =>
      Set<String>.unmodifiable(_session.joinedConversations);

  @visibleForTesting
  bool get debugLogoutLocked => _session.logoutLocked;

  @visibleForTesting
  int debugNewMessageListenerCount() => _onNewMessage.length;

  @visibleForTesting
  void debugDispatchNewMessage(dynamic data) =>
      _emitAll(_onNewMessage, data);

  @visibleForTesting
  static void debugReset() {
    final s = WebSocketService();
    s.disconnectForLogout();
    s._session.logoutLocked = false;
    s._session.tokenFetchCount = 0;
    s._session.tokensIssued.clear();
    s._clearAppListeners();
    debugSocketTokenFetcher = null;
    debugSkipRealSocket = false;
  }

  Future<void> connect() async {
    if (_session.logoutLocked) return;
    if (_isConnected && _socket != null) return;
    await _ensureSocketConnected();
  }

  /// Auth JWT court (POST /socket-token) via [ApiClient] (AUTH-REFRESH inclus).
  Future<void> authenticate({
    required String userId,
    String? accessToken,
  }) async {
    if (userId.isEmpty) return;

    final previous = _session.userId;
    _session.unlockForLogin(userId);

    if (previous != null && previous.isNotEmpty && previous != userId) {
      await _tearDownSocket(disableReconnect: true);
    }

    await _runConnectFlight(() async {
      await _ensureSocketConnected();
      await _emitSocketAuth(
        accessToken: accessToken,
        forceFreshToken: true,
      );
    });
  }

  Future<void> _runConnectFlight(Future<void> Function() body) async {
    if (_connectFlight != null) {
      await _connectFlight;
      if (_isConnected &&
          _session.socketAuthenticated &&
          !_session.logoutLocked) {
        return;
      }
    }
    final flight = body();
    _connectFlight = flight;
    try {
      await flight;
    } finally {
      if (identical(_connectFlight, flight)) {
        _connectFlight = null;
      }
    }
  }

  Future<void> _ensureSocketConnected() async {
    if (_session.logoutLocked) return;
    if (_isConnected && (_socket != null || debugSkipRealSocket)) return;
    if (debugSkipRealSocket) {
      _isConnected = true;
      return;
    }

    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000/api';
    final serverUrl = apiUrl.replaceFirst(RegExp(r'/api/?$'), '');

    await _tearDownSocket(disableReconnect: false);

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _bindSocketLifecycle();
    _socket!.connect();

    for (var i = 0; i < 50 && !_isConnected; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_session.logoutLocked) return;
    }
  }

  void _bindSocketLifecycle() {
    if (_socket == null) return;

    _socket!.onConnect((_) async {
      if (_session.logoutLocked) {
        _socket?.disconnect();
        return;
      }
      _isConnected = true;
      if (kDebugMode) print('WebSocket connecte');
      // (Re)connexion TCP -> toujours un socket-token frais.
      if (_session.hasSessionUser) {
        await _emitSocketAuth(forceFreshToken: true);
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _session.clearEphemeralToken();
      if (kDebugMode) print('WebSocket deconnecte');
    });

    _socket!.onConnectError((error) {
      if (kDebugMode) print('Erreur connexion WebSocket: $error');
    });

    // Backend emit: auth-error
    _socket!.on('auth-error', (data) async {
      if (kDebugMode) print('auth-error Socket: $data');
      _session.socketAuthenticated = false;
      if (_session.logoutLocked) return;
      if (_session.authRetryCount >= 1) return;
      _session.authRetryCount++;
      _session.clearEphemeralToken();
      final access = await TokenStore.getAccessToken();
      if (access == null || access.isEmpty) return;
      await _emitSocketAuth(forceFreshToken: true);
    });

    _socket!.on('new-message', (data) => _emitAll(_onNewMessage, data));
    _socket!.on('message-notification',
        (data) => _emitAll(_onMessageNotification, data));
    _socket!.on('order-status-updated',
        (data) => _emitAll(_onOrderStatusUpdated, data));
    _socket!.on('order-update', (data) => _emitAll(_onOrderUpdate, data));
    _socket!.on('notification', (data) => _emitAll(_onNotification, data));
    _socket!.on('user-typing', (data) => _emitAll(_onUserTyping, data));
    _socket!.on('message-error', (data) => _emitAll(_onMessageError, data));
    _socket!.on('order-error', (data) => _emitAll(_onOrderError, data));
  }

  Future<void> _emitSocketAuth({
    String? accessToken,
    bool forceFreshToken = true,
  }) async {
    if (_session.logoutLocked || !_session.hasSessionUser) return;
    if (!debugSkipRealSocket && (_socket == null || !_isConnected)) return;

    final gen = _session.connectGeneration;

    // Attendre un auth en cours ; si génération obsolète, on ne réutilise pas.
    if (_authFlight != null) {
      await _authFlight;
      if (gen != _session.connectGeneration || _session.logoutLocked) return;
      if (_session.socketAuthenticated && _session.hasSessionUser) return;
    }

    Future<void> run() async {
      try {
        final token = await _fetchSocketToken(
          accessToken: accessToken,
          force: forceFreshToken,
        );
        // Réponse async obsolète (logout / login B pendant le fetch).
        if (gen != _session.connectGeneration || _session.logoutLocked) {
          return;
        }
        if (token == null || token.isEmpty) {
          if (kDebugMode) print('Impossible d obtenir un socket token');
          return;
        }
        if (!_session.hasSessionUser) return;
        if (debugSkipRealSocket) {
          _session.socketAuthenticated = true;
          _session.authRetryCount = 0;
          return;
        }
        if (_socket == null) return;
        _socket!.emit('authenticate', {'token': token});
        _session.socketAuthenticated = true;
        _session.authRetryCount = 0;
        _rejoinRooms();
        if (kDebugMode) {
          print('Socket authentifie (JWT court) pour ${_session.userId}');
        }
      } on UnauthorizedException {
        if (kDebugMode) {
          print('Session REST invalide pendant socket-token');
        }
      } catch (e) {
        if (kDebugMode) print('_emitSocketAuth: $e');
      }
    }

    final flight = run();
    _authFlight = flight;
    try {
      await flight;
    } finally {
      if (identical(_authFlight, flight)) {
        _authFlight = null;
      }
    }
  }

  Future<String?> _fetchSocketToken({
    String? accessToken,
    bool force = true,
  }) async {
    return _session.fetchFreshSocketToken(
      () async {
        if (debugSocketTokenFetcher != null) {
          return debugSocketTokenFetcher!();
        }
        final api = ApiClient();
        final bearer = accessToken ?? await TokenStore.getAccessToken();
        if (bearer == null || bearer.isEmpty) {
          throw StateError('Aucun access token pour /socket-token');
        }
        return api.createSocketToken(bearer);
      },
      force: force,
    );
  }

  void _rejoinRooms() {
    if (_socket == null || !_isConnected) return;
    for (final id in _session.joinedConversations) {
      _socket!.emit('join-conversation', id);
    }
  }

  void joinConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    _session.joinedConversations.add(conversationId);
    if (_socket != null && _isConnected) {
      _socket!.emit('join-conversation', conversationId);
    }
  }

  void leaveConversation(String conversationId) {
    _session.joinedConversations.remove(conversationId);
    if (_socket != null && _isConnected) {
      _socket!.emit('leave-conversation', conversationId);
    }
  }

  void sendMessage({
    required String sender,
    required String recipient,
    required String content,
    required String conversationId,
    String messageType = 'NORMAL',
    String? referenceId,
    String? referenceType,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('send-message', {
        'expediteur': sender,
        'destinataire': recipient,
        'contenu': content,
        'conversationId': conversationId,
        'typeMessage': messageType,
        if (referenceId != null) 'referenceId': referenceId,
        if (referenceType != null) 'referenceType': referenceType,
      });
    }
  }

  void startTyping(String conversationId, {String? userId}) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing-start', {
        'conversationId': conversationId,
        if (userId != null) 'userId': userId,
      });
    }
  }

  void stopTyping(String conversationId, {String? userId}) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing-stop', {
        'conversationId': conversationId,
        if (userId != null) 'userId': userId,
      });
    }
  }

  /// Foreground / reseau : reconnecte seulement si le socket est perdu.
  Future<void> resumeIfNeeded() async {
    if (_session.logoutLocked) return;
    if (!_session.hasSessionUser) return;
    if (_isConnected &&
        _session.socketAuthenticated &&
        (_socket != null || debugSkipRealSocket)) {
      return;
    }
    await authenticate(userId: _session.userId!);
  }

  void _emitAll(List<WsCallback> listeners, dynamic data) {
    for (final cb in List<WsCallback>.from(listeners)) {
      try {
        cb(data);
      } catch (_) {}
    }
  }

  void _addListener(List<WsCallback> list, WsCallback callback) {
    if (!list.contains(callback)) list.add(callback);
  }

  void _removeListener(List<WsCallback> list, WsCallback callback) {
    list.remove(callback);
  }

  void _clearAppListeners() {
    _onNewMessage.clear();
    _onMessageNotification.clear();
    _onOrderStatusUpdated.clear();
    _onOrderUpdate.clear();
    _onNotification.clear();
    _onUserTyping.clear();
    _onMessageError.clear();
    _onOrderError.clear();
  }

  VoidCallback addNewMessageListener(WsCallback callback) {
    _addListener(_onNewMessage, callback);
    return () => _removeListener(_onNewMessage, callback);
  }

  VoidCallback addMessageNotificationListener(WsCallback callback) {
    _addListener(_onMessageNotification, callback);
    return () => _removeListener(_onMessageNotification, callback);
  }

  VoidCallback addOrderStatusUpdatedListener(WsCallback callback) {
    _addListener(_onOrderStatusUpdated, callback);
    return () => _removeListener(_onOrderStatusUpdated, callback);
  }

  VoidCallback addOrderUpdateListener(WsCallback callback) {
    _addListener(_onOrderUpdate, callback);
    return () => _removeListener(_onOrderUpdate, callback);
  }

  VoidCallback addNotificationListener(WsCallback callback) {
    _addListener(_onNotification, callback);
    return () => _removeListener(_onNotification, callback);
  }

  VoidCallback addUserTypingListener(WsCallback callback) {
    _addListener(_onUserTyping, callback);
    return () => _removeListener(_onUserTyping, callback);
  }

  void onNewMessage(WsCallback callback) {
    _onNewMessage
      ..clear()
      ..add(callback);
  }

  void onMessageNotification(WsCallback callback) {
    _onMessageNotification
      ..clear()
      ..add(callback);
  }

  void onOrderStatusUpdated(WsCallback callback) {
    _onOrderStatusUpdated
      ..clear()
      ..add(callback);
  }

  void onOrderUpdate(WsCallback callback) {
    _onOrderUpdate
      ..clear()
      ..add(callback);
  }

  void onNotification(WsCallback callback) {
    _onNotification
      ..clear()
      ..add(callback);
  }

  void onUserTyping(WsCallback callback) {
    _onUserTyping
      ..clear()
      ..add(callback);
  }

  void onMessageError(WsCallback callback) {
    _onMessageError
      ..clear()
      ..add(callback);
  }

  void onOrderError(WsCallback callback) {
    _onOrderError
      ..clear()
      ..add(callback);
  }

  Future<void> _tearDownSocket({required bool disableReconnect}) async {
    final s = _socket;
    _socket = null;
    _isConnected = false;
    _session.socketAuthenticated = false;
    if (s == null) return;
    try {
      if (disableReconnect) {
        s.io.options?['reconnection'] = false;
      }
      s.clearListeners();
      s.disconnect();
      s.dispose();
    } catch (_) {}
  }

  /// Deconnexion globale — uniquement au logout.
  void disconnectForLogout() {
    _session.resetForLogout();
    _connectFlight = null;
    _authFlight = null;
    _clearAppListeners();
    // ignore: discarded_futures
    _tearDownSocket(disableReconnect: true);
  }

  @Deprecated(
      'Ne pas disposer le singleton depuis un ecran — utiliser disconnectForLogout au logout')
  void disconnect() {
    if (kDebugMode) {
      print('WebSocketService.disconnect() ignore (singleton partage)');
    }
  }

  @Deprecated('Ne pas disposer le singleton depuis un ecran')
  void dispose() {
    if (kDebugMode) {
      print('WebSocketService.dispose() ignore (singleton partage)');
    }
  }
}
