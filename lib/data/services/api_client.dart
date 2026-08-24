import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:diacritic/diacritic.dart';
import '../models/article.dart';
import '../models/groupe.dart';
import '../models/service.dart';
import 'cache_service.dart';
import 'token_store.dart';

// http://180.149.197.115:3000/

// Exception spéciale pour forcer le re-login côté UI
class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException(
      [this.message = 'Session expirée. Veuillez vous reconnecter.']);
  @override
  String toString() => message;
}

/// STAB-09 — Google OK mais téléphone non vérifié (pas de session JWT).
class GooglePhoneVerificationRequiredException implements Exception {
  final String message;
  final String? email;
  const GooglePhoneVerificationRequiredException({
    this.message = 'Vérification du téléphone requise',
    this.email,
  });
  @override
  String toString() => message;
}

class ApiClient {
  // URL de production
  // final String baseUrl='http://180.149.197.115:3000/api';
  // URL configurable selon la plateforme

  var apiUrl = dotenv.env['API_URL'];

  /// Décodage UTF-8 fiable (évite les mojibake latin1 de response.body).
  static dynamic decodeJson(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static String decodeBody(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }
  // Logout uniquement si le refresh a réellement échoué (voir [_sendAuthorized]).
  static void Function()? onUnauthorized;

  /// Après un refresh réussi — AuthCubit se resynchronise depuis TokenStore.
  static void Function(String newAccessToken, String? newRefreshToken)?
      onTokenRefreshed;

  /// Single-flight partagé entre **toutes** les instances d'[ApiClient].
  static Future<String?>? _refreshFlight;

  /// Compteur de POST /refresh-token (tests AUTH-REFRESH).
  @visibleForTesting
  static int debugRefreshCallCount = 0;

  /// Remplace le POST refresh (tests) — ne doit JAMAIS passer par get/post.
  @visibleForTesting
  static Future<http.Response> Function({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  })? debugRefreshPoster;

  @visibleForTesting
  static void debugResetRefreshState() {
    _refreshFlight = null;
    debugRefreshCallCount = 0;
    debugRefreshPoster = null;
  }

  // 🔧 MÉTHODES HTTP GÉNÉRIQUES
  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// TokenStore = source de vérité ; [token] n'est qu'un fallback (tests / hors session hydratée).
  Future<String?> _resolveAccessToken({String? token}) async {
    final stored = await TokenStore.getAccessToken();
    if (stored != null && stored.isNotEmpty) return stored;
    if (token != null && token.isNotEmpty) return token;
    return null;
  }

  /// Rotation refresh token (aligné backend `/api/refresh-token`).
  ///
  /// Single-flight : N appelants concurrent attendent le **même** Future.
  /// Si [failedAccessToken] est déjà obsolète (un autre refresh a gagné),
  /// retourne le token courant **sans** nouveau POST.
  Future<String?> refreshAccessToken({String? failedAccessToken}) async {
    final latest = await TokenStore.getAccessToken();
    if (failedAccessToken != null &&
        latest != null &&
        latest.isNotEmpty &&
        latest != failedAccessToken) {
      return latest;
    }

    if (_refreshFlight != null) {
      return _refreshFlight;
    }

    final flight = _performRefresh();
    _refreshFlight = flight;
    try {
      return await flight;
    } finally {
      if (identical(_refreshFlight, flight)) {
        _refreshFlight = null;
      }
    }
  }

  Future<String?> _performRefresh() async {
    try {
      // Re-check après avoir gagné le flight (autre waiter a pu finir juste avant).
      final refresh = await TokenStore.getRefreshToken();
      if (refresh == null || refresh.isEmpty) return null;

      debugRefreshCallCount++;

      final uri = Uri.parse('$apiUrl/refresh-token');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'refreshToken': refresh});

      // Chemin dédié : jamais get/post (évite refresh récursif).
      final response = debugRefreshPoster != null
          ? await debugRefreshPoster!(uri: uri, headers: headers, body: body)
          : await http
              .post(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final data = decodeJson(response) as Map<String, dynamic>;
      final newAccess = data['token']?.toString();
      final newRefresh = data['refreshToken']?.toString();
      if (newAccess == null || newAccess.isEmpty) return null;

      // Bundle atomique access+refresh (rotation).
      await TokenStore.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      onTokenRefreshed?.call(newAccess, newRefresh);
      return newAccess;
    } catch (_) {
      return null;
    }
  }

  /// Envoi autorisé : 401 → (token déjà renouvelé ? retry) sinon single-flight refresh → retry.
  /// Logout seulement si aucun token plus récent n'existe et que le refresh échoue.
  Future<http.Response> _sendAuthorized(
    Future<http.Response> Function(String? access) send, {
    String? token,
  }) async {
    final access = await _resolveAccessToken(token: token);
    var response = await send(access);

    if (access == null || access.isEmpty || response.statusCode != 401) {
      return response;
    }

    // Un concurrent a peut‑être déjà renouvelé pendant notre round-trip.
    final latest = await TokenStore.getAccessToken();
    if (latest != null && latest.isNotEmpty && latest != access) {
      response = await send(latest);
      if (response.statusCode != 401) return response;
    }

    final refreshed =
        await refreshAccessToken(failedAccessToken: access);
    if (refreshed != null) {
      response = await send(refreshed);
      if (response.statusCode != 401) return response;
      // Session OK mais endpoint refuse — ne pas logout.
      throw const UnauthorizedException();
    }

    onUnauthorized?.call();
    throw const UnauthorizedException();
  }

  /// Multipart authentifié avec le même single-flight AUTH-REFRESH.
  ///
  /// [buildRequest] est rappelé à chaque tentative (401 → refresh → retry) :
  /// le MultipartRequest et les fichiers sont **reconstruits** (streams non réutilisables).
  Future<http.Response> sendAuthorizedMultipart(
    Future<http.MultipartRequest> Function(String? access) buildRequest, {
    String? token,
  }) {
    return _sendAuthorized(
      (access) async {
        final request = await buildRequest(access);
        final streamed =
            await request.send().timeout(const Duration(seconds: 60));
        return http.Response.fromStream(streamed);
      },
      token: token,
    );
  }

  /// JWT court Socket.io (`POST /socket-token`).
  /// Utilise [TokenStore] comme source de vérité (hint [accessToken] optionnel).
  Future<String> createSocketToken([String? accessToken]) async {
    final access = await _resolveAccessToken(token: accessToken);
    if (access == null || access.isEmpty) {
      onUnauthorized?.call();
      throw const UnauthorizedException();
    }

    final response = await http
        .post(
          Uri.parse('$apiUrl/socket-token'),
          headers: _headers(token: access),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) {
      final refreshed =
          await refreshAccessToken(failedAccessToken: access);
      if (refreshed != null) {
        final retry = await http
            .post(
              Uri.parse('$apiUrl/socket-token'),
              headers: _headers(token: refreshed),
            )
            .timeout(const Duration(seconds: 10));
        if (retry.statusCode == 200) {
          final data =
              jsonDecode(utf8.decode(retry.bodyBytes)) as Map<String, dynamic>;
          final socketToken = data['socketToken']?.toString();
          if (socketToken != null && socketToken.isNotEmpty) return socketToken;
        }
      }
      onUnauthorized?.call();
      throw const UnauthorizedException();
    }

    if (response.statusCode != 200) {
      throw Exception('Erreur socket-token ${response.statusCode}');
    }
    final data = decodeJson(response) as Map<String, dynamic>;
    final socketToken = data['socketToken']?.toString();
    if (socketToken == null || socketToken.isEmpty) {
      throw Exception('socketToken manquant');
    }
    return socketToken;
  }

  /// GET avec refresh automatique sur 401 (évite logout pendant saisie / polling).
  Future<http.Response> get(String endpoint, {String? token}) {
    return _sendAuthorized(
      (access) => http
          .get(
            Uri.parse('$apiUrl$endpoint'),
            headers: _headers(token: access),
          )
          .timeout(const Duration(seconds: 30)),
      token: token,
    );
  }

