import 'dart:math' as math;
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageEventM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageStateM.dart';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/utils/network_user_message.dart';
import 'package:sdealsmobile/ai_services/mock_implementations/mock_price_estimation_service.dart';
import 'package:sdealsmobile/ai_services/mock_implementations/mock_provider_matching_service.dart';
import 'package:sdealsmobile/ai_services/models/ai_recommendation_model.dart';
import 'package:sdealsmobile/ai_services/models/provider_match_explanation.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';

import '../../../../data/models/service.dart';

class JobPageBlocM extends Bloc<JobPageEventM, JobPageStateM> {
  JobPageBlocM({
    ApiClient? apiClient,
    Future<List<Map<String, dynamic>>> Function({
      bool forceRefresh,
      int page,
      int limit,
      String? serviceId,
      String? categorieId,
    })? fetchPrestataires,
    Future<List<Service>> Function(String nomGroupe)? fetchServices,
    Future<List<Service>> Function({String scope})? fetchShortcuts,
    Future<List<Categorie>> Function(String nomgroupe)? fetchCategories,
  })  : _apiClient = apiClient,
        _fetchPrestataires = fetchPrestataires,
        _fetchServices = fetchServices,
        _fetchShortcuts = fetchShortcuts,
        _fetchCategories = fetchCategories,
        super(JobPageStateM.initial()) {
    on<LoadCategorieDataJobM>(_onLoadCategorieDataJobM);
    on<LoadServiceDataJobM>(_onLoadServiceDataJobM);
    on<LoadPriceEstimationM>(_onLoadPriceEstimationM);
    on<LoadProviderMatchingM>(_onLoadProviderMatchingM);
    // ✅ NOUVEAU : Gestionnaires de géolocalisation
    on<LoadNearbyProvidersM>(_onLoadNearbyProvidersM);
    on<LoadProvidersByCategoryM>(_onLoadProvidersByCategoryM);
    on<LoadUrgentProvidersM>(_onLoadUrgentProvidersM);
    on<LoadMoreProvidersM>(_onLoadMoreProvidersM);
    on<UpdateExplorerFiltersM>((event, emit) {
      emit(state.copyWith(
        filterVerifiedOnly: event.filterVerifiedOnly,
        filterMinRating: event.filterMinRating,
        clearMinRating: event.clearMinRating,
        searchRadius: event.searchRadius,
      ));
    });
  }

  final ApiClient? _apiClient;
  final Future<List<Map<String, dynamic>>> Function({
    bool forceRefresh,
    int page,
    int limit,
    String? serviceId,
    String? categorieId,
  })? _fetchPrestataires;
  final Future<List<Service>> Function(String nomGroupe)? _fetchServices;
  final Future<List<Service>> Function({String scope})? _fetchShortcuts;
  final Future<List<Categorie>> Function(String nomgroupe)? _fetchCategories;

  static const int _pageLimit = 20;
  int _providersRequestId = 0;

  ApiClient? _ownedApi;
  ApiClient get _api => _apiClient ?? (_ownedApi ??= ApiClient());

  String _savedNotice() =>
      _api.catalogReadStale ? offlineUserMessage : '';

  Future<List<Map<String, dynamic>>> _loadPrestataires({
    bool forceRefresh = false,
    int page = 1,
    int limit = _pageLimit,
    String? serviceId,
    String? categorieId,
  }) {
    if (_fetchPrestataires != null) {
      return _fetchPrestataires(
        forceRefresh: forceRefresh,
        page: page,
        limit: limit,
        serviceId: serviceId,
        categorieId: categorieId,
      );
    }
    return _api.fetchPrestataires(
      forceRefresh: forceRefresh,
      page: page,
      limit: limit,
      serviceId: serviceId,
      categorieId: categorieId,
    );
  }

  List<Prestataire> _mapPrestataires(List<Map<String, dynamic>> data) {
    final out = <Prestataire>[];
    for (final row in data) {
      try {
        out.add(Prestataire.fromBackend(row));
      } catch (_) {
        // ignore invalid rows
      }
    }
    return out;
  }

  List<Prestataire> _mergeUnique(
      List<Prestataire> current, List<Prestataire> incoming) {
    final seen = {for (final p in current) p.idprestataire};
    final merged = List<Prestataire>.from(current);
    for (final p in incoming) {
      if (seen.add(p.idprestataire)) merged.add(p);
    }
    return merged;
  }

