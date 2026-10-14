import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:sdealsmobile/mobile/view/favorispagem/favorispageblocm/favoritePageEventM.dart';
import 'package:sdealsmobile/mobile/view/favorispagem/favorispageblocm/favoritePageStateM.dart';
import 'package:sdealsmobile/data/models/favorite.dart';
import 'package:sdealsmobile/data/services/api_client.dart';

class FavoritePageBlocM extends Bloc<FavoritePageEventM, FavoritePageStateM> {
  final ApiClient _apiClient = ApiClient();

  /// Remplace le GET favoris dans les tests. Le chemin production reste
  /// `_apiClient.get` lorsque ce crochet est nul.
  @visibleForTesting
  static Future<http.Response> Function(String endpoint)? debugGet;

  @visibleForTesting
  static void debugReset() => debugGet = null;

  FavoritePageBlocM() : super(FavoritePageStateM.initial()) {
    // 📋 ÉVÉNEMENTS DE CHARGEMENT
    on<LoadFavoritesM>(_onLoadFavoritesM);
    on<SearchFavoritesM>(_onSearchFavoritesM);
    on<LoadRecentFavoritesM>(_onLoadRecentFavoritesM);

    // ✏️ ÉVÉNEMENTS DE CRÉATION/MODIFICATION
    on<AddFavoriteM>(_onAddFavoriteM);
    on<UpdateFavoriteM>(_onUpdateFavoriteM);
    on<DeleteFavoriteM>(_onDeleteFavoriteM);
    on<ArchiveFavoriteM>(_onArchiveFavoriteM);

    // 📊 ÉVÉNEMENTS DE STATISTIQUES
    on<LoadFavoriteStatsM>(_onLoadFavoriteStatsM);
    on<LoadCustomListsM>(_onLoadCustomListsM);
    on<LoadFavoriteMetricsM>(_onLoadFavoriteMetricsM);

    // 🔄 ÉVÉNEMENTS DE FILTRAGE
    on<FilterByCustomListM>(_onFilterByCustomListM);
    on<FilterByLocationM>(_onFilterByLocationM);
    on<FilterByCategoryM>(_onFilterByCategoryM);

    // 🔄 ACTUALISATION
    on<RefreshFavoritesM>(_onRefreshFavoritesM);
  }

