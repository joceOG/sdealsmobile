import 'package:flutter/foundation.dart';

/// Chrono cold start. Visible en debug et en release (logcat), sans donnée privée.
class StartupTrace {
  StartupTrace._();

  static final Stopwatch _watch = Stopwatch()..start();

  static void mark(String label) {
    debugPrint('[startup] ${_watch.elapsedMilliseconds}ms $label');
  }
}
