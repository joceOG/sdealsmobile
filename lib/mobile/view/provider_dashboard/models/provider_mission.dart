import '../../../../data/utils/display_text.dart';

/// Identifiant prestation attendu par `/mission-details/:id` et GET `/prestation/:id`.
String? prestationIdOf(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  return cleanDisplayPart(
    raw['_id'] ?? raw['id'] ?? raw['prestationId'] ?? raw['missionId'],
  );
}

String? missionIdFromNotification(Map<String, dynamic> notification) {
  final data = notification['donnees'];
  if (data is Map) {
    final fromData = cleanDisplayPart(
      data['prestationId'] ?? data['missionId'] ?? data['prestation'],
    );
    if (fromData != null) return fromData;
  }
  return cleanDisplayPart(
    notification['prestationId'] ??
        notification['missionId'] ??
        notification['prestation'],
  );
}

String prestationStatusOf(Map<String, dynamic> mission) {
  return (mission['statut'] ?? mission['status'] ?? '')
      .toString()
      .trim()
      .toUpperCase();
}

String prestationStatusLabel(String statut) {
  switch (statut.toUpperCase()) {
    case 'EN_ATTENTE':
      return 'Nouvelle demande';
    case 'ACCEPTEE':
      return 'Acceptée';
    case 'EN_COURS':
      return 'En cours';
    case 'TERMINEE':
      return 'Terminée';
    case 'REFUSEE':
      return 'Refusée';
    case 'ANNULEE':
      return 'Annulée';
    case 'LITIGE':
      return 'Litige';
    default:
      return statut.isEmpty ? 'Statut inconnu' : statut;
  }
}

/// Transitions prestataire autorisées côté backend (`PRESTATAIRE_STATUS_TRANSITIONS`).
enum ProviderMissionAction { accept, refuse, start, complete }

List<ProviderMissionAction> providerActionsForStatus(String statut) {
  switch (statut.toUpperCase()) {
    case 'EN_ATTENTE':
      return const [
        ProviderMissionAction.accept,
        ProviderMissionAction.refuse,
      ];
    case 'ACCEPTEE':
      return const [ProviderMissionAction.start];
    case 'EN_COURS':
      return const [ProviderMissionAction.complete];
    default:
      return const [];
  }
}

/// Actions affichables : propriétaire + transition réelle + `canOperate`
/// (Terminer reste autorisé sans `canOperate`, comme le backend).
List<ProviderMissionAction> visibleProviderActions({
  required String statut,
  required bool isOwner,
  required bool canOperate,
}) {
  if (!isOwner) return const [];
  return [
    for (final action in providerActionsForStatus(statut))
      if (action == ProviderMissionAction.complete || canOperate) action,
  ];
}

String targetStatusFor(ProviderMissionAction action) {
  switch (action) {
    case ProviderMissionAction.accept:
      return 'ACCEPTEE';
    case ProviderMissionAction.refuse:
      return 'REFUSEE';
    case ProviderMissionAction.start:
      return 'EN_COURS';
    case ProviderMissionAction.complete:
      return 'TERMINEE';
  }
}

/// Propriétaire = document Prestataire de la mission, ou utilisateur lié.
/// Champs masqués pour les lecteurs non autorisés (aligné sur `prestationVisibility.js`).
const _prestationSensitiveKeys = [
  'adresse',
  'ville',
  'codePostal',
  'localisation',
  'telephoneUrgence',
  'notesClient',
  'notesPrestataire',
  'referencePaiement',
  'description',
  'photosAvant',
  'photosApres',
];

/// Données affichables pour un lecteur qui n’est pas propriétaire (défense en profondeur).
Map<String, dynamic> prestationForNonOwnerDisplay(Map<String, dynamic> mission) {
  final out = Map<String, dynamic>.from(mission);
  for (final key in _prestationSensitiveKeys) {
    out.remove(key);
  }
  return out;
}

bool isProviderOwnerOfPrestation(
  Map<String, dynamic> mission, {
  String? prestataireDocId,
  String? utilisateurId,
}) {
  final prest = mission['prestataire'];
  if (prestataireDocId != null && prestataireDocId.isNotEmpty) {
    if (prest is Map && prest['_id']?.toString() == prestataireDocId) {
      return true;
    }
    if (prest?.toString() == prestataireDocId) return true;
  }
  if (utilisateurId != null && utilisateurId.isNotEmpty && prest is Map) {
    final u = prest['utilisateur'];
    if (u is Map &&
        (u['_id']?.toString() == utilisateurId ||
            u['idutilisateur']?.toString() == utilisateurId)) {
      return true;
    }
    if (u?.toString() == utilisateurId) return true;
  }
  return false;
}