  Future<http.Response> post(String endpoint,
      {Map<String, dynamic>? body, String? token}) {
    return _sendAuthorized(
      (access) => http
          .post(
            Uri.parse('$apiUrl$endpoint'),
            headers: _headers(token: access),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30)),
      token: token,
    );
  }

  Future<http.Response> put(String endpoint,
      {Map<String, dynamic>? body, String? token}) {
    return _sendAuthorized(
      (access) => http
          .put(
            Uri.parse('$apiUrl$endpoint'),
            headers: _headers(token: access),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30)),
      token: token,
    );
  }

  Future<http.Response> delete(String endpoint,
      {String? token, Map<String, dynamic>? body}) {
    return _sendAuthorized(
      (access) => http
          .delete(
            Uri.parse('$apiUrl$endpoint'),
            headers: _headers(token: access),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30)),
      token: token,
    );
  }

  Future<http.Response> patch(String endpoint,
      {Map<String, dynamic>? body, String? token}) {
    return _sendAuthorized(
      (access) => http
          .patch(
            Uri.parse('$apiUrl$endpoint'),
            headers: _headers(token: access),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30)),
      token: token,
    );
  }

  // ✅ MÉTHODE POUR METTRE À JOUR LE PROFIL UTILISATEUR
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updateData,
    File? photoFile,
    String? token,
  }) async {
    try {
      final response = await sendAuthorizedMultipart(
        (access) async {
          final request = http.MultipartRequest(
            'PUT',
            Uri.parse('$apiUrl/utilisateur/$userId'),
          );
          if (access != null && access.isNotEmpty) {
            request.headers['Authorization'] = 'Bearer $access';
          }
          updateData.forEach((key, value) {
            if (value != null) {
              request.fields[key] = value.toString();
            }
          });
          if (photoFile != null) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'photoProfil',
                photoFile.path,
              ),
            );
          }
          return request;
        },
        token: token,
      );

      if (response.statusCode == 200) {
        return decodeJson(response);
      } else {
        throw Exception(
            'Erreur lors de la mise à jour: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur API: $e');
    }
  }

  // ✅ MÉTHODE POUR RÉCUPÉRER UN UTILISATEUR PAR ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await get('/utilisateur/$userId');
      if (response.statusCode == 200) {
        return decodeJson(response);
      } else {
        throw Exception('Erreur lors du chargement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur API: $e');
    }
  }

  Future<List<Categorie>> fetchCategorie(String nomGroupe) async {
    print('Récupération des catégories pour le groupe: $nomGroupe');
    final cacheKey = 'categories_${removeDiacritics(nomGroupe).toLowerCase()}';

    // 1️⃣ Tentative de récupération depuis le cache
    try {
      final cachedData = await CacheService().getCachedData(cacheKey);
      if (cachedData != null) {
        print('📦 Données récupérées du cache pour $cacheKey');
        List<dynamic> categoriesJson = cachedData;
        List<Categorie> allCategories = [];
        for (var json in categoriesJson) {
           try {
             if (json['groupe'] is Map<String, dynamic>) {
               var groupeJson = json['groupe'];
               var jsonCopy = Map<String, dynamic>.from(json);
               jsonCopy['groupe'] = {
                 '_id': groupeJson['_id'] as String,
                 'nomgroupe': groupeJson['nomgroupe'] as String
               };
               allCategories.add(Categorie.fromJson(jsonCopy));
             } else {
               allCategories.add(Categorie.fromJson(json));
             }
           } catch (e) {
             print('Erreur parsing catégorie cache: $e');
           }
        }
        // Filtrage local (redondant si la clé est spécifique, mais sécurisé)
        final filteredCategories = allCategories.where((cat) {
          final groupeNom = removeDiacritics(cat.groupe.nomgroupe.toLowerCase());
          final targetNom = removeDiacritics(nomGroupe.toLowerCase());
          return groupeNom == targetNom;
        }).toList();
        
        if (filteredCategories.isNotEmpty) return filteredCategories;
      }
    } catch (e) {
      print('Erreur cache categories: $e');
    }

    // 2️⃣ Appel API (si cache vide/expiré)
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/categorie'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        List<dynamic> categoriesJson = decodeJson(response);
        List<Categorie> allCategories = [];
        for (var json in categoriesJson) {
          try {
            // Si 'groupe' est un objet (populate), récupérer l'id et le nom
            if (json['groupe'] is Map<String, dynamic>) {
              var groupeJson = json['groupe'];
              var jsonCopy = Map<String, dynamic>.from(json);
              jsonCopy['groupe'] = {
                '_id': groupeJson['_id'] as String,
                'nomgroupe': groupeJson['nomgroupe'] as String
              };
              allCategories.add(Categorie.fromJson(jsonCopy));
            } else {
              // Cas où 'groupe' est déjà un ID ou nom
              allCategories.add(Categorie.fromJson(json));
            }
          } catch (e) {
            print('Erreur parsing catégorie: $e pour ${json.toString()}');
          }
        }

        // 3️⃣ Mise en cache et retour
        // On sauvegarde tout le json reçu pour pouvoir le filtrer plus tard si besoin, 
        // ou juste ce qu'on a reçu. Ici on a reçu TOUTES les catégories.
        // On devrait peut-être cacher "toutes" les catégories sous une clé, ou filtrer avant.
        // L'API renvoie TOUT. Donc on cache TOUT sous une clé générique ? 
        // Non, fetchCategorie est appelé par nomGroupe.
        // Mais l'endpoint est `/categorie` (ALL).
        // Donc on devrait cacher sous 'all_categories'.
        
        await CacheService().cacheData('all_categories', categoriesJson);
        await CacheService().cacheData(cacheKey, categoriesJson); // Aussi sous la clé spécifique pour simplifier mais c'est dupliqué

        // Filtrer les catégories par nom de groupe (insensible à casse et accents)
        final filteredCategories = allCategories.where((cat) {
          final groupeNom =
              removeDiacritics(cat.groupe.nomgroupe.toLowerCase());
          final targetNom = removeDiacritics(nomGroupe.toLowerCase());
          return groupeNom == targetNom;
        }).toList();

        print(
            'Catégories trouvées pour le groupe "$nomGroupe": ${filteredCategories.length}');
        return filteredCategories;
      } else {
        throw Exception(
            'Échec de récupération des catégories: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans fetchCategorie: $e');
      throw Exception('Échec de chargement des catégories: $e');
    }
  }

  // ✅ Favoris: ajouter (shape alignée backend + favoritePageBlocM)
  Future<void> addFavorite({
    required String token,
    required String objetType,
    required String objetId,
    required String titre,
    String? description,
    String? image,
  }) async {
    final response = await post(
      '/favorites',
      token: token,
      body: {
        'objetType': objetType,
        'objetId': objetId,
        'titre': titre,
        if (description != null) 'description': description,
        if (image != null) 'image': image,
      },
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
          'Erreur favoris: ${response.statusCode} ${response.body}');
    }
  }

  // ✅ Favoris: supprimer par id
  Future<void> deleteFavorite({
    required String token,
    required String favoriteId,
  }) async {
    final response = await delete('/favorites/$favoriteId', token: token);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Erreur suppression favori: ${response.statusCode} ${response.body}');
    }
  }

  /// Toggle favori (ajout / retrait) via objetType + objetId.
  /// Retourne `true` si désormais en favori, `false` sinon.
  Future<bool> toggleFavorite({
    required String token,
    required String objetType,
    required String objetId,
    String? titre,
    String? image,
  }) async {
    final response = await post(
      '/favorites/toggle',
      token: token,
      body: {
        'objetType': objetType,
        'objetId': objetId,
        if (titre != null) 'titre': titre,
        if (image != null) 'image': image,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = decodeJson(response);
      if (data is Map && data.containsKey('isFavorite')) {
        return data['isFavorite'] == true;
      }
      // create path returns the favorite doc → considered added
      return true;
    }
    throw Exception(
        'Erreur toggle favori: ${response.statusCode} ${response.body}');
  }

  // ✅ Signalement: créer
  Future<void> createReport(
      {required String token,
      required String targetType,
      required String targetId,
      required String reason}) async {
    final response = await post(
      '/reports',
      token: token,
      body: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
      },
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
          'Erreur signalement: ${response.statusCode} ${response.body}');
    }
  }

  // ✅ Mot de passe oublié
  Future<void> forgotPassword({required String email}) async {
    final uri = Uri.parse('$apiUrl/forgot-password');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Erreur réinitialisation: ${response.statusCode} ${response.body}');
    }
  }

  // Méthode pour récupérer toutes les catégories sans filtrage (pour débogage)
  Future<List<Categorie>> fetchAllCategories() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/categorie'));

      if (response.statusCode == 200) {
        List<dynamic> allCategoriesJson = decodeJson(response);
        List<Categorie> allCategories = [];

        // Traiter chaque catégorie
        for (var json in allCategoriesJson) {
          try {
            // Si groupe est un objet avec _id (cas populate)
            if (json['groupe'] is Map<String, dynamic>) {
              var jsonCopy = Map<String, dynamic>.from(json);
              jsonCopy['groupe'] = json['groupe']['_id'] as String;
              allCategories.add(Categorie.fromJson(jsonCopy));
            } else {
              allCategories.add(Categorie.fromJson(json));
            }
          } catch (e) {
            print('Erreur parsing catégorie: $e pour ${json.toString()}');
          }
        }

        // Log tous les groupes trouvés pour débogage
        Set<Groupe> groupes = allCategories.map((c) => c.groupe).toSet();
        print('Tous les IDs de groupe disponibles: $groupes');

        return allCategories;
      } else {
        throw Exception(
            'Échec de récupération des catégories: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans fetchAllCategories: $e');
      return [];
    }
  }

  Future<List<Service>> fetchServices(String nomGroupe) async {
    print('Récupération des services pour le groupe: $nomGroupe');
    final cacheKey = 'services_${removeDiacritics(nomGroupe).toLowerCase()}';

    // 1️⃣ Cache
    try {
      final cachedData = await CacheService().getCachedData(cacheKey);
      if (cachedData != null) {
        print('📦 Services récupérés du cache');
        List<dynamic> servicesJson = cachedData;
        List<Service> allServices = servicesJson
            .map((json) {
              try { return Service.fromJson(json); } catch (e) { return null; }
            })
            .whereType<Service>()
            .toList();
            
        List<Service> filteredServices = allServices.where((s) {
          final cat = s.categorie;
          final grp = cat == null ? null : cat.groupe;
          final groupeNom = grp == null ? null : grp.nomgroupe;
          return groupeNom != null &&
              groupeNom.toLowerCase() == nomGroupe.toLowerCase();
        }).toList();
        
        if (filteredServices.isNotEmpty) return filteredServices;
      }
    } catch (e) { print('Erreur cache services: $e'); }

    // 2️⃣ API

    try {
      final response = await http.get(Uri.parse('$apiUrl/service'));

      print('Status code de la réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> servicesJson = decodeJson(response);
        print('Nombre total de services reçus: ${servicesJson.length}');
        
        // 3️⃣ Save Cache
        await CacheService().cacheData(cacheKey, servicesJson);

        List<Service> allServices = servicesJson
            .map((json) {
              try {
                return Service.fromJson(json);
              } catch (e) {
                print('Erreur parsing service: $e pour $json');
                return null;
              }
            })
            .whereType<Service>()
            .toList(); // filtre les null

        // Afficher les services avec données manquantes pour debug
        for (var s in allServices) {
          final cat = s.categorie;
          final hasMissing = cat == null || cat.groupe.nomgroupe.isEmpty;
          if (hasMissing) {
            print('Service avec valeur manquante: ${s.nomservice}');
          }
        }

        // Filtrage sûr par groupe
        List<Service> filteredServices = allServices.where((s) {
          final cat = s.categorie;
          final grp = cat == null ? null : cat.groupe;
          final groupeNom = grp == null ? null : grp.nomgroupe;
          return groupeNom != null &&
              groupeNom.toLowerCase() == nomGroupe.toLowerCase();
        }).toList();

        print('Services filtrés: ${filteredServices.length}');
        return filteredServices;
      } else {
        throw Exception(
            'Échec de récupération des services: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans fetchServicesByGroupe: $e');
      throw Exception('Échec de chargement des services: $e');
    }
  }

  Future<List<Article>> fetchArticle() async {
    print('Récupération des articles');

    try {
      final response = await http.get(Uri.parse('$apiUrl/articles'));

      if (response.statusCode == 200) {
        List<dynamic> articlesJson = decodeJson(response);
        List<Article> articles =
            articlesJson.map((json) => Article.fromJson(json)).toList();
        print('Articles récupérés: ${articles.length}');
        return articles;
      } else {
        throw Exception(
            'Échec de récupération des articles: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans fetchArticle: $e');
      throw Exception('Échec de chargement des articles: $e');
    }
  }

  // Méthode utilitaire pour tester la connexion au backend
  Future<bool> testConnexion() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/groupe'));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Erreur de connexion au backend: $e');
      return false;
    }
  }

  /// STAB-08 — Envoi OTP téléphone (E.164).
  Future<Map<String, dynamic>> sendPhoneOtp({
    required String telephone,
    String? phoneCountry,
  }) async {
    final url = Uri.parse("$apiUrl/otp/send");
    final body = <String, dynamic>{"telephone": telephone};
    if (phoneCountry != null && phoneCountry.isNotEmpty) {
      body["phoneCountry"] = phoneCountry;
    }

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      final data = _decodeOtpResponse(response);
      if (response.statusCode == 200) return data;
      throw Exception(_otpErrorMessage(data, response.statusCode));
    } on SocketException {
      throw Exception('Connexion impossible. Vérifiez votre réseau.');
    } on http.ClientException {
      throw Exception('Connexion impossible. Vérifiez votre réseau.');
    }
  }

  /// STAB-08 — Vérifie le code OTP ; retourne `phoneVerificationToken` (éphémère).
  Future<Map<String, dynamic>> verifyPhoneOtp({
    required String telephone,
    required String code,
    String? phoneCountry,
  }) async {
    final url = Uri.parse("$apiUrl/otp/verify");
    final body = <String, dynamic>{
      "telephone": telephone,
      "code": code,
    };
    if (phoneCountry != null && phoneCountry.isNotEmpty) {
      body["phoneCountry"] = phoneCountry;
    }

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      final data = _decodeOtpResponse(response);
      if (response.statusCode == 200) return data;
      throw Exception(_otpErrorMessage(data, response.statusCode));
    } on SocketException {
      throw Exception('Connexion impossible. Vérifiez votre réseau.');
    } on http.ClientException {
      throw Exception('Connexion impossible. Vérifiez votre réseau.');
    }
  }

  Map<String, dynamic> _decodeOtpResponse(http.Response response) {
    try {
      final decoded = decodeJson(response);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{"error": "Réponse serveur invalide"};
    } catch (_) {
      return <String, dynamic>{
        "error": "Erreur serveur (${response.statusCode})",
      };
    }
  }

  String _otpErrorMessage(Map<String, dynamic> data, int statusCode) {
    final raw = (data["error"] ?? data["message"] ?? "").toString();
    final lower = raw.toLowerCase();
    if (lower.contains('expiré') || lower.contains('expire')) {
      return 'Code expiré. Demandez un nouveau code.';
    }
    if (lower.contains('incorrect')) {
      return 'Code incorrect. Réessayez.';
    }
    if (lower.contains('trop de tentatives') ||
        lower.contains('trop de demandes') ||
        statusCode == 429) {
      return 'Trop de tentatives. Réessayez plus tard.';
    }
    if (lower.contains('patienter')) {
      return raw;
    }
    if (lower.contains('déjà utilisé') || lower.contains('deja utilise')) {
      return 'Ce numéro est déjà utilisé.';
    }
    if (lower.contains('sms') ||
        lower.contains('indisponible') ||
        statusCode == 503) {
      return 'Service SMS temporairement indisponible. Réessayez plus tard.';
    }
    if (lower.contains('invalide') && lower.contains('téléphone')) {
      return 'Numéro de téléphone invalide pour le pays sélectionné.';
    }
    if (raw.isNotEmpty &&
        !raw.contains('Exception') &&
        !raw.contains('Socket') &&
        !raw.contains('bcrypt') &&
        !raw.contains('JWT') &&
        !raw.contains('at ')) {
      return raw;
    }
    return 'Impossible de vérifier le téléphone. Réessayez.';
  }

  Future<Map<String, dynamic>> registerUser(
      {required String fullName,
      required String phone,
      String? phoneCountry,
      required String password,
      String? email,
      String? phoneVerificationToken,
      String role = "Client"}) async {
    final url = Uri.parse("$apiUrl/register");

    final parts = fullName.trim().split(" ");
    final nom = parts.isNotEmpty ? parts.first : "";
    final prenom = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    final body = <String, dynamic>{
      "nom": nom,
      "prenom": prenom,
      "telephone": phone,
      "password": password,
      "role": role,
    };
    if (phoneCountry != null && phoneCountry.isNotEmpty) {
      body["phoneCountry"] = phoneCountry;
    }
    if (email != null && email.isNotEmpty) body["email"] = email;
    if (phoneVerificationToken != null && phoneVerificationToken.isNotEmpty) {
      body["phoneVerificationToken"] = phoneVerificationToken;
    }

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return decodeJson(response) as Map<String, dynamic>;
      } else {
        String message;
        try {
          final error = decodeJson(response);
          message =
              error["error"] ?? error["message"] ?? "Erreur d'inscription";
        } catch (_) {
          message = "Erreur inconnue (${response.statusCode})";
        }
        throw Exception(message);
      }
    } on SocketException {
      throw Exception('Connexion impossible. Vérifiez votre réseau.');
    } on http.ClientException {
      throw Exception('Connexion impossible. Vérifiez votre réseau.');
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String identifiant,
    required String password,
    String? phoneCountry,
    bool rememberMe = false,
  }) async {
    try {
      // Vérification locale
      if (identifiant.trim().isEmpty || password.trim().isEmpty) {
        throw Exception("Identifiant et mot de passe requis");
      }

      // Construire le body avec identifiant unique attendu par le backend
      final Map<String, String> body = {
        "identifiant": identifiant.trim(),
        "password": password.trim(),
      };
      if (phoneCountry != null && phoneCountry.isNotEmpty) {
        body["phoneCountry"] = phoneCountry;
      }

      final response = await http.post(
        Uri.parse("$apiUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = decodeJson(response);

      assert(() {
        // Ne jamais logger le body (JWT / hash) — même en debug, pas le payload brut
        print("📥 Login status=${response.statusCode} token=${data["token"] != null}");
        return true;
      }());

      if (response.statusCode == 200) {
        // Vérifier que le token est présent
        if (data["token"] == null) {
          throw Exception("Token manquant dans la réponse");
        }

        // Sauvegarde du token si rememberMe activé
        if (rememberMe && data["token"] != null) {
          // Exemple: SharedPreferences
          // final prefs = await SharedPreferences.getInstance();
          // await prefs.setString("token", data["token"]);
        }
        return data; // { utilisateur: {...}, token: "xxx" }
      }

      throw Exception(data["error"] ?? "Échec de connexion (${response.statusCode})");
    } catch (e) {
      rethrow;
    }
  }

  /// Connexion / inscription via Google idToken.
  /// Peut lever [GooglePhoneVerificationRequiredException].
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String role = 'client',
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/login/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "idToken": idToken,
          "role": role,
        }),
      );

      final data = decodeJson(response);
      if (response.statusCode == 200) {
        if (data["token"] == null) {
          throw Exception("Token manquant dans la réponse");
        }
        return data as Map<String, dynamic>;
      }

      if (response.statusCode == 403 &&
          data is Map &&
          data["code"]?.toString() == 'PHONE_VERIFICATION_REQUIRED') {
        throw GooglePhoneVerificationRequiredException(
          email: data["email"]?.toString(),
          message: data["message"]?.toString() ??
              data["error"]?.toString() ??
              'Vérification du téléphone requise',
        );
      }

      throw Exception(
        _googleUserFacingError(
          data is Map ? data["error"]?.toString() : null,
          response.statusCode,
        ),
      );
    } on GooglePhoneVerificationRequiredException {
      rethrow;
    } on SocketException {
      throw Exception('Connexion impossible. Vérifiez votre réseau.');
    } on http.ClientException {
      throw Exception('Connexion impossible. Vérifiez votre réseau.');
    }
  }

  /// Finalise Google après OTP (STAB-09).
  Future<Map<String, dynamic>> completeGoogleSignIn({
    required String idToken,
    required String telephone,
    String? phoneCountry,
    required String phoneVerificationToken,
    String role = 'client',
  }) async {
    try {
      final body = <String, dynamic>{
        "idToken": idToken,
        "telephone": telephone,
        "phoneVerificationToken": phoneVerificationToken,
        "role": role,
      };
      if (phoneCountry != null && phoneCountry.isNotEmpty) {
        body["phoneCountry"] = phoneCountry;
      }

      final response = await http.post(
        Uri.parse("$apiUrl/login/google/complete"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      final data = decodeJson(response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data["token"] == null) {
          throw Exception("Token manquant dans la réponse");
        }
        return data as Map<String, dynamic>;
      }
      throw Exception(
        _googleUserFacingError(
          data is Map ? data["error"]?.toString() : null,
          response.statusCode,
        ),
      );
    } on SocketException {
      throw Exception('Connexion impossible. Vérifiez votre réseau.');
    } on http.ClientException {
      throw Exception('Connexion impossible. Vérifiez votre réseau.');
    }
  }

  String _googleUserFacingError(String? raw, int statusCode) {
    final msg = (raw ?? '').trim();
    final lower = msg.toLowerCase();
    if (lower.contains('annul') || lower.contains('cancel')) {
      return 'Connexion Google annulée.';
    }
    if (lower.contains('audience') || lower.contains('token google invalide')) {
      return 'Configuration Google invalide. Réessayez plus tard.';
    }
    if (lower.contains('expiré') || lower.contains('expire')) {
      return 'Session Google expirée. Réessayez.';
    }
    if (msg.isNotEmpty &&
        !msg.contains('Exception') &&
        !msg.contains('ApiException') &&
        !msg.contains('PlatformException') &&
        !msg.contains('DEVELOPER_ERROR') &&
        !msg.contains('at ')) {
      return msg;
    }
    return 'Connexion Google impossible ($statusCode). Réessayez.';
  }

  // ✅ Récupérer les rôles d'un utilisateur (CLIENT + PRESTATAIRE/FREELANCE/VENDEUR)
  Future<Map<String, dynamic>> getUserRoles(
    String userId, {
    String? token,
  }) async {
    try {
      final response = await get(
        '/utilisateur/$userId/roles',
        token: token,
      );
      if (response.statusCode == 200) {
        return decodeJson(response) as Map<String, dynamic>;
      }
      throw Exception(
          'Erreur (${response.statusCode}) lors de la récupération des rôles');
    } catch (e) {
      throw Exception('Erreur getUserRoles: $e');
    }
  }

  /// Offres « service » pour l’accueil (GET /freelance-services/home).
  Future<Map<String, dynamic>> fetchHomeFreelanceServices({int limit = 12}) async {
    final base = dotenv.env['API_URL'] ?? '';
    final uri = Uri.parse('$base/freelance-services/home').replace(
      queryParameters: {'limit': limit.toString()},
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception(
        'Échec freelance-services/home: ${response.statusCode} ${response.body}');
  }

  /// Détail d’une offre catalogue freelance (GET /freelance-services/:id).
  Future<Map<String, dynamic>> fetchFreelanceServiceById(String id) async {
    final base = dotenv.env['API_URL'] ?? '';
    final uri = Uri.parse('$base/freelance-services/$id');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception(
        'Échec freelance-services/$id: ${response.statusCode} ${response.body}');
  }

  Future<Map<String, dynamic>> fetchFreelances({
    int page = 1,
    int limit = 50,
    String sortBy = 'rating',
    String sortOrder = 'desc',
  }) async {
    print('Récupération des freelances depuis le backend (page $page)');

    try {
      final uri = Uri.parse('${dotenv.env['API_URL']}/freelance').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'sortBy': sortBy,
          'sortOrder': sortOrder,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = decodeJson(response);

        // ✅ Gestion de l'ancienne structure (array) et nouvelle (objet avec pagination)
        if (responseData.containsKey('freelances')) {
          // Nouvelle structure avec pagination
          final List<dynamic> freelancesJson = responseData['freelances'];
          print(
              'Freelances récupérés: ${freelancesJson.length} (page ${responseData['pagination']['currentPage']}/${responseData['pagination']['totalPages']})');

          return {
            'freelances': freelancesJson.cast<Map<String, dynamic>>(),
            'pagination': responseData['pagination'],
          };
        } else {
          // Ancienne structure (array direct) - pour rétrocompatibilité
          final List<dynamic> freelancesJson = responseData as List<dynamic>;
          print(
              'Freelances récupérés: ${freelancesJson.length} (format legacy)');

          return {
            'freelances': freelancesJson.cast<Map<String, dynamic>>(),
            'pagination': null,
          };
        }
      } else {
        throw Exception(
            'Échec de récupération des freelances: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans fetchFreelances: $e');
      throw Exception('Échec de chargement des freelances: $e');
    }
  }


  // 🔧 TEST DE CONNECTIVITÉ BACKEND
  Future<bool> testConnectivity() async {
    try {
      print("🔍 Test de connectivité vers: ${dotenv.env['API_URL']}");
      // ✅ CORRIGÉ : Tester directement l'endpoint prestataire au lieu de /health
      final response = await http
          .get(Uri.parse('${dotenv.env['API_URL']}/prestataire'), headers: {
        'Content-Type': 'application/json'
      }).timeout(Duration(seconds: 5));

      print("📡 Réponse test connectivité: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Échec test connectivité: $e");
      return false;
    }
  }

  // ✅ NOUVELLE MÉTHODE : Récupérer tous les prestataires
  Future<List<Map<String, dynamic>>> fetchPrestataires({bool forceRefresh = false}) async {
    print('🚀 Récupération des prestataires depuis le backend');
    print('🌐 URL complète: ${dotenv.env['API_URL']}/prestataire');
    const cacheKey = 'all_prestataires';

    // 1️⃣ Cache (sauf si refresh forcé)
    if (!forceRefresh) {
      try {
        final cachedData = await CacheService().getCachedData(cacheKey);
        if (cachedData != null) {
          print('📦 Prestataires récupérés du cache');
          return (cachedData as List).cast<Map<String, dynamic>>();
        }
      } catch (e) {
        print('Erreur cache prestataires: $e');
      }
    }

    // 2️⃣ API

    // ✅ SUPPRIMÉ : Test de connectivité inutile qui causait le problème

    try {
      final response = await http
          .get(Uri.parse('${dotenv.env['API_URL']}/prestataire'), headers: {
        'Content-Type': 'application/json'
      }).timeout(const Duration(seconds: 25));

      print('📡 Status Code: ${response.statusCode}');
      print('📋 Response Headers: ${response.headers}');
      print('📝 Response Body Length: ${response.body.length}');

      if (response.statusCode == 200) {
        List<dynamic> prestatairesJson = decodeJson(response);
        print('✅ Prestataires récupérés: ${prestatairesJson.length}');

        // Retourner la liste de Map pour que le BLoC puisse la convertir
        List<Map<String, dynamic>> result = prestatairesJson.cast<Map<String, dynamic>>();
        await CacheService().cacheData(
          cacheKey,
          result,
          ttl: const Duration(minutes: 2),
        );
        return result;
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        throw Exception(
            'Échec de récupération des prestataires: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Erreur dans fetchPrestataires: $e');
      // Si refresh forcé échoue, tenter quand même le cache
      if (forceRefresh) {
        try {
          final cachedData = await CacheService().getCachedData(cacheKey);
          if (cachedData != null) {
            print('📦 Fallback cache prestataires (après échec refresh)');
            return (cachedData as List).cast<Map<String, dynamic>>();
          }
        } catch (_) {}
      }
      throw Exception('Impossible de charger les prestataires');
    }
  }

  // Données fictives retirées — ne plus présenter de faux prestataires.

  // ✅ NOUVELLE MÉTHODE : Récupérer tous les vendeurs (CORRIGÉ PARSING !)
  Future<List<Map<String, dynamic>>> fetchVendeurs() async {
    print('Récupération des vendeurs depuis le backend');

    try {
      final response =
          await http.get(Uri.parse('${dotenv.env['API_URL']}/vendeur'));

      if (response.statusCode == 200) {
        dynamic responseData = decodeJson(response);
        print('Type de réponse: ${responseData.runtimeType}');
        // Réduire le log pour éviter les erreurs Flutter Web avec gros JSON
        final preview = response.body.length > 300
            ? response.body.substring(0, 300) + '...'
            : response.body;
        print('Aperçu réponse: ${preview.replaceAll('\n', ' ')}');

        List<dynamic> vendeursJson;

        // ✅ GESTION FLEXIBLE DU FORMAT DE RÉPONSE
        if (responseData is List) {
          // Format: [vendeur1, vendeur2, ...]
          vendeursJson = responseData;
          print('Format direct array détecté');
        } else if (responseData is Map<String, dynamic>) {
          // Format: {vendeurs: [vendeur1, vendeur2, ...]}
          vendeursJson = responseData['vendeurs'] ?? [];
          print('Format objet avec propriété vendeurs détecté');
        } else {
          throw Exception(
              'Format de réponse inattendu: ${responseData.runtimeType}');
        }

        print('Vendeurs récupérés: ${vendeursJson.length}');

        // Convertir chaque élément et valider le format
        List<Map<String, dynamic>> result = [];
        for (int i = 0; i < vendeursJson.length; i++) {
          final vendeur = vendeursJson[i];
          if (vendeur is Map<String, dynamic>) {
            result.add(vendeur);
          } else {
            print(
                'Erreur: Vendeur à l\'index $i n\'est pas un Map: ${vendeur.runtimeType}');
          }
        }

        print('Vendeurs valides après conversion: ${result.length}');
        return result;
      } else {
        throw Exception(
            'Échec de récupération des vendeurs: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans fetchVendeurs: $e');
      throw Exception('Échec de chargement des vendeurs: $e');
    }
  }

  // ✅ NOUVELLE MÉTHODE : Calculer la distance entre deux points
  Future<double> calculateDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/maps/distance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'origin': {'lat': lat1, 'lng': lng1},
          'destination': {'lat': lat2, 'lng': lng2},
        }),
      );

      if (response.statusCode == 200) {
        final data = decodeJson(response);
        // Le backend renvoie { success, distance: { text, value }, duration: { text, value } }
        // distance.value est en mètres, on convertit en km
        final distanceObj = data['distance'];
        if (distanceObj is Map) {
          final meters = (distanceObj['value'] as num?)?.toDouble() ?? 0.0;
          return meters / 1000.0;
        }
        // Fallback si format inattendu
        return _calculateLocalDistance(lat1, lng1, lat2, lng2);
      } else {
        return _calculateLocalDistance(lat1, lng1, lat2, lng2);
      }
    } catch (e) {
      print('Erreur calcul distance API: $e');
      // Fallback vers calcul local
      return _calculateLocalDistance(lat1, lng1, lat2, lng2);
    }
  }

  // ✅ MÉTHODE FALLBACK : Calcul de distance local (formule de Haversine)
  double _calculateLocalDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // ✅ NOUVELLE MÉTHODE : Géocodage d'une adresse
  Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/maps/geocode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'address': address}),
      );

      if (response.statusCode == 200) {
        final data = decodeJson(response);
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Erreur geocodeAddress: $e');
      return null;
    }
  }

  // ✅ NOUVELLE MÉTHODE : Recherche Globale
  Future<Map<String, dynamic>> searchGlobal(
    String query, {
    int? minPrice, 
    int? maxPrice, 
    String? city
  }) async {
    print('🔍 Recherche globale pour: "$query" [Filtres: min=$minPrice, max=$maxPrice, city=$city]');
    try {
      final queryParams = {
        'query': query,
        if (minPrice != null) 'minPrice': minPrice.toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.toString(),
        if (city != null) 'city': city,
      };

      final uri = Uri.parse('$apiUrl/search/global').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = decodeJson(response);
        print('✅ Résultats trouvés: ${data['counts']}');
        return data;
      } else {
        print('❌ Erreur recherche: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('🔥 Exception recherche: $e');
      return {};
    }
  }

  // ✅ NOUVELLE MÉTHODE : Suggestions de recherche
  Future<List<String>> getSuggestions(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/search/suggestions?query=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = decodeJson(response);
        return data.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }


  // ✅ NOUVELLE MÉTHODE : Rechercher des lieux proches
  Future<List<Map<String, dynamic>>> searchNearbyPlaces({
    required double lat,
    required double lng,
    double radius = 5000,
    String type = 'establishment',
    String keyword = '',
  }) async {
    try {
      // Correction : lat et lng sont obligatoires côté backend
      final uri = Uri.parse('${dotenv.env['API_URL']}/maps/nearby').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radius': radius.toString(),
          'type': type,
          if (keyword.isNotEmpty) 'keyword': keyword,
        },
      );
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = decodeJson(response);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['places'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Erreur recherche lieux proches API: $e');
      return [];
    }
  }

  // ✅ NOUVELLE MÉTHODE : Récupérer des prestataires filtrés par service
  Future<List<Map<String, dynamic>>> fetchPrestatairesByService({
    String? serviceId,
    String? serviceName,
    bool? verified,
    int? limit,
  }) async {
    print('Récupération des prestataires par service...');
    try {
      final base = '${dotenv.env['API_URL']}/prestataire';
      final Map<String, String> queryParams = {};
      if (serviceId != null && serviceId.isNotEmpty) {
        queryParams['service'] = serviceId;
      }
      if (serviceName != null && serviceName.isNotEmpty) {
        queryParams['serviceName'] = serviceName;
      }
      if (verified != null) {
        queryParams['verified'] = verified.toString();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final uri = queryParams.isEmpty
          ? Uri.parse(base)
          : Uri.parse(base).replace(queryParameters: queryParams);

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = decodeJson(response);
        return jsonList.cast<Map<String, dynamic>>();
      }

      // Si l'API ne supporte pas encore les query params, fallback client
      print('Fallback client-side filtering (status ${response.statusCode})');
      final all = await fetchPrestataires();
      return all
          .where((p) {
            bool ok = true;
            if (serviceName != null && serviceName.isNotEmpty) {
              final svc = p['service'];
              final svcName = (svc is Map<String, dynamic>)
                  ? (svc['nomservice'] ?? svc['name'] ?? '')
                  : (svc?.toString() ?? '');
              ok = ok &&
                  svcName
                      .toString()
                      .toLowerCase()
                      .contains(serviceName.toLowerCase());
            }
            if (verified != null) {
              final isVerified =
                  (p['verifier'] == true) || (p['verified'] == true);
              ok = ok && (verified ? isVerified : true);
            }
            return ok;
          })
          .take(limit ?? 9999)
          .toList();
    } catch (e) {
      print('Erreur dans fetchPrestatairesByService: $e');
      throw Exception('Échec de chargement des prestataires par service: $e');
    }
  }

  // ✅ NOUVELLE MÉTHODE : Récupérer un prestataire par son ID
  Future<Map<String, dynamic>> fetchPrestataireById(String id) async {
    print('Récupération du prestataire avec ID: $id');
    try {
      final url = '${dotenv.env['API_URL']}/prestataire/$id';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = decodeJson(response) as Map<String, dynamic>;
        print('✅ Prestataire récupéré: ${data['utilisateur']?['nom']}');
        return data;
      } else {
        throw Exception('Prestataire non trouvé (${response.statusCode})');
      }
    } catch (e) {
      print('Erreur dans fetchPrestataireById: $e');
      throw Exception('Échec de chargement du prestataire: $e');
    }
  }

  // ✅ NOUVELLE MÉTHODE : Rechercher freelances par catégorie
  Future<List<Map<String, dynamic>>> searchFreelances({
    String? category,
    String? query,
    double? minRating,
    double? maxHourlyRate,
  }) async {
    print('Recherche de freelances avec filtres');

    try {
      String endpoint = '${dotenv.env['API_URL']}/freelances/search';
      Map<String, String> queryParams = {};

      if (category != null) queryParams['category'] = category;
      if (query != null) queryParams['query'] = query;
      if (minRating != null) queryParams['minRating'] = minRating.toString();
      if (maxHourlyRate != null)
        queryParams['maxHourlyRate'] = maxHourlyRate.toString();

      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> freelancesJson = decodeJson(response);
        print('Freelances trouvés: ${freelancesJson.length}');
        return freelancesJson.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Échec de la recherche: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans searchFreelances: $e');
      throw Exception('Échec de la recherche: $e');
    }
  }

  // ✅ NOUVELLE MÉTHODE : Récupérer freelances par catégorie avec options
  Future<List<Map<String, dynamic>>> getFreelancesByCategory(
    String category, {
    int limit = 10,
    String sortBy = 'rating',
  }) async {
    print('Récupération des freelances pour la catégorie: $category');

    try {
      final uri =
          Uri.parse('${dotenv.env['API_URL']}/freelances/category/$category')
              .replace(queryParameters: {
        'limit': limit.toString(),
        'sortBy': sortBy,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> freelancesJson = decodeJson(response);
        print('Freelances trouvés pour "$category": ${freelancesJson.length}');
        return freelancesJson.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Échec de récupération par catégorie: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans getFreelancesByCategory: $e');
      throw Exception('Échec de chargement par catégorie: $e');
    }
  }

  // ✅ NOUVEAU : Récupérer un freelance par ID
  Future<Map<String, dynamic>> getFreelanceById(String id) async {
    print('Récupération du freelance: $id');

    try {
      final response =
          await http.get(Uri.parse('${dotenv.env['API_URL']}/freelance/$id'));

      if (response.statusCode == 200) {
        Map<String, dynamic> freelanceJson = decodeJson(response);
        print('Freelance récupéré: ${freelanceJson['name']}');
        return freelanceJson;
      } else {
        throw Exception(
            'Échec de récupération du freelance: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans getFreelanceById: $e');
      throw Exception('Échec de chargement du freelance: $e');
    }
  }

  // ✅ NOUVEAU : Mettre à jour la note d'un freelance
  Future<Map<String, dynamic>> updateFreelanceRating({
    required String freelanceId,
    required double rating,
    required String clientId,
  }) async {
    print('Mise à jour de la note du freelance: $freelanceId');

    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['API_URL']}/freelance/$freelanceId/rating'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rating': rating,
          'clientId': clientId,
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> result = decodeJson(response);
        print('Note mise à jour: ${result['newRating']}');
        return result;
      } else {
        throw Exception(
            'Échec de mise à jour de la note: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans updateFreelanceRating: $e');
      throw Exception('Échec de mise à jour de la note: $e');
    }
  }
}

