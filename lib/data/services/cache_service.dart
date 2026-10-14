import 'package:hive_flutter/hive_flutter.dart';

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
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  /// Sauvegarde des données en cache avec un timestamp
  Future<void> cacheData(String key, dynamic data, {Duration? ttl}) async {
    await init();
    final expiry =
        DateTime.now().add(ttl ?? _defaultTtl).millisecondsSinceEpoch;

    // Si c'est un objet complexe, on l'encode en JSON si nécessaire,
    // mais Hive gère bien les Maps/Lists basiques.
    // Pour être sûr, on stocke souvent le JSON stringifié ou la Map.

    await _box!.put(key, {
      'data': data,
      'expiry': expiry,
    });
  }

  /// Récupère les données si elles sont encore dans le délai de fraîcheur.
  /// Une entrée périmée n'est pas effacée ici : [readRetained] peut encore
  /// la proposer hors ligne, jusqu'à sa limite de conservation.
  Future<dynamic> getCachedData(String key) async {
    await init();
    final retained = await readRetained(key);
    if (retained == null || !retained.fresh) return null;
    return retained.data;
  }

  /// Lecture après fermeture de l'app. [fresh] est faux quand le délai
  /// d'actualisation est dépassé, tant que la conservation (6 jours après
  /// l'expiration) n'est pas atteinte.
  Future<({dynamic data, bool fresh})?> readRetained(String key) async {
    await init();
    if (!_box!.containsKey(key)) return null;

    final record = Map<dynamic, dynamic>.from(_box!.get(key) as Map);
    final expiry = record['expiry'];
    if (expiry is! int) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    const retainAfterExpiry = Duration(days: 6);
    if (now > expiry + retainAfterExpiry.inMilliseconds) {
      await _box!.delete(key);
      return null;
    }
    return (data: record['data'], fresh: now <= expiry);
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

  /// Efface toutes les clés commençant par [prefix] (invalidation ciblée,
  /// sans vider le reste du cache catalogue).
  Future<void> removeByPrefix(String prefix) async {
    await init();
    final keys = _box!.keys
        .where((k) => k is String && k.startsWith(prefix))
        .toList();
    if (keys.isNotEmpty) await _box!.deleteAll(keys);
  }
}

/// Hive relit les objets JSON en `Map<dynamic, dynamic>`.
/// La conversion est immédiate : `List.cast` lève l'erreur seulement à la lecture.
List<Map<String, dynamic>> asStringKeyMaps(dynamic raw) {
  if (raw is! List) return const [];
  final out = <Map<String, dynamic>>[];
  for (final item in raw) {
    if (item is Map) out.add(Map<String, dynamic>.from(item));
  }
  return out;
}
