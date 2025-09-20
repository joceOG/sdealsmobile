import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/service.dart';

import '../../../../../../../data/models/groupe.dart';

class ProviderProfessionalInfoState extends Equatable {
  final List<Categorie> listItems;   // Catégories
  final List<Service> listItems2;    // Services
  final bool isLoading;
  final bool isLoading2;
  final String error;
  final String error2;

  const ProviderProfessionalInfoState({
    required this.listItems,
    required this.listItems2,
    this.isLoading = false,
    this.isLoading2 = false,
    this.error = '',
    this.error2 = '',
  });

  /// Données statiques de départ
  factory ProviderProfessionalInfoState.initial() {
    return ProviderProfessionalInfoState(
      listItems: [
        Categorie(
          idcategorie: '1',
          nomcategorie: 'Plomberie',
          imagecategorie: 'https://via.placeholder.com/150',
          groupe: Groupe(idgroupe: 'g1', nomgroupe: 'Métiers'),
        ),
        Categorie(
          idcategorie: '2',
          nomcategorie: 'Électricité',
          imagecategorie: 'https://via.placeholder.com/150',
          groupe: Groupe(idgroupe: 'g1', nomgroupe: 'Métiers'),
        ),
      ],
      listItems2: [],
    );
  }

  ProviderProfessionalInfoState copyWith({
    List<Categorie>? listItems,
    List<Service>? listItems2,
    bool? isLoading,
    bool? isLoading2,
    String? error,
    String? error2,
  }) {
    return ProviderProfessionalInfoState(
      listItems: listItems ?? this.listItems,
      listItems2: listItems2 ?? this.listItems2,
      isLoading: isLoading ?? this.isLoading,
      isLoading2: isLoading2 ?? this.isLoading2,
      error: error ?? this.error,
      error2: error2 ?? this.error2,
    );
  }

  @override
  List<Object?> get props => [listItems, listItems2, isLoading, isLoading2, error, error2];
}
