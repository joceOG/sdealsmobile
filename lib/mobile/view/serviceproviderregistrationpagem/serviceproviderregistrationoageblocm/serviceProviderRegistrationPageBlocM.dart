import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'serviceProviderRegistrationPageEventM.dart';
import 'serviceProviderRegistrationPageStateM.dart';

class ServiceProviderRegistrationBlocM extends Bloc<
    ServiceProviderRegistrationEventM, ServiceProviderRegistrationStateM> {
  ServiceProviderRegistrationBlocM()
      : super(ServiceProviderRegistrationInitial()) {
    on<SubmitServiceProviderRegistrationEvent>(_onSubmitRegistration);
  }

  Future<void> _onSubmitRegistration(
    SubmitServiceProviderRegistrationEvent event,
    Emitter<ServiceProviderRegistrationStateM> emit,
  ) async {
    emit(ServiceProviderRegistrationLoading());
    print("🚀 Démarrage inscription prestataire: ${event.formData.toString()}");

    try {
      final apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null) {
        throw Exception('URL API non configurée');
      }

      // ✅ ÉTAPE 1: Utiliser l'utilisateur existant si présent, sinon créer
      String userId;
      if ((event.formData['existingUserId'] as String?)?.isNotEmpty == true) {
        userId = event.formData['existingUserId'];
        print("✅ Utilisateur existant détecté: $userId (pas de réinscription)");
      } else {
        final userData = _prepareUserData(event.formData);
        print("📤 Création utilisateur: $userData");

        final userResponse = await http.post(
          Uri.parse("$apiUrl/register"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(userData),
        );

        if (userResponse.statusCode != 200 && userResponse.statusCode != 201) {
          final errorData = jsonDecode(userResponse.body);
          throw Exception(
              "Erreur création utilisateur: ${errorData['error'] ?? userResponse.body}");
        }

        final userResult = jsonDecode(userResponse.body);
        print("🔍 Réponse API utilisateur: $userResult");

        // Vérifier la structure de la réponse
        if (userResult['utilisateur'] != null) {
          userId = userResult['utilisateur']['_id'];
          print("✅ Utilisateur créé avec ID: $userId");
        } else if (userResult['_id'] != null) {
          // Si la structure est différente
          userId = userResult['_id'];
          print("✅ Utilisateur créé avec ID (structure alternative): $userId");
        } else {
          print("❌ Structure de réponse inattendue: $userResult");
          throw Exception("Structure de réponse utilisateur inattendue");
        }
      }

      // ✅ ÉTAPE 2: multipart/form-data (aligné dashboard) pour envoyer selfie / photo profil
      final prestataireData = _preparePrestataireData(event.formData, userId);
      print("📤 Création prestataire: $prestataireData");

      final prestataireResponse = await _postPrestataireMultipart(
        apiUrl: apiUrl!,
        data: prestataireData,
        userId: userId,
        token: event.token,
      );

      if (prestataireResponse.statusCode == 201 ||
          prestataireResponse.statusCode == 200) {
        print("✅ Prestataire créé avec succès!");

        // ✅ NOUVEAU : Mettre à jour les rôles de l'utilisateur connecté
        await _updateUserRoles(userId);

        emit(ServiceProviderRegistrationSuccess(
            message:
                'Inscription réussie. Bienvenue sur Soutrali Deals.'));
      } else {
        dynamic errorData;
        try {
          errorData = jsonDecode(prestataireResponse.body);
        } catch (_) {
          errorData = null;
        }
        print("❌ Erreur création prestataire: ${prestataireResponse.body}");
        final msg = errorData is Map && errorData['error'] != null
            ? errorData['error'].toString()
            : prestataireResponse.body;
        emit(ServiceProviderRegistrationFailure(
          error: "Erreur création prestataire: $msg",
        ));
      }
    } catch (e) {
      print("💥 Erreur inscription: $e");
      emit(ServiceProviderRegistrationFailure(
          error: "Erreur d'inscription: $e"));
    }
  }

  // ✅ PRÉPARATION DES DONNÉES UTILISATEUR
  Map<String, dynamic> _prepareUserData(Map<String, dynamic> formData) {
    // Séparer le nom complet en nom et prénom
    final fullName = formData['fullName'] as String? ?? '';
    final nameParts = fullName.trim().split(' ');
    final nom = nameParts.isNotEmpty ? nameParts.first : '';
    final prenom = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final phone = formData['phone'] ?? '';
    // Mot de passe choisi par l'utilisateur — jamais dérivé du téléphone
    final password = (formData['password'] as String?)?.trim() ?? '';
    if (password.length < 6) {
      throw Exception(
          'Mot de passe requis (6 caractères minimum) pour créer le compte');
    }

    return {
      "nom": nom,
      "prenom": prenom,
      "telephone": phone,
      "email": formData['email'] ?? '',
      "password": password,
      "genre": formData['gender'] ?? 'Homme',
      "role": "prestataire",
    };
  }

  /// POST /prestataire en multipart (champs texte + fichier [selfie] si photo choisie).
  Future<http.Response> _postPrestataireMultipart({
    required String apiUrl,
    required Map<String, dynamic> data,
    required String userId,
    String? token,
  }) async {
    final uri = Uri.parse('$apiUrl/prestataire');
    final request = http.MultipartRequest('POST', uri);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final maps = data['localisationmaps'];
    Map<String, dynamic> locMap;
    if (maps is Map<String, dynamic>) {
      locMap = maps;
    } else if (maps is Map) {
      locMap = Map<String, dynamic>.from(maps);
    } else {
      locMap = {'latitude': 0.0, 'longitude': 0.0};
    }

    void field(String k, String v) => request.fields[k] = v;

    field('utilisateur', userId);
    field('service', '${data['service'] ?? ''}');
    final cat = data['category'];
    if (cat != null && '$cat'.isNotEmpty) field('category', '$cat');
    field('prixprestataire', '${data['prixprestataire'] ?? 0}');
    field('localisation', '${data['localisation'] ?? 'Abidjan'}');
    field('note', '${data['note'] ?? 0}');
    field('verifier', (data['verifier'] == true) ? 'true' : 'false');
    field('localisationmaps', jsonEncode(locMap));
    field('description', '${data['description'] ?? ''}');
    field('zoneIntervention', jsonEncode(data['zoneIntervention'] ?? []));
    field('specialite', jsonEncode(data['specialite'] ?? []));
    field('anneeExperience', '${data['anneeExperience'] ?? '0'}');
    field('rayonIntervention', '${data['rayonIntervention'] ?? 10}');
    field('tarifHoraireMin', '${data['tarifHoraireMin'] ?? 0}');
    field('tarifHoraireMax', '${data['tarifHoraireMax'] ?? 0}');
    field('numeroCNI', '${data['numeroCNI'] ?? ''}');
    field('numeroRCCM', '${data['numeroRCCM'] ?? ''}');
    field('numeroAssurance', '${data['numeroAssurance'] ?? ''}');
    field('nbMission', '${data['nbMission'] ?? 0}');
    field('nbAvis', '${data['nbAvis'] ?? 0}');
    field('revenus', '${data['revenus'] ?? 0}');
    field('clients', jsonEncode(data['clients'] ?? []));
    field('source', '${data['source'] ?? 'sdealsmobile'}');
    // status contrôlé côté serveur — ne pas envoyer depuis le client

    final profilePath = data['profileImage'] as String?;
    if (profilePath != null && profilePath.isNotEmpty) {
      final file = File(profilePath);
      if (await file.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'selfie',
            profilePath,
            filename: profilePath.split(RegExp(r'[/\\]')).last,
          ),
        );
      }
    }

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // ✅ NOUVELLE MÉTHODE : Mettre à jour les rôles de l'utilisateur
  Future<void> _updateUserRoles(String userId) async {
    try {
      // Note: La mise à jour des rôles sera gérée dans l'écran après l'inscription
      // car le BLoC n'a pas accès au context
      print("✅ Rôle PRESTATAIRE à ajouter pour l'utilisateur: $userId");
    } catch (e) {
      print("❌ Erreur lors de la mise à jour des rôles: $e");
    }
  }

  // ✅ PRÉPARATION DES DONNÉES PRESTATAIRE
  // Les clés reçues sont déjà mappées par _prepareBackendData() dans l'écran.
  Map<String, dynamic> _preparePrestataireData(
      Map<String, dynamic> formData, String userId) {
    return {
      "utilisateur": userId,
      "service": formData['service'] ?? '',
      "category": formData['category'] ?? '',
      "prixprestataire": formData['prixprestataire'] ?? 0,
      "localisation": formData['localisation'] ?? 'Abidjan',
      "localisationmaps":
          formData['localisationmaps'] ?? {'latitude': 0.0, 'longitude': 0.0},
      "description": formData['description'] ?? '',
      "zoneIntervention": formData['zoneIntervention'] ?? [],
      "note": formData['note'] ?? 0,
      "verifier": formData['verifier'] ?? false,
      "specialite": formData['specialite'] ?? [],
      "anneeExperience": formData['anneeExperience'] ?? '0',
      "rayonIntervention": formData['rayonIntervention'] ?? 10,
      "tarifHoraireMin": formData['tarifHoraireMin'] ?? 0,
      "tarifHoraireMax": formData['tarifHoraireMax'] ?? 0,
      "numeroCNI": formData['numeroCNI'] ?? '',
      "numeroRCCM": formData['numeroRCCM'] ?? '',
      "numeroAssurance": formData['numeroAssurance'] ?? '',
      "nbMission": formData['nbMission'] ?? 0,
      "nbAvis": formData['nbAvis'] ?? 0,
      "revenus": formData['revenus'] ?? 0,
      "clients": formData['clients'] ?? [],
      if ((formData['profileImage'] as String?)?.isNotEmpty == true)
        "profileImage": formData['profileImage'],
    };
  }
}
