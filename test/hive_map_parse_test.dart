import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/services/cache_service.dart';

void main() {
  test('une map Hive se lit sans cast Map<String, dynamic>', () {
    final dynamic row = <dynamic, dynamic>{
      '_id': 'p1',
      'prixprestataire': 1000,
      'localisation': 'Cocody',
      'verifier': true,
      'utilisateur': <dynamic, dynamic>{
        '_id': 'u1',
        'nom': 'Kouassi',
        'prenom': 'Awa',
        'email': 'a@example.com',
        'password': '',
        'telephone': '000',
        'role': 'PRESTATAIRE',
      },
      'service': <dynamic, dynamic>{
        '_id': 's1',
        'nomservice': 'Plomberie',
        'imageservice': '',
        'prixmoyen': '0',
      },
      'localisationmaps': <dynamic, dynamic>{
        'latitude': 5.3,
        'longitude': -4.0,
      },
    };

    final maps = asStringKeyMaps(<dynamic>[row]);
    expect(maps, hasLength(1));

    final parsed = Prestataire.fromJson(maps.single);
    expect(parsed.idprestataire, 'p1');
    expect(parsed.service.nomservice, 'Plomberie');
    expect(parsed.localisationMaps?.latitude, 5.3);
    expect(parsed.utilisateur.nom, 'Kouassi');
  });
}
