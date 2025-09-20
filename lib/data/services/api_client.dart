import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:diacritic/diacritic.dart';
import '../models/article.dart';
import '../models/groupe.dart';
import '../models/service.dart';
import '../models/utilisateur.dart';


// http://180.149.197.115:3000/


class ApiClient {
  // URL de production
  // final String baseUrl='http://180.149.197.115:3000/api';
  // URL configurable selon la plateforme

  var apiUrl = dotenv.env['API_URL'] ;

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
           final groupeNom = removeDiacritics(cat.groupe.nomgroupe.toLowerCase());
           final targetNom = removeDiacritics(nomGroupe.toLowerCase());
           return groupeNom == targetNom;
         }).toList();

         print('Catégories trouvées pour le groupe "$nomGroupe": ${filteredCategories.length}');
         return filteredCategories;
       } else {
         throw Exception('Échec de récupération des catégories: ${response.statusCode}');
       }
     } catch (e) {
       print('Erreur dans fetchCategorie: $e');
       throw Exception('Échec de chargement des catégories: $e');
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
        throw Exception('Échec de récupération des catégories: ${response.statusCode}');
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

        List<Service> allServices = servicesJson.map((json) {
          try {
            return Service.fromJson(json);
          } catch (e) {
            print('Erreur parsing service: $e pour $json');
            return null;
          }
        }).whereType<Service>().toList(); // filtre les null

        // Afficher les services avec données manquantes pour debug
        for (var s in allServices) {
          if (s.categorie == null ||
              s.categorie?.groupe == null ||
              s.categorie?.groupe.nomgroupe == null) {
            print('Service avec valeur manquante: ${s.nomservice}');
          }
        }

        // Filtrage sûr par groupe
        List<Service> filteredServices = allServices.where((s) {
          final groupeNom = s.categorie?.groupe?.nomgroupe;
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
        List<Article> articles = articlesJson.map((json) => Article.fromJson(json)).toList();
        print('Articles récupérés: ${articles.length}');
        return articles;
      } else {
        throw Exception('Échec de récupération des articles: ${response.statusCode}');
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


  Future<Utilisateur> registerUser(Utilisateur utilisateur) async {
    final uri = Uri.parse("$apiUrl/register");
    var request = http.MultipartRequest("POST", uri);

    // Champs texte
    request.fields['nom'] = utilisateur.nom ?? "";
    request.fields['prenom'] = utilisateur.prenom ?? "";
    request.fields['email'] = utilisateur.email ?? "";
    request.fields['password'] = utilisateur.password ?? "";
    request.fields['telephone'] = utilisateur.telephone ?? "";
    request.fields['genre'] = utilisateur.genre ?? "";
    request.fields['note'] = utilisateur.note ?? "";
    request.fields['dateNaissance'] = utilisateur.dateNaissance ?? "";
    request.fields['role'] = utilisateur.role ?? "";

    // Photo profil
    if (utilisateur.photoProfil != null && File(utilisateur.photoProfil!).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath("photoProfil", utilisateur.photoProfil!));
    }

    print("📤 Champs envoyés utilisateur : ${request.fields}");
    print("📤 Fichiers envoyés utilisateur : ${request.files.map((f) => f.filename).toList()}");

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print("📥 Status: ${response.statusCode}");
    print("📥 Body: $responseBody");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(responseBody);
      return data["utilisateur"] != null
          ? Utilisateur.fromJson(data["utilisateur"])
          : Utilisateur.fromJson(data);
    } else {
      try {
        final error = jsonDecode(responseBody);
        throw Exception(error["message"] ?? error["error"] ?? "Erreur lors de l'inscription");
      } catch (_) {
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

       if (response.statusCode == 200) {
         // Sauvegarde du token si rememberMe activé
         if (rememberMe && data["token"] != null) {
           // Exemple: SharedPreferences
           // final prefs = await SharedPreferences.getInstance();
           // await prefs.setString("token", data["token"]);
         }
         return data; // { utilisateur: {...}, token: "xxx" }
       } else {
         throw Exception(data["error"] ?? "Erreur inconnue lors de la connexion");
       }
     } catch (e) {
       throw Exception("Erreur de connexion: $e");
     }
   }

  Future<Utilisateur> registerPrestataire(Map<String, dynamic> formData) async {
    // Étape 1 : Construire l’objet Utilisateur à partir du form
    final fullName = (formData["fullName"] ?? "").trim();
    final parts = fullName.split(" ");
    final nom = parts.isNotEmpty ? parts.first : "";
    final prenom = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    String? dateNaissanceStr;
    if (formData["dateNaissance"] != null && formData["dateNaissance"] is DateTime) {
      dateNaissanceStr = (formData["dateNaissance"] as DateTime).toIso8601String();
    } else if (formData["dateNaissance"] is String) {
      dateNaissanceStr = formData["dateNaissance"];
    }

    final utilisateur = Utilisateur(
      idutilisateur: "",
      nom: nom,
      prenom: prenom,
      email: formData["email"],
      password: formData["password"],
      telephone: formData["telephone"],
      genre: formData["genre"],
      note: formData["note"] ?? "",
      photoProfil: formData["photoProfil"],
      dateNaissance: dateNaissanceStr,
      role: "Prestataire",
    );

    // Étape 2 : Enregistrer l’utilisateur via ton endpoint
    final newUser = await registerUser(utilisateur);

    if (newUser.idutilisateur.isEmpty) {
      throw Exception("Impossible de créer l’utilisateur avant d’enregistrer le prestataire");
    }

    // ✅ Calcul automatique prixprestataire
    final tarifMin = (formData["tarifHoraireMin"] ?? 0) as num;
    final tarifMax = (formData["tarifHoraireMax"] ?? 0) as num;
    final prixMoyen = ((tarifMin + tarifMax) / 2).toDouble();

    // Étape 3 : Construire la requête multipart pour Prestataire
    var uri = Uri.parse("$apiUrl/prestataire");
    var request = http.MultipartRequest("POST", uri);

    // Champs texte obligatoires
    request.fields['utilisateur'] = newUser.idutilisateur;
    request.fields['service'] = formData['service'] ?? "";
    request.fields['prixprestataire'] = prixMoyen.toString();
    request.fields['anneeExperience'] = (formData['anneeExperience'] ?? 0).toString();
    request.fields['description'] = formData['description'] ?? "";
    request.fields['tarifHoraireMin'] = tarifMin.toString();
    request.fields['tarifHoraireMax'] = tarifMax.toString();
    request.fields['localisation'] = formData['localisation'] ?? "";
    request.fields['numeroAssurance'] = formData['numeroAssurance'] ?? "";
    request.fields['numeroRCCM'] = formData['numeroRCCM'] ?? "";
    request.fields['nbMission'] = (formData['nbMission'] ?? 0).toString();
    request.fields['revenus'] = (formData['revenus'] ?? 0).toString();
    request.fields['verifier'] = ((formData['verifier'] ?? false) as bool).toString();

    // Listes → encodage JSON
    request.fields['specialite'] = jsonEncode(formData['specialite'] ?? []);
    request.fields['zoneIntervention'] = jsonEncode(formData['zoneIntervention'] ?? []);
    request.fields['clients'] = jsonEncode(formData['clients'] ?? []);
    request.fields['localisationMaps'] = jsonEncode(formData['localisationMaps'] ?? {});

    // Ajout des fichiers
    Future<void> addFile(String key, dynamic path) async {
      if (path != null && path is String && File(path).existsSync()) {
        request.files.add(await http.MultipartFile.fromPath(key, path));
      }
    }

    await addFile("cni1", formData["cni1"]);
    await addFile("cni2", formData["cni2"]);
    await addFile("selfie", formData["selfie"]);
    await addFile("attestationAssurance", formData["attestationAssurance"]);

    // Diplômes multiples
    if (formData["diplomeCertificat"] != null && formData["diplomeCertificat"] is List) {
      for (var filePath in formData["diplomeCertificat"]) {
        if (filePath is String && File(filePath).existsSync()) {
          request.files.add(await http.MultipartFile.fromPath("diplomeCertificat", filePath));
        }
      }
    }

    print("📤 Champs envoyés : ${request.fields}");
    print("📤 Fichiers envoyés : ${request.files.map((f) => f.filename).toList()}");

    // Étape 4 : Envoi
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    print("📥 Status: ${response.statusCode}");
    print("📥 Body: $responseBody");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(responseBody);

      // ⚠️ suppose que ton backend renvoie { utilisateur: {...}, token: "..." }
      final utilisateurJson = json['utilisateur'];
      final token = json['token'];

      final utilisateurComplet = Utilisateur.fromJson(utilisateurJson);
      utilisateurComplet.token = token;

      return utilisateurComplet; // ✅ tu renvoies l’utilisateur complet
    } else {
      try {
        final error = jsonDecode(responseBody);
        throw Exception(error["message"] ?? error["error"] ?? "Erreur lors de la création du prestataire");
      } catch (_) {
        throw Exception("Erreur inconnue (${response.statusCode})");
      }
    }
  }
}

// 180.149.197.115:3000/api/categorie
//https://api.soutralideals.net/api