import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/config/startup_api.dart';

void main() {
  test('release sans dart-define utilise l’URL publique HTTPS', () {
    expect(
      resolveStartupApiUrl(fromEnvironment: '', releaseMode: true),
      publicApiUrl,
    );
  });

  test('release honore un dart-define HTTPS', () {
    expect(
      resolveStartupApiUrl(
        fromEnvironment: 'https://soutralideals-backend.onrender.com/api',
        releaseMode: true,
      ),
      publicApiUrl,
    );
  });

  test('release refuse HTTP et localhost', () {
    expect(
      () => resolveStartupApiUrl(
        fromEnvironment: 'http://soutralideals-backend.onrender.com/api',
        releaseMode: true,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => resolveStartupApiUrl(
        fromEnvironment: 'https://localhost/api',
        releaseMode: true,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => resolveStartupApiUrl(
        fromEnvironment: 'https://192.168.1.8/api',
        releaseMode: true,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('debug remplace un placeholder et garde une URL locale', () {
    expect(
      resolveStartupApiUrl(
        fromEnvironment: 'https://example.com/api',
        releaseMode: false,
      ),
      publicApiUrl,
    );
    expect(
      resolveStartupApiUrl(
        fromEnvironment: 'http://localhost:3000/api',
        releaseMode: false,
      ),
      'http://localhost:3000/api',
    );
  });
}