  // 📋 CHARGEMENT DES FAVORIS
  Future<void> _onLoadFavoritesM(
      LoadFavoritesM event, Emitter<FavoritePageStateM> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Construction des paramètres de requête
      final Map<String, String> queryParams = {};
      if (event.objetType != null) queryParams['objetType'] = event.objetType!;
      if (event.statut != null) queryParams['statut'] = event.statut!;
      if (event.categorie != null) queryParams['categorie'] = event.categorie!;
      if (event.ville != null) queryParams['ville'] = event.ville!;
      if (event.listePersonnalisee != null)
        queryParams['listePersonnalisee'] = event.listePersonnalisee!;
      queryParams['page'] = event.page.toString();
      queryParams['limit'] = event.limit.toString();
      if (event.sortBy != null) queryParams['sortBy'] = event.sortBy!;
      if (event.sortOrder != null) queryParams['sortOrder'] = event.sortOrder!;

      // Appel API
      final endpoint = '/favorites?${Uri(queryParameters: queryParams).query}';
      final response = debugGet != null
          ? await debugGet!(endpoint)
          : await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> favoritesJson =
            responseData['favorites'] ?? responseData;
        final List<Favorite> favorites =
            favoritesJson.map((json) => Favorite.fromJson(json)).toList();

        final pagination = responseData['pagination'];
        final totalFavorites = pagination?['total'] ?? favorites.length;
        final currentPage = pagination?['page'] ?? event.page;
        final totalPages = pagination?['pages'] ?? 1;
        final hasMoreData = currentPage < totalPages;

        emit(state.copyWith(
          favorites: favorites,
          isLoading: false,
          error: '',
          totalFavorites: totalFavorites,
          currentPage: currentPage,
          totalPages: totalPages,
          hasMoreData: hasMoreData,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Erreur lors du chargement des favoris',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔍 RECHERCHE DANS LES FAVORIS
  Future<void> _onSearchFavoritesM(
      SearchFavoritesM event, Emitter<FavoritePageStateM> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final Map<String, String> queryParams = {'q': event.query};
      if (event.objetType != null) queryParams['objetType'] = event.objetType!;
      if (event.categorie != null) queryParams['categorie'] = event.categorie!;
      if (event.ville != null) queryParams['ville'] = event.ville!;

      final response = await _apiClient
          .get('/favorites/search?${Uri(queryParameters: queryParams).query}');

      if (response.statusCode == 200) {
        final List<dynamic> favoritesJson = jsonDecode(response.body);
        final List<Favorite> favorites =
            favoritesJson.map((json) => Favorite.fromJson(json)).toList();

        emit(state.copyWith(
          favorites: favorites,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Erreur lors de la recherche',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // ➕ AJOUTER UN FAVORI
  Future<void> _onAddFavoriteM(
      AddFavoriteM event, Emitter<FavoritePageStateM> emit) async {
    emit(state.copyWith(isAdding: true, addError: null));

    try {
      final Map<String, dynamic> body = {
        'objetType': event.objetType,
        'objetId': event.objetId,
        'titre': event.titre,
        'description': event.description,
        'image': event.image,
        'prix': event.prix,
        'devise': event.devise,
        'categorie': event.categorie,
        'tags': event.tags,
        'localisation': event.ville != null || event.pays != null
            ? {
                'ville': event.ville,
                'pays': event.pays ?? 'Côte d\'Ivoire',
              }
            : null,
        'note': event.note,
        'listePersonnalisee': event.listePersonnalisee,
        'notesPersonnelles': event.notesPersonnelles,
        'alertePrix': event.alertePrix,
        'alerteDisponibilite': event.alerteDisponibilite,
      };

      final response = await _apiClient.post('/favorites', body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        emit(state.copyWith(isAdding: false));
        // Recharger les favoris
        add(LoadFavoritesM());
      } else {
        emit(state.copyWith(
          isAdding: false,
          addError: 'Erreur lors de l\'ajout du favori',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isAdding: false,
        addError: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // ✏️ MODIFIER UN FAVORI
  Future<void> _onUpdateFavoriteM(
      UpdateFavoriteM event, Emitter<FavoritePageStateM> emit) async {
    emit(state.copyWith(isUpdating: true, updateError: null));

    try {
      final Map<String, dynamic> body = {};
      if (event.titre != null) body['titre'] = event.titre;
      if (event.description != null) body['description'] = event.description;
      if (event.image != null) body['image'] = event.image;
      if (event.prix != null) body['prix'] = event.prix;
      if (event.devise != null) body['devise'] = event.devise;
      if (event.categorie != null) body['categorie'] = event.categorie;
      if (event.tags != null) body['tags'] = event.tags;
      if (event.ville != null || event.pays != null) {
        body['localisation'] = {
          'ville': event.ville,
          'pays': event.pays ?? 'Côte d\'Ivoire',
        };
      }
      if (event.note != null) body['note'] = event.note;
      if (event.listePersonnalisee != null)
        body['listePersonnalisee'] = event.listePersonnalisee;
      if (event.notesPersonnelles != null)
        body['notesPersonnelles'] = event.notesPersonnelles;
      if (event.alertePrix != null) body['alertePrix'] = event.alertePrix;
      if (event.alerteDisponibilite != null)
        body['alerteDisponibilite'] = event.alerteDisponibilite;

      final response =
          await _apiClient.put('/favorites/${event.favoriteId}', body: body);

      if (response.statusCode == 200) {
        emit(state.copyWith(isUpdating: false));
        // Recharger les favoris
        add(LoadFavoritesM());
      } else {
        emit(state.copyWith(
          isUpdating: false,
          updateError: 'Erreur lors de la modification',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        updateError: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🗑️ SUPPRIMER UN FAVORI
  Future<void> _onDeleteFavoriteM(
      DeleteFavoriteM event, Emitter<FavoritePageStateM> emit) async {
    emit(state.copyWith(isDeleting: true, deleteError: null));

    try {
      final response =
          await _apiClient.delete('/favorites/${event.favoriteId}');

      if (response.statusCode == 200) {
        emit(state.copyWith(isDeleting: false));
        // Recharger les favoris
        add(LoadFavoritesM());
      } else {
        emit(state.copyWith(
          isDeleting: false,
          deleteError: 'Erreur lors de la suppression',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isDeleting: false,
        deleteError: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔄 ARCHIVER UN FAVORI
  Future<void> _onArchiveFavoriteM(
      ArchiveFavoriteM event, Emitter<FavoritePageStateM> emit) async {
    try {
      final response =
          await _apiClient.patch('/favorites/${event.favoriteId}/archive');

      if (response.statusCode == 200) {
        // Recharger les favoris
        add(LoadFavoritesM());
      }
    } catch (e) {
      emit(state.copyWith(
          error: 'Erreur lors de l\'archivage: ${e.toString()}'));
    }
  }

  // 📊 CHARGEMENT DES STATISTIQUES
  Future<void> _onLoadFavoriteStatsM(
      LoadFavoriteStatsM event, Emitter<FavoritePageStateM> emit) async {
    try {
      final response = await _apiClient.get('/favorites/stats');

      if (response.statusCode == 200) {
        final Map<String, dynamic> stats = jsonDecode(response.body);
        emit(state.copyWith(stats: stats));
      }
    } catch (e) {
      emit(state.copyWith(
          error:
              'Erreur lors du chargement des statistiques: ${e.toString()}'));
    }
  }

  // 🏷️ CHARGEMENT DES LISTES PERSONNALISÉES
  Future<void> _onLoadCustomListsM(
      LoadCustomListsM event, Emitter<FavoritePageStateM> emit) async {
    try {
      final response = await _apiClient.get('/favorites/lists');

      if (response.statusCode == 200) {
        final List<dynamic> lists = jsonDecode(response.body);
        emit(state.copyWith(customLists: List<String>.from(lists)));
      }
    } catch (e) {
      emit(state.copyWith(
          error: 'Erreur lors du chargement des listes: ${e.toString()}'));
    }
  }

  // 📊 CHARGEMENT DES MÉTRIQUES
  Future<void> _onLoadFavoriteMetricsM(
      LoadFavoriteMetricsM event, Emitter<FavoritePageStateM> emit) async {
    try {
      // Pour l'instant, on utilise les données locales
      final metrics = {
        'totalActifs': state.totalActifs,
        'totalArchives': state.totalArchives,
        'totalRecents': state.totalRecents,
        'villesDisponibles': state.villesDisponibles,
        'categoriesDisponibles': state.categoriesDisponibles,
      };
      emit(state.copyWith(metrics: metrics));
    } catch (e) {
      emit(state.copyWith(
          error: 'Erreur lors du chargement des métriques: ${e.toString()}'));
    }
  }

  // 🔄 FILTRAGE PAR LISTE PERSONNALISÉE
  Future<void> _onFilterByCustomListM(
      FilterByCustomListM event, Emitter<FavoritePageStateM> emit) async {
    add(LoadFavoritesM(listePersonnalisee: event.listePersonnalisee));
  }

  // 📍 FILTRAGE PAR LOCALISATION
  Future<void> _onFilterByLocationM(
      FilterByLocationM event, Emitter<FavoritePageStateM> emit) async {
    add(LoadFavoritesM(ville: event.ville));
  }

  // 🏷️ FILTRAGE PAR CATÉGORIE
  Future<void> _onFilterByCategoryM(
      FilterByCategoryM event, Emitter<FavoritePageStateM> emit) async {
    add(LoadFavoritesM(categorie: event.categorie));
  }

  // 📱 FAVORIS RÉCENTS
  Future<void> _onLoadRecentFavoritesM(
      LoadRecentFavoritesM event, Emitter<FavoritePageStateM> emit) async {
    add(LoadFavoritesM(
        limit: event.limit, sortBy: 'dateAjout', sortOrder: 'desc'));
  }

  // 🔄 ACTUALISATION
  Future<void> _onRefreshFavoritesM(
      RefreshFavoritesM event, Emitter<FavoritePageStateM> emit) async {
    add(LoadFavoritesM());
  }
}
