import 'package:equatable/equatable.dart';
import '../../../../data/models/alert.dart';

abstract class AlertPageStateM extends Equatable {
  const AlertPageStateM();

  @override
  List<Object?> get props => [];
}

// 🔄 ÉTAT INITIAL
class AlertPageInitialM extends AlertPageStateM {
  const AlertPageInitialM();
}

// ⏳ ÉTAT DE CHARGEMENT
class AlertPageLoadingM extends AlertPageStateM {
  const AlertPageLoadingM();
}

// ✅ ÉTAT DE SUCCÈS - DONNÉES CHARGÉES
class AlertPageLoadedM extends AlertPageStateM {
  final List<Alert> alerts;
  final Map<String, dynamic>? pagination;
  final Map<String, dynamic>? stats;
  final List<Alert>? unreadAlerts;
  final List<Alert>? urgentAlerts;
  final List<Alert>? alertsByType;

  const AlertPageLoadedM({
    required this.alerts,
    this.pagination,
    this.stats,
    this.unreadAlerts,
    this.urgentAlerts,
    this.alertsByType,
  });

  @override
  List<Object?> get props => [
        alerts,
        pagination,
        stats,
        unreadAlerts,
        urgentAlerts,
        alertsByType,
      ];
}

// ❌ ÉTAT D'ERREUR
class AlertPageErrorM extends AlertPageStateM {
  final String message;
  final String? code;

  const AlertPageErrorM({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

// ➕ ÉTAT DE SUCCÈS - ALERTE CRÉÉE
class AlertCreatedM extends AlertPageStateM {
  final Alert alert;

  const AlertCreatedM({
    required this.alert,
  });

  @override
  List<Object?> get props => [alert];
}

// ✏️ ÉTAT DE SUCCÈS - ALERTE MODIFIÉE
class AlertUpdatedM extends AlertPageStateM {
  final Alert alert;

  const AlertUpdatedM({
    required this.alert,
  });

  @override
  List<Object?> get props => [alert];
}

// 🗑️ ÉTAT DE SUCCÈS - ALERTE SUPPRIMÉE
class AlertDeletedM extends AlertPageStateM {
  final String alertId;

  const AlertDeletedM({
    required this.alertId,
  });

  @override
  List<Object?> get props => [alertId];
}

// 👁️ ÉTAT DE SUCCÈS - ALERTE MARQUÉE COMME LUE
class AlertMarkedAsReadM extends AlertPageStateM {
  final String alertId;

  const AlertMarkedAsReadM({
    required this.alertId,
  });

  @override
  List<Object?> get props => [alertId];
}

// 👁️ ÉTAT DE SUCCÈS - TOUTES LES ALERTES MARQUÉES COMME LUES
class AllAlertsMarkedAsReadM extends AlertPageStateM {
  final int count;

  const AllAlertsMarkedAsReadM({
    required this.count,
  });

  @override
  List<Object?> get props => [count];
}

// 📁 ÉTAT DE SUCCÈS - ALERTE ARCHIVÉE
class AlertArchivedM extends AlertPageStateM {
  final String alertId;

  const AlertArchivedM({
    required this.alertId,
  });

  @override
  List<Object?> get props => [alertId];
}

// 📁 ÉTAT DE SUCCÈS - TOUTES LES ALERTES ARCHIVÉES
class AllAlertsArchivedM extends AlertPageStateM {
  final int count;

  const AllAlertsArchivedM({
    required this.count,
  });

  @override
  List<Object?> get props => [count];
}

// 📊 ÉTAT DE SUCCÈS - STATISTIQUES CHARGÉES
class AlertStatsLoadedM extends AlertPageStateM {
  final Map<String, dynamic> stats;

  const AlertStatsLoadedM({
    required this.stats,
  });

  @override
  List<Object?> get props => [stats];
}

// 📱 ÉTAT DE SUCCÈS - ALERTES NON LUES CHARGÉES
class UnreadAlertsLoadedM extends AlertPageStateM {
  final List<Alert> unreadAlerts;

  const UnreadAlertsLoadedM({
    required this.unreadAlerts,
  });

  @override
  List<Object?> get props => [unreadAlerts];
}

// 🏷️ ÉTAT DE SUCCÈS - ALERTES PAR TYPE CHARGÉES
class AlertsByTypeLoadedM extends AlertPageStateM {
  final List<Alert> alertsByType;
  final String type;

  const AlertsByTypeLoadedM({
    required this.alertsByType,
    required this.type,
  });

  @override
  List<Object?> get props => [alertsByType, type];
}

// 🔔 ÉTAT DE SUCCÈS - ALERTES URGENTES CHARGÉES
class UrgentAlertsLoadedM extends AlertPageStateM {
  final List<Alert> urgentAlerts;

  const UrgentAlertsLoadedM({
    required this.urgentAlerts,
  });

  @override
  List<Object?> get props => [urgentAlerts];
}

// 🧹 ÉTAT DE SUCCÈS - ALERTES NETTOYÉES
class AlertsCleanedM extends AlertPageStateM {
  final int deletedCount;

  const AlertsCleanedM({
    required this.deletedCount,
  });

  @override
  List<Object?> get props => [deletedCount];
}

// 🔍 ÉTAT DE SUCCÈS - RECHERCHE EFFECTUÉE
class AlertsSearchedM extends AlertPageStateM {
  final List<Alert> searchResults;
  final String query;

  const AlertsSearchedM({
    required this.searchResults,
    required this.query,
  });

  @override
  List<Object?> get props => [searchResults, query];
}

// ⚙️ ÉTAT DE SUCCÈS - PRÉFÉRENCES CHARGÉES
class AlertPreferencesLoadedM extends AlertPageStateM {
  final bool emailEnabled;
  final bool pushEnabled;
  final bool smsEnabled;
  final List<String> typesEnabled;
  final List<String> prioritesEnabled;

  const AlertPreferencesLoadedM({
    required this.emailEnabled,
    required this.pushEnabled,
    required this.smsEnabled,
    required this.typesEnabled,
    required this.prioritesEnabled,
  });

  @override
  List<Object?> get props => [
        emailEnabled,
        pushEnabled,
        smsEnabled,
        typesEnabled,
        prioritesEnabled,
      ];
}

// ⚙️ ÉTAT DE SUCCÈS - PRÉFÉRENCES MISES À JOUR
class AlertPreferencesUpdatedM extends AlertPageStateM {
  final bool emailEnabled;
  final bool pushEnabled;
  final bool smsEnabled;
  final List<String> typesEnabled;
  final List<String> prioritesEnabled;

  const AlertPreferencesUpdatedM({
    required this.emailEnabled,
    required this.pushEnabled,
    required this.smsEnabled,
    required this.typesEnabled,
    required this.prioritesEnabled,
  });

  @override
  List<Object?> get props => [
        emailEnabled,
        pushEnabled,
        smsEnabled,
        typesEnabled,
        prioritesEnabled,
      ];
}