  Future<void> _onLoadCategorieDataJobM(
    LoadCategorieDataJobM event,
    Emitter<JobPageStateM> emit,
  ) async {
    // String nomgroupe = "Metiers";
    // emit(state.copyWith3(isLoading2: true));
    emit(state.copyWith(isLoading: true, error: ''));

    try {
      var nomgroupe = "Métiers";
      final list_categorie = _fetchCategories != null
          ? await _fetchCategories(nomgroupe)
          : await _api.fetchCategorie(nomgroupe);
      emit(state.copyWith(
        listItems: list_categorie,
        isLoading: false,
        error: '',
      ));
    } catch (error) {
      emit(state.copyWith(
        error: userFacingNetworkMessage(error),
        isLoading: false,
      ));
    }
  }

  Future<void> _onLoadServiceDataJobM(
    LoadServiceDataJobM event,
    Emitter<JobPageStateM> emit,
  ) async {
    emit(state.copyWith(isLoading2: true, error2: '', shortcutsError: ''));

    try {
      var nomGroupe = "Métiers";
      final listService = _fetchServices != null
          ? await _fetchServices(nomGroupe)
          : await _api.fetchServices(nomGroupe);
      List<Service> shortcuts = const [];
      var shortcutsError = '';
      try {
        shortcuts = _fetchShortcuts != null
            ? await _fetchShortcuts(scope: 'metiers')
            : await _api.fetchServiceShortcuts(scope: 'metiers');
      } catch (_) {
        shortcutsError =
            'Impossible de charger les raccourcis. Les catégories restent disponibles.';
      }
      emit(state.copyWith(
        listItems2: listService,
        shortcuts: shortcuts,
        isLoading2: false,
        error2: '',
        shortcutsError: shortcutsError,
      ));
    } catch (error) {
      emit(state.copyWith(
        error2: userFacingNetworkMessage(error),
        isLoading2: false,
      ));
    }
  }

  // Gestion de l'estimation de prix IA
  Future<void> _onLoadPriceEstimationM(
      LoadPriceEstimationM event, Emitter<JobPageStateM> emit) async {
    final priceService = MockPriceEstimationService();
    emit(state.copyWith(isPriceLoading: true, priceError: ''));
    try {
      final estimation = await priceService.estimatePrice(
        serviceType: event.serviceType,
        location: event.location,
        additionalFactors: {'jobDescription': event.jobDescription},
      );
      emit(state.copyWith(
        priceEstimation: estimation,
        isPriceLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isPriceLoading: false,
        priceError: e.toString(),
      ));
    }
  }

