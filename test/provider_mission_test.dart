import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/models/provider_mission.dart';

void main() {
  group('prestationIdOf', () {
    test('prefers _id then aliases', () {
      expect(prestationIdOf({'_id': 'abc'}), 'abc');
      expect(prestationIdOf({'id': 'xyz'}), 'xyz');
      expect(prestationIdOf({'prestationId': 'p1'}), 'p1');
      expect(prestationIdOf(null), isNull);
      expect(prestationIdOf({}), isNull);
    });
  });

  group('missionIdFromNotification', () {
    test('reads backend prestationId before legacy missionId', () {
      expect(
        missionIdFromNotification({
          'donnees': {'prestationId': 'presta-1', 'missionId': 'legacy'},
        }),
        'presta-1',
      );
      expect(
        missionIdFromNotification({
          'donnees': {'missionId': 'legacy'},
        }),
        'legacy',
      );
      expect(
        missionIdFromNotification({'prestation': 'top-1'}),
        'top-1',
      );
    });
  });

  group('provider actions', () {
    test('transitions match backend PRESTATAIRE_STATUS_TRANSITIONS', () {
      expect(
        providerActionsForStatus('EN_ATTENTE'),
        [ProviderMissionAction.accept, ProviderMissionAction.refuse],
      );
      expect(
        providerActionsForStatus('ACCEPTEE'),
        [ProviderMissionAction.start],
      );
      expect(
        providerActionsForStatus('EN_COURS'),
        [ProviderMissionAction.complete],
      );
      expect(providerActionsForStatus('TERMINEE'), isEmpty);
      expect(providerActionsForStatus('REFUSEE'), isEmpty);
    });

    test('visible actions require owner; Terminer stays without canOperate', () {
      expect(
        visibleProviderActions(
          statut: 'EN_ATTENTE',
          isOwner: false,
          canOperate: true,
        ),
        isEmpty,
      );
      expect(
        visibleProviderActions(
          statut: 'EN_ATTENTE',
          isOwner: true,
          canOperate: false,
        ),
        isEmpty,
      );
      expect(
        visibleProviderActions(
          statut: 'EN_COURS',
          isOwner: true,
          canOperate: false,
        ),
        [ProviderMissionAction.complete],
      );
    });
  });

  group('isProviderOwnerOfPrestation', () {
    test('matches prestataire document or linked utilisateur', () {
      expect(
        isProviderOwnerOfPrestation(
          {
            'prestataire': {'_id': 'doc-1'},
          },
          prestataireDocId: 'doc-1',
        ),
        isTrue,
      );
      expect(
        isProviderOwnerOfPrestation(
          {
            'prestataire': {
              'utilisateur': {'_id': 'user-9'},
            },
          },
          utilisateurId: 'user-9',
        ),
        isTrue,
      );
      expect(
        isProviderOwnerOfPrestation(
          {
            'prestataire': {'_id': 'other'},
          },
          prestataireDocId: 'doc-1',
          utilisateurId: 'user-9',
        ),
        isFalse,
      );
    });
  });

  group('prestationForNonOwnerDisplay', () {
    test('strips address, description and photos', () {
      final raw = {
        'titre': 'Plomberie',
        'adresse': 'Rue secrète',
        'ville': 'Abidjan',
        'description': 'Détail personnel',
        'notesClient': 'Urgent',
        'photosAvant': ['https://x/a.jpg'],
      };
      final safe = prestationForNonOwnerDisplay(raw);
      expect(safe.containsKey('adresse'), isFalse);
      expect(safe.containsKey('ville'), isFalse);
      expect(safe.containsKey('description'), isFalse);
      expect(safe.containsKey('notesClient'), isFalse);
      expect(safe.containsKey('photosAvant'), isFalse);
      expect(safe['titre'], 'Plomberie');
    });
  });

  group('display mapping', () {
    test('service object is never shown raw', () {
      final title = prestationServiceTitle({
        'service': {
          'tags': [],
          'aliases': [],
          'nomservice': 'Plomberie',
        },
      });
      expect(title, 'Plomberie');
      expect(title, isNot(contains('tags')));
      expect(cleanDisplayPart({'tags': [], 'aliases': []}), isNull);
    });
  });
}
