import 'package:equatable/equatable.dart';

import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/service.dart';
import '../models/freelance_model.dart';

class FreelancePageStateM extends Equatable {
  final bool isLoading;
  final List<Categorie>? listItems;
  final String? error;

  // Freelancers
  final bool isLoadingFreelancers;
  final bool freelancersLoaded;
  final String? freelancersError;
  final List<FreelanceModel> freelancers;
  final List<FreelanceModel> filteredFreelancers;
  final String? selectedCategory;
  final String searchQuery;

  // Services
  final List<Service> services;
  final bool isLoadingServices;
  final String servicesError;

  // Inscription freelance
  final bool isRegistrationLoading;
  final String? registrationError;
  final String? registrationSuccess;

  /// Message d'erreur spécifique au filtre catégorie server-side
  /// (distinct de [freelancersError] qui concerne le chargement initial).
  final String? filterError;

  const FreelancePageStateM({
    required this.isLoading,
    required this.listItems,
    required this.error,
    required this.isLoadingFreelancers,
    required this.freelancersLoaded,
    required this.freelancersError,
    required this.freelancers,
    required this.filteredFreelancers,
    required this.selectedCategory,
    required this.searchQuery,
    required this.services,
    required this.isLoadingServices,
    required this.servicesError,
    required this.isRegistrationLoading,
    required this.registrationError,
    required this.registrationSuccess,
    this.filterError,
  });

  factory FreelancePageStateM.initial() {
    return const FreelancePageStateM(
      isLoading: false,
      listItems: null,
      error: null,
      isLoadingFreelancers: false,
      freelancersLoaded: false,
      freelancersError: null,
      freelancers: [],
      filteredFreelancers: [],
      selectedCategory: null,
      searchQuery: '',
      services: [],
      isLoadingServices: false,
      servicesError: '',
      isRegistrationLoading: false,
      registrationError: null,
      registrationSuccess: null,
      filterError: null,
    );
  }

  bool get isFreelancersEmpty =>
      freelancersLoaded &&
      !isLoadingFreelancers &&
      freelancersError == null &&
      freelancers.isEmpty;

  @override
  List<Object?> get props => [
        isLoading,
        listItems,
        error,
        isLoadingFreelancers,
        freelancersLoaded,
        freelancersError,
        freelancers,
        filteredFreelancers,
        selectedCategory,
        searchQuery,
        services,
        isLoadingServices,
        servicesError,
        isRegistrationLoading,
        registrationError,
        registrationSuccess,
        filterError,
      ];

  static const Object _unset = Object();

  FreelancePageStateM copyWith({
    bool? isLoading,
    Object? listItems = _unset,
    Object? error = _unset,
    bool? isLoadingFreelancers,
    bool? freelancersLoaded,
    Object? freelancersError = _unset,
    List<FreelanceModel>? freelancers,
    List<FreelanceModel>? filteredFreelancers,
    Object? selectedCategory = _unset,
    String? searchQuery,
    List<Service>? services,
    bool? isLoadingServices,
    String? servicesError,
    bool? isRegistrationLoading,
    Object? registrationError = _unset,
    Object? registrationSuccess = _unset,
    Object? filterError = _unset,
  }) {
    return FreelancePageStateM(
      isLoading: isLoading ?? this.isLoading,
      listItems: identical(listItems, _unset)
          ? this.listItems
          : listItems as List<Categorie>?,
      error: identical(error, _unset) ? this.error : error as String?,
      isLoadingFreelancers: isLoadingFreelancers ?? this.isLoadingFreelancers,
      freelancersLoaded: freelancersLoaded ?? this.freelancersLoaded,
      freelancersError: identical(freelancersError, _unset)
          ? this.freelancersError
          : freelancersError as String?,
      freelancers: freelancers ?? this.freelancers,
      filteredFreelancers: filteredFreelancers ?? this.filteredFreelancers,
      selectedCategory: identical(selectedCategory, _unset)
          ? this.selectedCategory
          : selectedCategory as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      services: services ?? this.services,
      isLoadingServices: isLoadingServices ?? this.isLoadingServices,
      servicesError: servicesError ?? this.servicesError,
      isRegistrationLoading:
          isRegistrationLoading ?? this.isRegistrationLoading,
      registrationError: identical(registrationError, _unset)
          ? this.registrationError
          : registrationError as String?,
      registrationSuccess: identical(registrationSuccess, _unset)
          ? this.registrationSuccess
          : registrationSuccess as String?,
      filterError: identical(filterError, _unset)
          ? this.filterError
          : filterError as String?,
    );
  }
}
