import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde-fous statiques — logs sensibles (Phase 10B Lot 1).
void main() {
  final libRoot = Directory('lib');

  test('aucun print(formData) / print(userData)', () {
    final hits = <String>[];
    for (final f in libRoot.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      if (src.contains('print(formData)') ||
          src.contains('print(userData)') ||
          src.contains('print(event.formData)') ||
          src.contains(r'print("${event.formData}') ||
          src.contains("print('\${event.formData")) {
        hits.add(f.path);
      }
      if (RegExp(r'print\([^)]*formData').hasMatch(src)) {
        hits.add('${f.path}:formData');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('pas de journalisation de mot de passe', () {
    final hits = <String>[];
    final re = RegExp(
      r'''print\([^;]*password|debugPrint\([^;]*password''',
      caseSensitive: false,
    );
    for (final f in libRoot.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      for (final m in re.allMatches(src)) {
        hits.add('${f.path}:${m.group(0)}');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('pas de token FCM complet journalisé', () {
    final hits = <String>[];
    for (final f in libRoot.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      if (src.contains(r'print($_fcmToken)') ||
          src.contains('print(fcmToken)') ||
          src.contains('debugPrint(fcmToken)') ||
          src.contains('debugPrint(_fcmToken)') ||
          src.contains('print(_token)') ||
          RegExp(r"print\('\[FCM\].*token: \$\{").hasMatch(src)) {
        hits.add(f.path);
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('Authorization non journalisé', () {
    final hits = <String>[];
    final re = RegExp(
      r'''print\([^;]*['"]Authorization|debugPrint\([^;]*['"]Authorization|print\([^;]*Bearer |debugPrint\([^;]*Bearer ''',
      caseSensitive: false,
    );
    for (final f in libRoot.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      for (final m in re.allMatches(src)) {
        hits.add('${f.path}:${m.group(0)}');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('.env absent des assets pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assetsMatch = RegExp(
      r'^  assets:\n((?:    .*\n)*)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(assetsMatch, isNotNull);
    final assetsBlock = assetsMatch!.group(1)!;
    final assetLines = assetsBlock
        .split('\n')
        .where((l) => l.trim().startsWith('- '))
        .toList();
    expect(
      assetLines.any((l) => RegExp(r'\.env(\.example)?\s*$').hasMatch(l.trim())),
      isFalse,
      reason: assetLines.join('\n'),
    );
  });
}
