import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/models/provider_portfolio.dart';

void main() {
  group('parseProviderPortfolioFromPrestataireJson', () {
    test('portfolioItems structurés', () {
      final data = parseProviderPortfolioFromPrestataireJson({
        'portfolioItems': [
          {
            'title': 'Portail',
            'imageUrl': 'https://cdn.example/a.jpg',
            'images': ['https://cdn.example/b.jpg'],
          },
        ],
      });
      expect(data.entries.length, 1);
      expect(data.entries.first.title, 'Portail');
      expect(data.entries.first.photoCount, 2);
      expect(data.photosOnly, isFalse);
    });

    test('liste plate de photos sans titres inventés', () {
      final data = parseProviderPortfolioFromPrestataireJson({
        'portfolioPhotos': [
          'https://cdn.example/1.jpg',
          'https://cdn.example/2.jpg',
        ],
      });
      expect(data.entries.length, 2);
      expect(data.photosOnly, isTrue);
      expect(data.entries.every((e) => !e.hasDisplayTitle), isTrue);
    });

    test('vide si aucun champ portfolio', () {
      final data = parseProviderPortfolioFromPrestataireJson({
        'description': 'Soudeur',
      });
      expect(data.isEmpty, isTrue);
    });
  });
}
