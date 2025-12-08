import 'package:equatable/equatable.dart';

// 🔔 TYPE DE NOTIFICATION
enum NotificationType {
  nouvelleMission,
  missionAcceptee,
  missionRefusee,
  missionDemarree,
  missionTerminee,
  missionAnnulee,
  nouveauMessage,
  paiementRecu,
  livraisonUpdate,
  system,
  autre,
}

// 📊 STATUT NOTIFICATION
enum NotificationStatus {
  nonLue,
  lue,
}

// 🎯 PRIORITÉ
enum NotificationPriority {
  normale,
  haute,
}

// 🔔 MODÈLE NOTIFICATION
class NotificationModel extends Equatable {
  final String id;
  final String destinataireId;
  final String? expediteurId;
  final String? expediteurNom;
  final NotificationType type;
  final String titre;
  final String contenu;
  final Map<String, dynamic> donnees;
  final String? prestationId;
  final NotificationPriority priorite;
  final NotificationStatus statut;
  final DateTime? dateLecture;
  final DateTime dateCreation;
  final DateTime? dateExpiration;

  const NotificationModel({
    required this.id,
    required this.destinataireId,
    this.expediteurId,
    this.expediteurNom,
    required this.type,
    required this.titre,
    required this.contenu,
    this.donnees = const {},
    this.prestationId,
    this.priorite = NotificationPriority.normale,
    this.statut = NotificationStatus.nonLue,
    this.dateLecture,
    required this.dateCreation,
    this.dateExpiration,
  });

  /// Factory depuis backend
  factory NotificationModel.fromBackend(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      destinataireId: json['destinataire']?.toString() ?? '',
      expediteurId: json['expediteur'] is Map
          ? json['expediteur']['_id']
          : json['expediteur']?.toString(),
      expediteurNom: json['expediteur'] is Map
          ? '${json['expediteur']['nom'] ?? ''} ${json['expediteur']['prenom'] ?? ''}'.trim()
          : null,
      type: _parseType(json['type'] ?? ''),
      titre: json['titre'] ?? 'Notification',
      contenu: json['contenu'] ?? '',
      donnees: json['donnees'] ?? {},
      prestationId: json['prestation'] is Map
          ? json['prestation']['_id']
          : json['prestation']?.toString(),
      priorite: _parsePriorite(json['priorite'] ?? 'NORMALE'),
      statut: _parseStatut(json['statut'] ?? 'NON_LUE'),
      dateLecture: json['dateLecture'] != null
          ? DateTime.parse(json['dateLecture'])
          : null,
      dateCreation: json['dateCreation'] != null
          ? DateTime.parse(json['dateCreation'])
          : DateTime.now(),
      dateExpiration: json['dateExpiration'] != null
          ? DateTime.parse(json['dateExpiration'])
          : null,
    );
  }

  // Helpers de parsing
  static NotificationType _parseType(String type) {
    switch (type.toUpperCase()) {
      case 'NOUVELLE_MISSION':
        return NotificationType.nouvelleMission;
      case 'MISSION_ACCEPTEE':
        return NotificationType.missionAcceptee;
      case 'MISSION_REFUSEE':
        return NotificationType.missionRefusee;
      case 'MISSION_DEMARREE':
        return NotificationType.missionDemarree;
      case 'MISSION_TERMINEE':
        return NotificationType.missionTerminee;
      case 'MISSION_ANNULEE':
        return NotificationType.missionAnnulee;
      case 'NOUVEAU_MESSAGE':
        return NotificationType.nouveauMessage;
      case 'PAIEMENT_RECU':
        return NotificationType.paiementRecu;
      case 'LIVRAISON_UPDATE':
        return NotificationType.livraisonUpdate;
      case 'SYSTEM':
        return NotificationType.system;
      default:
        return NotificationType.autre;
    }
  }

  static NotificationStatus _parseStatut(String statut) {
    return statut.toUpperCase() == 'LUE'
        ? NotificationStatus.lue
        : NotificationStatus.nonLue;
  }

  static NotificationPriority _parsePriorite(String priorite) {
    return priorite.toUpperCase() == 'HAUTE'
        ? NotificationPriority.haute
        : NotificationPriority.normale;
  }

  // Getters helpers
  bool get estLue => statut == NotificationStatus.lue;
  bool get estUrgente => priorite == NotificationPriority.haute;

  @override
  List<Object?> get props => [
        id,
        destinataireId,
        type,
        statut,
        dateCreation,
      ];
}
