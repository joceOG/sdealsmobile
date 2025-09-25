import 'package:equatable/equatable.dart';

abstract class HistoryPageEventM extends Equatable {
  const HistoryPageEventM();

  @override
  List<Object?> get props => [];
}

// 📋 CHARGER L'HISTORIQUE
class LoadHistoryDataM extends HistoryPageEventM {
  final String? objetType;
  final String? statut;
  final String? categorie;
  final String? ville;
  final int? page;
  final int? limit;
  final String? sortBy;
  final String? sortOrder;
  final int? periode;

  const LoadHistoryDataM({
    this.objetType,
    this.statut,
    this.categorie,
    this.ville,
    this.page,
    this.limit,
    this.sortBy,
    this.sortOrder,
    this.periode,
  });

  @override
  List<Object?> get props => [
        objetType,
        statut,
        categorie,
        ville,
        page,
        limit,
        sortBy,
        sortOrder,
        periode,
      ];
}

// 🔍 RECHERCHER DANS L'HISTORIQUE
class SearchHistoryM extends HistoryPageEventM {
  final String query;
  final String? objetType;
  final String? categorie;
  final String? ville;
  final int? periode;

  const SearchHistoryM({
    required this.query,
    this.objetType,
    this.categorie,
    this.ville,
    this.periode,
  });

  @override
  List<Object?> get props => [
        query,
        objetType,
        categorie,
        ville,
        periode,
      ];
}

// ➕ AJOUTER UNE CONSULTATION
class AddHistoryM extends HistoryPageEventM {
  final String objetType;
  final String? objetId;
  final String titre;
  final String? description;
  final String? image;
  final double? prix;
  final String? devise;
  final String? categorie;
  final List<String>? tags;
  final String? ville;
  final String? pays;
  final double? note;
  final int? dureeConsultation;
  final String sessionId;
  final String? userAgent;
  final String? ipAddress;
  final double? latitude;
  final double? longitude;
  final String? url;
  final String? referrer;
  final List<String>? tagsConsultation;
  final Map<String, dynamic>? interactions;
  final List<Map<String, dynamic>>? actions;
  final Map<String, dynamic>? deviceInfo;

  const AddHistoryM({
    required this.objetType,
    this.objetId,
    required this.titre,
    this.description,
    this.image,
    this.prix,
    this.devise,
    this.categorie,
    this.tags,
    this.ville,
    this.pays,
    this.note,
    this.dureeConsultation,
    required this.sessionId,
    this.userAgent,
    this.ipAddress,
    this.latitude,
    this.longitude,
    this.url,
    this.referrer,
    this.tagsConsultation,
    this.interactions,
    this.actions,
    this.deviceInfo,
  });

  @override
  List<Object?> get props => [
        objetType,
        objetId,
        titre,
        description,
        image,
        prix,
        devise,
        categorie,
        tags,
        ville,
        pays,
        note,
        dureeConsultation,
        sessionId,
        userAgent,
        ipAddress,
        latitude,
        longitude,
        url,
        referrer,
        tagsConsultation,
        interactions,
        actions,
        deviceInfo,
      ];
}

// ✏️ MODIFIER UNE CONSULTATION
class UpdateHistoryM extends HistoryPageEventM {
  final String historyId;
  final String? titre;
  final String? description;
  final int? dureeConsultation;
  final List<String>? tagsConsultation;
  final Map<String, dynamic>? interactions;
  final List<Map<String, dynamic>>? actions;

  const UpdateHistoryM({
    required this.historyId,
    this.titre,
    this.description,
    this.dureeConsultation,
    this.tagsConsultation,
    this.interactions,
    this.actions,
  });

  @override
  List<Object?> get props => [
        historyId,
        titre,
        description,
        dureeConsultation,
        tagsConsultation,
        interactions,
        actions,
      ];
}

// 🗑️ SUPPRIMER UNE CONSULTATION
class DeleteHistoryM extends HistoryPageEventM {
  final String historyId;

  const DeleteHistoryM({
    required this.historyId,
  });

  @override
  List<Object?> get props => [historyId];
}

// 📊 CHARGER LES STATISTIQUES
class LoadHistoryStatsM extends HistoryPageEventM {
  final int? periode;

  const LoadHistoryStatsM({
    this.periode,
  });

  @override
  List<Object?> get props => [periode];
}

// 📱 CONSULTATIONS RÉCENTES
class LoadRecentHistoryM extends HistoryPageEventM {
  final int? limit;

  const LoadRecentHistoryM({
    this.limit,
  });

  @override
  List<Object?> get props => [limit];
}

// 🏷️ CONSULTATIONS PAR TYPE
class LoadHistoryByTypeM extends HistoryPageEventM {
  final String objetType;
  final int? limit;

  const LoadHistoryByTypeM({
    required this.objetType,
    this.limit,
  });

  @override
  List<Object?> get props => [objetType, limit];
}

// 🔄 ARCHIVER UNE CONSULTATION
class ArchiveHistoryM extends HistoryPageEventM {
  final String historyId;

  const ArchiveHistoryM({
    required this.historyId,
  });

  @override
  List<Object?> get props => [historyId];
}

// 🧹 NETTOYER L'HISTORIQUE ANCIEN
class CleanOldHistoryM extends HistoryPageEventM {
  final int? jours;

  const CleanOldHistoryM({
    this.jours,
  });

  @override
  List<Object?> get props => [jours];
}

// 🔄 ACTUALISER L'HISTORIQUE
class RefreshHistoryM extends HistoryPageEventM {
  const RefreshHistoryM();
}



