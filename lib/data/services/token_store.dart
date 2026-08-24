import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Couple access + refresh cohérent (jamais observé à moitié mis à jour).
class AuthCredentials {
  final String accessToken;
  final String? refreshToken;

  const AuthCredentials({
    required this.accessToken,
    this.refreshToken,
  });
}

/// Source de vérité des credentials (Keychain / Keystore).
///
/// - Bundle JSON unique (`auth_credentials_bundle`)
/// - Cache mémoire publié **uniquement après** écriture persistante réussie
/// - Migration legacy `auth_token` / `refresh_token` au premier accès
/// - [hydrate] à appeler au cold start avant AuthCubit / ApiClient
class TokenStore {
  static const bundleKey = 'auth_credentials_bundle';
  static const legacyAccessKey = 'auth_token';
  static const legacyRefreshKey = 'refresh_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static AuthCredentials? _cache;
  static bool _hydrated = false;
  static Future<void>? _hydrateFuture;

  /// Mode mémoire pure (pas de Secure Storage) — tests unitaires simples.
  static bool _useMemoryOnly = false;

  /// Backend Secure Storage injectable (tests migration / échec d'écriture).
  @visibleForTesting
  static Map<String, String>? debugSecureMap;

  @visibleForTesting
  static Future<void> Function(String key, String value)? debugSecureWriteHook;

  @visibleForTesting
  static AuthCredentials? debugCache() => _cache;

  @visibleForTesting
  static bool debugIsHydrated() => _hydrated;

  @visibleForTesting
  static void debugUseInMemory({AuthCredentials? seed}) {
    _useMemoryOnly = true;
    debugSecureMap = null;
    debugSecureWriteHook = null;
    _cache = seed;
    _hydrated = true;
    _hydrateFuture = null;
  }

  /// Stockage faux (Map) pour tester migration / atomicité sans Keystore.
  @visibleForTesting
  static void debugUseFakeSecureStorage([Map<String, String>? initial]) {
    _useMemoryOnly = false;
    debugSecureMap = Map<String, String>.from(initial ?? {});
    debugSecureWriteHook = null;
    _cache = null;
    _hydrated = false;
    _hydrateFuture = null;
  }

  @visibleForTesting
  static void debugReset() {
    _useMemoryOnly = false;
    debugSecureMap = null;
    debugSecureWriteHook = null;
    _cache = null;
    _hydrated = false;
    _hydrateFuture = null;
  }

  /// Charge SecureStorage → cache **avant** toute lecture métier.
  /// Idempotent ; safe à appeler plusieurs fois.
  static Future<void> hydrate() {
    return _hydrateFuture ??= _hydrateImpl();
  }

  static Future<void> _hydrateImpl() async {
    try {
      await getCredentials();
    } finally {
      _hydrated = true;
    }
  }

