import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/favorite.dart';

class FavoritePageStateM extends Equatable {
  final List<Favorite>? favorites;
  final bool isLoading;
  final String? error;
  final int totalFavorites;
  final int currentPage;
  final int totalPages;
  final bool hasMoreData;
  final Map<String, dynamic>? stats;
  final List<String>? customLists;
  final Map<String, dynamic>? metrics;

  // États spécifiques
  final bool isAdding;
  final String? addError;
  final bool isUpdating;
  final String? updateError;
  final bool isDeleting;
  final String? deleteError;

  const FavoritePageStateM({
    this.favorites,
    this.isLoading = false,
    this.error,
    this.totalFavorites = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMoreData = false,
    this.stats,
    this.customLists,
    this.metrics,
    this.isAdding = false,
    this.addError,
    this.isUpdating = false,
    this.updateError,
    this.isDeleting = false,
    this.deleteError,
  });

  factory FavoritePageStateM.initial() {
    return const FavoritePageStateM(
      favorites: [],
      isLoading: false,
      error: null,
      totalFavorites: 0,
      currentPage: 1,
      totalPages: 1,
      hasMoreData: false,
      stats: null,
      customLists: [],
      metrics: null,
      isAdding: false,
      addError: null,
      isUpdating: false,
      updateError: null,
      isDeleting: false,
      deleteError: null,
    );
  }

  FavoritePageStateM copyWith({
    List<Favorite>? favorites,
    bool? isLoading,
    String? error,
    int? totalFavorites,
    int? currentPage,
    int? totalPages,
    bool? hasMoreData,
    Map<String, dynamic>? stats,
    List<String>? customLists,
    Map<String, dynamic>? metrics,
    bool? isAdding,
    String? addError,
    bool? isUpdating,
    String? updateError,
    bool? isDeleting,
    String? deleteError,
  }) {
    return FavoritePageStateM(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalFavorites: totalFavorites ?? this.totalFavorites,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      stats: stats ?? this.stats,
      customLists: customLists ?? this.customLists,
      metrics: metrics ?? this.metrics,
      isAdding: isAdding ?? this.isAdding,
      addError: addError ?? this.addError,
      isUpdating: isUpdating ?? this.isUpdating,
      updateError: updateError ?? this.updateError,
      isDeleting: isDeleting ?? this.isDeleting,
      deleteError: deleteError ?? this.deleteError,
    );
  }

  @override
  List<Object?> get props => [
        favorites,
        isLoading,
        error,
        totalFavorites,
        currentPage,
        totalPages,
        hasMoreData,
        stats,
        customLists,
        metrics,
        isAdding,
        addError,
        isUpdating,
        updateError,
        isDeleting,
        deleteError,
      ];

  // 🔄 MÉTHODES UTILITAIRES
  bool get hasFavorites => favorites != null && favorites!.isNotEmpty;
  bool get hasError => error != null && error!.isNotEmpty;
  bool get hasStats => stats != null;
  bool get hasCustomLists => customLists != null && customLists!.isNotEmpty;
  bool get hasMetrics => metrics != null;

  // 📊 MÉTRIQUES RAPIDES
  int get totalActifs => favorites?.where((f) => f.estActif).length ?? 0;
  int get totalArchives => favorites?.where((f) => f.estArchive).length ?? 0;
  int get totalRecents => favorites?.where((f) => f.estRecent).length ?? 0;

  // 🏷️ LISTES DISPONIBLES
  List<String> get listesDisponibles => customLists ?? [];

  // 📍 VILLES DISPONIBLES
  List<String> get villesDisponibles {
    if (favorites == null) return [];
    return favorites!
        .where((f) => f.localisation?.ville != null)
        .map((f) => f.localisation!.ville)
        .toSet()
        .toList();
  }

  // 🏷️ CATÉGORIES DISPONIBLES
  List<String> get categoriesDisponibles {
    if (favorites == null) return [];
    return favorites!
        .where((f) => f.categorie != null)
        .map((f) => f.categorie!)
        .toSet()
        .toList();
  }
}



