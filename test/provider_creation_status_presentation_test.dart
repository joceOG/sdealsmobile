import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/professional_capabilities.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/widgets/provider_creation_status_presentation.dart';

void main() {
  test('pending affiche le bandeau attente de validation', () {
    final p = ProviderCreationStatusPresentation.resolve(
      snapshot: const ProfessionalProfileSnapshot(
        exists: true,
        id: 'p1',
        status: 'pending',
        canOperate: false,
      ),
    );
    expect(p.badgeLabel, 'En attente de validation');
    expect(p.explanation, contains('validé'));
  });

  test('actif opérationnel uniquement si canOperate et status active', () {
    final p = ProviderCreationStatusPresentation.resolve(
      snapshot: const ProfessionalProfileSnapshot(
        exists: true,
        id: 'p1',
        status: 'active',
        canOperate: true,
      ),
    );
    expect(p.badgeLabel, 'Profil opérationnel');
  });

  test('active sans canOperate ne promet pas l’exercice', () {
    final p = ProviderCreationStatusPresentation.resolve(
      snapshot: const ProfessionalProfileSnapshot(
        exists: true,
        id: 'p1',
        status: 'active',
        canOperate: false,
      ),
    );
    expect(p.badgeLabel, isNull);
    expect(p.explanation, contains('enregistré'));
  });

  test('incomplete utilise les inconsistencies', () {
    final p = ProviderCreationStatusPresentation.resolve(
      snapshot: const ProfessionalProfileSnapshot(
        exists: true,
        status: 'incomplete',
      ),
      inconsistencies: ['Pièce d’identité'],
    );
    expect(p.badgeLabel, 'Profil incomplet');
    expect(p.explanation, contains('Pièce d’identité'));
  });
}
