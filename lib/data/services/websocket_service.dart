import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;

  // Getters
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  // 🔌 CONNEXION AU WEBSOCKET
  Future<void> connect() async {
    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000';
      final wsUrl = apiUrl.replaceFirst('http', 'ws');

      print('🔌 Connexion WebSocket vers: $wsUrl');

      _socket = IO.io(
          wsUrl,
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .enableAutoConnect()
              .build());

      _setupEventListeners();

      _socket!.connect();
      print('🔌 Tentative de connexion WebSocket...');
    } catch (e) {
      print('❌ Erreur connexion WebSocket: $e');
    }
  }

  // 📱 AUTHENTIFICATION UTILISATEUR
  void authenticate(String userId) {
    if (_socket != null && _isConnected) {
      _currentUserId = userId;
      _socket!.emit('authenticate', userId);
      print('👤 Utilisateur authentifié: $userId');
    }
  }

  // 💬 REJOINDRE UNE CONVERSATION
  void joinConversation(String conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join-conversation', conversationId);
      print('💬 Rejoint la conversation: $conversationId');
    }
  }

  // 💬 QUITTER UNE CONVERSATION
  void leaveConversation(String conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave-conversation', conversationId);
      print('💬 Quitté la conversation: $conversationId');
    }
  }

  // 📨 ENVOYER UN MESSAGE
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
      final messageData = {
        'expediteur': expediteur,
        'destinataire': destinataire,
        'contenu': contenu,
        'conversationId': conversationId,
        'typeMessage': typeMessage,
        if (referenceId != null) 'referenceId': referenceId,
        if (referenceType != null) 'referenceType': referenceType,
      };

      _socket!.emit('send-message', messageData);
      print('📨 Message envoyé: $contenu');
    }
  }

  // 📦 MISE À JOUR STATUT COMMANDE
  void updateOrderStatus({
    required String orderId,
    required String status,
    required String clientId,
  }) {
    if (_socket != null && _isConnected) {
      final orderData = {
        'orderId': orderId,
        'status': status,
        'clientId': clientId,
      };

      _socket!.emit('update-order-status', orderData);
      print('📦 Statut commande mis à jour: $orderId -> $status');
    }
  }

  // 🔔 ENVOYER NOTIFICATION
  void sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) {
    if (_socket != null && _isConnected) {
      final notificationData = {
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        if (data != null) 'data': data,
      };

      _socket!.emit('send-notification', notificationData);
      print('🔔 Notification envoyée à $userId');
    }
  }

  // 👤 INDICATEUR DE TYPING
  void startTyping(String conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing-start', {'conversationId': conversationId});
    }
  }

  void stopTyping(String conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing-stop', {'conversationId': conversationId});
    }
  }

  // 🎧 ÉCOUTEURS D'ÉVÉNEMENTS
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connexion établie
    _socket!.onConnect((_) {
      _isConnected = true;
      print('✅ WebSocket connecté');

      // Ré-authentifier si nécessaire
      if (_currentUserId != null) {
        authenticate(_currentUserId!);
      }
    });

    // Déconnexion
    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('❌ WebSocket déconnecté');
    });

    // Erreur de connexion
    _socket!.onConnectError((error) {
      print('❌ Erreur connexion WebSocket: $error');
    });

    // Nouveau message reçu
    _socket!.on('new-message', (data) {
      print('📨 Nouveau message reçu: $data');
      _onNewMessage?.call(data);
    });

    // Notification de message
    _socket!.on('message-notification', (data) {
      print('🔔 Notification message: $data');
      _onMessageNotification?.call(data);
    });

    // Statut commande mis à jour
    _socket!.on('order-status-updated', (data) {
      print('📦 Statut commande mis à jour: $data');
      _onOrderStatusUpdated?.call(data);
    });

    // Mise à jour commande
    _socket!.on('order-update', (data) {
      print('📦 Mise à jour commande: $data');
      _onOrderUpdate?.call(data);
    });

    // Notification générale
    _socket!.on('notification', (data) {
      print('🔔 Notification reçue: $data');
      _onNotification?.call(data);
    });

    // Indicateur de frappe
    _socket!.on('user-typing', (data) {
      print('👤 Utilisateur en train de taper: $data');
      _onUserTyping?.call(data);
    });

    // Erreurs
    _socket!.on('message-error', (data) {
      print('❌ Erreur message: $data');
      _onMessageError?.call(data);
    });

    _socket!.on('order-error', (data) {
      print('❌ Erreur commande: $data');
      _onOrderError?.call(data);
    });
  }

  // 🎧 CALLBACKS POUR LES ÉVÉNEMENTS
  Function(dynamic)? _onNewMessage;
  Function(dynamic)? _onMessageNotification;
  Function(dynamic)? _onOrderStatusUpdated;
  Function(dynamic)? _onOrderUpdate;
  Function(dynamic)? _onNotification;
  Function(dynamic)? _onUserTyping;
  Function(dynamic)? _onMessageError;
  Function(dynamic)? _onOrderError;

  // Configuration des callbacks
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

  // 🔌 DÉCONNEXION
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _currentUserId = null;
      print('🔌 WebSocket déconnecté');
    }
  }

  // 🧹 NETTOYAGE
  void dispose() {
    disconnect();
  }
}
