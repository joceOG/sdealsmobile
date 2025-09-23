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

  // Estimation de prix IA
  final AIPriceEstimation? priceEstimation;
  final bool isPriceLoading;
  final String priceError;

  // Matching prestataires IA
  final List<Prestataire> matchedProviders;
  final ProviderMatchExplanation? matchExplanation;
  final bool isMatchingLoading;
  final String matchError;

  // ✅ NOUVEAU : Géolocalisation
  final List<Prestataire> nearbyProviders;
  final bool isNearbyLoading;
  final String nearbyError;
  final double? userLatitude;
  final double? userLongitude;
  final double searchRadius;
  final String selectedCategory;
  final String selectedService;

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
    required this.isNearbyLoading,
    required this.nearbyError,
    this.userLatitude,
    this.userLongitude,
    required this.searchRadius,
    required this.selectedCategory,
    required this.selectedService,
  });

  /// État initial "safe"
  factory JobPageStateM.initial() {
    return const JobPageStateM(
      isLoading: true,
      listItems: [], // ✅ liste vide, plus de null
      error: '',
      isLoading2: true,
      listItems2: [],
      error2: '',
      priceEstimation: null,
      isPriceLoading: false,
      priceError: '',
      matchedProviders: [], // ✅ liste vide
      matchExplanation: null,
      isMatchingLoading: false,
      matchError: '',
      nearbyProviders: [],
      isNearbyLoading: false,
      nearbyError: '',
      userLatitude: null,
      userLongitude: null,
      searchRadius: 5.0,
      selectedCategory: '',
      selectedService: '',
    );
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
    bool? isNearbyLoading,
    String? nearbyError,
    double? userLatitude,
    double? userLongitude,
    double? searchRadius,
    String? selectedCategory,
    String? selectedService,
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
      isNearbyLoading: isNearbyLoading ?? this.isNearbyLoading,
      nearbyError: nearbyError ?? this.nearbyError,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      searchRadius: searchRadius ?? this.searchRadius,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedService: selectedService ?? this.selectedService,
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
        isNearbyLoading,
        nearbyError,
        userLatitude,
        userLongitude,
        searchRadius,
        selectedCategory,
        selectedService,
      ];
}
