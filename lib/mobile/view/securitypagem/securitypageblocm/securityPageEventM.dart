abstract class SecurityPageEventM {}

// 🔐 ÉVÉNEMENTS POUR LA SÉCURITÉ GÉNÉRALE
class LoadSecurityDataEventM extends SecurityPageEventM {}

class RefreshSecurityDataEventM extends SecurityPageEventM {}

// 🔑 ÉVÉNEMENTS POUR L'AUTHENTIFICATION À DEUX FACTEURS
class EnableTwoFactorEventM extends SecurityPageEventM {}

class DisableTwoFactorEventM extends SecurityPageEventM {
  final String currentPassword;

  DisableTwoFactorEventM({required this.currentPassword});
}

class VerifyTwoFactorCodeEventM extends SecurityPageEventM {
  final String code;

  VerifyTwoFactorCodeEventM({required this.code});
}

class GenerateTwoFactorQREventM extends SecurityPageEventM {}

// 📱 ÉVÉNEMENTS POUR LES SESSIONS
class LoadSessionsEventM extends SecurityPageEventM {}

class TerminateSessionEventM extends SecurityPageEventM {
  final String sessionId;

  TerminateSessionEventM({required this.sessionId});
}

class TerminateAllOtherSessionsEventM extends SecurityPageEventM {
  final String? keepSessionId;

  TerminateAllOtherSessionsEventM({this.keepSessionId});
}

// 🚨 ÉVÉNEMENTS POUR LES ALERTES DE SÉCURITÉ
class LoadSecurityAlertsEventM extends SecurityPageEventM {}

class MarkAlertAsReadEventM extends SecurityPageEventM {
  final String alertId;

  MarkAlertAsReadEventM({required this.alertId});
}

class MarkAllAlertsAsReadEventM extends SecurityPageEventM {}

class DeleteAlertEventM extends SecurityPageEventM {
  final String alertId;

  DeleteAlertEventM({required this.alertId});
}

// 🛡️ ÉVÉNEMENTS POUR LES APPAREILS DE CONFIANCE
class LoadTrustedDevicesEventM extends SecurityPageEventM {}

class AddTrustedDeviceEventM extends SecurityPageEventM {
  final String deviceName;
  final String deviceType;

  AddTrustedDeviceEventM({
    required this.deviceName,
    required this.deviceType,
  });
}

class RemoveTrustedDeviceEventM extends SecurityPageEventM {
  final String deviceId;

  RemoveTrustedDeviceEventM({required this.deviceId});
}

// ⚙️ ÉVÉNEMENTS POUR LES PARAMÈTRES DE SÉCURITÉ
class LoadSecuritySettingsEventM extends SecurityPageEventM {}

class UpdateSecuritySettingsEventM extends SecurityPageEventM {
  final Map<String, dynamic> settings;

  UpdateSecuritySettingsEventM({required this.settings});
}

// 🔒 ÉVÉNEMENTS POUR LE CHANGEMENT DE MOT DE PASSE
class ChangePasswordEventM extends SecurityPageEventM {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  ChangePasswordEventM({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
}

// 📊 ÉVÉNEMENTS POUR L'HISTORIQUE DE CONNEXION
class LoadLoginHistoryEventM extends SecurityPageEventM {}

class ClearLoginHistoryEventM extends SecurityPageEventM {}

class ExportSecurityDataEventM extends SecurityPageEventM {}

// 🔍 ÉVÉNEMENTS POUR LA RECHERCHE ET FILTRAGE
class SearchSecurityAlertsEventM extends SecurityPageEventM {
  final String query;

  SearchSecurityAlertsEventM({required this.query});
}

class FilterSecurityAlertsEventM extends SecurityPageEventM {
  final String severity;

  FilterSecurityAlertsEventM({required this.severity});
}

class SortSecurityAlertsEventM extends SecurityPageEventM {
  final String sortBy;
  final bool ascending;

  SortSecurityAlertsEventM({
    required this.sortBy,
    this.ascending = true,
  });
}

