import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_reviews_screen.dart';

void main() {
  group('avisAuthorLabel', () {
    test('formats author with initial', () {
      expect(
        avisAuthorLabel({
          'auteur': {'prenom': 'Aïcha', 'nom': 'Kouassi'},
        }),
        'Aïcha K.',
      );
    });

    test('anonyme hides identity', () {
      expect(
        avisAuthorLabel({
          'anonyme': true,
          'auteur': {'prenom': 'A', 'nom': 'B'},
        }),
        'Client',
      );
    });
  });
}
