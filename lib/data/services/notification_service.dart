import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sdealsmobile/data/services/api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiClient _api = ApiClient();
  final String? _apiUrl = dotenv.env['API_URL'];
  String? _fcmToken;

  String? get fcmToken => _fcmToken;
  bool get isTokenSet => _fcmToken != null;

  void setFCMToken(String token) {
    _fcmToken = token;
    if (kDebugMode) {
      debugPrint('FCM token set (len=${token.length})');
    }
  }

  Future<bool> sendPushNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (_apiUrl == null) {
        if (kDebugMode) debugPrint('API_URL missing for notification send');
        return false;
      }

      final payload = {
        'userId': userId,
        'title': title,
        'message': message,
        'data': data ?? {},
        'fcmToken': _fcmToken,
      };

      if (kDebugMode) {
        debugPrint('notification send status pending route=/notification/send');
      }

      final response = await _api.post('/notification/send', body: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      if (kDebugMode) {
        debugPrint('notification send failed status=${response.statusCode}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('notification send error=${e.runtimeType}');
      return false;
    }
  }

  Future<bool> notifyOrderStatusChange({
    required String userId,
    required String orderId,
    required String status,
    required String orderTitle,
  }) async {
    final title = 'Statut de commande mis à jour';
    final message = 'Votre commande "$orderTitle" est maintenant $status';

    return await sendPushNotification(
      userId: userId,
      title: title,
      message: message,
      data: {
        'type': 'order_status',
        'orderId': orderId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<bool> notifyNewMessage({
    required String userId,
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    final title = 'Nouveau message de $senderName';
    final messagePreview =
        message.length > 50 ? '${message.substring(0, 50)}...' : message;

    return await sendPushNotification(
      userId: userId,
      title: title,
      message: messagePreview,
      data: {
        'type': 'new_message',
        'conversationId': conversationId,
        'senderName': senderName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<bool> notifyPaymentReceived({
    required String userId,
    required double amount,
    required String orderId,
  }) async {
    final title = 'Paiement reçu';
    final message =
        'Vous avez reçu ${amount.toStringAsFixed(0)} FCFA pour la commande #$orderId';

    return await sendPushNotification(
      userId: userId,
      title: title,
      message: message,
      data: {
        'type': 'payment_received',
        'orderId': orderId,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<bool> notifyDeliveryUpdate({
    required String userId,
    required String orderId,
    required String status,
    required String orderTitle,
  }) async {
    final title = 'Mise à jour livraison';
    final message = 'Votre commande "$orderTitle" - $status';

    return await sendPushNotification(
      userId: userId,
      title: title,
      message: message,
      data: {
        'type': 'delivery_update',
        'orderId': orderId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<bool> notifyStats({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? stats,
  }) async {
    return await sendPushNotification(
      userId: userId,
      title: title,
      message: message,
      data: {
        'type': 'stats',
        'stats': stats ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<bool> notifyGeneric({
    required String userId,
    required String title,
    required String message,
    String type = 'generic',
    Map<String, dynamic>? data,
  }) async {
    return await sendPushNotification(
      userId: userId,
      title: title,
      message: message,
      data: {
        'type': type,
        ...?data,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      if (_apiUrl == null) return [];

      final response = await _api.get('/notification/user/$userId');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      if (_apiUrl == null) return false;

      final response =
          await _api.put('/notification/$notificationId/read');

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _fcmToken = null;
  }
}
