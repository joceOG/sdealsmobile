import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

import 'serviceProviderRegistrationPageEventM.dart';
import 'serviceProviderRegistrationPageStateM.dart';
import '../../../../data/services/authCubit.dart';

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

      // ✅ ÉTAPE 2: Créer le prestataire avec le nouveau modèle
      final prestataireData = _preparePrestataireData(event.formData, userId);
      print("📤 Création prestataire: $prestataireData");

      final prestataireResponse = await http.post(
        Uri.parse("$apiUrl/prestataire"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(prestataireData),
      );

      if (prestataireResponse.statusCode == 201 ||
          prestataireResponse.statusCode == 200) {
        print("✅ Prestataire créé avec succès!");

        // ✅ NOUVEAU : Mettre à jour les rôles de l'utilisateur connecté
        await _updateUserRoles(userId);

        emit(ServiceProviderRegistrationSuccess(
            message:
                "🎉 Inscription réussie ! Bienvenue chez Soutrali Deals !"));
      } else {
        final errorData = jsonDecode(prestataireResponse.body);
        print("❌ Erreur création prestataire: ${prestataireResponse.body}");
        emit(ServiceProviderRegistrationFailure(
          error:
              "Erreur création prestataire: ${errorData['error'] ?? prestataireResponse.body}",
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

    // Générer un mot de passe temporaire basé sur le téléphone
    final phone = formData['phone'] ?? '';
    final tempPassword =
        phone.replaceAll(RegExp(r'[^\d]'), ''); // Garder seulement les chiffres
    final finalPassword = tempPassword.isNotEmpty
        ? tempPassword
        : '123456'; // Mot de passe par défaut

    return {
      "nom": nom,
      "prenom": prenom,
      "telephone": phone,
      "email": formData['email'] ?? '',
      "password": finalPassword, // ✅ Mot de passe temporaire généré
      "genre": formData['gender'] ?? 'Homme',
      "role": "prestataire", // ✅ Ajouter le rôle prestataire
    };
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

  // ✅ PRÉPARATION DES DONNÉES PRESTATAIRE (MODÈLE BACKEND EXISTANT)
  Map<String, dynamic> _preparePrestataireData(
      Map<String, dynamic> formData, String userId) {
    return {
      // Champs requis par le backend
      "utilisateur": userId,
      "service":
          formData['service'] ?? '', // Service sélectionné par l'utilisateur
      "category": formData['category'] ?? '', // Catégorie sélectionnée
      "prixprestataire": formData['dailyRate'] ?? 0,
      "localisation": (formData['serviceAreas'] as List?)?.isNotEmpty == true
          ? (formData['serviceAreas'] as List)[0]
          : 'Abidjan',
      "localisationmaps": formData['position'] != null
          ? {
              'latitude': formData['position'].latitude,
              'longitude': formData['position'].longitude,
            }
          : formData['localisationmaps'] ?? {'latitude': 0.0, 'longitude': 0.0},
      "description": formData['description'] ?? '',
      "zoneIntervention": formData['serviceAreas'] ?? [],

      // Champs optionnels avec valeurs par défaut
      "note": 'Profil créé via inscription simplifiée',
      "verifier": false,
      "specialite": [formData['category'] ?? ''],
      "anneeExperience": '0',
      "rayonIntervention": 10,
      "tarifHoraireMin": (formData['dailyRate'] ?? 0) / 8,
      "tarifHoraireMax": (formData['dailyRate'] ?? 0) / 6,

      // Champs optionnels vides
      "numeroCNI": '',
      "numeroRCCM": '',
      "numeroAssurance": '',
      "nbMission": 0,
      "revenus": 0,
      "clients": [],
    };
  }
}
