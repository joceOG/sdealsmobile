import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/utils/string_list_normalizer.dart';

void main() {
  group('normalizeStringList', () {
    test('string simple', () {
      expect(
        normalizeStringList('Bâtiment & Construction'),
        ['Bâtiment & Construction'],
      );
    });

    test('List déjà propre', () {
      expect(
        normalizeStringList(['Bâtiment & Construction']),
        ['Bâtiment & Construction'],
      );
    });

    test('JSON string array', () {
      expect(
        normalizeStringList('["Bâtiment & Construction"]'),
        ['Bâtiment & Construction'],
      );
    });

    test('JSON string array avec espaces', () {
      expect(
        normalizeStringList('[ "Bâtiment & Construction", "Plomberie" ]'),
        ['Bâtiment & Construction', 'Plomberie'],
      );
    });

    test('legacy double-encodé (UPDATE multipart)', () {
      expect(
        normalizeStringList(['["Bâtiment & Construction"]']),
        ['Bâtiment & Construction'],
      );
    });

    test('deux éléments propres', () {
      expect(
        normalizeStringList(['Bâtiment & Construction', 'Plomberie']),
        ['Bâtiment & Construction', 'Plomberie'],
      );
    });

    test('doublons dédupliqués', () {
      expect(
        normalizeStringList(['Port-Bouët', 'Port-Bouët', ' Cocody ']),
        ['Port-Bouët', 'Cocody'],
      );
    });

    test('null → liste vide', () {
      expect(normalizeStringList(null), isEmpty);
    });

    test('vide → liste vide', () {
      expect(normalizeStringList(''), isEmpty);
      expect(normalizeStringList([]), isEmpty);
    });

    test('littéral null ignoré', () {
      expect(normalizeStringList('null'), isEmpty);
      expect(normalizeStringList(['null', 'Port-Bouët']), ['Port-Bouët']);
    });

    test('phrase avec [ non-JSON non cassée', () {
      expect(
        normalizeStringList('Promo [été]'),
        ['Promo [été]'],
      );
    });
  });

  group('Prestataire.fromBackend — régression chips', () {
    Map<String, dynamic> basePayload({
      required dynamic specialite,
      required dynamic zoneIntervention,
    }) {
      return {
        '_id': '507f1f77bcf86cd799439011',
        'verifier': true,
        'prixprestataire': 12000,
        'localisation': 'Port-Bouët',
        'specialite': specialite,
        'zoneIntervention': zoneIntervention,
        'utilisateur': {
          '_id': '507f1f77bcf86cd799439012',
          'nom': 'Residence',
          'prenom': 'Chapechape',
          'email': 'a@b.c',
          'telephone': '0700000000',
          'role': 'PRESTATAIRE',
        },
        'service': {
          '_id': '507f1f77bcf86cd799439013',
          'nomservice': 'Serrurier',
          'imageservice': '',
          'prixmoyen': '10000',
        },
      };
    }

    test('legacy specialite/zone → labels chips sans crochets', () {
      final p = Prestataire.fromBackend(basePayload(
        specialite: ['["Bâtiment & Construction"]'],
        zoneIntervention: ['["Port-Bouët"]'],
      ));

      expect(p.specialite, ['Bâtiment & Construction']);
      expect(p.zoneIntervention, ['Port-Bouët']);
      expect(p.specialite!.first, isNot(contains('[')));
      expect(p.zoneIntervention!.first, isNot(contains('[')));
    });

    test('JSON string specialite/zone', () {
      final p = Prestataire.fromBackend(basePayload(
        specialite: '["Bâtiment & Construction"]',
        zoneIntervention: '["Port-Bouët"]',
      ));

      expect(p.specialite, ['Bâtiment & Construction']);
      expect(p.zoneIntervention, ['Port-Bouët']);
    });
  });
}