extension ServiceRequestsApi on ApiClient {
  // ✅ Créer une prestation (commande de service)
  Future<Map<String, dynamic>> createPrestation({
    required String token,
    required String utilisateurId,
    String? prestataireId,
    String? serviceId,
    String? adresse,
    String? ville,
    DateTime? datePrestation,
    String? notesClient,
    String? moyenPaiement,
    num? montant,
  }) async {
    final body = <String, dynamic>{
      'utilisateur': utilisateurId,
      if (prestataireId != null) 'prestataire': prestataireId,
      if (serviceId != null) 'service': serviceId,
      if (adresse != null) 'adresse': adresse,
      if (ville != null) 'ville': ville,
      if (datePrestation != null) 'datePrestation': datePrestation.toIso8601String(),
      if (notesClient != null) 'notesClient': notesClient,
      if (moyenPaiement != null) 'moyenPaiement': moyenPaiement,
      // 💰 SYSTÈME GRATUIT - Montant toujours 0
      'montantTotal': 0,
      'statutPaiement': 'GRATUIT',
    };
    final res = await post(
      '/prestation',
      token: token,
      body: body,
    );
    if (res.statusCode == 201) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception(
        'Erreur création prestation: ${res.statusCode} ${res.body}');
  }

  // ✅ Mes prestations (client)
  Future<List<Map<String, dynamic>>> getMyPrestations({
    required String token,
    required String utilisateurId,
    String? status,
  }) async {
    final query = <String, String>{
      'utilisateur': utilisateurId,
      if (status != null) 'status': status,
    };
    final qs = Uri(queryParameters: query).query;
    final res = await get('/prestations?$qs', token: token);
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('prestations')) {
        return (data['prestations'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    }
    throw Exception('Erreur getMyPrestations: ${res.statusCode}');
  }

  // ✅ Récupérer un prestataire par l'ID de son utilisateur
  Future<Map<String, dynamic>?> getPrestataireByUserId(String userId, String token) async {
    try {
      final res = await get(
        '/prestataire?utilisateur=$userId',
        token: token,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = data is List ? data : (data['prestataires'] ?? []);
        if ((list as List).isEmpty) return null;
        return list[0] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erreur getPrestataireByUserId: $e');
      return null;
    }
  }

  // ✅ Récupérer prestations par statut (pour prestataires)
  Future<List<Map<String, dynamic>>> getPrestationsByStatus({
    required String token,
    required String status,
    String? prestataireId,
  }) async {
    final query = <String, String>{'statut': status};
    if (prestataireId != null) query['prestataireId'] = prestataireId;
    final qs = Uri(queryParameters: query).query;
    final res = await get('/prestations?$qs', token: token);
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('prestations')) {
        return (data['prestations'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    }
    throw Exception('Erreur getPrestationsByStatus: ${res.statusCode}');
  }

  // ✅ Mettre à jour le statut d'une prestation
  Future<Map<String, dynamic>> updatePrestationStatus({
    required String token,
    required String prestationId,
    required String newStatus,
  }) async {
    final res = await patch(
      '/prestation/$prestationId/statut',
      token: token,
      body: {'statut': newStatus},
    );
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Erreur updatePrestationStatus: ${res.statusCode}');
  }

  // ✅ Détail prestation
  Future<Map<String, dynamic>> getPrestationById({
    required String token,
    required String id,
  }) async {
    final res = await get('/prestation/$id', token: token);
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Erreur getPrestationById: ${res.statusCode}');
  }

  // ✅ Récupérer les notifications d'un utilisateur
  Future<List<Map<String, dynamic>>> getNotifications({
    required String token,
    required String userId,
    String? statut,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (statut != null) 'statut': statut,
    };
    final qs = Uri(queryParameters: query).query;
    final res = await get('/notification/user/$userId?$qs', token: token);
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is Map && data.containsKey('notifications')) {
        return (data['notifications'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    }
    throw Exception('Erreur getNotifications: ${res.statusCode}');
  }

  // ✅ Compter les notifications non lues
  Future<int> getUnreadNotificationCount({
    required String token,
    required String userId,
  }) async {
    final res =
        await get('/notification/user/$userId/unread-count', token: token);
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return data['count'] ?? 0;
    }
    throw Exception('Erreur getUnreadNotificationCount: ${res.statusCode}');
  }

  // ✅ Marquer une notification comme lue
  Future<void> markNotificationAsRead({
    required String token,
    required String notificationId,
  }) async {
    final res =
        await put('/notification/$notificationId/read', token: token);
    if (res.statusCode != 200) {
      throw Exception('Erreur markNotificationAsRead: ${res.statusCode}');
    }
  }

  // ✅ Marquer toutes les notifications comme lues
  Future<void> markAllNotificationsAsRead({
    required String token,
    required String userId,
  }) async {
    final res =
        await put('/notification/user/$userId/read-all', token: token);
    if (res.statusCode != 200) {
      throw Exception('Erreur markAllNotificationsAsRead: ${res.statusCode}');
    }
  }
}

/// 🛒 Extension pour la gestion du panier
extension CartApi on ApiClient {
  // ✅ Obtenir le panier d'un utilisateur
  Future<Map<String, dynamic>> getCart(String userId) async {
    final response = await get('/cart/user/$userId');
    if (response.statusCode == 200) {
      return ApiClient.decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception('Erreur récupération panier: ${response.statusCode}');
  }

  // ✅ Ajouter un article au panier
  Future<Map<String, dynamic>> addToCart({
    required String userId,
    required String articleId,
    required String vendeurId,
    int quantite = 1,
    Map<String, String>? variantes,
  }) async {
    final response = await post('/cart/add', body: {
      'userId': userId,
      'articleId': articleId,
      'vendeurId': vendeurId,
      'quantite': quantite,
      if (variantes != null) 'variantes': variantes,
    });

    if (response.statusCode == 200) {
      return ApiClient.decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception(
        'Erreur ajout au panier: ${response.statusCode} ${response.body}');
  }

  // ✅ Modifier la quantité d'un article
  Future<Map<String, dynamic>> updateCartItemQuantity({
    required String userId,
    required String itemId,
    required int quantite,
  }) async {
    final response = await put('/cart/user/$userId/item/$itemId', body: {
      'quantite': quantite,
    });

    if (response.statusCode == 200) {
      return ApiClient.decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception('Erreur mise à jour quantité: ${response.statusCode}');
  }

  // ✅ Retirer un article du panier
  Future<Map<String, dynamic>> removeFromCart({
    required String userId,
    required String itemId,
  }) async {
    final response = await delete('/cart/user/$userId/item/$itemId');

    if (response.statusCode == 200) {
      return ApiClient.decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception('Erreur retrait du panier: ${response.statusCode}');
  }

  // ✅ Vider le panier
  Future<Map<String, dynamic>> clearCart(String userId) async {
    final response = await delete('/cart/user/$userId/clear');

    if (response.statusCode == 200) {
      return ApiClient.decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception('Erreur vidage panier: ${response.statusCode}');
  }

  // ✅ Appliquer un code promo
  Future<Map<String, dynamic>> applyPromoCode({
    required String userId,
    required String code,
    required double reduction,
    String typeReduction = 'MONTANT_FIXE',
  }) async {
    final response = await post('/cart/user/$userId/promo', body: {
      'code': code,
      'reduction': reduction,
      'typeReduction': typeReduction,
    });

    if (response.statusCode == 200) {
      return ApiClient.decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception('Erreur application code promo: ${response.statusCode}');
  }

  // ✅ Mettre à jour l'adresse de livraison
  Future<Map<String, dynamic>> updateDeliveryAddress({
    required String userId,
    required String nom,
    required String telephone,
    required String adresse,
    required String ville,
    required String codePostal,
    String pays = 'Côte d\'Ivoire',
    String? instructions,
  }) async {
    final response = await put('/cart/user/$userId/address', body: {
      'nom': nom,
      'telephone': telephone,
      'adresse': adresse,
      'ville': ville,
      'codePostal': codePostal,
      'pays': pays,
      if (instructions != null) 'instructions': instructions,
    });

    if (response.statusCode == 200) {
      return ApiClient.decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception('Erreur mise à jour adresse: ${response.statusCode}');
  }

  // ✅ Checkout - Convertir le panier en commande
  Future<Map<String, dynamic>> checkout({
    required String userId,
    String? moyenPaiement,
    String? notesClient,
  }) async {
    final response = await post('/cart/user/$userId/checkout', body: {
      if (moyenPaiement != null) 'moyenPaiement': moyenPaiement,
      if (notesClient != null) 'notesClient': notesClient,
    });

    if (response.statusCode == 201) {
      return ApiClient.decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception('Erreur checkout: ${response.statusCode} ${response.body}');
  }
}

// 💬 MESSAGERIE API
extension MessagerieApi on ApiClient {
  /// GET authentifié via le single-flight [_sendAuthorized].
  Future<http.Response> _authedGet(Uri uri, {String? token}) {
    return _sendAuthorized(
      (access) => http
          .get(uri, headers: _headers(token: access))
          .timeout(const Duration(seconds: 30)),
      token: token,
    );
  }

  Future<http.Response> _authedPatch(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    // [patch] intègre déjà le refresh single-flight.
    return patch(endpoint, body: body, token: token);
  }

  Future<http.Response> _authedPostJson(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return post(endpoint, body: body, token: token);
  }

  // 📋 Récupérer les conversations d'un utilisateur
  Future<List<Map<String, dynamic>>> getConversations(String userId,
      {int page = 1, int limit = 50, String? token}) async {
    try {
      print('📋 Récupération conversations pour utilisateur: $userId');

      final uri = Uri.parse('$apiUrl/messages/conversations/$userId').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await _authedGet(uri, token: token);

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response);

        if (data is Map && data.containsKey('conversations')) {
          final List<dynamic> conversations = data['conversations'];
          print('✅ ${conversations.length} conversations récupérées (paginé)');
          return conversations.cast<Map<String, dynamic>>();
        } else if (data is List) {
          print('✅ ${data.length} conversations récupérées (array)');
          return data.cast<Map<String, dynamic>>();
        }

        return [];
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ Erreur getConversations: $e');
      rethrow;
    }
  }

  // 💬 Récupérer les messages d'une conversation
  Future<List<Map<String, dynamic>>> getConversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 100,
    String? userId,
    String? token,
  }) async {
    try {
      print('💬 Récupération messages pour conversation: $conversationId');

      final query = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (userId != null && userId.isNotEmpty) {
        query['userId'] = userId;
      }

      final uri =
          Uri.parse('$apiUrl/messages/conversation/$conversationId').replace(
        queryParameters: query,
      );

      final response = await _authedGet(uri, token: token);

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response);

        if (data is Map && data.containsKey('messages')) {
          final List<dynamic> messages = data['messages'];
          print('✅ ${messages.length} messages récupérés (paginé)');
          return messages.cast<Map<String, dynamic>>();
        } else if (data is List) {
          print('✅ ${data.length} messages récupérés (array)');
          return data.cast<Map<String, dynamic>>();
        }

        return [];
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ Erreur getConversationMessages: $e');
      rethrow;
    }
  }

  // 📨 Envoyer un message
  Future<Map<String, dynamic>> sendMessage({
    required String expediteur,
    required String destinataire,
    String contenu = '',
    File? pieceJointe,
    String? typePieceJointe,
    int? dureeFichier,
    String typeMessage = 'NORMAL',
    String? referenceId,
    String? referenceType,
    String? token,
  }) async {
    try {
      print('📨 Envoi message de $expediteur à $destinataire');

      if (pieceJointe != null) {
        final response = await sendAuthorizedMultipart(
          (bearer) async {
            final request =
                http.MultipartRequest('POST', Uri.parse('$apiUrl/message'));
            if (bearer != null) {
              request.headers['Authorization'] = 'Bearer $bearer';
            }
            request.fields['expediteur'] = expediteur;
            request.fields['destinataire'] = destinataire;
            if (contenu.isNotEmpty) request.fields['contenu'] = contenu;
            request.fields['typeMessage'] = typeMessage;
            if (typePieceJointe != null) {
              request.fields['typePieceJointe'] = typePieceJointe;
            }
            if (dureeFichier != null) {
              request.fields['dureeFichier'] = dureeFichier.toString();
            }
            if (referenceId != null) {
              request.fields['referenceId'] = referenceId;
            }
            if (referenceType != null) {
              request.fields['referenceType'] = referenceType;
            }
            request.files.add(await http.MultipartFile.fromPath(
                'pieceJointe', pieceJointe.path));
            return request;
          },
          token: token,
        );

        if (response.statusCode == 201) {
          print('✅ Message avec fichier envoyé');
          return ApiClient.decodeJson(response) as Map<String, dynamic>;
        }

        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      } else {
        final response = await _authedPostJson('/message', body: {
          'expediteur': expediteur,
          'destinataire': destinataire,
          'contenu': contenu,
          'typeMessage': typeMessage,
          if (referenceId != null) 'referenceId': referenceId,
          if (referenceType != null) 'referenceType': referenceType,
        }, token: token);

        if (response.statusCode == 201) {
          print('✅ Message texte envoyé');
          return ApiClient.decodeJson(response) as Map<String, dynamic>;
        }

        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur sendMessage: $e');
      rethrow;
    }
  }

  // ✅ Marquer les messages comme lus
  Future<void> markMessagesAsRead(String conversationId, String userId,
      {String? token}) async {
    try {
      print('✅ Marquage messages comme lus: $conversationId');

      final response = await _authedPatch('/messages/mark-read', body: {
        'conversationId': conversationId,
        'userId': userId,
      }, token: token);

      if (response.statusCode == 200) {
        print('✅ Messages marqués comme lus');
        return;
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ Erreur markMessagesAsRead: $e');
      rethrow;
    }
  }

  // 🗑️ Supprimer un message pour un utilisateur
  Future<void> deleteMessageForUser(String messageId, String userId,
      {String? token}) async {
    try {
      print('🗑️ Suppression message: $messageId pour $userId');
      final response = await _sendAuthorized(
        (access) => http
            .delete(
              Uri.parse('$apiUrl/message/$messageId/user'),
              headers: _headers(token: access),
              body: jsonEncode({'userId': userId}),
            )
            .timeout(const Duration(seconds: 30)),
        token: token,
      );

      if (response.statusCode == 200) {
        print('✅ Message supprimé');
        return;
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ Erreur deleteMessageForUser: $e');
      rethrow;
    }
  }

  // 🔍 Rechercher dans les messages
  Future<List<Map<String, dynamic>>> searchMessages(
    String userId,
    String query, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      print('🔍 Recherche messages: "$query"');

      final uri = Uri.parse('$apiUrl/messages/search').replace(
        queryParameters: {
          'userId': userId,
          'query': query,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response);

        if (data is Map && data.containsKey('messages')) {
          final List<dynamic> messages = data['messages'];
          print('✅ ${messages.length} messages trouvés');
          return messages.cast<Map<String, dynamic>>();
        } else if (data is List) {
          print('✅ ${data.length} messages trouvés');
          return data.cast<Map<String, dynamic>>();
        }

        return [];
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ Erreur searchMessages: $e');
      rethrow;
    }
  }

  // 📊 Statistiques des messages
  Future<Map<String, dynamic>> getMessageStats(String userId) async {
    try {
      print('📊 Récupération statistiques messages');
      // Correction : route backend = /api/messages/stats?userId=... (query param, pas path param)
      final uri = Uri.parse('$apiUrl/messages/stats').replace(
        queryParameters: {'userId': userId},
      );
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('✅ Statistiques récupérées');
        return ApiClient.decodeJson(response) as Map<String, dynamic>;
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ Erreur getMessageStats: $e');
      rethrow;
    }
  }

  // 📬 Récupérer les messages non lus
  Future<List<Map<String, dynamic>>> getUnreadMessages(String userId,
      {int page = 1, int limit = 50}) async {
    try {
      print('📬 Récupération messages non lus');

      final uri = Uri.parse('$apiUrl/messages/unread/$userId').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response);

        if (data is Map && data.containsKey('messages')) {
          final List<dynamic> messages = data['messages'];
          print('✅ ${messages.length} messages non lus');
          return messages.cast<Map<String, dynamic>>();
        } else if (data is List) {
          print('✅ ${data.length} messages non lus');
          return data.cast<Map<String, dynamic>>();
        }

        return [];
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('❌ Erreur getUnreadMessages: $e');
      rethrow;
    }
  }

  // ========================
  // 🛒 COMMANDES API
  // ========================

  /// Récupère toutes les commandes avec filtres optionnels
  Future<List<Map<String, dynamic>>> getCommandes({
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$apiUrl/commandes').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response);
        // Le backend retourne: { commandes: [...], total: X, ... }
        return List<Map<String, dynamic>>.from(data['commandes'] ?? []);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur getCommandes: $e');
      rethrow;
    }
  }

  /// Récupère une commande par ID
  Future<Map<String, dynamic>> getCommandeById(String commandeId) async {
    try {
      final response = await get('/commande/$commandeId');

      if (response.statusCode == 200) {
        return ApiClient.decodeJson(response);
      } else if (response.statusCode == 404) {
        throw Exception('Commande non trouvée');
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur getCommandeById: $e');
      rethrow;
    }
  }

  /// Met à jour une commande (ex: noter, changer statut)
  Future<Map<String, dynamic>> updateCommande({
    required String commandeId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await put(
        '/commande/$commandeId',
        body: updates,
      );

      if (response.statusCode == 200) {
        return ApiClient.decodeJson(response);
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur updateCommande: $e');
      rethrow;
    }
  }

  /// Annule une commande
  Future<bool> cancelCommande(String commandeId) async {
    try {
      final response = await updateCommande(
        commandeId: commandeId,
        updates: {'statusCommande': 'Annulée'},
      );
      return response != null;
    } catch (e) {
      print('❌ Erreur cancelCommande: $e');
      return false;
    }
  }

  // ========================
  // 🔔 NOTIFICATIONS API
  // ========================

  /// Enregistre le token FCM appareil sur le backend.
  Future<void> registerFcmToken({
    required String token,
    required String platform,
    required String accessToken,
  }) async {
    final response = await post(
      '/utilisateur/fcm-token',
      body: {'token': token, 'platform': platform},
      token: accessToken,
    );
    if (response.statusCode != 200) {
      throw Exception('FCM register ${response.statusCode}: ${response.body}');
    }
  }

  /// Retire le token FCM (logout).
  Future<void> unregisterFcmToken({
    required String token,
    required String accessToken,
  }) async {
    final response = await delete(
      '/utilisateur/fcm-token',
      token: accessToken,
      body: {'token': token},
    );
    if (response.statusCode != 200) {
      throw Exception('FCM unregister ${response.statusCode}: ${response.body}');
    }
  }

  /// Récupère les notifications d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserNotifications({
    String? token,
    required String userId,
    String? statut,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (statut != null && statut.isNotEmpty) {
        queryParams['statut'] = statut;
      }

      final qs = Uri(queryParameters: queryParams).query;
      final response = await get(
        '/notification/user/$userId?$qs',
        token: token,
      );
      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response);
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur getNotifications: $e');
      rethrow;
    }
  }

  /// Récupère le nombre de notifications non lues
  Future<int> getUserUnreadNotificationCount({
    String? token,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse('$apiUrl/notification/user/$userId/unread-count');

      Future<http.Response> once(String? access) {
        return http
            .get(uri, headers: _headers(token: access))
            .timeout(const Duration(seconds: 5));
      }

      var access = await _resolveAccessToken(token: token);
      var response = await once(access);
      if (response.statusCode == 401 &&
          access != null &&
          access.isNotEmpty) {
        final latest = await TokenStore.getAccessToken();
        if (latest != null && latest.isNotEmpty && latest != access) {
          response = await once(latest);
        } else {
          final refreshed =
              await refreshAccessToken(failedAccessToken: access);
          if (refreshed != null) {
            response = await once(refreshed);
          }
        }
      }

      // Ne pas forcer logout ici : un compteur de notifs ne doit pas détruire
      // la session pendant un formulaire. Retourner 0 si toujours 401.
      if (response.statusCode == 401) return 0;

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response);
        return data['count'] ?? 0;
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur getUnreadNotificationCount: $e');
      return 0; // Retourner 0 au lieu de crash
    }
  }

  /// Marque une notification comme lue
  Future<bool> markUserNotificationAsRead({
    String? token,
    required String notificationId,
  }) async {
    try {
      final response = await put(
        '/notification/$notificationId/read',
        token: token,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('✅ Notification marquée comme lue');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('❌ Erreur markNotificationAsRead: $e');
      return false;
    }
  }

  /// Marque toutes les notifications comme lues
  Future<bool> markAllUserNotificationsAsRead({
    String? token,
    required String userId,
  }) async {
    try {
      final response = await put(
        '/notification/user/$userId/read-all',
        token: token,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Toutes les notifications marquées comme lues');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('❌ Erreur markAllNotificationsAsRead: $e');
      return false;
    }
  }

  /// Supprime une notification
  Future<bool> deleteNotification({
    String? token,
    required String notificationId,
  }) async {
    try {
      final response = await delete(
        '/notification/$notificationId',
        token: token,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ✅ WALLET — récupérer le solde et les transactions
  Future<Map<String, dynamic>> getWallet({
    required String token,
    required String userId,
  }) async {
    final response = await get('/wallet/$userId', token: token);
    if (response.statusCode == 200) {
      return ApiClient.decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception('Erreur wallet: ${response.statusCode} — ${response.body}');
  }

  // ✅ WALLET — effectuer un transfert
  Future<Map<String, dynamic>> walletTransfert({
    required String token,
    required String payeurId,
    required String beneficiaireId,
    required double montant,
    String? description,
  }) async {
    final response = await post(
      '/wallet/transfert',
      token: token,
      body: {
        'payeurId': payeurId,
        'beneficiaireId': beneficiaireId,
        'montant': montant,
        if (description != null) 'description': description,
      },
    );

    if (response.statusCode == 201) {
      return ApiClient.decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception('Erreur transfert: ${response.statusCode} — ${response.body}');
  }

  // ✅ WALLET — historique des transactions
  Future<Map<String, dynamic>> getWalletTransactions({
    required String token,
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await get(
      '/wallet/$userId/transactions?page=$page&limit=$limit',
      token: token,
    );

    if (response.statusCode == 200) {
      return ApiClient.decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception(
        'Erreur wallet transactions: ${response.statusCode} — ${response.body}');
  }
}

// 180.149.197.115:3000/api/categorie
//https://api.soutralideals.net/api
