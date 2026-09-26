import 'package:bloc/bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/local_storage_service.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageEventM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageStateM.dart';

class SearchPageBlocM extends Bloc<SearchPageEventM, SearchPageStateM> {
  final ApiClient _apiClient = ApiClient();
  final LocalStorageService _localStorageService = LocalStorageService();
  int _suggestionRequestId = 0;
  int _searchRequestId = 0;

  SearchPageBlocM() : super(SearchPageStateM.initial()) {
    on<FetchSuggestions>(_onFetchSuggestions);
    on<PerformGlobalSearch>(_onPerformGlobalSearch);
    on<ClearSearch>(_onClearSearch);
    on<LoadHistory>(_onLoadHistory);
    on<AddToHistory>(_onAddToHistory);
    on<ClearHistory>(_onClearHistory);
    on<RemoveFromHistory>(_onRemoveFromHistory);
    on<UpdateFilters>(_onUpdateFilters);

    // Legacy support
    on<LoadCategorieDataM>((event, emit) {});
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<SearchPageStateM> emit,
  ) async {
    final history = await _localStorageService.getSearchHistory();
    emit(state.copyWith(history: history));
  }

  Future<void> _onAddToHistory(
    AddToHistory event,
    Emitter<SearchPageStateM> emit,
  ) async {
    await _localStorageService.addToHistory(event.query);
    add(LoadHistory());
  }

  Future<void> _onClearHistory(
    ClearHistory event,
    Emitter<SearchPageStateM> emit,
  ) async {
    await _localStorageService.clearHistory();
    emit(state.copyWith(history: []));
  }

  Future<void> _onRemoveFromHistory(
    RemoveFromHistory event,
    Emitter<SearchPageStateM> emit,
  ) async {
    await _localStorageService.removeFromHistory(event.query);
    final history = await _localStorageService.getSearchHistory();
    emit(state.copyWith(history: history));
  }

  Future<void> _onFetchSuggestions(
    FetchSuggestions event,
    Emitter<SearchPageStateM> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      final history = await _localStorageService.getSearchHistory();
      emit(state.copyWith(suggestions: [], history: history));
      return;
    }

    if (event.query.trim().length < 2) {
      emit(state.copyWith(suggestions: []));
      return;
    }

    final requestQuery = event.query.trim();
    final requestId = ++_suggestionRequestId;
    try {
      final suggestions = await _apiClient.getSuggestions(requestQuery);
      if (requestId != _suggestionRequestId) return;
      emit(state.copyWith(suggestions: suggestions));
    } catch (e) {
      if (requestId != _suggestionRequestId) return;
      emit(state.copyWith(suggestions: []));
    }
  }

  Future<void> _onPerformGlobalSearch(
    PerformGlobalSearch event,
    Emitter<SearchPageStateM> emit,
  ) async {
    final query = event.query.trim();
    if (query.length < 2) {
      emit(state.copyWith(
        isLoading: false,
        hasSearched: false,
        query: query,
        error: '',
        suggestions: [],
      ));
      return;
    }

    await _localStorageService.addToHistory(query);
    final history = await _localStorageService.getSearchHistory();
    final requestId = ++_searchRequestId;
    emit(state.copyWith(
      isLoading: true,
      query: query,
      error: '',
      history: history,
    ));

    try {
      final result = await _apiClient.searchGlobal(
        query,
        minPrice: state.minPrice != 0 ? state.minPrice.toInt() : null,
        maxPrice: state.maxPrice != 1000000 ? state.maxPrice.toInt() : null,
        city: state.city.isNotEmpty ? state.city : null,
      );
      if (requestId != _searchRequestId) return;

      final results = result['results'] ?? {};
      final counts = result['counts'] ?? {};

      emit(state.copyWith(
        isLoading: false,
        hasSearched: true,
        query: query,
        services: results['services'] ?? [],
        articles: results['articles'] ?? [],
        freelances: results['freelances'] ?? [],
        prestataires: results['prestataires'] ?? [],
        vendeurs: results['vendeurs'] ?? [],
        counts: Map<String, int>.from(counts),
      ));
    } catch (e) {
      if (requestId != _searchRequestId) return;
      emit(state.copyWith(
        isLoading: false,
        hasSearched: true,
        query: query,
        error: 'Erreur lors de la recherche: $e',
      ));
    }
  }

  void _onUpdateFilters(UpdateFilters event, Emitter<SearchPageStateM> emit) {
    emit(state.copyWith(
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      city: event.city,
    ));
  }

  void _onClearSearch(ClearSearch event, Emitter<SearchPageStateM> emit) {
    _suggestionRequestId++;
    _searchRequestId++;
    emit(SearchPageStateM.initial().copyWith(history: state.history));
  }
}
