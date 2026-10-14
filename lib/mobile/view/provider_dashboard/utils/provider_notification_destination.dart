import '../../../../data/utils/display_text.dart';
import '../models/provider_mission.dart';

enum ProviderNotificationNavKind {
  mission,
  conversation,
  missionsList,
  none,
}

/// Destination exploitable depuis une notification prestataire (liste).
class ProviderNotificationDestination {
  const ProviderNotificationDestination({
    this.kind = ProviderNotificationNavKind.none,
    this.actionLabel,
    this.detailUnavailable = false,
    this.missionId,
    this.conversationId,
  });

  final ProviderNotificationNavKind kind;
  final String? actionLabel;
  final bool detailUnavailable;
  final String? missionId;
  final String? conversationId;

  bool get hasFooterAction =>
      actionLabel != null && actionLabel!.isNotEmpty && kind != ProviderNotificationNavKind.none;
}

ProviderNotificationDestination resolveProviderNotificationDestination(
  Map<String, dynamic> notification,
) {
  final type = '${notification['type'] ?? ''}'.toUpperCase();
  final category = '${notification['categorie'] ?? ''}'.toLowerCase();
  final titre = '${notification['titre'] ?? ''}'.toLowerCase();

  final isMessage = type.contains('MESSAGE');
  if (isMessage) {
    final data = notification['donnees'];
    final convId = data is Map
        ? cleanDisplayPart(data['conversationId'])
        : null;
    if (convId != null) {
      return ProviderNotificationDestination(
        kind: ProviderNotificationNavKind.conversation,
        actionLabel: 'Ouvrir la conversation',
        conversationId: convId,
      );
    }
    return const ProviderNotificationDestination(
      detailUnavailable: true,
      actionLabel: 'Ouvrir la conversation',
    );
  }

  final isMissionRelated = type.contains('MISSION') ||
      type.contains('PRESTATION') ||
      category == 'prestation' ||
      titre.contains('mission') ||
      titre.contains('demande') ||
      titre.contains('intervention');

  if (!isMissionRelated) {
    return const ProviderNotificationDestination();
  }

  final missionId = missionIdFromNotification(notification);
  if (missionId != null) {
    final isNewRequest = type.contains('ATTENTE') ||
        titre.contains('nouvelle demande') ||
        titre.contains('nouvelle mission');
    final isConfirmed =
        titre.contains('confirm') || titre.contains('intervention');
    final label = isNewRequest
        ? 'Voir la demande'
        : (isConfirmed ? 'Voir la mission' : 'Voir la mission');
    return ProviderNotificationDestination(
      kind: ProviderNotificationNavKind.mission,
      actionLabel: label,
      missionId: missionId,
    );
  }

  return const ProviderNotificationDestination(
    kind: ProviderNotificationNavKind.missionsList,
    detailUnavailable: true,
    actionLabel: 'Voir mes missions',
  );
}
