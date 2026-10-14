import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../../data/services/api_client.dart';
import 'alertPageEventM.dart';
import 'alertPageStateM.dart';
import '../../../../data/models/alert.dart';

class AlertPageBlocM extends Bloc<AlertPageEventM, AlertPageStateM> {
  final ApiClient _apiClient = ApiClient();

  @visibleForTesting
  static Future<http.Response> Function(String endpoint)? debugGet;

  @visibleForTesting
  static Future<http.Response> Function(String endpoint)? debugPut;

  @visibleForTesting
  static void debugReset() {
    debugGet = null;
    debugPut = null;
  }

  AlertPageBlocM() : super(const AlertPageInitialM()) {
    // 📋 CHARGER LES ALERTES
    on<LoadAlertsDataM>(_onLoadAlertsDataM);

    // 🔍 RECHERCHER DANS LES ALERTES
    on<SearchAlertsM>(_onSearchAlertsM);

    // ➕ CRÉER UNE ALERTE
    on<CreateAlertM>(_onCreateAlertM);

    // ✏️ MODIFIER UNE ALERTE
    on<UpdateAlertM>(_onUpdateAlertM);

    // 🗑️ SUPPRIMER UNE ALERTE
    on<DeleteAlertM>(_onDeleteAlertM);

    // 👁️ MARQUER COMME LUE
    on<MarkAsReadM>(_onMarkAsReadM);

    // 👁️ MARQUER TOUTES COMME LUES
    on<MarkAllAsReadM>(_onMarkAllAsReadM);

    // 📁 ARCHIVER UNE ALERTE
    on<ArchiveAlertM>(_onArchiveAlertM);

    // 📁 ARCHIVER TOUTES LES ALERTES
    on<ArchiveAllAlertsM>(_onArchiveAllAlertsM);

    // 📊 CHARGER LES STATISTIQUES
    on<LoadAlertStatsM>(_onLoadAlertStatsM);

    // 📱 ALERTES NON LUES
    on<LoadUnreadAlertsM>(_onLoadUnreadAlertsM);

    // 🏷️ ALERTES PAR TYPE
    on<LoadAlertsByTypeM>(_onLoadAlertsByTypeM);

    // 🔔 ALERTES URGENTES
    on<LoadUrgentAlertsM>(_onLoadUrgentAlertsM);

    // 🧹 NETTOYER LES ALERTES ANCIENNES
    on<CleanOldAlertsM>(_onCleanOldAlertsM);

    // 🔄 ACTUALISER LES ALERTES
    on<RefreshAlertsM>(_onRefreshAlertsM);

    // ⚙️ CONFIGURER LES PRÉFÉRENCES
    on<UpdateAlertPreferencesM>(_onUpdateAlertPreferencesM);

    // 📋 CHARGER LES PRÉFÉRENCES
    on<LoadAlertPreferencesM>(_onLoadAlertPreferencesM);
  }

