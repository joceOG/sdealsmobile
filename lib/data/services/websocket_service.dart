import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/token_store.dart';

typedef WsCallback = void Function(dynamic data);

/// Singleton WebSocket — ne jamais appeler [disconnect]/[dispose] depuis un écran.
/// Seul le logout (via [disconnectForLogout]) coupe la connexion globale.
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _socketToken;
  DateTime? _socketTokenExpiresAt;
  bool _authenticating = false;

  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;
  String? get currentUserId => _currentUserId;

  final List<WsCallback> _onNewMessage = [];
  final List<WsCallback> _onMessageNotification = [];
  final List<WsCallback> _onOrderStatusUpdated = [];
  final List<WsCallback> _onOrderUpdate = [];
  final List<WsCallback> _onNotification = [];
  final List<WsCallback> _onUserTyping = [];
  final List<WsCallback> _onMessageError = [];
  final List<WsCallback> _onOrderError = [];

  Future<void> connect() async {
    if (_isConnected && _socket != null) return;

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000/api';
      final serverUrl = apiUrl.replaceFirst(RegExp(r'/api/?$'), '');

      _socket?.dispose();
      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur connexion WebSocket: $e');
      rethrow;
    }
  }

  /// Auth JWT court (`POST /socket-token`) — aligné web / backend prod.
  Future<void> authenticate({
    required String userId,
    String? accessToken,
  }) async {
    _currentUserId = userId;
    if (_socket == null || !_isConnected) {
      await connect();
    }
    await _emitSocketAuth(accessToken: accessToken);
  }

  Future<void> _emitSocketAuth({String? accessToken}) async {
    if (_socket == null || !_isConnected || _currentUserId == null) return;
    if (_authenticating) return;
    _authenticating = true;
    try {
      final token = await _ensureSocketToken(accessToken: accessToken);
      if (token == null || token.isEmpty) {
        if (kDebugMode) print('❌ Impossible d\'obtenir un socket token');
        return;
      }
      _socket!.emit('authenticate', {'token': token});
      if (kDebugMode) {
        print('👤 Socket authentifié (JWT court) pour $_currentUserId');
      }
    } finally {
      _authenticating = false;
    }
  }

  Future<String?> _ensureSocketToken({String? accessToken}) async {
    final stillValid = _socketToken != null &&
        _socketTokenExpiresAt != null &&
        DateTime.now().isBefore(
          _socketTokenExpiresAt!.subtract(const Duration(seconds: 30)),
        );
    if (stillValid) return _socketToken;

    final bearer = accessToken ?? await TokenStore.getAccessToken();
    if (bearer == null || bearer.isEmpty) return null;

    try {
      final api = ApiClient();
      final socketToken = await api.createSocketToken(bearer);
      _socketToken = socketToken;
      _socketTokenExpiresAt = DateTime.now().add(const Duration(minutes: 4));
      return socketToken;
    } catch (e) {
      if (kDebugMode) print('❌ createSocketToken: $e');
      return null;
    }
  }

  void joinConversation(String conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join-conversation', conversationId);
    }
  }

  void leaveConversation(String conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave-conversation', conversationId);
    }
  }

  void sendMessage({
    required String expediteur,
    required String destinataire,
    required String contenu,
    required String conversationId,
    String typeMessage = 'NORMAL',
    String? referenceId,
    String? referenceType,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('send-message', {
        'expediteur': expediteur,
        'destinataire': destinataire,
        'contenu': contenu,
        'conversationId': conversationId,
        'typeMessage': typeMessage,
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

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) async {
      _isConnected = true;
      if (kDebugMode) print('✅ WebSocket connecté');
      if (_currentUserId != null) {
        await _emitSocketAuth();
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      if (kDebugMode) print('❌ WebSocket déconnecté');
    });

    _socket!.onConnectError((error) {
      if (kDebugMode) print('❌ Erreur connexion WebSocket: $error');
    });

    _socket!.on('new-message', (data) => _emitAll(_onNewMessage, data));
    _socket!.on(
        'message-notification', (data) => _emitAll(_onMessageNotification, data));
    _socket!.on(
        'order-status-updated', (data) => _emitAll(_onOrderStatusUpdated, data));
    _socket!.on('order-update', (data) => _emitAll(_onOrderUpdate, data));
    _socket!.on('notification', (data) => _emitAll(_onNotification, data));
    _socket!.on('user-typing', (data) => _emitAll(_onUserTyping, data));
    _socket!.on('message-error', (data) => _emitAll(_onMessageError, data));
    _socket!.on('order-error', (data) => _emitAll(_onOrderError, data));
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

  /// Enregistre un listener (multi-écrans). Retourne une fonction de désabonnement.
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

  /// Compat : remplace le listener unique (préférer [addNewMessageListener]).
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

  /// Déconnexion globale — uniquement au logout.
  void disconnectForLogout() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _currentUserId = null;
    _socketToken = null;
    _socketTokenExpiresAt = null;
  }

  @Deprecated('Ne pas disposer le singleton depuis un écran — utiliser disconnectForLogout au logout')
  void disconnect() {
    // No-op volontaire : éviter de couper le WS global en quittant chat/commandes
    if (kDebugMode) {
      print('⚠️ WebSocketService.disconnect() ignoré (singleton partagé)');
    }
  }

  @Deprecated('Ne pas disposer le singleton depuis un écran')
  void dispose() {
    if (kDebugMode) {
      print('⚠️ WebSocketService.dispose() ignoré (singleton partagé)');
    }
  }
}
