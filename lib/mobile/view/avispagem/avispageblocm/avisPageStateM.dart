import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/avis.dart';

class AvisPageStateM extends Equatable {
  // 📋 DONNÉES PRINCIPALES
  final List<Avis>? avis;
  final List<Avis>? avisRecents;
  final Avis? avisDetail;

  // 🔄 ÉTATS DE CHARGEMENT
  final bool isLoading;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final bool isSearching;
  final bool isRefreshing;

  // ❌ GESTION D'ERREURS
  final String? error;
  final String? createError;
  final String? updateError;
  final String? deleteError;
  final String? searchError;

  // 🔍 FILTRES ET RECHERCHE
  final String? searchQuery;
  final String? selectedObjetType;
  final String? selectedStatut;
  final int? selectedNote;
  final List<String>? selectedTags;
  final String? selectedVille;

  // 📊 STATISTIQUES
  final Map<String, dynamic>? statsObjet;
  final int totalAvis;
  final double moyenneNote;
  final Map<String, int>? distributionNotes;

  // 🎯 MÉTADONNÉES
  final int currentPage;
  final int totalPages;
  final bool hasMoreData;

  // 🏷️ OPTIONS DE FILTRAGE
  final List<String>? availableTags;
  final List<String>? availableVilles;
  final List<String>? availableObjetTypes;

  const AvisPageStateM({
    this.avis,
    this.avisRecents,
    this.avisDetail,
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isSearching = false,
    this.isRefreshing = false,
    this.error,
    this.createError,
    this.updateError,
    this.deleteError,
    this.searchError,
    this.searchQuery,
    this.selectedObjetType,
    this.selectedStatut,
    this.selectedNote,
    this.selectedTags,
    this.selectedVille,
    this.statsObjet,
    this.totalAvis = 0,
    this.moyenneNote = 0.0,
    this.distributionNotes,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMoreData = false,
    this.availableTags,
    this.availableVilles,
    this.availableObjetTypes,
  });

  factory AvisPageStateM.initial() {
    return const AvisPageStateM(
      isLoading: true,
      totalAvis: 0,
      moyenneNote: 0.0,
      currentPage: 1,
      totalPages: 1,
      hasMoreData: false,
    );
  }

  AvisPageStateM copyWith({
    List<Avis>? avis,
    List<Avis>? avisRecents,
    Avis? avisDetail,
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isSearching,
    bool? isRefreshing,
    String? error,
    String? createError,
    String? updateError,
    String? deleteError,
    String? searchError,
    String? searchQuery,
    String? selectedObjetType,
    String? selectedStatut,
    int? selectedNote,
    List<String>? selectedTags,
    String? selectedVille,
    Map<String, dynamic>? statsObjet,
    int? totalAvis,
    double? moyenneNote,
    Map<String, int>? distributionNotes,
    int? currentPage,
    int? totalPages,
    bool? hasMoreData,
    List<String>? availableTags,
    List<String>? availableVilles,
    List<String>? availableObjetTypes,
  }) {
    return AvisPageStateM(
      avis: avis ?? this.avis,
      avisRecents: avisRecents ?? this.avisRecents,
      avisDetail: avisDetail ?? this.avisDetail,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isSearching: isSearching ?? this.isSearching,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
      createError: createError ?? this.createError,
      updateError: updateError ?? this.updateError,
      deleteError: deleteError ?? this.deleteError,
      searchError: searchError ?? this.searchError,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedObjetType: selectedObjetType ?? this.selectedObjetType,
      selectedStatut: selectedStatut ?? this.selectedStatut,
      selectedNote: selectedNote ?? this.selectedNote,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedVille: selectedVille ?? this.selectedVille,
      statsObjet: statsObjet ?? this.statsObjet,
      totalAvis: totalAvis ?? this.totalAvis,
      moyenneNote: moyenneNote ?? this.moyenneNote,
      distributionNotes: distributionNotes ?? this.distributionNotes,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      availableTags: availableTags ?? this.availableTags,
      availableVilles: availableVilles ?? this.availableVilles,
      availableObjetTypes: availableObjetTypes ?? this.availableObjetTypes,
    );
  }

  // Méthodes utilitaires
  bool get hasError =>
      error != null ||
      createError != null ||
      updateError != null ||
      deleteError != null ||
      searchError != null;

  bool get isLoadingAny =>
      isLoading ||
      isCreating ||
      isUpdating ||
      isDeleting ||
      isSearching ||
      isRefreshing;

  bool get hasAvis => avis != null && avis!.isNotEmpty;

  bool get hasAvisRecents => avisRecents != null && avisRecents!.isNotEmpty;

  List<Avis> get avisFiltres {
    if (avis == null) return [];

    List<Avis> result = List.from(avis!);

    // Filtrer par type d'objet
    if (selectedObjetType != null && selectedObjetType!.isNotEmpty) {
      result = result.where((a) => a.objetType == selectedObjetType).toList();
    }

    // Filtrer par statut
    if (selectedStatut != null && selectedStatut!.isNotEmpty) {
      result = result.where((a) => a.statut == selectedStatut).toList();
    }

    // Filtrer par note
    if (selectedNote != null) {
      result = result.where((a) => a.note == selectedNote).toList();
    }

    // Filtrer par tags
    if (selectedTags != null && selectedTags!.isNotEmpty) {
      result = result
          .where((a) =>
              a.tags != null &&
              selectedTags!.any((tag) => a.tags!.contains(tag)))
          .toList();
    }

    // Filtrer par ville
    if (selectedVille != null && selectedVille!.isNotEmpty) {
      result =
          result.where((a) => a.localisation?.ville == selectedVille).toList();
    }

    return result;
  }

  @override
  List<Object?> get props => [
        avis,
        avisRecents,
        avisDetail,
        isLoading,
        isCreating,
        isUpdating,
        isDeleting,
        isSearching,
        isRefreshing,
        error,
        createError,
        updateError,
        deleteError,
        searchError,
        searchQuery,
        selectedObjetType,
        selectedStatut,
        selectedNote,
        selectedTags,
        selectedVille,
        statsObjet,
        totalAvis,
        moyenneNote,
        distributionNotes,
        currentPage,
        totalPages,
        hasMoreData,
        availableTags,
        availableVilles,
        availableObjetTypes,
      ];
}



