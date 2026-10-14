import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/models/provider_statistics_aggregator.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/models/provider_statistics_period.dart';

void main() {
  test('aggregate counts by business dates', () {
    final period = ProviderStatsPeriod(
      preset: ProviderStatsPeriodPreset.thisMonth,
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 10),
    );
    final stats = aggregateProviderPeriodStatistics(
      period: period,
      prestations: [
        {
          'createdAt': '2026-10-02T10:00:00.000Z',
          'statut': 'EN_ATTENTE',
        },
        {
          'createdAt': '2026-09-01T10:00:00.000Z',
          'statut': 'TERMINEE',
          'statutPaiement': 'PAYE',
          'montantTotal': 10000,
          'historiqueStatuts': [
            {'statut': 'TERMINEE', 'date': '2026-10-05T12:00:00.000Z'},
          ],
          'noteClient': 5,
        },
        {
          'createdAt': '2026-10-03T10:00:00.000Z',
          'statut': 'ANNULEE',
          'historiqueStatuts': [
            {'statut': 'ANNULEE', 'date': '2026-10-04T12:00:00.000Z'},
          ],
        },
      ],
    );
    expect(stats.demandesRecues, 2);
    expect(stats.missionsTerminees, 1);
    expect(stats.annulations, 1);
    expect(stats.paiementsRecus.isAvailable, isTrue);
    expect(stats.paiementsRecus.amountFcfa, 10000);
    expect(stats.reviews.count, 1);
  });

  test('paiements unavailable without terminee history', () {
    final period = ProviderStatsPeriod.resolve(
      ProviderStatsPeriodPreset.thisMonth,
      now: DateTime(2026, 10, 10),
    );
    final stats = aggregateProviderPeriodStatistics(
      period: period,
      prestations: [
        {
          'createdAt': '2026-10-01T10:00:00.000Z',
          'statut': 'TERMINEE',
          'statutPaiement': 'PAYE',
          'montantTotal': 5000,
          'updatedAt': '2026-10-02T10:00:00.000Z',
        },
      ],
    );
    expect(stats.paiementsRecus.isAvailable, isFalse);
  });
}
