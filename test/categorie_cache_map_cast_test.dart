import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/service.dart';

void main() {
  test('Categorie.fromJson accepte Map Hive (dynamic keys)', () {
    // Simule le shape renvoyé par Hive après cacheData
    final hiveLike = <dynamic, dynamic>{
      '_id': 'cat1',
      'nomcategorie': 'Design',
      'imagecategorie': '',
      'groupe': <dynamic, dynamic>{
        '_id': 'g1',
        'nomgroupe': 'Freelance',
      },
    };

    final cat = Categorie.fromJson(hiveLike);
    expect(cat.nomcategorie, 'Design');
    expect(cat.groupe.nomgroupe, 'Freelance');
    expect(cat.idcategorie, 'cat1');
  });

  test('Service.fromJson accepte categorie nested Hive', () {
    final hiveLike = <dynamic, dynamic>{
      '_id': 's1',
      'nomservice': 'Logo',
      'imageservice': '',
      'prixmoyen': '10',
      'categorie': <dynamic, dynamic>{
        '_id': 'c1',
        'nomcategorie': 'Design',
        'imagecategorie': '',
        'groupe': <dynamic, dynamic>{
          '_id': 'g1',
          'nomgroupe': 'Freelance',
        },
      },
    };

    final s = Service.fromJson(hiveLike);
    expect(s.nomservice, 'Logo');
    expect(s.categorie?.nomcategorie, 'Design');
  });
}
