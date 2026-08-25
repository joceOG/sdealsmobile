import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';

/// STAB-11b : liste publique remplace selfie/CNI par booléens.
/// Le mapping mobile ne doit plus planter ni masquer ces profils.
void main() {
  final publicListPayload = <String, dynamic>{
    '_id': '507f1f77bcf86cd799439011',
    'verifier': true,
    'status': 'active',
    'prixprestataire': 12000,
    'localisation': 'Port-Bouët',
    'selfie': true,
    'cni1': true,
    'cni2': false,
    'attestationAssurance': true,
    'diplomeCertificat': [true, true],
    'utilisateur': {
      '_id': '507f1f77bcf86cd799439012',
      'nom': 'Residence',
      'prenom': 'Chapechape',
      'email': 'a@b.c',
      'telephone': '0700000000',
      'role': 'PRESTATAIRE',
      'photoProfil': null,
    },
    'service': {
      '_id': '507f1f77bcf86cd799439013',
      'nomservice': 'Serrurier',
      'imageservice': '',
      'prixmoyen': '10000',
    },
  };

  test('fromBackend accepte selfie/CNI booléens sans exception', () {
    final p = Prestataire.fromBackend(publicListPayload);
    expect(p.idprestataire, '507f1f77bcf86cd799439011');
    expect(p.utilisateur.nom, 'Residence');
    expect(p.selfie, isNull);
    expect(p.cni1, isNull);
    expect(p.cni2, isNull);
    expect(p.diplomeCertificat, isNull);
  });

  test('fromJson accepte selfie/CNI booléens sans exception', () {
    final p = Prestataire.fromJson(publicListPayload);
    expect(p.selfie, isNull);
    expect(p.utilisateur.prenom, 'Chapechape');
  });

  test('providerPhotoUrl ignore selfie bool et privilégie photoProfil', () {
    expect(
      providerPhotoUrl(
        selfie: null,
        photoProfil: null,
        prestataireMap: publicListPayload,
        utilisateurMap:
            Map<String, dynamic>.from(publicListPayload['utilisateur'] as Map),
      ),
      isNull,
    );

    expect(
      providerPhotoUrl(
        photoProfil: 'https://cdn.example.com/avatar.jpg',
        prestataireMap: {'selfie': true},
      ),
      'https://cdn.example.com/avatar.jpg',
    );

    expect(kycFieldAsPublicUrl(true), isNull);
    expect(kycFieldAsPublicUrl('true'), isNull);
    expect(
      kycFieldAsPublicUrl('https://res.cloudinary.com/x/image.jpg'),
      'https://res.cloudinary.com/x/image.jpg',
    );
  });
}
