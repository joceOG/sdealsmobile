import 'package:flutter/foundation.dart';
import 'package:sdealsmobile/mobile/view/homepagem/homepageblocm/homePageEventM.dart';
import 'package:sdealsmobile/mobile/view/homepagem/homepageblocm/homePageStateM.dart';

import 'package:bloc/bloc.dart';

import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/utils/network_user_message.dart';

class HomePageBlocM extends Bloc<HomePageEventM, HomePageStateM> {
  HomePageBlocM({
    ApiClient? apiClient,
    Duration retryDelay = const Duration(seconds: 2),
  })  : _apiClient = apiClient ?? ApiClient(),
        _retryDelay = retryDelay,
        super(HomePageStateM.initial()) {
    on<LoadCategorieDataM>(_onLoadCategorieDataM);
  }

  final ApiClient _apiClient;
  final Duration _retryDelay;

  Future<void> _onLoadCategorieDataM(
    LoadCategorieDataM event,
    Emitter<HomePageStateM> emit,
  ) async {
    final kept = state.listItems;
    final started = Stopwatch()..start();
    emit(state.copyWith(isLoading: true, error: '', showingSaved: false));

    final cached = await _apiClient.readCachedCategorie('Métiers');
    if (cached.isNotEmpty) {
      emit(state.copyWith(
        listItems: cached,
        isLoading: true,
        error: '',
      ));
    }

    try {
      final fresh = await _loadFreshCategories();
      if (kDebugMode) {
        debugPrint(
          'home.categories elapsed=${started.elapsedMilliseconds}ms result=ok count=${fresh.length}',
        );
      }
      emit(state.copyWith(
        listItems: fresh,
        isLoading: false,
        error: '',
        showingSaved: false,
      ));
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'home.categories elapsed=${started.elapsedMilliseconds}ms result=error kind=${classifyUserNetworkFailure(error).name}',
        );
      }
      final visible = cached.isNotEmpty
          ? cached
          : (kept != null && kept.isNotEmpty ? kept : state.listItems);
      final hasVisible = visible != null && visible.isNotEmpty;
      emit(state.copyWith(
        listItems: visible,
        isLoading: false,
        error: hasVisible ? '' : _errorWhenNothingVisible(error),
        showingSaved: hasVisible,
      ));
    }
  }

  /// Un seul essai supplémentaire, après le premier timeout.
  /// Pas de second retry dans ApiClient.
  Future<List<Categorie>> _loadFreshCategories() async {
    try {
      return await _apiClient.fetchCategorie(
        'Métiers',
        skipCache: true,
        settleLateResponse: true,
      );
    } catch (error) {
      if (!isTransientReadFailure(error)) rethrow;
      await Future<void>.delayed(_retryDelay);
      return _apiClient.fetchCategorie(
        'Métiers',
        skipCache: true,
        settleLateResponse: true,
      );
    }
  }

  String _errorWhenNothingVisible(Object error) {
    final message = userFacingNetworkMessage(error);
    if (message.isNotEmpty) return message;
    return genericUserMessage;
  }
}
