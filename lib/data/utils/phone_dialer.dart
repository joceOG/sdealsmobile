import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum PhoneDialOutcome { opened, invalidNumber, launchFailed, alreadyOpening }

class PhoneDialResult {
  const PhoneDialResult(this.outcome, {this.error});

  final PhoneDialOutcome outcome;
  final Object? error;

  bool get opened => outcome == PhoneDialOutcome.opened;
}

typedef TelLauncher = Future<bool> Function(Uri uri);
typedef CanLaunchChecker = Future<bool> Function(Uri uri);

/// Ouvre le composeur (`tel:`) sans lancer l'appel et sans journaliser le numéro.
class PhoneDialer {
  static TelLauncher launch = _platformLaunch;
  static CanLaunchChecker canLaunchUrlCheck = _platformCanLaunch;
  static void Function(String message) logStatus = _defaultLog;
  static int openCount = 0;

  static Future<bool> _platformLaunch(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
  }

  static Future<bool> _platformCanLaunch(Uri uri) => canLaunchUrl(uri);

  static void _defaultLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Retire la présentation, conserve un `+` initial, refuse le vide ou l'invalide.
  /// N'ajoute pas d'indicatif pays.
  static String? normalize(String? raw) {
    if (raw == null) return null;
    var value = raw.trim();
    if (value.isEmpty) return null;
    final keepPlus = value.startsWith('+');
    value = value.replaceAll(RegExp(r'[\s\-\(\)\.\/]'), '');
    if (keepPlus) {
      if (!value.startsWith('+')) return null;
      if (value.indexOf('+', 1) != -1) return null;
      value = value.substring(1);
      if (value.isEmpty) return null;
    } else if (value.contains('+')) {
      return null;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return null;
    if (value.length < 8 || value.length > 15) return null;
    return keepPlus ? '+$value' : value;
  }

  static Uri? buildTelUri(String? raw) {
    final normalized = normalize(raw);
    if (normalized == null) return null;
    return Uri(scheme: 'tel', path: normalized);
  }

  static Future<PhoneDialResult> openDialer(String? raw) async {
    final uri = buildTelUri(raw);
    if (uri == null) {
      logStatus('PhoneDialer: invalid');
      return const PhoneDialResult(PhoneDialOutcome.invalidNumber);
    }
    try {
      final canLaunch = await canLaunchUrlCheck(uri);
      if (!canLaunch) {
        logStatus('PhoneDialer: canLaunchUrl false');
        return const PhoneDialResult(PhoneDialOutcome.launchFailed);
      }
      openCount++;
      final ok = await launch(uri);
      if (!ok) {
        logStatus('PhoneDialer: launch returned false');
        return const PhoneDialResult(PhoneDialOutcome.launchFailed);
      }
      logStatus('PhoneDialer: opened');
      return const PhoneDialResult(PhoneDialOutcome.opened);
    } catch (e) {
      logStatus('PhoneDialer: launch exception ${e.runtimeType}');
      return PhoneDialResult(PhoneDialOutcome.launchFailed, error: e);
    }
  }

  static void resetForTest() {
    openCount = 0;
    launch = _platformLaunch;
    canLaunchUrlCheck = _platformCanLaunch;
    logStatus = _defaultLog;
    DialerSession.resetForTest();
  }
}

class DialerSession {
  static bool _busy = false;

  static Future<PhoneDialResult> openOnce(String? raw) async {
    if (_busy) {
      return const PhoneDialResult(PhoneDialOutcome.alreadyOpening);
    }
    _busy = true;
    try {
      return await PhoneDialer.openDialer(raw);
    } finally {
      _busy = false;
    }
  }

  static void resetForTest() {
    _busy = false;
  }
}
