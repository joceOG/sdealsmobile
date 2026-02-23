import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/api_client.dart';
import 'historyPageEventM.dart';
import 'historyPageStateM.dart';
import '../../../../data/models/history.dart';

class HistoryPageBlocM extends Bloc<HistoryPageEventM, HistoryPageStateM> {
  final ApiClient _apiClient = ApiClient();

  HistoryPageBlocM() : super(const HistoryPageInitialM()) {
    // 📋 CHARGER L'HISTORIQUE
    on<LoadHistoryDataM>(_onLoadHistoryDataM);

    // 🔍 RECHERCHER DANS L'HISTORIQUE
    on<SearchHistoryM>(_onSearchHistoryM);

    // ➕ AJOUTER UNE CONSULTATION
    on<AddHistoryM>(_onAddHistoryM);

    // ✏️ MODIFIER UNE CONSULTATION
    on<UpdateHistoryM>(_onUpdateHistoryM);

    // 🗑️ SUPPRIMER UNE CONSULTATION
    on<DeleteHistoryM>(_onDeleteHistoryM);

    // 📊 CHARGER LES STATISTIQUES
    on<LoadHistoryStatsM>(_onLoadHistoryStatsM);

    // 📱 CONSULTATIONS RÉCENTES
    on<LoadRecentHistoryM>(_onLoadRecentHistoryM);

    // 🏷️ CONSULTATIONS PAR TYPE
    on<LoadHistoryByTypeM>(_onLoadHistoryByTypeM);

    // 🔄 ARCHIVER UNE CONSULTATION
    on<ArchiveHistoryM>(_onArchiveHistoryM);

    // 🧹 NETTOYER L'HISTORIQUE ANCIEN
    on<CleanOldHistoryM>(_onCleanOldHistoryM);

    // 🔄 ACTUALISER L'HISTORIQUE
    on<RefreshHistoryM>(_onRefreshHistoryM);
  }