  // 📋 CHARGER LES ALERTES
  Future<void> _onLoadAlertsDataM(
    LoadAlertsDataM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      emit(const AlertPageLoadingM());

      final Map<String, dynamic> queryParams = {};
      if (event.type != null) queryParams['type'] = event.type!;
      if (event.statut != null) queryParams['statut'] = event.statut!;
      if (event.priorite != null) queryParams['priorite'] = event.priorite!;
      if (event.page != null) queryParams['page'] = event.page!.toString();
      if (event.limit != null) queryParams['limit'] = event.limit!.toString();
      if (event.sortBy != null) queryParams['sortBy'] = event.sortBy!;
      if (event.sortOrder != null) queryParams['sortOrder'] = event.sortOrder!;
      if (event.periode != null)
        queryParams['periode'] = event.periode!.toString();

      String url;
      if (event.userId != null && event.userId!.isNotEmpty) {
        final qs = <String, String>{
          'limit': (event.limit ?? 50).toString(),
          if (event.statut != null) 'statut': event.statut!,
        };
        url =
            '/notification/user/${event.userId}?${Uri(queryParameters: qs).query}';
      } else {
        url = '/notifications';
        if (queryParams.isNotEmpty) {
          final queryString = queryParams.entries
              .map((e) =>
                  '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
              .join('&');
          url += '?$queryString';
        }
      }
      final response =
          debugGet != null ? await debugGet!(url) : await _apiClient.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> raw = responseData is List
            ? responseData
            : (responseData['notifications'] as List? ?? const []);
        final List<Alert> alerts = raw
            .map((item) => Alert.fromJson(item as Map<String, dynamic>))
            .toList();

        emit(AlertPageLoadedM(
          alerts: alerts,
          pagination: responseData is Map
              ? responseData['pagination'] as Map<String, dynamic>?
              : null,
        ));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors du chargement des alertes',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔍 RECHERCHER DANS LES ALERTES
  Future<void> _onSearchAlertsM(
    SearchAlertsM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      emit(const AlertPageLoadingM());

      final Map<String, dynamic> queryParams = {
        'q': event.query,
      };
      if (event.type != null) queryParams['type'] = event.type!;
      if (event.priorite != null) queryParams['priorite'] = event.priorite!;
      if (event.periode != null)
        queryParams['periode'] = event.periode!.toString();

      // Construire l'URL avec les paramètres de requête
      String url = '/notifications/search';
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
        final List<Alert> searchResults =
            (responseData as List).map((item) => Alert.fromJson(item)).toList();

        emit(AlertsSearchedM(
          searchResults: searchResults,
          query: event.query,
        ));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors de la recherche',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // ➕ CRÉER UNE ALERTE
  Future<void> _onCreateAlertM(
    CreateAlertM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> body = {
        'titre': event.titre,
        'description': event.description,
        'type': event.type,
        'priorite': event.priorite,
        'envoiEmail': event.envoiEmail,
        'envoiPush': event.envoiPush,
        'envoiSMS': event.envoiSMS,
      };

      if (event.sousType != null) body['sousType'] = event.sousType!;
      if (event.referenceId != null) body['referenceId'] = event.referenceId!;
      if (event.referenceType != null)
        body['referenceType'] = event.referenceType!;
      if (event.donnees != null) body['donnees'] = event.donnees!;
      if (event.urlAction != null) body['urlAction'] = event.urlAction!;
      if (event.dateExpiration != null)
        body['dateExpiration'] = event.dateExpiration!.toIso8601String();

      final response = await _apiClient.post('/notification', body: body);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final Alert alert = Alert.fromJson(responseData);

        emit(AlertCreatedM(alert: alert));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors de la création de l\'alerte',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // ✏️ MODIFIER UNE ALERTE
  Future<void> _onUpdateAlertM(
    UpdateAlertM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> body = {};

      if (event.titre != null) body['titre'] = event.titre!;
      if (event.description != null) body['description'] = event.description!;
      if (event.type != null) body['type'] = event.type!;
      if (event.sousType != null) body['sousType'] = event.sousType!;
      if (event.priorite != null) body['priorite'] = event.priorite!;
      if (event.envoiEmail != null) body['envoiEmail'] = event.envoiEmail!;
      if (event.envoiPush != null) body['envoiPush'] = event.envoiPush!;
      if (event.envoiSMS != null) body['envoiSMS'] = event.envoiSMS!;
      if (event.donnees != null) body['donnees'] = event.donnees!;
      if (event.urlAction != null) body['urlAction'] = event.urlAction!;
      if (event.dateExpiration != null)
        body['dateExpiration'] = event.dateExpiration!.toIso8601String();

      final response =
          await _apiClient.put('/notification/${event.alertId}', body: body);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final Alert alert = Alert.fromJson(responseData);

        emit(AlertUpdatedM(alert: alert));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors de la modification de l\'alerte',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🗑️ SUPPRIMER UNE ALERTE
  Future<void> _onDeleteAlertM(
    DeleteAlertM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final response =
          await _apiClient.delete('/notification/${event.alertId}');

      if (response.statusCode == 200) {
        emit(AlertDeletedM(alertId: event.alertId));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors de la suppression de l\'alerte',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 👁️ MARQUER COMME LUE
  Future<void> _onMarkAsReadM(
    MarkAsReadM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final endpoint = '/notification/${event.alertId}/read';
      final response = debugPut != null
          ? await debugPut!(endpoint)
          : await _apiClient.put(endpoint);

      if (response.statusCode == 200) {
        emit(AlertMarkedAsReadM(alertId: event.alertId));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors du marquage comme lue',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 👁️ MARQUER TOUTES COMME LUES
  Future<void> _onMarkAllAsReadM(
    MarkAllAsReadM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final userId = event.userId;
      final endpoint = (userId != null && userId.isNotEmpty)
          ? '/notification/user/$userId/read-all'
          : '/notifications/user/read-all';
      final response = debugPut != null
          ? await debugPut!(endpoint)
          : await _apiClient.put(endpoint);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final int count = responseData['modifiedCount'] ?? 0;
        emit(AllAlertsMarkedAsReadM(count: count));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors du marquage de toutes les alertes',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 📁 ARCHIVER UNE ALERTE
  Future<void> _onArchiveAlertM(
    ArchiveAlertM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final endpoint = '/notification/${event.alertId}/archive';
      final response = debugPut != null
          ? await debugPut!(endpoint)
          : await _apiClient.put(endpoint);

      if (response.statusCode == 200) {
        emit(AlertArchivedM(alertId: event.alertId));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors de l\'archivage de l\'alerte',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 📁 ARCHIVER TOUTES LES ALERTES
  Future<void> _onArchiveAllAlertsM(
    ArchiveAllAlertsM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final response =
          await _apiClient.patch('/notifications/user/archive-all');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final int count = responseData['modifiedCount'] ?? 0;
        emit(AllAlertsArchivedM(count: count));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors de l\'archivage de toutes les alertes',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 📊 CHARGER LES STATISTIQUES
  Future<void> _onLoadAlertStatsM(
    LoadAlertStatsM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (event.periode != null)
        queryParams['periode'] = event.periode!.toString();

      // Construire l'URL avec les paramètres de requête
      String url = '/notifications/stats';
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

        emit(AlertStatsLoadedM(stats: responseData));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors du chargement des statistiques',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 📱 ALERTES NON LUES
  Future<void> _onLoadUnreadAlertsM(
    LoadUnreadAlertsM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> queryParams = {
        'statut': 'NON_LUE',
      };
      if (event.limit != null) queryParams['limit'] = event.limit!.toString();

      // Construire l'URL avec les paramètres de requête
      String url = '/notifications';
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
        final List<Alert> unreadAlerts = (responseData['notifications'] as List)
            .map((item) => Alert.fromJson(item))
            .toList();

        emit(UnreadAlertsLoadedM(unreadAlerts: unreadAlerts));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors du chargement des alertes non lues',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🏷️ ALERTES PAR TYPE
  Future<void> _onLoadAlertsByTypeM(
    LoadAlertsByTypeM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> queryParams = {
        'type': event.type,
      };
      if (event.limit != null) queryParams['limit'] = event.limit!.toString();

      // Construire l'URL avec les paramètres de requête
      String url = '/notifications';
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
        final List<Alert> alertsByType = (responseData['notifications'] as List)
            .map((item) => Alert.fromJson(item))
            .toList();

        emit(AlertsByTypeLoadedM(
          alertsByType: alertsByType,
          type: event.type,
        ));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors du chargement des alertes par type',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔔 ALERTES URGENTES
  Future<void> _onLoadUrgentAlertsM(
    LoadUrgentAlertsM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> queryParams = {
        'priorite': 'HAUTE,CRITIQUE',
      };
      if (event.limit != null) queryParams['limit'] = event.limit!.toString();

      // Construire l'URL avec les paramètres de requête
      String url = '/notifications';
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
        final List<Alert> urgentAlerts = (responseData['notifications'] as List)
            .map((item) => Alert.fromJson(item))
            .toList();

        emit(UrgentAlertsLoadedM(urgentAlerts: urgentAlerts));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors du chargement des alertes urgentes',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🧹 NETTOYER LES ALERTES ANCIENNES
  Future<void> _onCleanOldAlertsM(
    CleanOldAlertsM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (event.jours != null) queryParams['jours'] = event.jours!.toString();

      // Construire l'URL avec les paramètres de requête
      String url = '/notifications/clean';
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

        emit(AlertsCleanedM(deletedCount: deletedCount));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors du nettoyage des alertes',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔄 ACTUALISER LES ALERTES
  Future<void> _onRefreshAlertsM(
    RefreshAlertsM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    add(const LoadAlertsDataM());
  }

  // ⚙️ CONFIGURER LES PRÉFÉRENCES
  Future<void> _onUpdateAlertPreferencesM(
    UpdateAlertPreferencesM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> body = {
        'emailEnabled': event.emailEnabled,
        'pushEnabled': event.pushEnabled,
        'smsEnabled': event.smsEnabled,
        'typesEnabled': event.typesEnabled,
        'prioritesEnabled': event.prioritesEnabled,
      };

      final response =
          await _apiClient.put('/notifications/preferences', body: body);

      if (response.statusCode == 200) {
        emit(AlertPreferencesUpdatedM(
          emailEnabled: event.emailEnabled,
          pushEnabled: event.pushEnabled,
          smsEnabled: event.smsEnabled,
          typesEnabled: event.typesEnabled,
          prioritesEnabled: event.prioritesEnabled,
        ));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors de la mise à jour des préférences',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 📋 CHARGER LES PRÉFÉRENCES
  Future<void> _onLoadAlertPreferencesM(
    LoadAlertPreferencesM event,
    Emitter<AlertPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.get('/notifications/preferences');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        emit(AlertPreferencesLoadedM(
          emailEnabled: responseData['emailEnabled'] ?? true,
          pushEnabled: responseData['pushEnabled'] ?? true,
          smsEnabled: responseData['smsEnabled'] ?? false,
          typesEnabled: List<String>.from(responseData['typesEnabled'] ?? []),
          prioritesEnabled:
              List<String>.from(responseData['prioritesEnabled'] ?? []),
        ));
      } else {
        emit(AlertPageErrorM(
          message: 'Erreur lors du chargement des préférences',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(AlertPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }
}
