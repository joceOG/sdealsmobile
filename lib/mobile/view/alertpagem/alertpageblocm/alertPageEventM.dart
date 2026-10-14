import 'package:equatable/equatable.dart';

abstract class AlertPageEventM extends Equatable {
  const AlertPageEventM();

  @override
  List<Object?> get props => [];
}

// 📋 CHARGER LES ALERTES
class LoadAlertsDataM extends AlertPageEventM {
  final String? userId;
  final String? type;
  final String? statut;
  final String? priorite;
  final int? page;
  final int? limit;
  final String? sortBy;
  final String? sortOrder;
  final int? periode;

  const LoadAlertsDataM({
    this.userId,
    this.type,
    this.statut,
    this.priorite,
    this.page,
    this.limit,
    this.sortBy,
    this.sortOrder,
    this.periode,
  });

  @override
  List<Object?> get props => [
        userId,
        type,
        statut,
        priorite,
        page,
        limit,
        sortBy,
        sortOrder,
        periode,
      ];
}

// 🔍 RECHERCHER DANS LES ALERTES
class SearchAlertsM extends AlertPageEventM {
  final String query;
  final String? type;
  final String? priorite;
  final int? periode;

  const SearchAlertsM({
    required this.query,
    this.type,
    this.priorite,
    this.periode,
  });

  @override
  List<Object?> get props => [
        query,
        type,
        priorite,
        periode,
      ];
}

// ➕ CRÉER UNE ALERTE
class CreateAlertM extends AlertPageEventM {
  final String titre;
  final String description;
  final String type;
  final String? sousType;
  final String? referenceId;
  final String? referenceType;
  final String priorite;
  final bool envoiEmail;
  final bool envoiPush;
  final bool envoiSMS;
  final Map<String, dynamic>? donnees;
  final String? urlAction;
  final DateTime? dateExpiration;

  const CreateAlertM({
    required this.titre,
    required this.description,
    required this.type,
    this.sousType,
    this.referenceId,
    this.referenceType,
    required this.priorite,
    required this.envoiEmail,
    required this.envoiPush,
    required this.envoiSMS,
    this.donnees,
    this.urlAction,
    this.dateExpiration,
  });

  @override
  List<Object?> get props => [
        titre,
        description,
        type,
        sousType,
        referenceId,
        referenceType,
        priorite,
        envoiEmail,
        envoiPush,
        envoiSMS,
        donnees,
        urlAction,
        dateExpiration,
      ];
}

// ✏️ MODIFIER UNE ALERTE
class UpdateAlertM extends AlertPageEventM {
  final String alertId;
  final String? titre;
  final String? description;
  final String? type;
  final String? sousType;
  final String? priorite;
  final bool? envoiEmail;
  final bool? envoiPush;
  final bool? envoiSMS;
  final Map<String, dynamic>? donnees;
  final String? urlAction;
  final DateTime? dateExpiration;

  const UpdateAlertM({
    required this.alertId,
    this.titre,
    this.description,
    this.type,
    this.sousType,
    this.priorite,
    this.envoiEmail,
    this.envoiPush,
    this.envoiSMS,
    this.donnees,
    this.urlAction,
    this.dateExpiration,
  });

  @override
  List<Object?> get props => [
        alertId,
        titre,
        description,
        type,
        sousType,
        priorite,
        envoiEmail,
        envoiPush,
        envoiSMS,
        donnees,
        urlAction,
        dateExpiration,
      ];
}

// 🗑️ SUPPRIMER UNE ALERTE
class DeleteAlertM extends AlertPageEventM {
  final String alertId;

  const DeleteAlertM({
    required this.alertId,
  });

  @override
  List<Object?> get props => [alertId];
}

// 👁️ MARQUER COMME LUE
class MarkAsReadM extends AlertPageEventM {
  final String alertId;

  const MarkAsReadM({
    required this.alertId,
  });

  @override
  List<Object?> get props => [alertId];
}

// 👁️ MARQUER TOUTES COMME LUES
class MarkAllAsReadM extends AlertPageEventM {
  final String? userId;

  const MarkAllAsReadM({this.userId});

  @override
  List<Object?> get props => [userId];
}

// 📁 ARCHIVER UNE ALERTE
class ArchiveAlertM extends AlertPageEventM {
  final String alertId;

  const ArchiveAlertM({
    required this.alertId,
  });

  @override
  List<Object?> get props => [alertId];
}

// 📁 ARCHIVER TOUTES LES ALERTES
class ArchiveAllAlertsM extends AlertPageEventM {
  const ArchiveAllAlertsM();
}

// 📊 CHARGER LES STATISTIQUES
class LoadAlertStatsM extends AlertPageEventM {
  final int? periode;

  const LoadAlertStatsM({
    this.periode,
  });

  @override
  List<Object?> get props => [periode];
}

// 📱 ALERTES NON LUES
class LoadUnreadAlertsM extends AlertPageEventM {
  final int? limit;

  const LoadUnreadAlertsM({
    this.limit,
  });

  @override
  List<Object?> get props => [limit];
}

// 🏷️ ALERTES PAR TYPE
class LoadAlertsByTypeM extends AlertPageEventM {
  final String type;
  final int? limit;

  const LoadAlertsByTypeM({
    required this.type,
    this.limit,
  });

  @override
  List<Object?> get props => [type, limit];
}

// 🔔 ALERTES URGENTES
class LoadUrgentAlertsM extends AlertPageEventM {
  final int? limit;

  const LoadUrgentAlertsM({
    this.limit,
  });

  @override
  List<Object?> get props => [limit];
}

// 🧹 NETTOYER LES ALERTES ANCIENNES
class CleanOldAlertsM extends AlertPageEventM {
  final int? jours;

  const CleanOldAlertsM({
    this.jours,
  });

  @override
  List<Object?> get props => [jours];
}

// 🔄 ACTUALISER LES ALERTES
class RefreshAlertsM extends AlertPageEventM {
  const RefreshAlertsM();
}

// ⚙️ CONFIGURER LES PRÉFÉRENCES
class UpdateAlertPreferencesM extends AlertPageEventM {
  final bool emailEnabled;
  final bool pushEnabled;
  final bool smsEnabled;
  final List<String> typesEnabled;
  final List<String> prioritesEnabled;

  const UpdateAlertPreferencesM({
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

// 📋 CHARGER LES PRÉFÉRENCES
class LoadAlertPreferencesM extends AlertPageEventM {
  const LoadAlertPreferencesM();
}