  // ✅ NOUVEAU : Chargement réel des prestataires depuis le backend
  Future<void> _onLoadProviderMatchingM(
      LoadProviderMatchingM event, Emitter<JobPageStateM> emit) async {
    final requestId = ++_providersRequestId;
    emit(state.copyWith(
      isMatchingLoading: true,
      matchError: '',
      selectedService: event.serviceType,
      selectedServiceId: event.serviceId ?? '',
      selectedCategoryId: event.categoryId ?? '',
    ));

    try {
      final List<Map<String, dynamic>> prestatairesData =
          await _loadPrestataires(
        forceRefresh: true,
        page: 1,
        limit: _pageLimit,
        serviceId: event.serviceId,
        categorieId: event.categoryId,
      );
      // Un appel nearby/byCategory a pris le relais → libère le spinner
      if (requestId != _providersRequestId) {
        emit(state.copyWith(isMatchingLoading: false));
        return;
      }

      List<Prestataire> providers = _mapPrestataires(prestatairesData);
      final hasMore = prestatairesData.length >= _pageLimit;

      // 📍 Filtrer par localisation si spécifié
      if (event.location.isNotEmpty) {
        providers = providers
            .where((p) => p.localisation
                .toLowerCase()
                .contains(event.location.toLowerCase()))
            .toList();
      }

      // 🏆 Trier par note (vérifiés en premier, puis par expérience)
      providers.sort((a, b) {
        if (a.verifier && !b.verifier) return -1;
        if (!a.verifier && b.verifier) return 1;

        // Comparer les années d'expérience
        int expA = int.tryParse(a.anneeExperience ?? '0') ?? 0;
        int expB = int.tryParse(b.anneeExperience ?? '0') ?? 0;
        return expB.compareTo(expA);
      });

      // ✅ Créer l'explication du matching
      final matchCriteria = [event.serviceType, event.location];
      if (event.preferences != null && event.preferences!.isNotEmpty) {
        matchCriteria.addAll(event.preferences!);
      }

      final providerScores = <String, double>{};
      final providerStrengths = <String, List<String>>{};

      // Générer des scores basés sur les critères réels
      for (final provider in providers) {
        final idKey = provider.utilisateur.idutilisateur;
        double score = 0.0;
        List<String> strengths = [];

        // Points pour vérification
        if (provider.verifier) {
          score += 30;
          strengths.add("Profil vérifié");
        }

        // Points pour expérience
        int exp = int.tryParse(provider.anneeExperience ?? '0') ?? 0;
        if (exp > 5) {
          score += 25;
          strengths.add("${exp} ans d'expérience");
        } else if (exp > 2) {
          score += 15;
          strengths.add("${exp} ans d'expérience");
        }

        // Points pour spécialités
        if (provider.specialite != null && provider.specialite!.isNotEmpty) {
          score += 20;
          strengths
              .add("Spécialisé en ${provider.specialite!.take(2).join(', ')}");
        }

        // Points pour localisation
        if (provider.localisation.isNotEmpty) {
          score += 15;
          strengths.add("Basé à ${provider.localisation}");
        }

        // Points pour description
        if (provider.description != null && provider.description!.isNotEmpty) {
          score += 10;
          strengths.add("Profil détaillé");
        }

        providerScores[idKey] = score;
        providerStrengths[idKey] = strengths;
      }

      final explanation = ProviderMatchExplanation(
        matchingCriteria: matchCriteria,
        providerScores: providerScores,
        providerStrengths: providerStrengths,
      );

      if (requestId != _providersRequestId) {
        emit(state.copyWith(isMatchingLoading: false));
        return;
      }
      emit(state.copyWith(
        matchedProviders: providers,
        matchExplanation: explanation,
        isMatchingLoading: false,
        providersPage: 1,
        providersHasMore: hasMore,
        selectedServiceId: event.serviceId ?? '',
        selectedCategoryId: event.categoryId ?? '',
        matchError: _savedNotice(),
      ));
    } catch (error) {
      if (requestId != _providersRequestId) return;
      if (kDebugMode) debugPrint('matching providers load failed');
      emit(state.copyWith(
        isMatchingLoading: false,
        // Pas de matchedProviders: const [] — préserve les fiches déjà chargées
        matchError: 'Impossible de charger les prestataires. Réessayez.',
      ));
    }
  }

  // ✅ NOUVEAU : Chargement des prestataires à proximité
  Future<void> _onLoadNearbyProvidersM(
      LoadNearbyProvidersM event, Emitter<JobPageStateM> emit) async {
    final requestId = ++_providersRequestId;
    emit(state.copyWith(
      isNearbyLoading: true,
      // Annule le spinner de matching si un appel nearby le supplante
      isMatchingLoading: false,
      nearbyError: '',
      userLatitude: event.latitude,
      userLongitude: event.longitude,
      searchRadius: event.radius,
      selectedCategory: event.category ?? '',
      selectedCategoryId: event.categoryId ?? '',
      selectedService: event.service ?? '',
      selectedServiceId: event.serviceId ?? '',
      providersPage: 1,
      providersHasMore: true,
      isLoadingMore: false,
    ));

    try {
      final List<Map<String, dynamic>> prestatairesData =
          await _loadPrestataires(
        forceRefresh: true,
        page: 1,
        limit: _pageLimit,
        serviceId: event.serviceId,
        categorieId: event.categoryId,
      );
      if (requestId != _providersRequestId) return;
      List<Prestataire> allProviders = _mapPrestataires(prestatairesData);
      final hasMore = prestatairesData.length >= _pageLimit;

      final distances = _distancesOnly(
        allProviders,
        event.latitude,
        event.longitude,
      );

      allProviders.sort((a, b) {
        final da = distances[a.idprestataire] ?? 9999;
        final db = distances[b.idprestataire] ?? 9999;
        final cmp = da.compareTo(db);
        if (cmp != 0) return cmp;
        if (a.verifier && !b.verifier) return -1;
        if (!a.verifier && b.verifier) return 1;
        return 0;
      });

      if (requestId != _providersRequestId) return;
      emit(state.copyWith(
        nearbyProviders: allProviders,
        providerDistances: distances,
        isNearbyLoading: false,
        providersPage: 1,
        providersHasMore: hasMore,
        isLoadingMore: false,
        nearbyError: _savedNotice(),
      ));
    } catch (error) {
      if (requestId != _providersRequestId) return;
      if (kDebugMode) debugPrint('nearby providers load failed');
      emit(state.copyWith(
        isNearbyLoading: false,
        nearbyError: userFacingNetworkMessage(error).isEmpty
            ? genericUserMessage
            : userFacingNetworkMessage(error),
      ));
    }
  }

