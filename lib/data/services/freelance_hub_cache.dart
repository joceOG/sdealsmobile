import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'cache_service.dart';

/// Stockage clé/valeur minimal derrière [FreelanceHubCache].
/// Par défaut : le [CacheService] (Hive) déjà utilisé par `ApiClient`.
abstract class HubCacheStore {
  Future<dynamic> read(String key);
  Future<void> write(String key, dynamic value, Duration ttl);
  Future<void> removeByPrefix(String prefix);
}

class CacheServiceHubStore implements HubCacheStore {
  const CacheServiceHubStore();

  @override
  Future<dynamic> read(String key) => CacheService().getCachedData(key);

  @override
  Future<void> write(String key, dynamic value, Duration ttl) =>
      CacheService().cacheData(key, value, ttl: ttl);

  @override
  Future<void> removeByPrefix(String prefix) =>
      CacheService().removeByPrefix(prefix);
}

/// Entrée lue : données + âge (pour décider de rafraîchir ou non).
class HubCacheEntry {
  const HubCacheEntry({required this.items, required this.age});

  final List<Map<String, dynamic>> items;
  final Duration age;
}

/// Cache « afficher puis actualiser » des listes du hub Freelance.
///
/// - **Validité** : [maxAge] (au-delà, l'entrée est ignorée) ; [freshFor]
///   (en deçà, aucun appel réseau n'est nécessaire).
/// - **Clés** : version | propriétaire | périmètre | type | paramètres
///   (catégorie, tri, pagination). Deux filtres ne partagent jamais une entrée.
/// - **Propriétaire** : `public` pour les listes servies sans authentification
///   (cas de `GET /freelance`, appelé sans jeton). Une donnée privée DOIT
///   passer un `owner` = identifiant du compte, jamais `public`.
/// - **Invalidation** : [invalidateScope] après mutation ; [clearAll] à la
///   déconnexion / expiration de session.
/// - Toute erreur de stockage est avalée : le cache ne casse jamais le chargement.
class FreelanceHubCache {
  FreelanceHubCache({
    HubCacheStore? store,
    this.freshFor = const Duration(minutes: 2),
    this.maxAge = const Duration(minutes: 30),
    DateTime Function()? clock,
  })  : _store = store ?? const CacheServiceHubStore(),
        _clock = clock ?? DateTime.now;

  /// Instance de l'application. Pas d'état en mémoire : tout passe par le
  /// stockage, donc rien n'est « gardé en vie » comme un BLoC.
  /// Non final pour permettre aux tests d'injecter un stockage isolé.
  static FreelanceHubCache shared = FreelanceHubCache();

  static const String publicOwner = 'public';
  static const String _root = 'hub:v1:';

  final Duration freshFor;
  final Duration maxAge;
  final HubCacheStore _store;
  final DateTime Function() _clock;

  String key({
    String owner = publicOwner,
    String scope = 'freelance',
    required String kind,
    String params = '',
  }) =>
      '$_root$owner:$scope:$kind:$params';

  Future<HubCacheEntry?> read(String key) async {
    try {
      final raw = await _store.read(key);
      if (raw is! Map) return null;
      final storedAt = raw['storedAt'];
      final json = raw['json'];
      if (storedAt is! int || json is! String) return null;
      final age = _clock().difference(
        DateTime.fromMillisecondsSinceEpoch(storedAt),
      );
      if (age > maxAge || age.isNegative) return null;
      final decoded = jsonDecode(json);
      if (decoded is! List) return null;
      return HubCacheEntry(
        items: decoded.whereType<Map>().map((m) {
          return Map<String, dynamic>.from(m);
        }).toList(),
        age: age,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('FreelanceHubCache.read: $e');
      return null;
    }
  }

  bool isFresh(HubCacheEntry entry) => entry.age < freshFor;

  Future<void> write(String key, List<Map<String, dynamic>> items) async {
    try {
      await _store.write(
        key,
        {
          'storedAt': _clock().millisecondsSinceEpoch,
          'json': jsonEncode(items),
        },
        maxAge,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('FreelanceHubCache.write: $e');
    }
  }

  /// Après une mutation qui change ce que le hub doit afficher.
  Future<void> invalidateScope({
    String owner = publicOwner,
    String scope = 'freelance',
  }) async {
    try {
      await _store.removeByPrefix('$_root$owner:$scope:');
    } catch (e) {
      if (kDebugMode) debugPrint('FreelanceHubCache.invalidateScope: $e');
    }
  }

  /// Déconnexion, session expirée : plus aucune entrée, tous propriétaires.
  Future<void> clearAll() async {
    try {
      await _store.removeByPrefix(_root);
    } catch (e) {
      if (kDebugMode) debugPrint('FreelanceHubCache.clearAll: $e');
    }
  }
}
