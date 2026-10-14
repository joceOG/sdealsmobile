import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/utils/provider_notification_destination.dart';

void main() {
  group('resolveProviderNotificationDestination', () {
    test('mission with prestationId', () {
      final dest = resolveProviderNotificationDestination({
        'type': 'PRESTATION',
        'titre': 'Nouvelle demande',
        'donnees': {'prestationId': 'p1'},
      });
      expect(dest.kind, ProviderNotificationNavKind.mission);
      expect(dest.missionId, 'p1');
      expect(dest.detailUnavailable, isFalse);
      expect(dest.actionLabel, 'Voir la demande');
    });

    test('mission without id — fallback list', () {
      final dest = resolveProviderNotificationDestination({
        'type': 'PRESTATION',
        'titre': 'Mise à jour d’une mission',
      });
      expect(dest.kind, ProviderNotificationNavKind.missionsList);
      expect(dest.detailUnavailable, isTrue);
      expect(dest.actionLabel, 'Voir mes missions');
    });

    test('message with conversationId', () {
      final dest = resolveProviderNotificationDestination({
        'type': 'MESSAGE',
        'donnees': {'conversationId': 'c1'},
      });
      expect(dest.kind, ProviderNotificationNavKind.conversation);
      expect(dest.conversationId, 'c1');
    });
  });
}