  static Future<AuthCredentials?> getCredentials() async {
    if (_cache != null) return _cache;

    if (_useMemoryOnly) return null;

    await _migrateFromLegacyIfNeeded();

    final raw = await _readKey(bundleKey);
    if (raw == null || raw.isEmpty) {
      _hydrated = true;
      return null;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final access = map['accessToken']?.toString();
      if (access == null || access.isEmpty) return null;
      final refresh = map['refreshToken']?.toString();
      final creds = AuthCredentials(
        accessToken: access,
        refreshToken: (refresh != null && refresh.isNotEmpty) ? refresh : null,
      );
      _cache = creds;
      _hydrated = true;
      return creds;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getAccessToken() async {
    return (await getCredentials())?.accessToken;
  }

  static Future<String?> getRefreshToken() async {
    return (await getCredentials())?.refreshToken;
  }

  /// Persiste le couple : **écrire d'abord**, publier le cache ensuite.
  ///
  /// Si l'écriture échoue, le cache mémoire reste sur l'ancienne valeur
  /// (jamais access-new en RAM + access-old sur disque).
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final previous = _cache ??
        (_useMemoryOnly ? null : await _readBundleFromDiskOnly());

    final nextRefresh = (refreshToken != null && refreshToken.isNotEmpty)
        ? refreshToken
        : previous?.refreshToken;

    final bundle = AuthCredentials(
      accessToken: accessToken,
      refreshToken: nextRefresh,
    );

    if (_useMemoryOnly) {
      _cache = bundle;
      _hydrated = true;
      return;
    }

    final encoded = jsonEncode({
      'accessToken': bundle.accessToken,
      if (bundle.refreshToken != null) 'refreshToken': bundle.refreshToken,
    });

    try {
      await _writeKey(bundleKey, encoded);
      await _deleteLegacyKeys();
      // Publier le cache seulement après persistance réussie.
      _cache = bundle;
      _hydrated = true;
    } catch (e) {
      // Restaurer explicitement l'ancien couple mémoire.
      _cache = previous;
      rethrow;
    }
  }

  /// @Deprecated — préférer [saveTokens] avec le couple complet.
  static Future<void> updateAccessToken(String accessToken) async {
    await saveTokens(accessToken: accessToken);
  }

  /// Logout : bundle + clés legacy SecureStorage + prefs.
  static Future<void> clear() async {
    _cache = null;
    if (_useMemoryOnly) {
      _hydrated = true;
      return;
    }

    await _deleteKey(bundleKey);
    await _deleteLegacyKeys();
    _hydrated = true;
  }

  /// Migration : bundle absent → lire legacy → écrire bundle → supprimer legacy.
  /// Cache publié uniquement si l'écriture du bundle réussit.
  static Future<void> _migrateFromLegacyIfNeeded() async {
    final existing = await _readKey(bundleKey);
    if (existing != null && existing.isNotEmpty) return;

    var access = await _readKey(legacyAccessKey);
    var refresh = await _readKey(legacyRefreshKey);

    if (access == null || access.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      access = prefs.getString(legacyAccessKey);
      refresh ??= prefs.getString(legacyRefreshKey);
    }

    if (access == null || access.isEmpty) return;

    final bundle = AuthCredentials(
      accessToken: access,
      refreshToken: (refresh != null && refresh.isNotEmpty) ? refresh : null,
    );
    final encoded = jsonEncode({
      'accessToken': bundle.accessToken,
      if (bundle.refreshToken != null) 'refreshToken': bundle.refreshToken,
    });

    try {
      await _writeKey(bundleKey, encoded);
      await _deleteLegacyKeys();
      _cache = bundle;
    } catch (_) {
      // Ne pas publier un cache nouveau si le bundle n'est pas persisté.
      // La session legacy reste lisible au prochain essai.
    }
  }

  static Future<AuthCredentials?> _readBundleFromDiskOnly() async {
    final raw = await _readKey(bundleKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final access = map['accessToken']?.toString();
      if (access == null || access.isEmpty) return null;
      final refresh = map['refreshToken']?.toString();
      return AuthCredentials(
        accessToken: access,
        refreshToken: (refresh != null && refresh.isNotEmpty) ? refresh : null,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _deleteLegacyKeys() async {
    await _deleteKey(legacyAccessKey);
    await _deleteKey(legacyRefreshKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(legacyAccessKey);
      await prefs.remove(legacyRefreshKey);
    } catch (_) {}
  }

  static Future<String?> _readKey(String key) async {
    if (debugSecureMap != null) return debugSecureMap![key];
    return _storage.read(key: key);
  }

  static Future<void> _writeKey(String key, String value) async {
    if (debugSecureWriteHook != null) {
      await debugSecureWriteHook!(key, value);
      // Si le hook réussit sans écrire dans la map, synchroniser la map test.
      debugSecureMap?[key] = value;
      return;
    }
    if (debugSecureMap != null) {
      debugSecureMap![key] = value;
      return;
    }
    await _storage.write(key: key, value: value);
  }

  static Future<void> _deleteKey(String key) async {
    if (debugSecureMap != null) {
      debugSecureMap!.remove(key);
      return;
    }
    if (_useMemoryOnly) return;
    await _storage.delete(key: key);
  }
}
