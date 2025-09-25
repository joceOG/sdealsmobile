import 'package:equatable/equatable.dart';

abstract class FavoritePageEventM extends Equatable {
  const FavoritePageEventM();

  @override
  List<Object?> get props => [];
}

// 📋 CHARGEMENT DES FAVORIS
class LoadFavoritesM extends FavoritePageEventM {
  final String? objetType;
  final String? statut;
  final String? categorie;
  final String? ville;
  final String? listePersonnalisee;
  final int page;
  final int limit;
  final String? sortBy;
  final String? sortOrder;

  const LoadFavoritesM({
    this.objetType,
    this.statut,
    this.categorie,
    this.ville,
    this.listePersonnalisee,
    this.page = 1,
    this.limit = 20,
    this.sortBy,
    this.sortOrder,
  });

  @override
  List<Object?> get props => [
        objetType,
        statut,
        categorie,
        ville,
        listePersonnalisee,
        page,
        limit,
        sortBy,
        sortOrder,
      ];
}

// 🔍 RECHERCHE DANS LES FAVORIS
class SearchFavoritesM extends FavoritePageEventM {
  final String query;
  final String? objetType;
  final String? categorie;
  final String? ville;

  const SearchFavoritesM({
    required this.query,
    this.objetType,
    this.categorie,
    this.ville,
  });

  @override
  List<Object?> get props => [query, objetType, categorie, ville];
}

// ➕ AJOUTER UN FAVORI
class AddFavoriteM extends FavoritePageEventM {
  final String objetType;
  final String objetId;
  final String titre;
  final String? description;
  final String? image;
  final double? prix;
  final String? devise;
  final String? categorie;
  final List<String>? tags;
  final String? ville;
  final String? pays;
  final double? note;
  final String? listePersonnalisee;
  final String? notesPersonnelles;
  final bool alertePrix;
  final bool alerteDisponibilite;

  const AddFavoriteM({
    required this.objetType,
    required this.objetId,
    required this.titre,
    this.description,
    this.image,
    this.prix,
    this.devise,
    this.categorie,
    this.tags,
    this.ville,
    this.pays,
    this.note,
    this.listePersonnalisee,
    this.notesPersonnelles,
    this.alertePrix = false,
    this.alerteDisponibilite = false,
  });

  @override
  List<Object?> get props => [
        objetType,
        objetId,
        titre,
        description,
        image,
        prix,
        devise,
        categorie,
        tags,
        ville,
        pays,
        note,
        listePersonnalisee,
        notesPersonnelles,
        alertePrix,
        alerteDisponibilite,
      ];
}

// ✏️ MODIFIER UN FAVORI
class UpdateFavoriteM extends FavoritePageEventM {
  final String favoriteId;
  final String? titre;
  final String? description;
  final String? image;
  final double? prix;
  final String? devise;
  final String? categorie;
  final List<String>? tags;
  final String? ville;
  final String? pays;
  final double? note;
  final String? listePersonnalisee;
  final String? notesPersonnelles;
  final bool? alertePrix;
  final bool? alerteDisponibilite;

  const UpdateFavoriteM({
    required this.favoriteId,
    this.titre,
    this.description,
    this.image,
    this.prix,
    this.devise,
    this.categorie,
    this.tags,
    this.ville,
    this.pays,
    this.note,
    this.listePersonnalisee,
    this.notesPersonnelles,
    this.alertePrix,
    this.alerteDisponibilite,
  });

  @override
  List<Object?> get props => [
        favoriteId,
        titre,
        description,
        image,
        prix,
        devise,
        categorie,
        tags,
        ville,
        pays,
        note,
        listePersonnalisee,
        notesPersonnelles,
        alertePrix,
        alerteDisponibilite,
      ];
}

// 🗑️ SUPPRIMER UN FAVORI
class DeleteFavoriteM extends FavoritePageEventM {
  final String favoriteId;

  const DeleteFavoriteM({required this.favoriteId});

  @override
  List<Object?> get props => [favoriteId];
}

// 🔄 ARCHIVER UN FAVORI
class ArchiveFavoriteM extends FavoritePageEventM {
  final String favoriteId;

  const ArchiveFavoriteM({required this.favoriteId});

  @override
  List<Object?> get props => [favoriteId];
}

// 📊 CHARGEMENT DES STATISTIQUES
class LoadFavoriteStatsM extends FavoritePageEventM {
  const LoadFavoriteStatsM();

  @override
  List<Object?> get props => [];
}

// 🏷️ CHARGEMENT DES LISTES PERSONNALISÉES
class LoadCustomListsM extends FavoritePageEventM {
  const LoadCustomListsM();

  @override
  List<Object?> get props => [];
}

// 🔄 ACTUALISATION
class RefreshFavoritesM extends FavoritePageEventM {
  const RefreshFavoritesM();

  @override
  List<Object?> get props => [];
}

// 📱 FAVORIS RÉCENTS
class LoadRecentFavoritesM extends FavoritePageEventM {
  final int limit;

  const LoadRecentFavoritesM({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

// 🏷️ FILTRER PAR LISTE PERSONNALISÉE
class FilterByCustomListM extends FavoritePageEventM {
  final String listePersonnalisee;

  const FilterByCustomListM({required this.listePersonnalisee});

  @override
  List<Object?> get props => [listePersonnalisee];
}

// 📍 FILTRER PAR LOCALISATION
class FilterByLocationM extends FavoritePageEventM {
  final String ville;
  final String? pays;

  const FilterByLocationM({
    required this.ville,
    this.pays,
  });

  @override
  List<Object?> get props => [ville, pays];
}

// 🏷️ FILTRER PAR CATÉGORIE
class FilterByCategoryM extends FavoritePageEventM {
  final String categorie;

  const FilterByCategoryM({required this.categorie});

  @override
  List<Object?> get props => [categorie];
}

// 📊 CHARGEMENT DES MÉTRIQUES
class LoadFavoriteMetricsM extends FavoritePageEventM {
  const LoadFavoriteMetricsM();

  @override
  List<Object?> get props => [];
}
