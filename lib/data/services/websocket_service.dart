import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/token_store.dart';

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
      print('❌ Erreur connexion WebSocket: $e');
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
        print('❌ Impossible d\'obtenir un socket token');
        return;
      }
      _socket!.emit('authenticate', {'token': token});
      print('👤 Socket authentifié (JWT court) pour $_currentUserId');
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
      // TTL backend = 5 min
      _socketTokenExpiresAt = DateTime.now().add(const Duration(minutes: 4));
      return socketToken;
    } catch (e) {
      print('❌ createSocketToken: $e');
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
      print('✅ WebSocket connecté');
      if (_currentUserId != null) {
        await _emitSocketAuth();
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('❌ WebSocket déconnecté');
    });

    _socket!.onConnectError((error) {
      print('❌ Erreur connexion WebSocket: $error');
    });

    _socket!.on('new-message', (data) {
      _onNewMessage?.call(data);
    });

    _socket!.on('message-notification', (data) {
      _onMessageNotification?.call(data);
    });

    _socket!.on('order-status-updated', (data) {
      _onOrderStatusUpdated?.call(data);
    });

    _socket!.on('order-update', (data) {
      _onOrderUpdate?.call(data);
    });

    _socket!.on('notification', (data) {
      _onNotification?.call(data);
    });

    _socket!.on('user-typing', (data) {
      _onUserTyping?.call(data);
    });

    _socket!.on('message-error', (data) {
      _onMessageError?.call(data);
    });

    _socket!.on('order-error', (data) {
      _onOrderError?.call(data);
    });
  }

  Function(dynamic)? _onNewMessage;
  Function(dynamic)? _onMessageNotification;
  Function(dynamic)? _onOrderStatusUpdated;
  Function(dynamic)? _onOrderUpdate;
  Function(dynamic)? _onNotification;
  Function(dynamic)? _onUserTyping;
  Function(dynamic)? _onMessageError;
  Function(dynamic)? _onOrderError;

  void onNewMessage(Function(dynamic) callback) => _onNewMessage = callback;
  void onMessageNotification(Function(dynamic) callback) =>
      _onMessageNotification = callback;
  void onOrderStatusUpdated(Function(dynamic) callback) =>
      _onOrderStatusUpdated = callback;
  void onOrderUpdate(Function(dynamic) callback) => _onOrderUpdate = callback;
  void onNotification(Function(dynamic) callback) => _onNotification = callback;
  void onUserTyping(Function(dynamic) callback) => _onUserTyping = callback;
  void onMessageError(Function(dynamic) callback) => _onMessageError = callback;
  void onOrderError(Function(dynamic) callback) => _onOrderError = callback;

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _currentUserId = null;
      _socketToken = null;
      _socketTokenExpiresAt = null;
    }
  }

  void dispose() => disconnect();
}
