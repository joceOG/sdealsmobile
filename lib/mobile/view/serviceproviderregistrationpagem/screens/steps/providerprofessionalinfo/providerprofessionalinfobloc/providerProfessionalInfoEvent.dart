import 'package:equatable/equatable.dart';

abstract class ProviderProfessionalInfoEvent extends Equatable {
  const ProviderProfessionalInfoEvent();

  @override
  List<Object?> get props => [];
}

/// Charger les catégories
class LoadCategorieData extends ProviderProfessionalInfoEvent {}

/// Charger les services après sélection d’une catégorie
class LoadServiceData extends ProviderProfessionalInfoEvent {
  final String categorieId;

  const LoadServiceData(this.categorieId);

  @override
  List<Object?> get props => [categorieId];
}
