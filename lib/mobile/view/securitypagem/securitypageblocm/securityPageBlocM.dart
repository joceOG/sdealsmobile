import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/models/security.dart';
import 'securityPageEventM.dart';
import 'securityPageStateM.dart';

/// Aligné sur `backend/routes/securityRoutes.js` :
/// `/security/user/:utilisateurId/...` + Bearer token.
class SecurityPageBlocM extends Bloc<SecurityPageEventM, SecurityPageStateM> {
  final ApiClient _apiClient;
  String? _token;
  String? _userId;

  SecurityPageBlocM({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(SecurityPageInitialStateM()) {
    on<LoadSecurityDataEventM>(_onLoadSecurityData);
    on<RefreshSecurityDataEventM>(_onRefreshSecurityData);
    on<EnableTwoFactorEventM>(_onEnableTwoFactor);
    on<DisableTwoFactorEventM>(_onDisableTwoFactor);
    on<VerifyTwoFactorCodeEventM>(_onVerifyTwoFactorCode);
    on<GenerateTwoFactorQREventM>(_onGenerateTwoFactorQR);
    on<LoadSessionsEventM>(_onLoadSessions);
    on<TerminateSessionEventM>(_onTerminateSession);
    on<TerminateAllOtherSessionsEventM>(_onTerminateAllOtherSessions);
    on<LoadSecurityAlertsEventM>(_onLoadSecurityAlerts);
    on<MarkAlertAsReadEventM>(_onMarkAlertAsRead);
    on<MarkAllAlertsAsReadEventM>(_onMarkAllAlertsAsRead);
    on<DeleteAlertEventM>(_onDeleteAlert);
    on<LoadTrustedDevicesEventM>(_onLoadTrustedDevices);
    on<AddTrustedDeviceEventM>(_onAddTrustedDevice);
    on<RemoveTrustedDeviceEventM>(_onRemoveTrustedDevice);
    on<LoadSecuritySettingsEventM>(_onLoadSecuritySettings);
    on<UpdateSecuritySettingsEventM>(_onUpdateSecuritySettings);
    on<ChangePasswordEventM>(_onChangePassword);
    on<LoadLoginHistoryEventM>(_onLoadLoginHistory);
    on<ClearLoginHistoryEventM>(_onClearLoginHistory);
    on<SearchSecurityAlertsEventM>(_onSearchSecurityAlerts);
    on<FilterSecurityAlertsEventM>(_onFilterSecurityAlerts);
    on<SortSecurityAlertsEventM>(_onSortSecurityAlerts);
  }

  void setAuth({required String token, required String userId}) {
    _token = token;
    _userId = userId;
  }

  String get _base {
    final id = _userId;
    if (id == null || id.isEmpty) {
      throw StateError('Utilisateur non authentifié');
    }
    return '/security/user/$id';
  }

  bool get _hasAuth =>
      _token != null &&
      _token!.isNotEmpty &&
      _userId != null &&
      _userId!.isNotEmpty;

  Future<void> _onLoadSecurityData(
    LoadSecurityDataEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (!_hasAuth) {
        emit(SecurityPageErrorStateM(
            message: 'Session requise pour accéder à la sécurité'));
        return;
      }
      emit(SecurityPageLoadingStateM());

      final response =
          await _apiClient.get(_base, token: _token);

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response) as Map<String, dynamic>;
        final security = Security.fromBackend(data);

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
          message: 'Erreur lors du chargement (${response.statusCode})',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRefreshSecurityData(
    RefreshSecurityDataEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    add(LoadSecurityDataEventM());
  }

  Future<void> _onEnableTwoFactor(
    EnableTwoFactorEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (!_hasAuth) {
        emit(SecurityPageErrorStateM(message: 'Session requise'));
        return;
      }
      final response = await _apiClient.post(
        '$_base/2fa/enable',
        token: _token,
      );

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response) as Map<String, dynamic>;
        emit(TwoFactorEnabledStateM(
          qrCode: data['qrCode']?.toString() ?? '',
          secret: data['secret']?.toString() ?? '',
        ));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur activation 2FA (${response.statusCode})',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDisableTwoFactor(
    DisableTwoFactorEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (!_hasAuth) {
        emit(SecurityPageErrorStateM(message: 'Session requise'));
        return;
      }
      final response = await _apiClient.post(
        '$_base/2fa/disable',
        body: {'password': event.currentPassword},
        token: _token,
      );

      if (response.statusCode == 200) {
        emit(TwoFactorDisabledStateM(
          message: 'Authentification à deux facteurs désactivée',
        ));
        add(LoadSecurityDataEventM());
      } else {
        String message = 'Erreur désactivation 2FA';
        try {
          final data = ApiClient.decodeJson(response);
          if (data is Map && data['error'] != null) {
            message = data['error'].toString();
          }
        } catch (_) {}
        emit(SecurityPageErrorStateM(message: message));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  Future<void> _onVerifyTwoFactorCode(
    VerifyTwoFactorCodeEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (!_hasAuth) {
        emit(SecurityPageErrorStateM(message: 'Session requise'));
        return;
      }
      // Backend attend `token` (code TOTP), pas `code`
      final response = await _apiClient.post(
        '$_base/2fa/verify',
        body: {'token': event.code},
        token: _token,
      );

      if (response.statusCode == 200) {
        emit(TwoFactorVerificationStateM(
          isValid: true,
          message: 'Code vérifié avec succès',
        ));
        add(LoadSecurityDataEventM());
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

  Future<void> _onGenerateTwoFactorQR(
    GenerateTwoFactorQREventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    // Pas d'endpoint QR séparé : réutiliser enable
    add(EnableTwoFactorEventM());
  }

  Future<void> _onLoadSessions(
    LoadSessionsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (!_hasAuth) return;
      final response =
          await _apiClient.get('$_base/sessions', token: _token);

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response) as Map<String, dynamic>;
        final list = (data['activeSessions'] ?? data['sessions'] ?? []) as List;
        final sessions = list
            .map((s) => SecuritySession.fromJson(
                Map<String, dynamic>.from(s as Map)))
            .toList();
        emit(SessionsLoadedStateM(sessions: sessions));
      } else {
        emit(SecurityPageErrorStateM(
          message: 'Erreur chargement sessions (${response.statusCode})',
        ));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  Future<void> _onTerminateSession(
    TerminateSessionEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (!_hasAuth) return;
      final response = await _apiClient.delete(
        '$_base/sessions/${event.sessionId}',
        token: _token,
      );

      if (response.statusCode == 200) {
        emit(SessionTerminatedStateM(message: 'Session terminée'));
        add(LoadSessionsEventM());
      } else {
        emit(SecurityPageErrorStateM(message: 'Erreur terminaison session'));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  Future<void> _onTerminateAllOtherSessions(
    TerminateAllOtherSessionsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    emit(SecurityPageErrorStateM(
      message: 'Terminaison groupée non disponible sur le serveur',
    ));
  }

  Future<void> _onLoadSecurityAlerts(
    LoadSecurityAlertsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (!_hasAuth) return;
      final response =
          await _apiClient.get('$_base/alerts', token: _token);

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response) as Map<String, dynamic>;
        final list =
            (data['alerts'] ?? data['securityAlerts'] ?? []) as List;
        final alerts = list
            .map((a) =>
                SecurityAlert.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
        emit(SecurityAlertsLoadedStateM(
          alerts: alerts,
          unreadCount: data['unreadCount'] ?? 0,
        ));
      } else {
        emit(SecurityPageErrorStateM(message: 'Erreur chargement alertes'));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  Future<void> _onMarkAlertAsRead(
    MarkAlertAsReadEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (!_hasAuth) return;
      final response = await _apiClient.patch(
        '$_base/alerts/${event.alertId}/read',
        token: _token,
      );

      if (response.statusCode == 200) {
        emit(AlertMarkedAsReadStateM(
          alertId: event.alertId,
          message: 'Alerte marquée comme lue',
        ));
      } else {
        emit(SecurityPageErrorStateM(message: 'Erreur marquage alerte'));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  Future<void> _onMarkAllAlertsAsRead(
    MarkAllAlertsAsReadEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    emit(SecurityPageErrorStateM(
      message: 'Marquage global des alertes non disponible sur le serveur',
    ));
  }

  Future<void> _onDeleteAlert(
    DeleteAlertEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    emit(SecurityPageErrorStateM(
      message: 'Suppression d\'alerte non disponible sur le serveur',
    ));
  }

  Future<void> _onLoadTrustedDevices(
    LoadTrustedDevicesEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (!_hasAuth) return;
      final response =
          await _apiClient.get('$_base/devices', token: _token);

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response) as Map<String, dynamic>;
        final list =
            (data['devices'] ?? data['trustedDevices'] ?? []) as List;
        final devices = list
            .map((d) =>
                TrustedDevice.fromJson(Map<String, dynamic>.from(d as Map)))
            .toList();
        emit(TrustedDevicesLoadedStateM(devices: devices));
      } else {
        emit(SecurityPageErrorStateM(message: 'Erreur chargement appareils'));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  Future<void> _onAddTrustedDevice(
    AddTrustedDeviceEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    emit(SecurityPageErrorStateM(
      message: 'Ajout d\'appareil de confiance non disponible sur le serveur',
    ));
  }

  Future<void> _onRemoveTrustedDevice(
    RemoveTrustedDeviceEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (!_hasAuth) return;
      final response = await _apiClient.delete(
        '$_base/devices/${event.deviceId}',
        token: _token,
      );

      if (response.statusCode == 200) {
        emit(TrustedDeviceRemovedStateM(
          deviceId: event.deviceId,
          message: 'Appareil retiré',
        ));
        add(LoadTrustedDevicesEventM());
      } else {
        emit(SecurityPageErrorStateM(message: 'Erreur suppression appareil'));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadSecuritySettings(
    LoadSecuritySettingsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    // Pas de GET settings dédié : recharger le doc sécurité
    add(LoadSecurityDataEventM());
  }

  Future<void> _onUpdateSecuritySettings(
    UpdateSecuritySettingsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (!_hasAuth) return;
      final response = await _apiClient.put(
        '$_base/settings',
        body: {'securitySettings': event.settings},
        token: _token,
      );

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response) as Map<String, dynamic>;
        final settingsMap = data['security']?['securitySettings'] ??
            data['securitySettings'] ??
            event.settings;
        final settings = SecuritySettings.fromJson(
          settingsMap is Map
              ? Map<String, dynamic>.from(settingsMap)
              : <String, dynamic>{},
        );
        emit(SecuritySettingsUpdatedStateM(
          settings: settings,
          message: 'Paramètres mis à jour',
        ));
      } else {
        emit(SecurityPageErrorStateM(message: 'Erreur mise à jour paramètres'));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

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
      if (event.newPassword.length < 6) {
        emit(SecurityPageErrorStateM(
          message: 'Le nouveau mot de passe doit contenir au moins 6 caractères',
        ));
        return;
      }
      if (!_hasAuth) {
        emit(SecurityPageErrorStateM(message: 'Session requise'));
        return;
      }

      final response = await _apiClient.patch(
        '/utilisateur/password',
        body: {
          'currentPassword': event.currentPassword,
          'newPassword': event.newPassword,
        },
        token: _token,
      );

      if (response.statusCode == 200) {
        emit(PasswordChangedStateM(
          message: 'Mot de passe changé avec succès',
        ));
      } else {
        String message = 'Erreur changement mot de passe';
        try {
          final data = ApiClient.decodeJson(response);
          if (data is Map && data['error'] != null) {
            message = data['error'].toString();
          }
        } catch (_) {}
        emit(SecurityPageErrorStateM(message: message));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadLoginHistory(
    LoadLoginHistoryEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    try {
      if (!_hasAuth) return;
      final response =
          await _apiClient.get('$_base/history', token: _token);

      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response) as Map<String, dynamic>;
        final list =
            (data['history'] ?? data['loginHistory'] ?? []) as List;
        final loginHistory = list
            .map((s) => SecuritySession.fromJson(
                Map<String, dynamic>.from(s as Map)))
            .toList();
        emit(LoginHistoryLoadedStateM(loginHistory: loginHistory));
      } else {
        emit(SecurityPageErrorStateM(message: 'Erreur chargement historique'));
      }
    } catch (e) {
      emit(SecurityPageErrorStateM(
        message: 'Erreur de connexion: ${e.toString()}',
      ));
    }
  }

  Future<void> _onClearLoginHistory(
    ClearLoginHistoryEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    emit(SecurityPageErrorStateM(
      message: 'Effacement de l\'historique non disponible sur le serveur',
    ));
  }

  Future<void> _onSearchSecurityAlerts(
    SearchSecurityAlertsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    emit(SecurityPageErrorStateM(
      message: 'Recherche d\'alertes non disponible sur le serveur',
    ));
  }

  Future<void> _onFilterSecurityAlerts(
    FilterSecurityAlertsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    emit(SecurityPageErrorStateM(
      message: 'Filtrage d\'alertes non disponible sur le serveur',
    ));
  }

  Future<void> _onSortSecurityAlerts(
    SortSecurityAlertsEventM event,
    Emitter<SecurityPageStateM> emit,
  ) async {
    emit(SecurityPageErrorStateM(
      message: 'Tri d\'alertes non disponible sur le serveur',
    ));
  }
}
