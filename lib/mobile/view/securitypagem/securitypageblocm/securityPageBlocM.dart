import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/models/security.dart';
import 'securityPageEventM.dart';
import 'securityPageStateM.dart';

class SecurityPageBlocM extends Bloc<SecurityPageEventM, SecurityPageStateM> {
  final ApiClient _apiClient;

  SecurityPageBlocM({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(SecurityPageInitialStateM()) {
    // 🔐 ÉVÉNEMENTS GÉNÉRAUX
    on<LoadSecurityDataEventM>(_onLoadSecurityData);
    on<RefreshSecurityDataEventM>(_onRefreshSecurityData);

    // 🔑 AUTHENTIFICATION À DEUX FACTEURS
    on<EnableTwoFactorEventM>(_onEnableTwoFactor);
    on<DisableTwoFactorEventM>(_onDisableTwoFactor);
    on<VerifyTwoFactorCodeEventM>(_onVerifyTwoFactorCode);
    on<GenerateTwoFactorQREventM>(_onGenerateTwoFactorQR);

    // 📱 SESSIONS
    on<LoadSessionsEventM>(_onLoadSessions);
    on<TerminateSessionEventM>(_onTerminateSession);
    on<TerminateAllOtherSessionsEventM>(_onTerminateAllOtherSessions);

    // 🚨 ALERTES DE SÉCURITÉ
    on<LoadSecurityAlertsEventM>(_onLoadSecurityAlerts);
    on<MarkAlertAsReadEventM>(_onMarkAlertAsRead);
    on<MarkAllAlertsAsReadEventM>(_onMarkAllAlertsAsRead);
    on<DeleteAlertEventM>(_onDeleteAlert);

    // 🛡️ APPAREILS DE CONFIANCE
    on<LoadTrustedDevicesEventM>(_onLoadTrustedDevices);
    on<AddTrustedDeviceEventM>(_onAddTrustedDevice);
    on<RemoveTrustedDeviceEventM>(_onRemoveTrustedDevice);

    // ⚙️ PARAMÈTRES DE SÉCURITÉ
    on<LoadSecuritySettingsEventM>(_onLoadSecuritySettings);
    on<UpdateSecuritySettingsEventM>(_onUpdateSecuritySettings);

    // 🔒 CHANGEMENT DE MOT DE PASSE
    on<ChangePasswordEventM>(_onChangePassword);

    // 📊 HISTORIQUE DE CONNEXION
    on<LoadLoginHistoryEventM>(_onLoadLoginHistory);
    on<ClearLoginHistoryEventM>(_onClearLoginHistory);

    // 🔍 RECHERCHE ET FILTRAGE
    on<SearchSecurityAlertsEventM>(_onSearchSecurityAlerts);
    on<FilterSecurityAlertsEventM>(_onFilterSecurityAlerts);
    on<SortSecurityAlertsEventM>(_onSortSecurityAlerts);
  }

  // 🔐 CHARGEMENT DES DONNÉES DE SÉCURITÉ
  Future<void> _onLoadSecurityData(
    LoadSecurityDataEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      emit(SecurityPageLoadingStateM());

      final response = await _apiClient.get('/security');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final security = Security.fromJson(data);

        emit(SecurityPageLoadedStateM(
          security: security,
          alerts: security.alerts,
          sessions: security.sessions,
          trustedDevices: security.trustedDevices,
          settings: security.settings,
          twoFactorEnabled: security.twoFactorEnabled,
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors du chargement des données de sécurité',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🔄 ACTUALISATION DES DONNÉES
  Future<void> _onRefreshSecurityData(
    RefreshSecurityDataEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      emit(SecurityPageRefreshingStateM());

      final response = await _apiClient.get('/security');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final security = Security.fromJson(data);

        emit(SecurityPageLoadedStateM(
          security: security,
          alerts: security.alerts,
          sessions: security.sessions,
          trustedDevices: security.trustedDevices,
          settings: security.settings,
          twoFactorEnabled: security.twoFactorEnabled,
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur lors de l\'actualisation: ${e.toString()}',
      ));
    }
  }

  // 🔑 ACTIVATION DE L'AUTHENTIFICATION À DEUX FACTEURS
  Future<void> _onEnableTwoFactor(
    EnableTwoFactorEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.post('/security/two-factor/enable');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        emit(TwoFactorEnabledStateM(
          qrCode: data['qrCode'],
          secret: data['secret'],
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message:
              'Erreur lors de l\'activation de l\'authentification à deux facteurs',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🔑 DÉSACTIVATION DE L'AUTHENTIFICATION À DEUX FACTEURS
  Future<void> _onDisableTwoFactor(
    DisableTwoFactorEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final body = {
        'currentPassword': event.currentPassword,
      };

      final response =
          await _apiClient.post('/security/two-factor/disable', body: body);

      if (response.statusCode == 200) {
        emit(TwoFactorDisabledStateM(
          message: 'Authentification à deux facteurs désactivée avec succès',
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message:
              'Erreur lors de la désactivation de l\'authentification à deux facteurs',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🔑 VÉRIFICATION DU CODE À DEUX FACTEURS
  Future<void> _onVerifyTwoFactorCode(
    VerifyTwoFactorCodeEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final body = {
        'code': event.code,
      };

      final response =
          await _apiClient.post('/security/two-factor/verify', body: body);

      if (response.statusCode == 200) {
        emit(TwoFactorVerificationStateM(
          isValid: true,
          message: 'Code vérifié avec succès',
        ));
      } else {
        emit(TwoFactorVerificationStateM(
          isValid: false,
          message: 'Code invalide',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🔑 GÉNÉRATION DU QR CODE
  Future<void> _onGenerateTwoFactorQR(
    GenerateTwoFactorQREventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.get('/security/two-factor/qr');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        emit(TwoFactorEnabledStateM(
          qrCode: data['qrCode'],
          secret: data['secret'],
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors de la génération du QR code',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 📱 CHARGEMENT DES SESSIONS
  Future<void> _onLoadSessions(
    LoadSessionsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.get('/security/sessions');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = (data['sessions'] as List<dynamic>)
            .map((session) => SecuritySession.fromJson(session))
            .toList();

        emit(SessionsLoadedStateM(sessions: sessions));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors du chargement des sessions',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 📱 TERMINAISON D'UNE SESSION
  Future<void> _onTerminateSession(
    TerminateSessionEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response =
          await _apiClient.delete('/security/sessions/${event.sessionId}');

      if (response.statusCode == 200) {
        emit(SessionTerminatedStateM(
          message: 'Session terminée avec succès',
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors de la terminaison de la session',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 📱 TERMINAISON DE TOUTES LES AUTRES SESSIONS
  Future<void> _onTerminateAllOtherSessions(
    TerminateAllOtherSessionsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.delete('/security/sessions/others');

      if (response.statusCode == 200) {
        emit(SessionTerminatedStateM(
          message: 'Toutes les autres sessions ont été terminées',
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors de la terminaison des sessions',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🚨 CHARGEMENT DES ALERTES DE SÉCURITÉ
  Future<void> _onLoadSecurityAlerts(
    LoadSecurityAlertsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.get('/security/alerts');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final alerts = (data['alerts'] as List<dynamic>)
            .map((alert) => SecurityAlert.fromJson(alert))
            .toList();
        final unreadCount = data['unreadCount'] ?? 0;

        emit(SecurityAlertsLoadedStateM(
          alerts: alerts,
          unreadCount: unreadCount,
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors du chargement des alertes',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🚨 MARQUER UNE ALERTE COMME LUE
  Future<void> _onMarkAlertAsRead(
    MarkAlertAsReadEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response =
          await _apiClient.put('/security/alerts/${event.alertId}/read');

      if (response.statusCode == 200) {
        emit(AlertMarkedAsReadStateM(
          alertId: event.alertId,
          message: 'Alerte marquée comme lue',
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors du marquage de l\'alerte',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🚨 MARQUER TOUTES LES ALERTES COMME LUES
  Future<void> _onMarkAllAlertsAsRead(
    MarkAllAlertsAsReadEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.put('/security/alerts/read-all');

      if (response.statusCode == 200) {
        emit(SecurityPageSuccessStateM(
          message: 'Toutes les alertes ont été marquées comme lues',
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors du marquage des alertes',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🚨 SUPPRESSION D'UNE ALERTE
  Future<void> _onDeleteAlert(
    DeleteAlertEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response =
          await _apiClient.delete('/security/alerts/${event.alertId}');

      if (response.statusCode == 200) {
        emit(AlertDeletedStateM(
          alertId: event.alertId,
          message: 'Alerte supprimée avec succès',
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors de la suppression de l\'alerte',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🛡️ CHARGEMENT DES APPAREILS DE CONFIANCE
  Future<void> _onLoadTrustedDevices(
    LoadTrustedDevicesEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.get('/security/trusted-devices');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final devices = (data['devices'] as List<dynamic>)
            .map((device) => TrustedDevice.fromJson(device))
            .toList();

        emit(TrustedDevicesLoadedStateM(devices: devices));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors du chargement des appareils de confiance',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🛡️ AJOUT D'UN APPAREIL DE CONFIANCE
  Future<void> _onAddTrustedDevice(
    AddTrustedDeviceEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final body = {
        'deviceName': event.deviceName,
        'deviceType': event.deviceType,
      };

      final response =
          await _apiClient.post('/security/trusted-devices', body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final device = TrustedDevice.fromJson(data['device']);

        emit(TrustedDeviceAddedStateM(
          device: device,
          message: 'Appareil de confiance ajouté avec succès',
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors de l\'ajout de l\'appareil de confiance',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🛡️ SUPPRESSION D'UN APPAREIL DE CONFIANCE
  Future<void> _onRemoveTrustedDevice(
    RemoveTrustedDeviceEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient
          .delete('/security/trusted-devices/${event.deviceId}');

      if (response.statusCode == 200) {
        emit(TrustedDeviceRemovedStateM(
          deviceId: event.deviceId,
          message: 'Appareil de confiance supprimé avec succès',
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors de la suppression de l\'appareil de confiance',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // ⚙️ CHARGEMENT DES PARAMÈTRES DE SÉCURITÉ
  Future<void> _onLoadSecuritySettings(
    LoadSecuritySettingsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.get('/security/settings');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final settings = SecuritySettings.fromJson(data);

        emit(SecuritySettingsLoadedStateM(settings: settings));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors du chargement des paramètres',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // ⚙️ MISE À JOUR DES PARAMÈTRES DE SÉCURITÉ
  Future<void> _onUpdateSecuritySettings(
    UpdateSecuritySettingsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response =
          await _apiClient.put('/security/settings', body: event.settings);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final settings = SecuritySettings.fromJson(data);

        emit(SecuritySettingsUpdatedStateM(
          settings: settings,
          message: 'Paramètres mis à jour avec succès',
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors de la mise à jour des paramètres',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🔒 CHANGEMENT DE MOT DE PASSE
  Future<void> _onChangePassword(
    ChangePasswordEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (event.newPassword != event.confirmPassword) {
        emit(SecurityPageErrorStateM(
          message: 'Les mots de passe ne correspondent pas',
        ));
        return;
      }

      final body = {
        'currentPassword': event.currentPassword,
        'newPassword': event.newPassword,
      };

      final response =
          await _apiClient.put('/security/change-password', body: body);

      if (response.statusCode == 200) {
        emit(PasswordChangedStateM(
          message: 'Mot de passe changé avec succès',
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors du changement de mot de passe',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 📊 CHARGEMENT DE L'HISTORIQUE DE CONNEXION
  Future<void> _onLoadLoginHistory(
    LoadLoginHistoryEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.get('/security/login-history');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginHistory = (data['history'] as List<dynamic>)
            .map((session) => SecuritySession.fromJson(session))
            .toList();

        emit(LoginHistoryLoadedStateM(loginHistory: loginHistory));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors du chargement de l\'historique',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 📊 SUPPRESSION DE L'HISTORIQUE DE CONNEXION
  Future<void> _onClearLoginHistory(
    ClearLoginHistoryEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.delete('/security/login-history');

      if (response.statusCode == 200) {
        emit(LoginHistoryClearedStateM(
          message: 'Historique de connexion supprimé avec succès',
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors de la suppression de l\'historique',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🔍 RECHERCHE D'ALERTES
  Future<void> _onSearchSecurityAlerts(
    SearchSecurityAlertsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final url =
          '/security/alerts/search?query=${Uri.encodeComponent(event.query)}';
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final filteredAlerts = (data['alerts'] as List<dynamic>)
            .map((alert) => SecurityAlert.fromJson(alert))
            .toList();

        emit(SecurityAlertsFilteredStateM(
          filteredAlerts: filteredAlerts,
          filter: event.query,
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors de la recherche d\'alertes',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🔍 FILTRAGE D'ALERTES
  Future<void> _onFilterSecurityAlerts(
    FilterSecurityAlertsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final url =
          '/security/alerts/filter?severity=${Uri.encodeComponent(event.severity)}';
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final filteredAlerts = (data['alerts'] as List<dynamic>)
            .map((alert) => SecurityAlert.fromJson(alert))
            .toList();

        emit(SecurityAlertsFilteredStateM(
          filteredAlerts: filteredAlerts,
          filter: event.severity,
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors du filtrage des alertes',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  // 🔍 TRI D'ALERTES
  Future<void> _onSortSecurityAlerts(
    SortSecurityAlertsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      final url =
          '/security/alerts/sort?sortBy=${Uri.encodeComponent(event.sortBy)}&ascending=${event.ascending}';
      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sortedAlerts = (data['alerts'] as List<dynamic>)
            .map((alert) => SecurityAlert.fromJson(alert))
            .toList();

        emit(SecurityAlertsSortedStateM(
          sortedAlerts: sortedAlerts,
          sortBy: event.sortBy,
          ascending: event.ascending,
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur lors du tri des alertes',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }
}

