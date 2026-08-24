import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdealsmobile/data/services/token_store.dart';

/// Vérifications finales AUTH-REFRESH : atomicité, migration, hydratation.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TokenStore.debugReset();
  });

  tearDown(() {
    TokenStore.debugReset();
  });

  group('Atomicité TokenStore', () {
    test(
      'échec écriture SecureStorage → cache reste sur l’ancien couple',
      () async {
        TokenStore.debugUseFakeSecureStorage();
        await TokenStore.saveTokens(
          accessToken: 'access-old',
          refreshToken: 'refresh-old',
        );
        expect(TokenStore.debugCache()?.accessToken, 'access-old');
        expect(
          TokenStore.debugSecureMap![TokenStore.bundleKey],
          contains('access-old'),
        );

        TokenStore.debugSecureWriteHook = (key, value) async {
          if (key == TokenStore.bundleKey) {
            throw Exception('disk full');
          }
        };

        await expectLater(
          () => TokenStore.saveTokens(
            accessToken: 'access-new',
            refreshToken: 'refresh-new',
          ),
          throwsA(isA<Exception>()),
        );

        // Mémoire = ancien couple
        expect(TokenStore.debugCache()?.accessToken, 'access-old');
        expect(TokenStore.debugCache()?.refreshToken, 'refresh-old');

        // Disque = ancien bundle (pas de half-write new)
        final persisted = TokenStore.debugSecureMap![TokenStore.bundleKey]!;
        expect(persisted, contains('access-old'));
        expect(persisted, isNot(contains('access-new')));
        expect(persisted, contains('refresh-old'));
        expect(persisted, isNot(contains('refresh-new')));
      },
    );
  });

  group('Migration legacy', () {
    test(
      'clés séparées → bundle ; session conservée ; legacy nettoyées',
      () async {
        TokenStore.debugUseFakeSecureStorage({
          TokenStore.legacyAccessKey: 'legacy-access',
          TokenStore.legacyRefreshKey: 'legacy-refresh',
        });

        await TokenStore.hydrate();

        expect(await TokenStore.getAccessToken(), 'legacy-access');
        expect(await TokenStore.getRefreshToken(), 'legacy-refresh');
        expect(TokenStore.debugCache()?.accessToken, 'legacy-access');

        final map = TokenStore.debugSecureMap!;
        expect(map.containsKey(TokenStore.bundleKey), isTrue);
        expect(map.containsKey(TokenStore.legacyAccessKey), isFalse);
        expect(map.containsKey(TokenStore.legacyRefreshKey), isFalse);

        final bundle =
            jsonDecode(map[TokenStore.bundleKey]!) as Map<String, dynamic>;
        expect(bundle['accessToken'], 'legacy-access');
        expect(bundle['refreshToken'], 'legacy-refresh');
      },
    );

    test(
      'logout clear() supprime bundle + clés legacy résiduelles',
      () async {
        TokenStore.debugUseFakeSecureStorage({
          TokenStore.bundleKey: jsonEncode({
            'accessToken': 'a',
            'refreshToken': 'r',
          }),
          TokenStore.legacyAccessKey: 'stale-access',
          TokenStore.legacyRefreshKey: 'stale-refresh',
        });
        SharedPreferences.setMockInitialValues({
          TokenStore.legacyAccessKey: 'prefs-access',
          TokenStore.legacyRefreshKey: 'prefs-refresh',
        });

        await TokenStore.clear();

        expect(TokenStore.debugCache(), isNull);
        expect(TokenStore.debugSecureMap, isEmpty);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(TokenStore.legacyAccessKey), isNull);
        expect(prefs.getString(TokenStore.legacyRefreshKey), isNull);
      },
    );
  });

  group('Hydratation startup', () {
    test(
      'hydrate() charge SecureStorage → cache avant lecture métier',
      () async {
        final encoded = jsonEncode({
          'accessToken': 'persisted-access',
          'refreshToken': 'persisted-refresh',
        });
        TokenStore.debugUseFakeSecureStorage({
          TokenStore.bundleKey: encoded,
        });

        expect(TokenStore.debugCache(), isNull);
        expect(TokenStore.debugIsHydrated(), isFalse);

        await TokenStore.hydrate();

        expect(TokenStore.debugIsHydrated(), isTrue);
        expect(TokenStore.debugCache()?.accessToken, 'persisted-access');
        expect(TokenStore.debugCache()?.refreshToken, 'persisted-refresh');

        // Lecture suivante = hit cache (pas de dépendance à un 2e read).
        TokenStore.debugSecureMap!.clear();
        expect(await TokenStore.getAccessToken(), 'persisted-access');
        expect(await TokenStore.getRefreshToken(), 'persisted-refresh');
      },
    );
  });
}
