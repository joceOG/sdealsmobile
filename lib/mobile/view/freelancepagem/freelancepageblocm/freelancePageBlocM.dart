import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageEventM.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageStateM.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/models/freelance_model.dart';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';

/// Timeout réseau Freelance — évite un Loading indéfini.
const Duration _kFreelanceTimeout = Duration(seconds: 15);

String _userFreelanceError(Object error) {
  return 'Impossible de charger les freelances. Réessayez.';
}

String _userCategoriesError(Object error) {
  return 'Impossible de charger les catégories. Réessayez.';
}

class FreelancePageBlocM
    extends Bloc<FreelancePageEventM, FreelancePageStateM> {
  FreelancePageBlocM({
    ApiClient? apiClient,
    this.requestTimeout = _kFreelanceTimeout,
  })  : _apiClient = apiClient ?? ApiClient(),
        super(FreelancePageStateM.initial()) {
    on<LoadCategorieDataM>(_onLoadCategorieDataM);
    on<LoadFreelancersEvent>(_onLoadFreelancers);
    on<LoadServicesEvent>(_onLoadServices);
    on<FilterByCategoryEvent>(_onFilterByCategory);
    on<SearchFreelancerEvent>(_onSearchFreelancer);
    on<ClearFiltersEvent>(_onClearFilters);
    on<SubmitFreelanceRegistrationEvent>(_onSubmitFreelanceRegistration);
  }

  final ApiClient _apiClient;
  final Duration requestTimeout;

  Future<void> _onLoadCategorieDataM(
    LoadCategorieDataM event,
    Emitter<FreelancePageStateM> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      const nomgroupe = 'Freelance';
      if (kDebugMode) {
        print('Chargement des catégories pour le groupe: $nomgroupe');
      }
      final List<Categorie> listCategorie = await _apiClient
          .fetchCategorie(nomgroupe)
          .timeout(requestTimeout);

      emit(state.copyWith(
        listItems: listCategorie,
        isLoading: false,
        error: null,
      ));

      // STAB-13B Phase 2 : freelances uniquement (Services populaires hors hub V1).
      // LoadServicesEvent reste disponible mais n'est plus déclenché ici.
      add(LoadFreelancersEvent());
    } on TimeoutException {
      emit(state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les catégories. Réessayez.',
      ));
    } catch (error) {
      emit(state.copyWith(
        isLoading: false,
        error: _userCategoriesError(error),
      ));
      if (kDebugMode) {
        print('Erreur chargement catégories: $error');
      }
    }
  }

  Future<void> _onLoadFreelancers(
    LoadFreelancersEvent event,
    Emitter<FreelancePageStateM> emit,
  ) async {
    emit(state.copyWith(
      isLoadingFreelancers: true,
      freelancersError: null,
    ));

    try {
      if (kDebugMode) {
        print('Chargement des freelances depuis le backend...');
      }

      final Map<String, dynamic> response = await _apiClient
          .fetchFreelances(
            page: 1,
            limit: 50,
            sortBy: 'rating',
          )
          .timeout(requestTimeout);

      final List<Map<String, dynamic>> freelancesData =
          (response['freelances'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();

      final List<FreelanceModel> freelancers = [];
      for (final data in freelancesData) {
        try {
          freelancers.add(FreelanceModel.fromBackend(data));
        } catch (e) {
          if (kDebugMode) {
            print('Erreur conversion freelance (ID: ${data['_id']}): $e');
          }
        }
      }

      // 200 + vide -> Empty. Jamais de mock en production.
      emit(state.copyWith(
        freelancers: freelancers,
        filteredFreelancers: freelancers,
        isLoadingFreelancers: false,
        freelancersLoaded: true,
        freelancersError: null,
      ));
    } on TimeoutException {
      emit(state.copyWith(
        freelancers: const [],
        filteredFreelancers: const [],
        isLoadingFreelancers: false,
        freelancersLoaded: true,
        freelancersError: 'Impossible de charger les freelances. Réessayez.',
      ));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Erreur backend freelances (aucun mock): $error');
        print(stackTrace);
      }
      emit(state.copyWith(
        freelancers: const [],
        filteredFreelancers: const [],
        isLoadingFreelancers: false,
        freelancersLoaded: true,
        freelancersError: _userFreelanceError(error),
      ));
    }
  }

  Future<void> _onLoadServices(
    LoadServicesEvent event,
    Emitter<FreelancePageStateM> emit,
  ) async {
    emit(state.copyWith(isLoadingServices: true, servicesError: ''));

    try {
      const nomGroupe = 'Freelance';
      final List<Service> services = await _apiClient
          .fetchServices(nomGroupe)
          .timeout(requestTimeout);

      emit(state.copyWith(
        services: services,
        isLoadingServices: false,
        servicesError: '',
      ));
    } on TimeoutException {
      emit(state.copyWith(
        isLoadingServices: false,
        servicesError: 'Impossible de charger les services. Réessayez.',
      ));
    } catch (error) {
      if (kDebugMode) print('Erreur chargement services: $error');
      emit(state.copyWith(
        isLoadingServices: false,
        servicesError: 'Impossible de charger les services. Réessayez.',
      ));
    }
  }

  void _onFilterByCategory(
    FilterByCategoryEvent event,
    Emitter<FreelancePageStateM> emit,
  ) {
    final category = event.category;

    if (category == null || category == 'Tous') {
      emit(state.copyWith(
        selectedCategory: category,
        filteredFreelancers: _applySearch(state.freelancers, state.searchQuery),
      ));
    } else {
      final filtered = state.freelancers
          .where((freelancer) => freelancer.category == category)
          .toList();
      emit(state.copyWith(
        selectedCategory: category,
        filteredFreelancers: _applySearch(filtered, state.searchQuery),
      ));
    }
  }

  void _onSearchFreelancer(
    SearchFreelancerEvent event,
    Emitter<FreelancePageStateM> emit,
  ) {
    final query = event.query.toLowerCase();

    // Appliquer d'abord le filtre de catégorie s'il existe
    List<FreelanceModel> categoryFiltered = state.freelancers;
    if (state.selectedCategory != null && state.selectedCategory != 'Tous') {
      categoryFiltered = state.freelancers
          .where((freelancer) => freelancer.category == state.selectedCategory)
          .toList();
    }

    // Appliquer ensuite la recherche sur les résultats filtrés par catégorie
    final List<FreelanceModel> searchFiltered =
        _applySearch(categoryFiltered, query);

    emit(state.copyWith(
      searchQuery: query,
      filteredFreelancers: searchFiltered,
    ));
  }

  void _onClearFilters(
    ClearFiltersEvent event,
    Emitter<FreelancePageStateM> emit,
  ) {
    emit(state.copyWith(
      selectedCategory: null,
      searchQuery: '',
      filteredFreelancers: state.freelancers,
    ));
  }

  // ✅ NOUVELLE MÉTHODE : Gérer l'inscription freelance
  Future<void> _onSubmitFreelanceRegistration(
    SubmitFreelanceRegistrationEvent event,
    Emitter<FreelancePageStateM> emit,
  ) async {
    emit(state.copyWith(
      isRegistrationLoading: true,
      registrationError: null,
      registrationSuccess: null,
    ));

    print("🚀 Démarrage inscription freelance: ${event.formData.toString()}");

    try {
      final apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null) {
        throw Exception('URL API non configurée');
      }

      // ✅ ÉTAPE 1: Utiliser user existant si présent, sinon créer
      String userId;
      if ((event.formData['existingUserId'] as String?)?.isNotEmpty == true) {
        userId = event.formData['existingUserId'];
        print("✅ Utilisateur existant détecté: $userId (pas de réinscription)");
      } else {
        final userData = _prepareUserDataForFreelance(event.formData);
        print("📤 Création utilisateur pour freelance: $userData");

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
        userId = userResult['utilisateur']['_id'];
        print("✅ Utilisateur créé avec ID: $userId");
      }

      // ✅ ÉTAPE 2: Créer le freelance avec le nouveau modèle
      final freelanceData = _prepareFreelanceData(event.formData, userId);
      print("📤 Création freelance: $freelanceData");

      final freelanceResponse = await http.post(
        Uri.parse("$apiUrl/freelance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(freelanceData),
      );

      if (freelanceResponse.statusCode == 201 ||
          freelanceResponse.statusCode == 200) {
        print("✅ Freelance créé avec succès!");

        // Recharger la liste des freelances pour inclure le nouveau
        add(LoadFreelancersEvent());

        emit(state.copyWith(
          isRegistrationLoading: false,
          registrationSuccess:
              "🎉 Inscription freelance réussie ! Bienvenue dans l'équipe Soutrali !",
        ));
      } else {
        final errorData = jsonDecode(freelanceResponse.body);
        print("❌ Erreur création freelance: ${freelanceResponse.body}");
        emit(state.copyWith(
          isRegistrationLoading: false,
          registrationError:
              "Erreur création freelance: ${errorData['error'] ?? freelanceResponse.body}",
        ));
      }
    } catch (e) {
      print("💥 Erreur inscription freelance: $e");
      emit(state.copyWith(
        isRegistrationLoading: false,
        registrationError: "Erreur d'inscription: $e",
      ));
    }
  }

  // ✅ PRÉPARATION DES DONNÉES UTILISATEUR POUR FREELANCE
  Map<String, dynamic> _prepareUserDataForFreelance(
      Map<String, dynamic> formData) {
    // Récupérer les données personnelles
    final fullName = formData['fullName'] as String? ?? '';
    final split = splitPersonNameInput(fullName);
    final nom = split.nom;
    final prenom = split.prenom;

    return {
      "nom": nom,
      if (prenom != null && prenom.isNotEmpty) "prenom": prenom,
      "telephone": formData['phone'] ?? '',
      "email": formData['email'] ?? '',
      "password":
          formData['password'] ?? 'freelance123', // Mot de passe par défaut
      "genre": formData['gender'] ?? 'Homme',
      "role": "freelance", // ✅ Ajouter le rôle freelance
    };
  }

  // ✅ PRÉPARATION DES DONNÉES FREELANCE (MODÈLE UNIFIÉ)
  Map<String, dynamic> _prepareFreelanceData(
      Map<String, dynamic> formData, String userId) {
    // Convertir les catégories sélectionnées
    final selectedCategories =
        formData['selectedCategories'] as Set<String>? ?? {};
    final mainCategory =
        selectedCategories.isNotEmpty ? selectedCategories.first : 'Autre';

    // Compétences depuis les étapes du formulaire
    final skills = <String>[];
    if (formData['skills'] != null) {
      skills.addAll(List<String>.from(formData['skills']));
    }
    if (formData['selectedServices'] != null) {
      final services = formData['selectedServices'] as Set<String>? ?? {};
      skills.addAll(services);
    }

    return {
      // Champs de base
      "utilisateur": userId,
      "name": formData['fullName'] ?? '',
      "job": mainCategory,
      "category": mainCategory,

      // Image de profil
      "imagePath": formData['profileImagePath'] ?? '',

      // Système de performance
      "rating": 0,
      "completedJobs": 0,
      "isTopRated": false,
      "isFeatured": false,
      "isNew": true,
      "responseTime": 24,

      // Compétences et tarification
      "skills": skills,
      "hourlyRate": formData['hourlyRate'] ?? formData['minimumRate'] ?? 0,
      "description": formData['description'] ?? formData['bio'] ?? '',

      // Informations professionnelles
      "experienceLevel": _convertExperienceLevel(formData['experienceLevel']),
      "availabilityStatus": _convertAvailability(formData['availability']),
      "workingHours": formData['workingHours'] ?? 'Temps partiel',

      // Localisation et contact
      "location": formData['location'] ?? '',
      "phoneNumber": formData['phone'] ?? '',

      // Portfolio (sera rempli plus tard)
      "portfolioItems": _preparePortfolioItems(formData),

      // Documents de vérification
      "verificationDocuments": {
        "isVerified": false,
        "cni1": formData['cniImagePath'],
        "selfie": formData['selfieImagePath'],
      },

      // Statistiques business
      "totalEarnings": 0,
      "currentProjects": 0,
      "clientSatisfaction": 0,

      // Préférences
      "preferredCategories": selectedCategories.toList(),
      "minimumProjectBudget":
          (formData['hourlyRate'] ?? 0) * 8, // Estimation 1 jour
      "maxProjectsPerMonth": formData['maxProjectsPerMonth'] ?? 5,

      // Statut du compte
      "accountStatus": "Pending",
      "subscriptionType": "Free"
    };
  }

  // ✅ CONVERTIR LE NIVEAU D'EXPÉRIENCE
  String _convertExperienceLevel(dynamic experience) {
    if (experience == null) return 'Débutant';
    final exp = experience.toString().toLowerCase();
    if (exp.contains('expert') || exp.contains('senior')) return 'Expert';
    if (exp.contains('intermédiaire') || exp.contains('intermediate'))
      return 'Intermédiaire';
    return 'Débutant';
  }

  // ✅ CONVERTIR LA DISPONIBILITÉ
  String _convertAvailability(dynamic availability) {
    if (availability == null) return 'Disponible';
    final avail = availability.toString().toLowerCase();
    if (avail.contains('temps plein') || avail.contains('full'))
      return 'Temps plein';
    if (avail.contains('occupé') || avail.contains('busy')) return 'Occupé';
    return 'Disponible';
  }

  // ✅ PRÉPARER LES ÉLÉMENTS DU PORTFOLIO
  List<Map<String, dynamic>> _preparePortfolioItems(
      Map<String, dynamic> formData) {
    final portfolioItems = <Map<String, dynamic>>[];

    // Récupérer les projets du portfolio si disponibles
    if (formData['portfolioProjects'] != null) {
      final projects = formData['portfolioProjects'] as List?;
      for (var project in projects ?? []) {
        if (project is Map<String, dynamic>) {
          portfolioItems.add({
            'title': project['title'] ?? '',
            'description': project['description'] ?? '',
            'imageUrl': project['imageUrl'] ?? '',
            'projectUrl': project['projectUrl'] ?? '',
            'technologies': project['technologies'] ?? [],
          });
        }
      }
    }

    return portfolioItems;
  }

  // Méthode utilitaire pour appliquer la recherche
  List<FreelanceModel> _applySearch(
      List<FreelanceModel> freelancers, String query) {
    if (query.isEmpty) {
      return freelancers;
    }

    return freelancers.where((freelancer) {
      return freelancer.name.toLowerCase().contains(query) ||
          freelancer.job.toLowerCase().contains(query) ||
          freelancer.description.toLowerCase().contains(query) ||
          freelancer.skills.any((skill) => skill.toLowerCase().contains(query));
    }).toList();
  }
}
