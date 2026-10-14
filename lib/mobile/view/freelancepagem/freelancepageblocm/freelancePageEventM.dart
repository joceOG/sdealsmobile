import 'package:equatable/equatable.dart';

abstract class FreelancePageEventM extends Equatable {
  const FreelancePageEventM();

  @override
  List<Object> get props => [];
}

class LoadCategorieDataM extends FreelancePageEventM {}

class LoadFreelancersEvent extends FreelancePageEventM {
  /// `true` : ignore le cache (Réessayer, tirer pour actualiser, mutation).
  final bool force;

  LoadFreelancersEvent({this.force = false});

  @override
  List<Object> get props => [force];
}

class LoadServicesEvent extends FreelancePageEventM {}

class FilterByCategoryEvent extends FreelancePageEventM {
  final String? category;

  /// `true` : ignore le cache (Réessayer après un échec).
  final bool force;

  const FilterByCategoryEvent(this.category, {this.force = false});

  @override
  List<Object> get props => [category ?? '', force];
}

class SearchFreelancerEvent extends FreelancePageEventM {
  final String query;

  const SearchFreelancerEvent(this.query);

  @override
  List<Object> get props => [query];
}

class ClearFiltersEvent extends FreelancePageEventM {}

// ✅ NOUVEAU : Événement pour soumettre l'inscription freelance
class SubmitFreelanceRegistrationEvent extends FreelancePageEventM {
  final Map<String, dynamic> formData;

  const SubmitFreelanceRegistrationEvent({required this.formData});

  @override
  List<Object> get props => [formData];
}
