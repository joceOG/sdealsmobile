import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/fcm_route_policy.dart';
import 'package:sdealsmobile/data/services/fcm_token_errors.dart';
import 'package:sdealsmobile/data/services/token_store.dart';

/// Handler background (doit être top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  if (kDebugMode) {
    print(
        '[FCM] background: ${message.messageId} ${message.notification?.title}');
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
  bool _coldStartCaptured = false;
  Future<void>? _coldStartFuture;
  Future<bool>? _initFuture;
  String? _token;
  FcmNavigationHandler? onNavigate;

  /// Deep link cold-start (notification) reçu avant que le router soit branché.
  Map<String, dynamic>? _pendingLaunchData;

  bool get isReady => _ready;
  String? get token => _token;

  static const _androidChannel = AndroidNotificationChannel(
    'soutrali_default',
    'Soutrali notifications',
    description: 'Notifications Soutrali Deals',
    importance: Importance.high,
  );

  /// Firebase + message ayant lancé l'app. Ne demande pas la permission ni le token.
  /// Appelé par le splash, avec un délai borné. Pas avant [runApp].
  Future<void> captureColdStart() {
    return _coldStartFuture ??= _captureColdStartImpl();
  }

  Future<void> _captureColdStartImpl() async {
    if (_coldStartCaptured) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleMessageNavigation(initial);
      }
      if (kDebugMode) {
        print(
            '[FCM] cold start capturé (pending=${_pendingLaunchData != null})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] cold start non capturé ($e)');
      }
    } finally {
      _coldStartCaptured = true;
    }
  }

  /// Initialise Firebase + messaging. No-op gracieux si non configuré.
  Future<bool> initialize({FcmNavigationHandler? onNavigate}) {
    if (onNavigate != null) this.onNavigate = onNavigate;
    return _initFuture ??= _initializeImpl();
  }

  Future<bool> _initializeImpl() async {
    if (_ready) return true;
    await captureColdStart();

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

    try {
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

      messaging.onTokenRefresh.listen((t) {
        _token = t;
        // ignore: unawaited_futures
        _registerTokenWithBackend(t);
      });

      _token = await _tryGetToken(messaging);
      if (_token != null) {
        // ignore: unawaited_futures
        _registerTokenWithBackend(_token!);
      } else {
        // ignore: unawaited_futures
        _retryGetTokenLater(messaging);
      }

      _ready = true;
      if (kDebugMode) {
        print('[FCM] prêt — tokenLen=${_token?.length ?? 0}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] init partielle ($e) — l’app démarre sans push');
      }
      return false;
    }
  }

  Future<String?> _tryGetToken(FirebaseMessaging messaging) async {
    try {
      return await messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        if (isTransientFcmTokenError(e)) {
          print(
            '[FCM] token indisponible pour l’instant ($e). '
            'Push différé — l’app continue.',
          );
        } else {
          print('[FCM] getToken: $e');
        }
      }
      return null;
    }
  }

  Future<void> _retryGetTokenLater(FirebaseMessaging messaging) async {
    const delays = [
      Duration(seconds: 8),
      Duration(seconds: 20),
      Duration(seconds: 60),
    ];
    for (final delay in delays) {
      await Future<void>.delayed(delay);
      if (_token != null) return;
      final t = await _tryGetToken(messaging);
      if (t != null) {
        _token = t;
        await _registerTokenWithBackend(t);
        return;
      }
    }
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
    final data = Map<String, dynamic>.from(message.data);
    if (onNavigate != null) {
      onNavigate!(data);
    } else {
      _pendingLaunchData = data;
    }
  }

  /// Route allowlistée, ou null. Ne renvoie jamais une route brute du payload.
  String? consumePendingLaunchRoute() {
    final data = _pendingLaunchData;
    _pendingLaunchData = null;
    if (data == null) return null;
    return resolveRoute(data);
  }

  void holdDestination(String route) => PendingLaunchDestination.hold(route);

  String? peekPendingDestination() => PendingLaunchDestination.peek();

  String? consumePendingDestination() => PendingLaunchDestination.consume();

  void clearPendingDestination() => PendingLaunchDestination.clear();

  /// À appeler après login (token access disponible).
  Future<void> syncTokenWithBackend() async {
    if (!_ready) {
      await initialize(onNavigate: onNavigate);
    }
    final t = _token ?? await _tryGetToken(FirebaseMessaging.instance);
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

  /// Navigation deep-link. Route inconnue ou arbitraire → null (l'accueil gère l'absence).
  static String? resolveRoute(Map<String, dynamic> data) {
    return FcmRoutePolicy.mapToAllowedRoute(data);
  }
}
