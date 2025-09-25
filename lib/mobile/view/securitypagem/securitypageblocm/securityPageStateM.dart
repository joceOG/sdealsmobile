import '../../../../data/models/security.dart';

abstract class SecurityPageStateM {}

// 🔄 ÉTATS DE CHARGEMENT
class SecurityPageInitialStateM extends SecurityPageStateM {}

class SecurityPageLoadingStateM extends SecurityPageStateM {}

class SecurityPageRefreshingStateM extends SecurityPageStateM {}

// ✅ ÉTATS DE SUCCÈS
class SecurityPageLoadedStateM extends SecurityPageStateM {
  final Security security;
  final List<SecurityAlert> alerts;
  final List<SecuritySession> sessions;
  final List<TrustedDevice> trustedDevices;
  final SecuritySettings settings;
  final bool twoFactorEnabled;
  final String? twoFactorQRCode;

  SecurityPageLoadedStateM({
    required this.security,
    required this.alerts,
    required this.sessions,
    required this.trustedDevices,
    required this.settings,
    required this.twoFactorEnabled,
    this.twoFactorQRCode,
  });
}

class SecurityPageSuccessStateM extends SecurityPageStateM {
  final String message;

  SecurityPageSuccessStateM({required this.message});
}

// ❌ ÉTATS D'ERREUR
class SecurityPageErrorStateM extends SecurityPageStateM {
  final String message;

  SecurityPageErrorStateM({required this.message});
}

// 🔐 ÉTATS SPÉCIFIQUES POUR L'AUTHENTIFICATION À DEUX FACTEURS
class TwoFactorEnabledStateM extends SecurityPageStateM {
  final String qrCode;
  final String secret;

  TwoFactorEnabledStateM({
    required this.qrCode,
    required this.secret,
  });
}

class TwoFactorDisabledStateM extends SecurityPageStateM {
  final String message;

  TwoFactorDisabledStateM({required this.message});
}

class TwoFactorVerificationStateM extends SecurityPageStateM {
  final bool isValid;
  final String message;

  TwoFactorVerificationStateM({
    required this.isValid,
    required this.message,
  });
}

// 📱 ÉTATS POUR LES SESSIONS
class SessionsLoadedStateM extends SecurityPageStateM {
  final List<SecuritySession> sessions;

  SessionsLoadedStateM({required this.sessions});
}

class SessionTerminatedStateM extends SecurityPageStateM {
  final String message;

  SessionTerminatedStateM({required this.message});
}

// 🚨 ÉTATS POUR LES ALERTES
class SecurityAlertsLoadedStateM extends SecurityPageStateM {
  final List<SecurityAlert> alerts;
  final int unreadCount;

  SecurityAlertsLoadedStateM({
    required this.alerts,
    required this.unreadCount,
  });
}

class AlertMarkedAsReadStateM extends SecurityPageStateM {
  final String alertId;
  final String message;

  AlertMarkedAsReadStateM({
    required this.alertId,
    required this.message,
  });
}

class AlertDeletedStateM extends SecurityPageStateM {
  final String alertId;
  final String message;

  AlertDeletedStateM({
    required this.alertId,
    required this.message,
  });
}

// 🛡️ ÉTATS POUR LES APPAREILS DE CONFIANCE
class TrustedDevicesLoadedStateM extends SecurityPageStateM {
  final List<TrustedDevice> devices;

  TrustedDevicesLoadedStateM({required this.devices});
}

class TrustedDeviceAddedStateM extends SecurityPageStateM {
  final TrustedDevice device;
  final String message;

  TrustedDeviceAddedStateM({
    required this.device,
    required this.message,
  });
}

class TrustedDeviceRemovedStateM extends SecurityPageStateM {
  final String deviceId;
  final String message;

  TrustedDeviceRemovedStateM({
    required this.deviceId,
    required this.message,
  });
}

// ⚙️ ÉTATS POUR LES PARAMÈTRES
class SecuritySettingsLoadedStateM extends SecurityPageStateM {
  final SecuritySettings settings;

  SecuritySettingsLoadedStateM({required this.settings});
}

class SecuritySettingsUpdatedStateM extends SecurityPageStateM {
  final SecuritySettings settings;
  final String message;

  SecuritySettingsUpdatedStateM({
    required this.settings,
    required this.message,
  });
}

// 🔒 ÉTATS POUR LE CHANGEMENT DE MOT DE PASSE
class PasswordChangedStateM extends SecurityPageStateM {
  final String message;

  PasswordChangedStateM({required this.message});
}

// 📊 ÉTATS POUR L'HISTORIQUE
class LoginHistoryLoadedStateM extends SecurityPageStateM {
  final List<SecuritySession> loginHistory;

  LoginHistoryLoadedStateM({required this.loginHistory});
}

class LoginHistoryClearedStateM extends SecurityPageStateM {
  final String message;

  LoginHistoryClearedStateM({required this.message});
}

// 🔍 ÉTATS POUR LA RECHERCHE
class SecurityAlertsFilteredStateM extends SecurityPageStateM {
  final List<SecurityAlert> filteredAlerts;
  final String filter;

  SecurityAlertsFilteredStateM({
    required this.filteredAlerts,
    required this.filter,
  });
}

class SecurityAlertsSortedStateM extends SecurityPageStateM {
  final List<SecurityAlert> sortedAlerts;
  final String sortBy;
  final bool ascending;

  SecurityAlertsSortedStateM({
    required this.sortedAlerts,
    required this.sortBy,
    required this.ascending,
  });
}