  Future<void> _onLoadMoreProvidersM(
      LoadMoreProvidersM event, Emitter<JobPageStateM> emit) async {
    if (state.isLoadingMore ||
        !state.providersHasMore ||
        state.isNearbyLoading) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, nearbyError: ''));
    final requestId = _providersRequestId;
    try {
      final nextPage = state.providersPage + 1;
      final batch = await _loadPrestataires(
        page: nextPage,
        limit: _pageLimit,
        serviceId: state.selectedServiceId.isEmpty ? null : state.selectedServiceId,
        categorieId:
            state.selectedCategoryId.isEmpty ? null : state.selectedCategoryId,
      );
      if (requestId != _providersRequestId) return;
      var providers = _mapPrestataires(batch);

      var distances = Map<String, double>.from(state.providerDistances);
      if (state.userLatitude != null && state.userLongitude != null) {
        distances = {
          ...distances,
          ..._distancesOnly(
            providers,
            state.userLatitude!,
            state.userLongitude!,
          ),
        };
      }

      final merged = _mergeUnique(state.nearbyProviders, providers);
      emit(state.copyWith(
        nearbyProviders: merged,
        providerDistances: distances,
        providersPage: nextPage,
        providersHasMore: batch.length >= _pageLimit,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(
        isLoadingMore: false,
        nearbyError: 'Chargement supplémentaire impossible. Réessayez.',
      ));
    }
  }

  // ✅ NOUVEAU : Chargement par catégorie
  Future<void> _onLoadProvidersByCategoryM(
      LoadProvidersByCategoryM event, Emitter<JobPageStateM> emit) async {
    final requestId = ++_providersRequestId;
    emit(state.copyWith(
      isNearbyLoading: true,
      // Idem : annule le spinner matching si byCategory le supplante
      isMatchingLoading: false,
      nearbyError: '',
      selectedCategory: event.category,
      selectedCategoryId: event.categoryId,
      selectedService: '',
      selectedServiceId: '',
    ));

    try {
      final List<Map<String, dynamic>> prestatairesData =
          await _loadPrestataires(
        forceRefresh: true,
        page: 1,
        limit: _pageLimit,
        categorieId: event.categoryId.isEmpty ? null : event.categoryId,
      );
      if (requestId != _providersRequestId) return;

      List<Prestataire> providers = _mapPrestataires(prestatairesData);

      Map<String, double> distances = {};
      if (event.latitude != null && event.longitude != null) {
        distances = _distancesOnly(
          providers,
          event.latitude!,
          event.longitude!,
        );
      }

      // Trier par note (conversion sécurisée)
      providers.sort((a, b) {
        final noteA =
            double.tryParse('${a.note ?? ''}'.replaceAll(',', '.')) ?? 0.0;
        final noteB =
            double.tryParse('${b.note ?? ''}'.replaceAll(',', '.')) ?? 0.0;
        if (noteB > noteA) return 1;
        if (noteB < noteA) return -1;
        return 0;
      });

      if (requestId != _providersRequestId) return;
      emit(state.copyWith(
        nearbyProviders: providers,
        providerDistances: distances,
        selectedCategory: event.category,
        selectedCategoryId: event.categoryId,
        providersPage: 1,
        providersHasMore: prestatairesData.length >= _pageLimit,
        isNearbyLoading: false,
        isLoadingMore: false,
        nearbyError: _savedNotice(),
      ));
    } catch (error) {
      if (requestId != _providersRequestId) return;
      if (kDebugMode) debugPrint('category providers load failed');
      emit(state.copyWith(
        isNearbyLoading: false,
        nearbyError: userFacingNetworkMessage(error).isEmpty
            ? genericUserMessage
            : userFacingNetworkMessage(error),
      ));
    }
  }

  // ✅ NOUVEAU : Chargement des prestataires d'urgence
  Future<void> _onLoadUrgentProvidersM(
      LoadUrgentProvidersM event, Emitter<JobPageStateM> emit) async {
    emit(state.copyWith(
      isNearbyLoading: true,
      nearbyError: '',
    ));

    try {
      ApiClient apiClient = _api;
      print("🚨 Chargement prestataires d'urgence...");

      final List<Map<String, dynamic>> prestatairesData = await apiClient
          .fetchPrestataires(forceRefresh: true, page: 1, limit: _pageLimit);

      List<Prestataire> providers = [];
      for (final data in prestatairesData) {
        try {
          providers.add(Prestataire.fromBackend(data));
        } catch (e) {
          if (kDebugMode) debugPrint('prestataire mapping skipped');
        }
      }

      // Filtrer les prestataires d'urgence (disponibles 24h/24)
      // Note: Le champ 'disponibilite' n'existe pas dans le modèle Prestataire
      // Pour l'instant, on filtre par prestataires vérifiés comme approximation
      providers = providers.where((p) => p.verifier).toList();

      // ✅ Filtrer par distance si position disponible
      Map<String, double> distances = {};
      if (event.latitude != null && event.longitude != null) {
        final filtered = await _filterByDistance(
          providers,
          event.latitude!,
          event.longitude!,
          event.radius,
        );
        providers = filtered.providers;
        distances = filtered.distances;
      }

      // Trier par disponibilité et note
      providers.sort((a, b) {
        if (a.verifier && !b.verifier) return -1;
        if (!a.verifier && b.verifier) return 1;
        final noteA =
            double.tryParse('${a.note ?? ''}'.replaceAll(',', '.')) ?? 0.0;
        final noteB =
            double.tryParse('${b.note ?? ''}'.replaceAll(',', '.')) ?? 0.0;
        if (noteB > noteA) return 1;
        if (noteB < noteA) return -1;
        return 0;
      });

      print("✅ Prestataires d'urgence trouvés: ${providers.length}");

      emit(state.copyWith(
        nearbyProviders: providers,
        providerDistances: distances,
        isNearbyLoading: false,
        nearbyError: _savedNotice(),
      ));
    } catch (error) {
      if (kDebugMode) debugPrint('urgent providers load failed');
      emit(state.copyWith(
        isNearbyLoading: false,
        nearbyError: userFacingNetworkMessage(error).isEmpty
            ? genericUserMessage
            : userFacingNetworkMessage(error),
      ));
    }
  }

  // ✅ Filtre distance + map id → km
  Map<String, double> _distancesOnly(
    List<Prestataire> providers,
    double userLat,
    double userLng,
  ) {
    final distances = <String, double>{};
    for (final provider in providers) {
      final lat = provider.localisationMaps?.latitude;
      final lng = provider.localisationMaps?.longitude;
      if (lat == null || lng == null || lat == 0.0 || lng == 0.0) continue;
      distances[provider.idprestataire] =
          _calculateLocalDistance(userLat, userLng, lat, lng);
    }
    return distances;
  }

  Future<({List<Prestataire> providers, Map<String, double> distances})>
      _filterByDistance(
    List<Prestataire> providers,
    double userLat,
    double userLng,
    double radiusKm,
  ) async {
    final nearbyProviders = <Prestataire>[];
    final distances = <String, double>{};

    for (Prestataire provider in providers) {
      double? providerLat;
      double? providerLng;

      if (provider.localisationMaps != null) {
        try {
          providerLat = provider.localisationMaps?.latitude;
          providerLng = provider.localisationMaps?.longitude;
        } catch (e) {
          continue;
        }
      }

      if (providerLat == null ||
          providerLng == null ||
          providerLat == 0.0 ||
          providerLng == 0.0) {
        continue;
      }

      final distance =
          _calculateLocalDistance(userLat, userLng, providerLat, providerLng);

      if (distance <= radiusKm) {
        nearbyProviders.add(provider);
        distances[provider.idprestataire] = distance;
      }
    }

    return (providers: nearbyProviders, distances: distances);
  }

  // ✅ NOUVELLE MÉTHODE : Calculer la distance via l'API backend
  Future<double> _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) async {
    try {
      // Utiliser l'API backend pour le calcul de distance
      final distance = await ApiClient().calculateDistance(
        lat1: lat1,
        lng1: lng1,
        lat2: lat2,
        lng2: lng2,
      );
      return distance;
    } catch (e) {
      print('Erreur calcul distance API: $e');
      // Fallback vers calcul local si l'API échoue
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
}