  // 📋 CHARGER L'HISTORIQUE
  Future<void> _onLoadHistoryDataM(
    LoadHistoryDataM event,
    Emitter<HistoryPageStateM> emit,
  ) async {
    try {
      emit(const HistoryPageLoadingM());

      final Map<String, dynamic> queryParams = {};
      if (event.objetType != null) queryParams['objetType'] = event.objetType!;
      if (event.statut != null) queryParams['statut'] = event.statut!;
      if (event.categorie != null) queryParams['categorie'] = event.categorie!;
      if (event.ville != null) queryParams['ville'] = event.ville!;
      if (event.page != null) queryParams['page'] = event.page!.toString();
      if (event.limit != null) queryParams['limit'] = event.limit!.toString();
      if (event.sortBy != null) queryParams['sortBy'] = event.sortBy!;
      if (event.sortOrder != null) queryParams['sortOrder'] = event.sortOrder!;
      if (event.periode != null)
        queryParams['periode'] = event.periode!.toString();

      // Construire l'URL avec les paramètres de requête
      String url = '/history';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        url += '?$queryString';
      }
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<History> history = (responseData['history'] as List)
            .map((item) => History.fromJson(item))
            .toList();

        emit(HistoryPageLoadedM(
          history: history,
          pagination: responseData['pagination'],
        ));
      } else {
        emit(HistoryPageErrorM(
          message: 'Erreur lors du chargement de l\'historique',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(HistoryPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔍 RECHERCHER DANS L'HISTORIQUE
  Future<void> _onSearchHistoryM(
    SearchHistoryM event,
    Emitter<HistoryPageStateM> emit,
  ) async {
    try {
      emit(const HistoryPageLoadingM());

      final Map<String, dynamic> queryParams = {
        'q': event.query,
      };
      if (event.objetType != null) queryParams['objetType'] = event.objetType!;
      if (event.categorie != null) queryParams['categorie'] = event.categorie!;
      if (event.ville != null) queryParams['ville'] = event.ville!;
      if (event.periode != null)
        queryParams['periode'] = event.periode!.toString();

      // Construire l'URL avec les paramètres de requête
      String url = '/history/search';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        url += '?$queryString';
      }
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<History> searchResults = (responseData as List)
            .map((item) => History.fromJson(item))
            .toList();

        emit(HistorySearchedM(
          searchResults: searchResults,
          query: event.query,
        ));
      } else {
        emit(HistoryPageErrorM(
          message: 'Erreur lors de la recherche',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(HistoryPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // ➕ AJOUTER UNE CONSULTATION
  Future<void> _onAddHistoryM(
    AddHistoryM event,
    Emitter<HistoryPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> body = {
        'objetType': event.objetType,
        'titre': event.titre,
        'sessionId': event.sessionId,
      };

      if (event.objetId != null) body['objetId'] = event.objetId!;
      if (event.description != null) body['description'] = event.description!;
      if (event.image != null) body['image'] = event.image!;
      if (event.prix != null) body['prix'] = event.prix!;
      if (event.devise != null) body['devise'] = event.devise!;
      if (event.categorie != null) body['categorie'] = event.categorie!;
      if (event.tags != null) body['tags'] = event.tags!;
      if (event.ville != null)
        body['localisation'] = {
          'ville': event.ville!,
          'pays': event.pays ?? 'Côte d\'Ivoire',
        };
      if (event.note != null) body['note'] = event.note!;
      if (event.dureeConsultation != null)
        body['dureeConsultation'] = event.dureeConsultation!;
      if (event.userAgent != null) body['userAgent'] = event.userAgent!;
      if (event.ipAddress != null) body['ipAddress'] = event.ipAddress!;
      if (event.latitude != null && event.longitude != null) {
        body['localisationUtilisateur'] = {
          'latitude': event.latitude!,
          'longitude': event.longitude!,
        };
      }
      if (event.url != null) body['url'] = event.url!;
      if (event.referrer != null) body['referrer'] = event.referrer!;
      if (event.tagsConsultation != null)
        body['tagsConsultation'] = event.tagsConsultation!;
      if (event.interactions != null)
        body['interactions'] = event.interactions!;
      if (event.actions != null) body['actions'] = event.actions!;
      if (event.deviceInfo != null) body['deviceInfo'] = event.deviceInfo!;

      final response = await _apiClient.post('/history', body: body);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final History history = History.fromJson(responseData);

        emit(HistoryAddedM(history: history));
      } else {
        emit(HistoryPageErrorM(
          message: 'Erreur lors de l\'ajout de la consultation',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(HistoryPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // ✏️ MODIFIER UNE CONSULTATION
  Future<void> _onUpdateHistoryM(
    UpdateHistoryM event,
    Emitter<HistoryPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> body = {};

      if (event.titre != null) body['titre'] = event.titre!;
      if (event.description != null) body['description'] = event.description!;
      if (event.dureeConsultation != null)
        body['dureeConsultation'] = event.dureeConsultation!;
      if (event.tagsConsultation != null)
        body['tagsConsultation'] = event.tagsConsultation!;
      if (event.interactions != null)
        body['interactions'] = event.interactions!;
      if (event.actions != null) body['actions'] = event.actions!;

      final response =
          await _apiClient.put('/history/${event.historyId}', body: body);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final History history = History.fromJson(responseData);

        emit(HistoryUpdatedM(history: history));
      } else {
        emit(HistoryPageErrorM(
          message: 'Erreur lors de la modification de la consultation',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(HistoryPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🗑️ SUPPRIMER UNE CONSULTATION
  Future<void> _onDeleteHistoryM(
    DeleteHistoryM event,
    Emitter<HistoryPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.delete('/history/${event.historyId}');

      if (response.statusCode == 200) {
        emit(HistoryDeletedM(historyId: event.historyId));
      } else {
        emit(HistoryPageErrorM(
          message: 'Erreur lors de la suppression de la consultation',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(HistoryPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 📊 CHARGER LES STATISTIQUES
  Future<void> _onLoadHistoryStatsM(
    LoadHistoryStatsM event,
    Emitter<HistoryPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (event.periode != null)
        queryParams['periode'] = event.periode!.toString();

      // Construire l'URL avec les paramètres de requête
      String url = '/history/stats';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        url += '?$queryString';
      }
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        emit(HistoryStatsLoadedM(stats: responseData));
      } else {
        emit(HistoryPageErrorM(
          message: 'Erreur lors du chargement des statistiques',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(HistoryPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 📱 CONSULTATIONS RÉCENTES
  Future<void> _onLoadRecentHistoryM(
    LoadRecentHistoryM event,
    Emitter<HistoryPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (event.limit != null) queryParams['limit'] = event.limit!.toString();

      // Construire l'URL avec les paramètres de requête
      String url = '/history/recent';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        url += '?$queryString';
      }
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<History> recentHistory = (responseData as List)
            .map((item) => History.fromJson(item))
            .toList();

        emit(RecentHistoryLoadedM(recentHistory: recentHistory));
      } else {
        emit(HistoryPageErrorM(
          message: 'Erreur lors du chargement des consultations récentes',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(HistoryPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🏷️ CONSULTATIONS PAR TYPE
  Future<void> _onLoadHistoryByTypeM(
    LoadHistoryByTypeM event,
    Emitter<HistoryPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> queryParams = {
        'objetType': event.objetType,
      };
      if (event.limit != null) queryParams['limit'] = event.limit!.toString();

      // Construire l'URL avec les paramètres de requête
      String url = '/history/by-type';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        url += '?$queryString';
      }
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<History> historyByType = (responseData as List)
            .map((item) => History.fromJson(item))
            .toList();

        emit(HistoryByTypeLoadedM(
          historyByType: historyByType,
          objetType: event.objetType,
        ));
      } else {
        emit(HistoryPageErrorM(
          message: 'Erreur lors du chargement des consultations par type',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(HistoryPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔄 ARCHIVER UNE CONSULTATION
  Future<void> _onArchiveHistoryM(
    ArchiveHistoryM event,
    Emitter<HistoryPageStateM> emit,
  ) async {
    try {
      final response =
          await _apiClient.patch('/history/${event.historyId}/archive');

      if (response.statusCode == 200) {
        emit(HistoryArchivedM(historyId: event.historyId));
      } else {
        emit(HistoryPageErrorM(
          message: 'Erreur lors de l\'archivage de la consultation',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(HistoryPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🧹 NETTOYER L'HISTORIQUE ANCIEN
  Future<void> _onCleanOldHistoryM(
    CleanOldHistoryM event,
    Emitter<HistoryPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (event.jours != null) queryParams['jours'] = event.jours!.toString();

      // Construire l'URL avec les paramètres de requête
      String url = '/history/clean';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        url += '?$queryString';
      }
      final response = await _apiClient.delete(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final int deletedCount = responseData['deletedCount'] ?? 0;

        emit(HistoryCleanedM(deletedCount: deletedCount));
      } else {
        emit(HistoryPageErrorM(
          message: 'Erreur lors du nettoyage de l\'historique',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(HistoryPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔄 ACTUALISER L'HISTORIQUE
  Future<void> _onRefreshHistoryM(
    RefreshHistoryM event,
    Emitter<HistoryPageStateM> emit,
  ) async {
    add(const LoadHistoryDataM());
  }
}
