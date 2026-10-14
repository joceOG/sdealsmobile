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
import 'package:sdealsmobile/data/services/freelance_hub_cache.dart';
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

    /// Cache « afficher puis actualiser ». `null` = aucun cache (tests unitaires
    /// du BLoC) ; les écrans passent [FreelanceHubCache.shared].
    FreelanceHubCache? cache,
  })  : _apiClient = apiClient ?? ApiClient(),
        _cache = cache,
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
  final FreelanceHubCache? _cache;
  final Duration requestTimeout;
  int _filterRequestId = 0; // anti-race : catégorie changée avant réponse

  /// Chargement complet (LoadFreelancersEvent) en cours. `isLoadingFreelancers`
  /// est partagé avec le filtre catégorie : ce drapeau évite qu'un filtre
  /// annulé ou terminé n'éteigne le chargement initial (ou l'inverse).
  bool _freelancersLoadInFlight = false;

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
      // Les freelancers sont chargés directement depuis FreelancePageScreen
      // via LoadFreelancersEvent au démarrage — pas besoin d'un second déclenchement ici.
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

  /// Convertit les maps backend en modèles (une entrée invalide est ignorée).
  List<FreelanceModel> _parseFreelancers(List<Map<String, dynamic>> raw) {
    final out = <FreelanceModel>[];
    for (final data in raw) {
      try {
        out.add(FreelanceModel.fromBackend(data));
      } catch (e) {
        if (kDebugMode) {
          print('Erreur conversion freelance (ID: ${data['_id']}): $e');
        }
      }
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _fetchFreelanceMaps({
    String? category,
  }) async {
    final Map<String, dynamic> response = await _apiClient
        .fetchFreelances(
          page: 1,
          limit: 50,
          sortBy: 'rating',
          category: category,
        )
        .timeout(requestTimeout);
    return (response['freelances'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Clé = périmètre + type + paramètres (catégorie, tri, pagination).
  String? _cacheKey({String? category}) {
    final cache = _cache;
    if (cache == null) return null;
    final cat = (category == null || category.trim().isEmpty)
        ? 'all'
        : 'cat=${category.trim().toLowerCase()}';
    return cache.key(
      kind: 'freelancers',
      params: 'p1_l50_rating_desc_$cat',
    );
  }

  Future<void> _onLoadFreelancers(
    LoadFreelancersEvent event,
    Emitter<FreelancePageStateM> emit,
  ) async {
    final cache = _cache;
    final key = _cacheKey();

    // 1) Données encore valides : affichées tout de suite, sans spinner.
    if (cache != null && key != null && !event.force) {
      final cached = await cache.read(key);
      if (cached != null) {
        final fromCache = _parseFreelancers(cached.items);
        // Un filtre catégorie actif garde sa liste filtrée.
        final keepFilter = state.selectedCategory != null &&
            state.selectedCategory != 'Tous';
        emit(state.copyWith(
          freelancers: fromCache,
          filteredFreelancers:
              keepFilter ? state.filteredFreelancers : fromCache,
          isLoadingFreelancers: false,
          freelancersLoaded: true,
          freelancersError: null,
        ));
        if (cache.isFresh(cached)) return;
        // 2) Actualisation silencieuse : en cas d'échec, les données
        // affichées restent (pas de spinner, pas de liste vidée).
        try {
          final raw = await _fetchFreelanceMaps();
          await cache.write(key, raw);
          final fresh = _parseFreelancers(raw);
          final keep = state.selectedCategory != null &&
              state.selectedCategory != 'Tous';
          emit(state.copyWith(
            freelancers: fresh,
            filteredFreelancers: keep ? state.filteredFreelancers : fresh,
            freelancersError: null,
          ));
        } catch (e) {
          if (kDebugMode) print('Actualisation freelances ignorée: $e');
        }
        return;
      }
    }

    // 3) Pas de donnée valide : chargement bloquant (spinner si liste vide).
    _freelancersLoadInFlight = true;
    emit(state.copyWith(
      isLoadingFreelancers: true,
      freelancersError: null,
    ));

    try {
      if (kDebugMode) {
        print('Chargement des freelances depuis le backend...');
      }

      final raw = await _fetchFreelanceMaps();
      final freelancers = _parseFreelancers(raw);
      if (cache != null && key != null) await cache.write(key, raw);

      // 200 + vide -> Empty. Jamais de mock en production.
      _freelancersLoadInFlight = false;
      emit(state.copyWith(
        freelancers: freelancers,
        filteredFreelancers: freelancers,
        isLoadingFreelancers: false,
        freelancersLoaded: true,
        freelancersError: null,
      ));
    } on TimeoutException {
      _freelancersLoadInFlight = false;
      emit(state.copyWith(
        freelancers: const [],
        filteredFreelancers: const [],
        isLoadingFreelancers: false,
        freelancersLoaded: true,
        freelancersError: 'Impossible de charger les freelances. Réessayez.',
      ));
    } catch (error, stackTrace) {
      _freelancersLoadInFlight = false;
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
  ) async {
    final category = event.category;

    // Catégorie effacée → réaffiche la liste complète déjà chargée.
    if (category == null || category == 'Tous') {
      emit(state.copyWith(
        selectedCategory: category,
        filterError: null,
        filteredFreelancers: _applySearch(state.freelancers, state.searchQuery),
      ));
      return;
    }

    // Anti-race : si l'utilisateur change de catégorie rapidement, seule
    // la dernière réponse met à jour l'état.
    final requestId = ++_filterRequestId;
    final cache = _cache;
    final key = _cacheKey(category: category);

    // Liste de cette catégorie encore valide : affichée sans spinner.
    var shownFromCache = false;
    if (cache != null && key != null && !event.force) {
      final cached = await cache.read(key);
      if (requestId != _filterRequestId) return;
      if (cached != null) {
        shownFromCache = true;
        emit(state.copyWith(
          selectedCategory: category,
          filteredFreelancers:
              _applySearch(_parseFreelancers(cached.items), state.searchQuery),
          isLoadingFreelancers: _freelancersLoadInFlight,
          filterError: null,
        ));
        if (cache.isFresh(cached)) return;
      }
    }

    if (!shownFromCache) {
      emit(state.copyWith(
        selectedCategory: category,
        isLoadingFreelancers: true,
        filterError: null,
      ));
    }

    try {
      final raw = await _fetchFreelanceMaps(category: category);

      // Réponse périmée : une autre catégorie a été sélectionnée entre-temps.
      if (requestId != _filterRequestId) return;

      if (cache != null && key != null) await cache.write(key, raw);
      final freelancers = _parseFreelancers(raw);

      emit(state.copyWith(
        filteredFreelancers: _applySearch(freelancers, state.searchQuery),
        isLoadingFreelancers: _freelancersLoadInFlight,
        filterError: null,
      ));
    } on TimeoutException {
      if (requestId != _filterRequestId) return;
      // Actualisation silencieuse d'une liste déjà affichée : on la garde.
      if (shownFromCache) {
        emit(state.copyWith(isLoadingFreelancers: _freelancersLoadInFlight));
        return;
      }
      // Conserve les données existantes + signale l'échec : pas de repli
      // silencieux sur une liste partielle présentée comme complète.
      emit(state.copyWith(
        isLoadingFreelancers: _freelancersLoadInFlight,
        filterError:
            'Les résultats de la catégorie n\'ont pas pu être actualisés. Réessayez.',
        // filteredFreelancers inchangé → données précédentes restent visibles
      ));
    } catch (_) {
      if (requestId != _filterRequestId) return;
      if (shownFromCache) {
        emit(state.copyWith(isLoadingFreelancers: _freelancersLoadInFlight));
        return;
      }
      emit(state.copyWith(
        isLoadingFreelancers: _freelancersLoadInFlight,
        filterError:
            'Impossible de filtrer par catégorie. Réessayez.',
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
    // Retour depuis une page catégorie/service : la requête de filtre encore
    // en vol est périmée. Sans ça, `isLoadingFreelancers` restait vrai (le hub
    // réaffichait un chargement sur des freelances déjà chargés) puis la
    // réponse tardive écrasait `filteredFreelancers` avec la catégorie quittée.
    _filterRequestId++;
    emit(state.copyWith(
      selectedCategory: null,
      searchQuery: '',
      filteredFreelancers: state.freelancers,
      isLoadingFreelancers: _freelancersLoadInFlight,
      filterError: null,
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

    try {
      final apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null) {
        throw Exception('URL API non configurée');
      }

      // ✅ ÉTAPE 1: Utiliser user existant si présent, sinon créer
      String userId;
      if ((event.formData['existingUserId'] as String?)?.isNotEmpty == true) {
        userId = event.formData['existingUserId'];
      } else {
        final userData = _prepareUserDataForFreelance(event.formData);

        final userResponse = await http.post(
          Uri.parse("$apiUrl/register"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(userData),
        );

        if (userResponse.statusCode != 200 && userResponse.statusCode != 201) {
          final errorData = jsonDecode(userResponse.body);
          throw Exception(
              "Erreur création utilisateur: ${errorData['error'] ?? 'échec inscription'}");
        }

        final userResult = jsonDecode(userResponse.body);
        userId = userResult['utilisateur']['_id'];
      }

      // ✅ ÉTAPE 2: Créer le freelance avec le nouveau modèle
      final freelanceData = _prepareFreelanceData(event.formData, userId);

      final freelanceResponse = await http.post(
        Uri.parse("$apiUrl/freelance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(freelanceData),
      );

      if (freelanceResponse.statusCode == 201 ||
          freelanceResponse.statusCode == 200) {
        // Mutation : le hub ne doit plus servir d'entrées antérieures.
        await _cache?.invalidateScope();
        add(LoadFreelancersEvent(force: true));

        emit(state.copyWith(
          isRegistrationLoading: false,
          registrationSuccess:
              "Inscription freelance réussie. Bienvenue sur Soutrali Deals.",
        ));
      } else {
        final errorData = jsonDecode(freelanceResponse.body);
        emit(state.copyWith(
          isRegistrationLoading: false,
          registrationError:
              "Erreur création freelance: ${errorData['error'] ?? 'échec'}",
        ));
      }
    } catch (e) {
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

    final password = (formData['password'] as String?)?.trim() ?? '';
    if (password.length < 6) {
      throw Exception(
          'Mot de passe requis (6 caractères minimum) pour créer le compte');
    }

    return {
      "nom": nom,
      if (prenom != null && prenom.isNotEmpty) "prenom": prenom,
      "telephone": formData['phone'] ?? '',
      "email": formData['email'] ?? '',
      "password": password,
      "genre": formData['gender'] ?? 'Homme',
      "role": "freelance",
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
