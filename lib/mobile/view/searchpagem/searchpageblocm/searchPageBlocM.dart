import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageEventM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageStateM.dart';

import 'package:bloc/bloc.dart';

import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/local_storage_service.dart';



class SearchPageBlocM extends Bloc<SearchPageEventM, SearchPageStateM> {
  final ApiClient _apiClient = ApiClient();
  final LocalStorageService _localStorageService = LocalStorageService();

  SearchPageBlocM() : super(SearchPageStateM.initial()) {
    on<FetchSuggestions>(_onFetchSuggestions);
    on<PerformGlobalSearch>(_onPerformGlobalSearch);
    on<ClearSearch>(_onClearSearch);
    on<LoadHistory>(_onLoadHistory);
    on<AddToHistory>(_onAddToHistory);
    on<ClearHistory>(_onClearHistory);
    on<UpdateFilters>(_onUpdateFilters);
    
    // Legacy support
    on<LoadCategorieDataM>((event, emit) {});
  }

  Future<void> _onLoadHistory(LoadHistory event, Emitter<SearchPageStateM> emit) async {
    final history = await _localStorageService.getSearchHistory();
    emit(state.copyWith(history: history));
  }

  Future<void> _onAddToHistory(AddToHistory event, Emitter<SearchPageStateM> emit) async {
    await _localStorageService.addToHistory(event.query);
    add(LoadHistory()); // Rafraîchir l'historique
  }

  Future<void> _onClearHistory(ClearHistory event, Emitter<SearchPageStateM> emit) async {
    await _localStorageService.clearHistory();
    emit(state.copyWith(history: []));
  }

  Future<void> _onFetchSuggestions(
    FetchSuggestions event,
    Emitter<SearchPageStateM> emit,
  ) async {
    // Si vide ou trop court, on vide les suggestions API mais on garde l'historique dispo dans le state
    if (event.query.isEmpty) {
      final history = await _localStorageService.getSearchHistory();
      emit(state.copyWith(suggestions: [], history: history));
      return;
    }

    // Appel API seulement si > 2 caractères
    if (event.query.length > 2) {
      try {
        final suggestions = await _apiClient.getSuggestions(event.query);
        emit(state.copyWith(suggestions: suggestions));
      } catch (e) {
        print('Erreur suggestions: $e');
        emit(state.copyWith(suggestions: []));
      }
    } else {
      emit(state.copyWith(suggestions: []));
    }
  }

  Future<void> _onPerformGlobalSearch(
    PerformGlobalSearch event,
    Emitter<SearchPageStateM> emit,
  ) async {
    // Sauvegarder dans l'historique
    if (event.query.isNotEmpty) {
      await _localStorageService.addToHistory(event.query);
      // On rafraîchit l'historique en fond
      final history = await _localStorageService.getSearchHistory();
      emit(state.copyWith(isLoading: true, query: event.query, error: '', history: history));
    } else {
      emit(state.copyWith(isLoading: true, query: event.query, error: ''));
    }

    try {
      final result = await _apiClient.searchGlobal(
        event.query,
        minPrice: state.minPrice != 0 ? state.minPrice.toInt() : null,
        maxPrice: state.maxPrice != 1000000 ? state.maxPrice.toInt() : null,
        city: state.city.isNotEmpty ? state.city : null,
      );
      
      final results = result['results'] ?? {};
      final counts = result['counts'] ?? {};

      emit(state.copyWith(
        isLoading: false,
        services: results['services'] ?? [],
        articles: results['articles'] ?? [],
        freelances: results['freelances'] ?? [],
        prestataires: results['prestataires'] ?? [],
        vendeurs: results['vendeurs'] ?? [],
        counts: Map<String, int>.from(counts),
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: "Erreur lors de la recherche: $e",
      ));
    }
  }

  void _onUpdateFilters(UpdateFilters event, Emitter<SearchPageStateM> emit) {
    emit(state.copyWith(
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      city: event.city,
    ));
    // Optionnel : Lancer la recherche automatiquement ou attendre un bouton "Appliquer"
    // Ici, on met juste à jour l'état UI, l'event PerformGlobalSearch utilisera ces valeurs.
  }

  void _onClearSearch(ClearSearch event, Emitter<SearchPageStateM> emit) {
    emit(SearchPageStateM.initial());
  }
}
