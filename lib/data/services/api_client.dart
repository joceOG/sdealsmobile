import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:diacritic/diacritic.dart';
import '../models/article.dart';
import '../models/groupe.dart';
import '../models/service.dart';

// http://180.149.197.115:3000/

class ApiClient {
  // URL de production
  // final String baseUrl='http://180.149.197.115:3000/api';
  // URL configurable selon la plateforme

  var apiUrl = dotenv.env['API_URL'];

  // 🔧 MÉTHODES HTTP GÉNÉRIQUES
  Future<http.Response> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$apiUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 30));
    return response;
  }

  Future<http.Response> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    final response = await http
        .post(
          Uri.parse('$apiUrl$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 30));
    return response;
  }

  Future<http.Response> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    final response = await http
        .put(
          Uri.parse('$apiUrl$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 30));
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$apiUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 30));
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
        return jsonDecode(response.body);
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
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du chargement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur API: $e');
    }
  }

  Future<http.Response> patch(String endpoint,
      {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse('$apiUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    return response;
  }

  Future<List<Categorie>> fetchCategorie(String nomGroupe) async {
    print('Récupération des catégories pour le groupe: $nomGroupe');
    try {
      final response = await http.get(Uri.parse('$apiUrl/categorie'));
      if (response.statusCode == 200) {
        List<dynamic> categoriesJson = jsonDecode(response.body);
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

  // ✅ Favoris: ajouter
  Future<void> addFavorite(
      {required String token,
      String? serviceId,
      required String title,
      String? image}) async {
    final uri = Uri.parse('$apiUrl/favorites');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (serviceId != null) 'service': serviceId,
        'title': title,
        if (image != null) 'image': image,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
          'Erreur favoris: ${response.statusCode} ${response.body}');
    }
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
    if (response.statusCode != 201) {
      throw Exception(
          'Erreur signalement: ${response.statusCode} ${response.body}');
    }
  }

  // Méthode pour récupérer toutes les catégories sans filtrage (pour débogage)
  Future<List<Categorie>> fetchAllCategories() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/categorie'));

      if (response.statusCode == 200) {
        List<dynamic> allCategoriesJson = jsonDecode(response.body);
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

    try {
      final response = await http.get(Uri.parse('$apiUrl/service'));

      print('Status code de la réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> servicesJson = jsonDecode(response.body);
        print('Nombre total de services reçus: ${servicesJson.length}');

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
        List<dynamic> articlesJson = jsonDecode(response.body);
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
      String role = "Client"}) async {
    final url = Uri.parse("$apiUrl/register");

    // Découper le fullName en nom et prénom
    final parts = fullName.trim().split(" ");
    final nom = parts.isNotEmpty ? parts.first : "";
    final prenom = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    print("🌍 Appel API: $url");
    print(
        "📤 Données envoyées: { nom: $nom, prenom: $prenom, telephone: $phone, password: *****, role: $role }");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nom": nom,
        "prenom": prenom,
        "telephone": phone,
        "password": password, // 👈 correspond à ton backend
        "role": role, // ✅ Ajouter le rôle
      }),
    );

    print("📥 StatusCode: ${response.statusCode}");
    print("📥 Réponse brute: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print("✅ Succès Register: $data");
      return data;
    } else {
      try {
        final error = jsonDecode(response.body);
        print("❌ Erreur API Register: $error");
        throw Exception(
            error["error"] ?? error["message"] ?? "Erreur d'inscription");
      } catch (e) {
        print("⚠️ Impossible de parser l'erreur: ${response.body}");
        throw Exception("Erreur inconnue (${response.statusCode})");
      }
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

      final data = jsonDecode(response.body);

      print("📥 Réponse login brute: ${response.body}");
      print("📥 StatusCode: ${response.statusCode}");
      print("📥 Data parsed: $data");
      print("📥 Token présent: ${data["token"] != null}");
      print("📥 Utilisateur présent: ${data["utilisateur"] != null}");

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
      } else {
        throw Exception(
            data["error"] ?? "Erreur inconnue lors de la connexion");
      }
    } catch (e) {
      throw Exception("Erreur de connexion: $e");
    }
  }

  // ✅ NOUVEAU : Récupérer les rôles d'un utilisateur
  Future<Map<String, dynamic>> getUserRoles(String userId) async {
    try {
      final response =
          await http.get(Uri.parse('$apiUrl/utilisateur/$userId/roles'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception(
          'Erreur (${response.statusCode}) lors de la récupération des rôles');
    } catch (e) {
      throw Exception('Erreur getUserRoles: $e');
    }
  }

  // ✅ NOUVELLE MÉTHODE : Récupérer tous les freelances
  Future<List<Map<String, dynamic>>> fetchFreelances() async {
    print('Récupération des freelances depuis le backend');

    try {
      final response =
          await http.get(Uri.parse('${dotenv.env['API_URL']}/freelance'));

      if (response.statusCode == 200) {
        List<dynamic> freelancesJson = jsonDecode(response.body);
        print('Freelances récupérés: ${freelancesJson.length}');

        // Retourner la liste de Map pour que le BLoC puisse la convertir
        return freelancesJson.cast<Map<String, dynamic>>();
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
  Future<List<Map<String, dynamic>>> fetchPrestataires() async {
    print('🚀 Récupération des prestataires depuis le backend');
    print('🌐 URL complète: ${dotenv.env['API_URL']}/prestataire');

    // ✅ SUPPRIMÉ : Test de connectivité inutile qui causait le problème

    try {
      final response = await http
          .get(Uri.parse('${dotenv.env['API_URL']}/prestataire'), headers: {
        'Content-Type': 'application/json'
      }).timeout(Duration(seconds: 10));

      print('📡 Status Code: ${response.statusCode}');
      print('📋 Response Headers: ${response.headers}');
      print('📝 Response Body Length: ${response.body.length}');

      if (response.statusCode == 200) {
        List<dynamic> prestatairesJson = jsonDecode(response.body);
        print('✅ Prestataires récupérés: ${prestatairesJson.length}');

        // Retourner la liste de Map pour que le BLoC puisse la convertir
        return prestatairesJson.cast<Map<String, dynamic>>();
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        throw Exception(
            'Échec de récupération des prestataires: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 Erreur dans fetchPrestataires: $e');
      // Utiliser les données de fallback en cas d'erreur
      return _getFallbackPrestataires();
    }
  }

  // 🛡️ DONNÉES DE FALLBACK EN CAS DE PROBLÈME DE CONNECTIVITÉ
  List<Map<String, dynamic>> _getFallbackPrestataires() {
    print("📦 Utilisation des données de fallback prestataires");
    return [
      {
        'idprestataire': 'fallback1',
        'utilisateur': {
          'idutilisateur': 'user1',
          'nom': 'Diallo',
          'prenom': 'Amadou',
          'email': 'amadou@example.com',
          'telephone': '+223 65 43 21 00'
        },
        'service': {
          'idservice': 'service1',
          'nomservice': 'Ménage résidentiel',
          'prixservice': 15000.0,
          'categorie': {
            'idcategorie': 'cat1',
            'nomcategorie': 'Ménage',
            'groupe': {'idgroupe': 'grp1', 'nomgroupe': 'Métiers'}
          }
        },
        'prixprestataire': 15000.0, // ✅ Requis par le modèle
        'localisation': 'Abidjan, Côte d\'Ivoire',
        'localisationmaps': {'latitude': 5.3600, 'longitude': -4.0083},
        'description': 'Service de ménage professionnel disponible 24h/7',
        'verifier': true,
        'note': '4.8', // ✅ String comme attendu
        'anneeExperience': '5',
        'specialite': ['Ménage résidentiel', 'Nettoyage bureaux'],
        // Champs optionnels pour éviter les erreurs null
        'cni1': null,
        'cni2': null,
        'selfie': null,
        'numeroCNI': null,
        'rayonIntervention': 10.0,
        'zoneIntervention': ['Abidjan'],
        'tarifHoraireMin': 2000.0,
        'tarifHoraireMax': 5000.0,
        'diplomeCertificat': null,
        'attestationAssurance': null,
        'numeroAssurance': null,
        'numeroRCCM': null
      },
      {
        'idprestataire': 'fallback2',
        'utilisateur': {
          'idutilisateur': 'user2',
          'nom': 'Traoré',
          'prenom': 'Fatoumata',
          'email': 'fatoumata@example.com',
          'telephone': '+223 76 54 32 10'
        },
        'service': {
          'idservice': 'service2',
          'nomservice': 'Jardinage',
          'prixservice': 25000.0,
          'categorie': {
            'idcategorie': 'cat2',
            'nomcategorie': 'Jardinage',
            'groupe': {'idgroupe': 'grp1', 'nomgroupe': 'Métiers'}
          }
        },
        'prixprestataire': 25000.0, // ✅ Requis par le modèle
        'localisation': 'Abidjan, Côte d\'Ivoire',
        'localisationmaps': {'latitude': 5.3700, 'longitude': -4.0200},
        'description':
            'Spécialiste en aménagement paysager et entretien jardins',
        'verifier': true,
        'note': '4.5', // ✅ String comme attendu
        'anneeExperience': '8',
        'specialite': ['Jardinage', 'Paysagisme'],
        // Champs optionnels pour éviter les erreurs null
        'cni1': null,
        'cni2': null,
        'selfie': null,
        'numeroCNI': null,
        'rayonIntervention': 15.0,
        'zoneIntervention': ['Abidjan'],
        'tarifHoraireMin': 3000.0,
        'tarifHoraireMax': 8000.0,
        'diplomeCertificat': null,
        'attestationAssurance': null,
        'numeroAssurance': null,
        'numeroRCCM': null
      }
    ];
  }

  // ✅ NOUVELLE MÉTHODE : Récupérer tous les vendeurs (CORRIGÉ PARSING !)
  Future<List<Map<String, dynamic>>> fetchVendeurs() async {
    print('Récupération des vendeurs depuis le backend');

    try {
      final response =
          await http.get(Uri.parse('${dotenv.env['API_URL']}/vendeur'));

      if (response.statusCode == 200) {
        dynamic responseData = jsonDecode(response.body);
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
        final data = jsonDecode(response.body);
        return data['distance']?.toDouble() ?? 0.0;
      } else {
        // Fallback vers calcul local si l'API échoue
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
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Erreur géocodage API: $e');
      return null;
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
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/maps/nearby'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
        final List<dynamic> jsonList = jsonDecode(response.body);
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
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
        List<dynamic> freelancesJson = jsonDecode(response.body);
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

  // ✅ NOUVELLE MÉTHODE : Récupérer freelances par catégorie
  Future<List<Map<String, dynamic>>> getFreelancesByCategory(
      String category) async {
    print('Récupération des freelances pour la catégorie: $category');

    try {
      final response = await http.get(
          Uri.parse('${dotenv.env['API_URL']}/freelances/category/$category'));

      if (response.statusCode == 200) {
        List<dynamic> freelancesJson = jsonDecode(response.body);
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
    DateTime? dateHeure,
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
      if (dateHeure != null) 'dateHeure': dateHeure.toIso8601String(),
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
      return jsonDecode(res.body) as Map<String, dynamic>;
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
      final data = jsonDecode(res.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('prestations')) {
        return (data['prestations'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    }
    throw Exception('Erreur getMyPrestations: ${res.statusCode}');
  }

  // ✅ Récupérer prestations par statut (pour prestataires)
  Future<List<Map<String, dynamic>>> getPrestationsByStatus({
    required String token,
    required String status,
  }) async {
    final query = {'status': status};
    final uri =
        Uri.parse('$apiUrl/prestations').replace(queryParameters: query);
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
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
      return jsonDecode(res.body) as Map<String, dynamic>;
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
      return jsonDecode(res.body) as Map<String, dynamic>;
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
      final data = jsonDecode(res.body);
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
      final data = jsonDecode(res.body);
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

// 180.149.197.115:3000/api/categorie
//https://api.soutralideals.net/api
