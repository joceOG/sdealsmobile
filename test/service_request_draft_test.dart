import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/widgets/service_request_draft.dart';

void main() {
  group('ServiceRequestDraft', () {
    test('notesClient fusionne précision et besoin', () {
      const draft = ServiceRequestDraft(
        besoin: 'Fuite robinet',
        adresse: 'Cocody',
        ville: 'Abidjan',
        precisionLieu: 'Près des Oscars',
      );
      expect(
        draft.notesClient,
        'Précision: Près des Oscars\nFuite robinet',
      );
    });

    test('lieuAffiche joint adresse et ville', () {
      const draft = ServiceRequestDraft(
        besoin: 'x',
        adresse: 'Cocody',
        ville: 'Angré',
      );
      expect(draft.lieuAffiche, 'Cocody · Angré');
    });

    test('validateForVerification exige besoin et lieu', () {
      const empty = ServiceRequestDraft(
        besoin: '',
        adresse: '',
        ville: '',
      );
      expect(empty.validateForVerification(), isNotNull);

      const ok = ServiceRequestDraft(
        besoin: 'Besoin',
        adresse: 'Cocody',
        ville: 'Abidjan',
      );
      expect(ok.validateForVerification(), isNull);
    });
  });
}
