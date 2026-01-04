import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/categorie.dart';


abstract class SearchPageEventM extends Equatable {
  const SearchPageEventM();

  @override
  List<Object?> get props => [];
}

// 🟢 Événement déclenché quand l'utilisateur tape (pour suggestions)
class FetchSuggestions extends SearchPageEventM {
  final String query;
  const FetchSuggestions(this.query);

  @override
  List<Object> get props => [query];
}

// 🟢 Événement déclenché quand l'utilisateur valide la recherche (Entrée)
class PerformGlobalSearch extends SearchPageEventM {
  final String query;
  const PerformGlobalSearch(this.query);

  @override
  List<Object> get props => [query];
}

// 🟢 Réinitialiser la recherche
class ClearSearch extends SearchPageEventM {}

// Legacy event (à garder pour compatibilité si utilisé ailleurs, sinon supprimer)
// 🟢 Charger l'historique
class LoadHistory extends SearchPageEventM {}

// 🟢 Ajouter à l'historique
class AddToHistory extends SearchPageEventM {
  final String query;
  const AddToHistory(this.query);

  @override
  List<Object> get props => [query];
}

// 🟢 Effacer l'historique
class ClearHistory extends SearchPageEventM {}

// 🟢 Mettre à jour les filtres (sans lancer la recherche)
class UpdateFilters extends SearchPageEventM {
  final double? minPrice;
  final double? maxPrice;
  final String? city;

  const UpdateFilters({this.minPrice, this.maxPrice, this.city});

  @override
  List<Object?> get props => [minPrice, maxPrice, city];
}

class LoadCategorieDataM extends SearchPageEventM {}


