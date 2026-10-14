import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/ai_services/models/ai_recommendation_model.dart';
import 'package:sdealsmobile/ai_services/models/provider_match_explanation.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/models/service.dart';

class JobPageStateM extends Equatable {
  final bool isLoading;
  final List<Categorie> listItems;
  final String error;
  final bool isLoading2;
  final List<Service> listItems2;
  final String error2;

  final AIPriceEstimation? priceEstimation;
  final bool isPriceLoading;
  final String priceError;

  final List<Prestataire> matchedProviders;
  final ProviderMatchExplanation? matchExplanation;
  final bool isMatchingLoading;
  final String matchError;

  final List<Prestataire> nearbyProviders;

  /// idprestataire → distance km (calcul Haversine)
  final Map<String, double> providerDistances;
  final bool isNearbyLoading;
  final String nearbyError;
  final double? userLatitude;
  final double? userLongitude;
  final double searchRadius;
  final String selectedCategory;
  final String selectedCategoryId;
  final String selectedService;
  final String selectedServiceId;
  final List<Service> shortcuts;
  final String shortcutsError;
  final bool filterVerifiedOnly;
  final double? filterMinRating;
  final int providersPage;
  final bool providersHasMore;
  final bool isLoadingMore;

  const JobPageStateM({
    required this.isLoading,
    required this.listItems,
    required this.error,
    required this.isLoading2,
    required this.listItems2,
    required this.error2,
    this.priceEstimation,
    required this.isPriceLoading,
    required this.priceError,
    required this.matchedProviders,
    this.matchExplanation,
    required this.isMatchingLoading,
    required this.matchError,
    required this.nearbyProviders,
    this.providerDistances = const {},
    required this.isNearbyLoading,
    required this.nearbyError,
    this.userLatitude,
    this.userLongitude,
    required this.searchRadius,
    required this.selectedCategory,
    this.selectedCategoryId = '',
    required this.selectedService,
    this.selectedServiceId = '',
    this.shortcuts = const [],
    this.shortcutsError = '',
    this.filterVerifiedOnly = false,
    this.filterMinRating,
    this.providersPage = 1,
    this.providersHasMore = true,
    this.isLoadingMore = false,
  });

  factory JobPageStateM.initial() {
    return const JobPageStateM(
      isLoading: true,
      listItems: [],
      error: '',
      isLoading2: true,
      listItems2: [],
      error2: '',
      priceEstimation: null,
      isPriceLoading: false,
      priceError: '',
      matchedProviders: [],
      matchExplanation: null,
      isMatchingLoading: false,
      matchError: '',
      nearbyProviders: [],
      providerDistances: {},
      isNearbyLoading: false,
      nearbyError: '',
      userLatitude: null,
      userLongitude: null,
      searchRadius: 5.0,
      selectedCategory: '',
      selectedService: '',
      filterVerifiedOnly: false,
      filterMinRating: null,
      providersPage: 1,
      providersHasMore: true,
      isLoadingMore: false,
    );
  }

  /// Vrai seulement quand une position et des distances estimées existent.
  /// Le rayon limite alors la liste et les pastilles. Il ne recadre pas la carte.
  bool get appliesSearchRadius =>
      userLatitude != null &&
      userLongitude != null &&
      providerDistances.isNotEmpty;

  /// Liste affichable (nearby prioritaire, sinon matching), après filtres chips.
  List<Prestataire> get displayProviders {
    final base =
        nearbyProviders.isNotEmpty ? nearbyProviders : matchedProviders;
    return base.where((p) {
      if (filterVerifiedOnly && !p.verifier) return false;
      if (filterMinRating != null) {
        final n = double.tryParse('${p.note ?? ''}'.replaceAll(',', '.')) ?? 0;
        if (n < filterMinRating!) return false;
      }
      if (appliesSearchRadius) {
        final d = providerDistances[p.idprestataire];
        if (d == null || d > searchRadius) return false;
      }
      return true;
    }).toList();
  }

  JobPageStateM copyWith({
    bool? isLoading,
    List<Categorie>? listItems,
    String? error,
    bool? isLoading2,
    List<Service>? listItems2,
    String? error2,
    AIPriceEstimation? priceEstimation,
    bool? isPriceLoading,
    String? priceError,
    List<Prestataire>? matchedProviders,
    ProviderMatchExplanation? matchExplanation,
    bool? isMatchingLoading,
    String? matchError,
    List<Prestataire>? nearbyProviders,
    Map<String, double>? providerDistances,
    bool? isNearbyLoading,
    String? nearbyError,
    double? userLatitude,
    double? userLongitude,
    double? searchRadius,
    String? selectedCategory,
    String? selectedCategoryId,
    String? selectedService,
    String? selectedServiceId,
    List<Service>? shortcuts,
    String? shortcutsError,
    bool? filterVerifiedOnly,
    double? filterMinRating,
    bool clearMinRating = false,
    int? providersPage,
    bool? providersHasMore,
    bool? isLoadingMore,
  }) {
    return JobPageStateM(
      isLoading: isLoading ?? this.isLoading,
      listItems: listItems ?? this.listItems,
      error: error ?? this.error,
      isLoading2: isLoading2 ?? this.isLoading2,
      listItems2: listItems2 ?? this.listItems2,
      error2: error2 ?? this.error2,
      priceEstimation: priceEstimation ?? this.priceEstimation,
      isPriceLoading: isPriceLoading ?? this.isPriceLoading,
      priceError: priceError ?? this.priceError,
      matchedProviders: matchedProviders ?? this.matchedProviders,
      matchExplanation: matchExplanation ?? this.matchExplanation,
      isMatchingLoading: isMatchingLoading ?? this.isMatchingLoading,
      matchError: matchError ?? this.matchError,
      nearbyProviders: nearbyProviders ?? this.nearbyProviders,
      providerDistances: providerDistances ?? this.providerDistances,
      isNearbyLoading: isNearbyLoading ?? this.isNearbyLoading,
      nearbyError: nearbyError ?? this.nearbyError,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      searchRadius: searchRadius ?? this.searchRadius,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedService: selectedService ?? this.selectedService,
      selectedServiceId: selectedServiceId ?? this.selectedServiceId,
      shortcuts: shortcuts ?? this.shortcuts,
      shortcutsError: shortcutsError ?? this.shortcutsError,
      filterVerifiedOnly: filterVerifiedOnly ?? this.filterVerifiedOnly,
      filterMinRating:
          clearMinRating ? null : (filterMinRating ?? this.filterMinRating),
      providersPage: providersPage ?? this.providersPage,
      providersHasMore: providersHasMore ?? this.providersHasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        listItems,
        error,
        isLoading2,
        listItems2,
        error2,
        priceEstimation,
        isPriceLoading,
        priceError,
        matchedProviders,
        matchExplanation,
        isMatchingLoading,
        matchError,
        nearbyProviders,
        providerDistances,
        isNearbyLoading,
        nearbyError,
        userLatitude,
        userLongitude,
        searchRadius,
        selectedCategory,
        selectedCategoryId,
        selectedService,
        selectedServiceId,
        shortcuts,
        shortcutsError,
        filterVerifiedOnly,
        filterMinRating,
        providersPage,
        providersHasMore,
        isLoadingMore,
      ];
}
