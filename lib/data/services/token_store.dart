import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistance sécurisée des tokens (Keychain / Keystore).
/// Migre automatiquement depuis l'ancien stockage SharedPreferences.
class TokenStore {
  static const _accessKey = 'auth_token';
  static const _refreshKey = 'refresh_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<String?> getAccessToken() async {
    await _migrateFromPrefsIfNeeded();
    return _storage.read(key: _accessKey);
  }

  static Future<String?> getRefreshToken() async {
    await _migrateFromPrefsIfNeeded();
    return _storage.read(key: _refreshKey);
  }

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
    // Nettoyer l'ancien stockage non chiffré
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  static Future<void> updateAccessToken(String accessToken) async {
    await _storage.write(key: _accessKey, value: accessToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  static Future<void> _migrateFromPrefsIfNeeded() async {
    final existing = await _storage.read(key: _accessKey);
    if (existing != null && existing.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final legacyAccess = prefs.getString(_accessKey);
    final legacyRefresh = prefs.getString(_refreshKey);
    if (legacyAccess == null || legacyAccess.isEmpty) return;

    await _storage.write(key: _accessKey, value: legacyAccess);
    if (legacyRefresh != null && legacyRefresh.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: legacyRefresh);
    }
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}
