import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class CacheService {
  static const String _boxName = 'api_cache';
  static const Duration _defaultTtl = Duration(hours: 1);

  // Singleton
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  Box? _box;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox(_boxName);
  }

  /// Sauvegarde des données en cache avec un timestamp
  Future<void> cacheData(String key, dynamic data, {Duration? ttl}) async {
    await init();
    final expiry = DateTime.now().add(ttl ?? _defaultTtl).millisecondsSinceEpoch;
    
    // Si c'est un objet complexe, on l'encode en JSON si nécessaire, 
    // mais Hive gère bien les Maps/Lists basiques.
    // Pour être sûr, on stocke souvent le JSON stringifié ou la Map.
    
    await _box!.put(key, {
      'data': data,
      'expiry': expiry,
    });
  }

  /// Récupère les données si elles sont valides (non expirées)
  Future<dynamic> getCachedData(String key) async {
    await init();
    if (!_box!.containsKey(key)) return null;

    final record = _box!.get(key) as Map;
    final expiry = record['expiry'] as int;
    
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      await _box!.delete(key);
      return null;
    }

    return record['data'];
  }

  /// Efface tout le cache
  Future<void> clearCache() async {
    await init();
    await _box!.clear();
  }

  /// Efface une clé spécifique
  Future<void> remove(String key) async {
    await init();
    await _box!.delete(key);
  }
}
