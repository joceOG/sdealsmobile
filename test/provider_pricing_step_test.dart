import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/steps/provider_pricing_step.dart';

void main() {
  group('parseProviderDailyRateText', () {
    test('vide → null', () {
      expect(parseProviderDailyRateText(''), isNull);
      expect(parseProviderDailyRateText('   '), isNull);
    });

    test('montant formaté → entier', () {
      expect(parseProviderDailyRateText('15 000'), 15000);
    });

    test('zéro explicite', () {
      expect(parseProviderDailyRateText('0'), 0);
    });
  });
}
