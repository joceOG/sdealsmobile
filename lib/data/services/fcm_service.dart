import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/token_store.dart';

/// Handler background (doit être top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  if (kDebugMode) {
    print('[FCM] background: ${message.messageId} ${message.notification?.title}');
  }
}

typedef FcmNavigationHandler = void Function(Map<String, dynamic> data);

/// Service FCM : init Firebase, permissions, token → backend, deep-links.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final ApiClient _api = ApiClient();
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  String? _token;
  FcmNavigationHandler? onNavigate;

  bool get isReady => _ready;
  String? get token => _token;

  static const _androidChannel = AndroidNotificationChannel(
    'soutrali_default',
    'Soutrali notifications',
    description: 'Notifications Soutrali Deals',
    importance: Importance.high,
  );

  /// Initialise Firebase + messaging. No-op gracieux si non configuré.
  Future<bool> initialize({FcmNavigationHandler? onNavigate}) async {
    this.onNavigate = onNavigate;
    if (_ready) return true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[FCM] Firebase non initialisé ($e). '
          'Ajoutez google-services.json / GoogleService-Info.plist '
          'ou lancez `flutterfire configure`.',
        );
      }
      return false;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      print('[FCM] permission: ${settings.authorizationStatus}');
    }

    if (Platform.isAndroid) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
    } else {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleMessageNavigation(initial);
    }

    messaging.onTokenRefresh.listen((t) async {
      _token = t;
      await _registerTokenWithBackend(t);
    });

    _token = await messaging.getToken();
    if (_token != null) {
      await _registerTokenWithBackend(_token!);
    }

    _ready = true;
    if (kDebugMode) {
      print('[FCM] prêt — token: ${_token?.substring(0, 12)}…');
    }
    return true;
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        if (resp.payload == null || resp.payload!.isEmpty) return;
        try {
          final data = jsonDecode(resp.payload!) as Map<String, dynamic>;
          onNavigate?.call(data);
        } catch (_) {}
      },
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Soutrali';
    final body = message.notification?.body ?? '';
    final payload = jsonEncode(message.data);

    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  void _handleMessageNavigation(RemoteMessage message) {
    onNavigate?.call(Map<String, dynamic>.from(message.data));
  }

  /// À appeler après login (token access disponible).
  Future<void> syncTokenWithBackend() async {
    if (!_ready) {
      await initialize(onNavigate: onNavigate);
    }
    final t = _token ?? await FirebaseMessaging.instance.getToken();
    if (t == null) return;
    _token = t;
    await _registerTokenWithBackend(t);
  }

  Future<void> _registerTokenWithBackend(String token) async {
    final access = await TokenStore.getAccessToken();
    if (access == null || access.isEmpty) return;
    try {
      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'unknown';
      await _api.registerFcmToken(
        token: token,
        platform: platform,
        accessToken: access,
      );
    } catch (e) {
      if (kDebugMode) print('[FCM] register backend: $e');
    }
  }

  /// Logout : retire le token côté serveur.
  Future<void> unregisterFromBackend() async {
    final t = _token;
    if (t == null) return;
    final access = await TokenStore.getAccessToken();
    if (access == null) return;
    try {
      await _api.unregisterFcmToken(token: t, accessToken: access);
    } catch (_) {}
  }

  /// Navigation deep-link depuis payload FCM.
  static String? resolveRoute(Map<String, dynamic> data) {
    final explicit = data['route']?.toString();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final type = (data['type']?.toString() ?? '').toUpperCase();
    final conversationId = data['conversationId']?.toString();
    final missionId = data['missionId']?.toString();

    if (conversationId != null && conversationId.isNotEmpty) {
      return '/chat/$conversationId';
    }
    if (missionId != null && missionId.isNotEmpty) {
      return '/mission-details/$missionId';
    }
    if (type.contains('MESSAGE')) return '/homepage';
    return '/homepage';
  }
}
