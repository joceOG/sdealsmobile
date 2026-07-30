import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Initialise Firebase (si besoin) + Crashlytics.
/// No-op gracieux si `google-services.json` est absent.
class CrashlyticsService {
  CrashlyticsService._();

  static bool _ready = false;
  static bool get isReady => _ready;

  static Future<bool> initialize() async {
    if (_ready) return true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Collecte aussi en debug pour valider le branchement Firebase.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      FlutterError.onError = (details) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      _ready = true;
      if (kDebugMode) {
        print('[Crashlytics] initialisé');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[Crashlytics] non initialisé ($e)');
      }
      return false;
    }
  }

  /// Envoie un rapport non-fatal (ne tue pas l'app).
  static Future<void> sendTestReport() async {
    if (!_ready) return;
    await FirebaseCrashlytics.instance.log('Soutrali Crashlytics setup test');
    await FirebaseCrashlytics.instance.recordError(
      Exception('Soutrali Crashlytics test'),
      StackTrace.current,
      fatal: true,
      reason: 'manual_setup_test',
    );
    await FirebaseCrashlytics.instance.sendUnsentReports();
    if (kDebugMode) {
      print('[Crashlytics] rapport de test envoyé — redémarre l’app si besoin');
    }
  }

  /// Crash natif fatal (ferme l'app). Relancer l'app envoie le rapport à Firebase.
  static void forceNativeCrash() {
    FirebaseCrashlytics.instance.crash();
  }
}
