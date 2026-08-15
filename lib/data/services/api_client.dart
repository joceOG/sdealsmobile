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
  // Callback déclenché quand le token est invalide/expiré — pour forcer logout
  static void Function()? onUnauthorized;

  /// Après un refresh réussi — pour resynchroniser AuthCubit.token
  static void Function(String newAccessToken)? onTokenRefreshed;

  bool _refreshInFlight = false;

  // 🔧 MÉTHODES HTTP GÉNÉRIQUES
  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String?> _resolveAccessToken({String? token}) async {
    if (token != null && token.isNotEmpty) return token;
    return TokenStore.getAccessToken();
  }

  /// Rotation refresh token (aligné backend `/api/refresh-token`).
  Future<String?> refreshAccessToken() async {
    if (_refreshInFlight) return TokenStore.getAccessToken();
    _refreshInFlight = true;
    try {
      final refresh = await TokenStore.getRefreshToken();
      if (refresh == null || refresh.isEmpty) return null;

      final response = await http
          .post(
            Uri.parse('$apiUrl/refresh-token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final data = decodeJson(response) as Map<String, dynamic>;
      final newAccess = data['token']?.toString();
      final newRefresh = data['refreshToken']?.toString();
      if (newAccess == null || newAccess.isEmpty) return null;

      await TokenStore.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      onTokenRefreshed?.call(newAccess);
      return newAccess;
    } catch (_) {
      return null;
    } finally {
      _refreshInFlight = false;
    }
  }

  /// JWT court Socket.io (`POST /socket-token`).
  Future<String> createSocketToken(String accessToken) async {
    final response = await http
        .post(
          Uri.parse('$apiUrl/socket-token'),
          headers: _headers(token: accessToken),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed != null) {
        final retry = await http
            .post(
              Uri.parse('$apiUrl/socket-token'),
              headers: _headers(token: refreshed),
            )
            .timeout(const Duration(seconds: 10));
        if (retry.statusCode == 200) {
          final data = jsonDecode(utf8.decode(retry.bodyBytes)) as Map<String, dynamic>;
          final socketToken = data['socketToken']?.toString();
          if (socketToken != null && socketToken.isNotEmpty) return socketToken;
        }
      }
      _checkUnauthorized(response);
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

  // Vérifie si une réponse 401 doit déclencher un logout
  void _checkUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw const UnauthorizedException();
    }
  }

  /// GET avec refresh automatique sur 401 (évite logout pendant saisie / polling).
  Future<http.Response> get(String endpoint, {String? token}) async {
    Future<http.Response> once(String? access) {
      return http
          .get(
            Uri.parse('$apiUrl$endpoint'),
            headers: _headers(token: access),
          )
          .timeout(const Duration(seconds: 30));
    }

    var access = token;
    var response = await once(access);
    if (access != null && response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed != null) {
        access = refreshed;
        response = await once(access);
      }
    }
    if (access != null) _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> post(String endpoint,
      {Map<String, dynamic>? body, String? token}) async {
    Future<http.Response> once(String? access) {
      return http
          .post(
            Uri.parse('$apiUrl$endpoint'),
            headers: _headers(token: access),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
    }

    var access = token;
    var response = await once(access);
    if (access != null && response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed != null) {
        access = refreshed;
        response = await once(access);
      }
    }
    if (access != null) _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> put(String endpoint,
      {Map<String, dynamic>? body, String? token}) async {
    Future<http.Response> once(String? access) {
      return http
          .put(
            Uri.parse('$apiUrl$endpoint'),
            headers: _headers(token: access),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
    }

    var access = token;
    var response = await once(access);
    if (access != null && response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed != null) {
        access = refreshed;
        response = await once(access);
      }
    }
    if (access != null) _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> delete(String endpoint,
      {String? token, Map<String, dynamic>? body}) async {
    Future<http.Response> once(String? access) {
      return http
          .delete(
            Uri.parse('$apiUrl$endpoint'),
            headers: _headers(token: access),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
    }

    var access = token;
    var response = await once(access);
    if (access != null && response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed != null) {
        access = refreshed;
        response = await once(access);
      }
    }
    if (access != null) _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> patch(String endpoint,
      {Map<String, dynamic>? body, String? token}) async {
    Future<http.Response> once(String? access) {
      return http
          .patch(
            Uri.parse('$apiUrl$endpoint'),
            headers: _headers(token: access),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
    }

    var access = token;
    var response = await once(access);
    if (access != null && response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed != null) {
        access = refreshed;
        response = await once(access);
      }
    }
    if (access != null) _checkUnauthorized(response);
    return response;
  }

  // ✅ MÉTHODE POUR METTRE À JOUR LE PROFIL UTILISATEUR
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updateData,
    File? photoFile,
    required String token,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$apiUrl/utilisateur/$userId'),
      );

      // Ajouter le token d'authentification
      request.headers['Authorization'] = 'Bearer $token';

      // Ajouter les données de mise à jour
      updateData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Ajouter la photo si fournie
      if (photoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'photoProfil',
            photoFile.path,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

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
      final response = await http.get(Uri.parse('$apiUrl/categorie'));
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
    final uri = Uri.parse('$apiUrl/favorites');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'objetType': objetType,
        'objetId': objetId,
        'titre': titre,
        if (description != null) 'description': description,
        if (image != null) 'image': image,
      }),
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
    final uri = Uri.parse('$apiUrl/favorites/$favoriteId');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
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
    final uri = Uri.parse('$apiUrl/favorites/toggle');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'objetType': objetType,
        'objetId': objetId,
        if (titre != null) 'titre': titre,
        if (image != null) 'image': image,
      }),
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
    final uri = Uri.parse('$apiUrl/reports');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
      }),
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

  Future<Map<String, dynamic>> registerUser(
      {required String fullName,
      required String phone,
      required String password,
      String? email,
      String role = "Client"}) async {
    final url = Uri.parse("$apiUrl/register");

    final parts = fullName.trim().split(" ");
    final nom = parts.isNotEmpty ? parts.first : "";
    final prenom = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    print("🌍 Appel API register");
    print(
        "📤 Données envoyées: { nom: $nom, prenom: $prenom, telephone: $phone, password: *****, role: $role }");

    final body = <String, dynamic>{
      "nom": nom,
      "prenom": prenom,
      "telephone": phone,
      "password": password,
      "role": role,
    };
    if (email != null && email.isNotEmpty) body["email"] = email;

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("📥 StatusCode: ${response.statusCode}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = decodeJson(response);
      print("✅ Succès Register");
      return data;
    } else {
      String message;
      try {
        final error = decodeJson(response);
        message = error["error"] ?? error["message"] ?? "Erreur d'inscription";
      } catch (_) {
        message = "Erreur inconnue (${response.statusCode})";
      }
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String identifiant,
    required String password,
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
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String role = 'client',
  }) async {
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

    throw Exception(
      data["error"]?.toString() ??
          "Échec connexion Google (${response.statusCode})",
    );
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

  // ✅ NOUVELLE MÉTHODE : Récupérer tous les freelances (avec pagination)
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

      final response = await http.get(uri);

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
    final uri = Uri.parse('$apiUrl/prestation');
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
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
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
    final query = {
      'utilisateur': utilisateurId,
      if (status != null) 'status': status
    };
    final uri =
        Uri.parse('$apiUrl/prestations').replace(queryParameters: query);
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });
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
      final uri = Uri.parse('$apiUrl/prestataire').replace(queryParameters: {'utilisateur': userId});
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));
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
    final uri =
        Uri.parse('$apiUrl/prestations').replace(queryParameters: query);
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });
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
    final uri = Uri.parse('$apiUrl/prestation/$prestationId/statut');
    final res = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'statut': newStatus}),
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
    final uri = Uri.parse('$apiUrl/prestation/$id');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });
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
    final uri = Uri.parse('$apiUrl/notification/user/$userId')
        .replace(queryParameters: query);
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });
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
    final uri = Uri.parse('$apiUrl/notification/user/$userId/unread-count');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });
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
    final uri = Uri.parse('$apiUrl/notification/$notificationId/read');
    final res = await http.put(uri, headers: {
      'Authorization': 'Bearer $token',
    });
    if (res.statusCode != 200) {
      throw Exception('Erreur markNotificationAsRead: ${res.statusCode}');
    }
  }

  // ✅ Marquer toutes les notifications comme lues
  Future<void> markAllNotificationsAsRead({
    required String token,
    required String userId,
  }) async {
    final uri = Uri.parse('$apiUrl/notification/user/$userId/read-all');
    final res = await http.put(uri, headers: {
      'Authorization': 'Bearer $token',
    });
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
  Future<http.Response> _authedGet(Uri uri, {String? token}) async {
    var access = await _resolveAccessToken(token: token);
    var response = await http
        .get(uri, headers: _headers(token: access))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed != null) {
        response = await http
            .get(uri, headers: _headers(token: refreshed))
            .timeout(const Duration(seconds: 30));
      }
    }
    if (response.statusCode == 401) _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> _authedPatch(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    var access = await _resolveAccessToken(token: token);
    var response = await patch(endpoint, body: body, token: access);
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed != null) {
        response = await patch(endpoint, body: body, token: refreshed);
      }
    }
    if (response.statusCode == 401) _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> _authedPostJson(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    var access = await _resolveAccessToken(token: token);
    var response = await post(endpoint, body: body, token: access);
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed != null) {
        response = await post(endpoint, body: body, token: refreshed);
      }
    }
    if (response.statusCode == 401) _checkUnauthorized(response);
    return response;
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
      var access = await _resolveAccessToken(token: token);

      if (pieceJointe != null) {
        Future<http.Response> sendMultipart(String? bearer) async {
          var request =
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
          if (referenceId != null) request.fields['referenceId'] = referenceId;
          if (referenceType != null) {
            request.fields['referenceType'] = referenceType;
          }
          request.files.add(await http.MultipartFile.fromPath(
              'pieceJointe', pieceJointe.path));
          final streamed =
              await request.send().timeout(const Duration(seconds: 60));
          return http.Response.fromStream(streamed);
        }

        var response = await sendMultipart(access);
        if (response.statusCode == 401) {
          final refreshed = await refreshAccessToken();
          if (refreshed != null) {
            response = await sendMultipart(refreshed);
          }
        }
        if (response.statusCode == 401) _checkUnauthorized(response);

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
        }, token: access);

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
      var access = await _resolveAccessToken(token: token);
      var response = await http.delete(
        Uri.parse('$apiUrl/message/$messageId/user'),
        headers: _headers(token: access),
        body: jsonEncode({'userId': userId}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed != null) {
          response = await http.delete(
            Uri.parse('$apiUrl/message/$messageId/user'),
            headers: _headers(token: refreshed),
            body: jsonEncode({'userId': userId}),
          ).timeout(const Duration(seconds: 30));
        }
      }
      if (response.statusCode == 401) _checkUnauthorized(response);

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
    required String token,
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

      final uri = Uri.parse('$apiUrl/notification/user/$userId').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      _checkUnauthorized(response);
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
    required String token,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse('$apiUrl/notification/user/$userId/unread-count');

      Future<http.Response> once(String access) {
        return http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $access',
          },
        ).timeout(const Duration(seconds: 5));
      }

      var access = token;
      var response = await once(access);
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed != null) {
          access = refreshed;
          response = await once(access);
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
    required String token,
    required String notificationId,
  }) async {
    try {
      final uri = Uri.parse('$apiUrl/notification/$notificationId/read');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
    required String token,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse('$apiUrl/notification/user/$userId/read-all');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
    required String token,
    required String notificationId,
  }) async {
    try {
      final uri = Uri.parse('$apiUrl/notification/$notificationId');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
    final response = await http.get(
      Uri.parse('$apiUrl/wallet/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 30));

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
    final response = await http.post(
      Uri.parse('$apiUrl/wallet/transfert'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'payeurId': payeurId,
        'beneficiaireId': beneficiaireId,
        'montant': montant,
        if (description != null) 'description': description,
      }),
    ).timeout(const Duration(seconds: 30));

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
    final uri = Uri.parse('$apiUrl/wallet/$userId/transactions').replace(
      queryParameters: {'page': '$page', 'limit': '$limit'},
    );
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return ApiClient.decodeJson(response) as Map<String, dynamic>;
    }
    throw Exception('Erreur transactions: ${response.statusCode}');
  }
}

// 180.149.197.115:3000/api/categorie
//https://api.soutralideals.net/api
