import 'package:equatable/equatable.dart';

import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/service.dart';
import '../models/freelance_model.dart';

class FreelancePageStateM extends Equatable {
  final bool isLoading;
  final List<Categorie>? listItems;
  final String? error;

  // Nouveaux champs pour la gestion des freelancers
  final List<FreelanceModel> freelancers;
  final List<FreelanceModel> filteredFreelancers;
  final String? selectedCategory;
  final String searchQuery;

  // ✅ Champs pour la gestion des services
  final List<Service> services;
  final bool isLoadingServices;
  final String servicesError;

  // ✅ NOUVEAU : États pour l'inscription freelance
  final bool isRegistrationLoading;
  final String? registrationError;
  final String? registrationSuccess;

  const FreelancePageStateM({
    required this.isLoading,
    required this.listItems,
    required this.error,
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
  });

  factory FreelancePageStateM.initial() {
    return const FreelancePageStateM(
      isLoading: false,
      listItems: null,
      error: null,
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
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        listItems,
        error,
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
      ];

  FreelancePageStateM copyWith({
    bool? isLoading,
    List<Categorie>? listItems,
    String? error,
    List<FreelanceModel>? freelancers,
    List<FreelanceModel>? filteredFreelancers,
    String? selectedCategory,
    String? searchQuery,
    List<Service>? services,
    bool? isLoadingServices,
    String? servicesError,
    bool? isRegistrationLoading,
    String? registrationError,
    String? registrationSuccess,
  }) {
    return FreelancePageStateM(
      isLoading: isLoading ?? this.isLoading,
      listItems: listItems ?? this.listItems,
      error: error ?? this.error,
      freelancers: freelancers ?? this.freelancers,
      filteredFreelancers: filteredFreelancers ?? this.filteredFreelancers,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      services: services ?? this.services,
      isLoadingServices: isLoadingServices ?? this.isLoadingServices,
      servicesError: servicesError ?? this.servicesError,
      isRegistrationLoading:
          isRegistrationLoading ?? this.isRegistrationLoading,
      registrationError: registrationError ?? this.registrationError,
      registrationSuccess: registrationSuccess ?? this.registrationSuccess,
    );
  }
}
