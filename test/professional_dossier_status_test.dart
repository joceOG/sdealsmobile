import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/professional_dossier_status.dart';

void main() {
  test('canOperate false sans statut n’est pas un dossier incomplet', () {
    expect(
      ProfessionalDossierCopy.resolve(status: null, canOperate: false),
      isNull,
    );
  });

  test('une API indisponible n’est pas un dossier incomplet', () {
    expect(
      ProfessionalDossierCopy.resolve(status: 'pending', apiUnavailable: true),
      isNull,
    );
  });

  test('pending, refus avec motif, actif sans exercice', () {
    expect(
      ProfessionalDossierCopy.resolve(status: 'pending')!.title,
      'Dossier transmis',
    );
    expect(
      ProfessionalDossierCopy.resolve(status: 'rejected', motif: 'Pièce illisible')!
          .message,
      'Pièce illisible',
    );
    final active = ProfessionalDossierCopy.resolve(
      status: 'active',
      canOperate: false,
    )!;
    expect(active.title, 'Profil validé');
    expect(active.message, contains('pas encore autorisé'));
  });

  test('seuls les éléments absents du dossier sont listés', () {
    expect(missingProviderCompletionItems(null), isEmpty);

    final onlyLocation = missingProviderCompletionItems({
      'cni1': 'https://cdn/cni1.jpg',
      'cni2': 'https://cdn/cni2.jpg',
      'selfie': 'https://cdn/selfie.jpg',
    });
    expect(onlyLocation.map((item) => item.title), ['Localisation']);

    final identityAndSelfie = missingProviderCompletionItems({
      'cni1': '',
      'localisationmaps': {'latitude': 5.3, 'longitude': -4.0},
    });
    expect(
      identityAndSelfie.map((item) => item.title),
      ['Pièce d’identité', 'Selfie de vérification'],
    );

    expect(
      missingProviderCompletionItems({
        'cni1': 'a',
        'cni2': 'b',
        'selfie': 'c',
        'localisationmaps': {'latitude': 5.3, 'longitude': -4.0},
      }),
      isEmpty,
    );
  });
}
