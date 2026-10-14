import 'provider_statistics_period.dart';

String _monthShort(int month) {
  const names = [
    'jan.',
    'fév.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  if (month < 1 || month > 12) return '';
  return names[month - 1];
}

/// Valeur affichable ou indisponibilité explicite (pas de placeholder fictif).
class StatAmountMetric {
  const StatAmountMetric.available(this.amountFcfa)
      : unavailableReason = null;
  const StatAmountMetric.unavailable(this.unavailableReason) : amountFcfa = null;

  final double? amountFcfa;
  final String? unavailableReason;

  bool get isAvailable => amountFcfa != null;
}

class DemandesBucket {
  const DemandesBucket({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;
}

class ReviewsPeriodSummary {
  const ReviewsPeriodSummary({
    required this.count,
    this.averageNote,
  });

  final int count;
  final double? averageNote;
}

class ProviderPeriodStatistics {
  const ProviderPeriodStatistics({
    required this.period,
    required this.loadedAt,
    required this.demandesRecues,
    required this.missionsTerminees,
    required this.annulations,
    required this.paiementsRecus,
    required this.demandesBuckets,
    required this.demandesDistributionReliable,
    required this.reviews,
  });

  final ProviderStatsPeriod period;
  final DateTime loadedAt;
  final int demandesRecues;
  final int missionsTerminees;
  final int annulations;
  final StatAmountMetric paiementsRecus;
  final List<DemandesBucket> demandesBuckets;
  final bool demandesDistributionReliable;
  final ReviewsPeriodSummary reviews;
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw.toString());
}

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _dayEnd(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

bool _inPeriod(DateTime? date, DateTime start, DateTime end) {
  if (date == null) return false;
  final s = _dayStart(start);
  final e = _dayEnd(end);
  return !date.isBefore(s) && !date.isAfter(e);
}

DateTime? _createdAt(Map<String, dynamic> m) =>
    _parseDate(m['createdAt'] ?? m['date']);

DateTime? _statusDateFromHistory(
  Map<String, dynamic> m,
  String statut,
) {
  final hist = m['historiqueStatuts'];
  if (hist is List) {
    DateTime? latest;
    for (final entry in hist) {
      if (entry is! Map) continue;
      if (entry['statut']?.toString() != statut) continue;
      final d = _parseDate(entry['date']);
      if (d != null && (latest == null || d.isAfter(latest))) latest = d;
    }
    if (latest != null) return latest;
  }
  if (m['statut']?.toString() == statut) {
    return _parseDate(m['updatedAt']) ?? _parseDate(m['datePrestation']);
  }
  return null;
}

DateTime? _completedAt(Map<String, dynamic> m) =>
    _statusDateFromHistory(m, 'TERMINEE');

bool _hasExplicitTermineeHistory(Map<String, dynamic> m) {
  final hist = m['historiqueStatuts'];
  if (hist is! List) return false;
  for (final entry in hist) {
    if (entry is Map && entry['statut']?.toString() == 'TERMINEE') {
      return _parseDate(entry['date']) != null;
    }
  }
  return false;
}

double _amount(Map<String, dynamic> m) {
  final v = m['montantTotal'];
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

List<DemandesBucket> _buildDemandesBuckets({
  required List<Map<String, dynamic>> prestations,
  required DateTime start,
  required DateTime end,
}) {
  final startDay = _dayStart(start);
  final endDay = _dayStart(end);
  final totalDays = endDay.difference(startDay).inDays + 1;
  if (totalDays <= 0) return const [];

  const bucketCount = 3;
  final buckets = List.generate(bucketCount, (_) => 0);
  final labels = <String>[];

  for (var i = 0; i < bucketCount; i++) {
    final from = startDay.add(Duration(days: (totalDays * i / bucketCount).floor()));
    final to = i == bucketCount - 1
        ? endDay
        : startDay.add(
            Duration(days: (totalDays * (i + 1) / bucketCount).floor() - 1),
          );
    labels.add('${from.day} – ${to.day} ${_monthShort(from.month)}');
  }

  for (final m in prestations) {
    final created = _createdAt(m);
    if (!_inPeriod(created, start, end)) continue;
    final day = _dayStart(created!);
    final offset = day.difference(startDay).inDays.clamp(0, totalDays - 1);
    final idx = (offset * bucketCount / totalDays).floor().clamp(0, bucketCount - 1);
    buckets[idx]++;
  }

  return List.generate(
    bucketCount,
    (i) => DemandesBucket(label: labels[i], count: buckets[i]),
  );
}

/// Agrège les indicateurs période depuis les prestations du prestataire.
ProviderPeriodStatistics aggregateProviderPeriodStatistics({
  required List<Map<String, dynamic>> prestations,
  required ProviderStatsPeriod period,
  DateTime? loadedAt,
}) {
  final start = period.start;
  final end = period.end;
  var demandes = 0;
  var terminees = 0;
  var annulations = 0;
  double paiementsSum = 0;
  var paiementsCount = 0;
  var paiementsReliable = true;

  var reviewCount = 0;
  var reviewSum = 0.0;

  for (final m in prestations) {
    final created = _createdAt(m);
    if (_inPeriod(created, start, end)) {
      demandes++;
    }

    final completed = _completedAt(m);
    if (m['statut']?.toString() == 'TERMINEE' &&
        _inPeriod(completed, start, end)) {
      terminees++;
      final note = m['noteClient'];
      if (note is num && note > 0) {
        reviewCount++;
        reviewSum += note.toDouble();
      }
    }

    final statut = m['statut']?.toString() ?? '';
    if (statut == 'ANNULEE' || statut == 'REFUSEE') {
      final cancelDate = _statusDateFromHistory(m, statut) ??
          _parseDate(m['updatedAt']);
      if (_inPeriod(cancelDate, start, end)) {
        annulations++;
      }
    }

    if (m['statutPaiement']?.toString() == 'PAYE' &&
        m['statut']?.toString() == 'TERMINEE') {
      final payDate = _completedAt(m);
      if (_inPeriod(payDate, start, end)) {
        if (!_hasExplicitTermineeHistory(m)) {
          paiementsReliable = false;
        } else {
          paiementsSum += _amount(m);
          paiementsCount++;
        }
      }
    }
  }

  if (paiementsCount == 0 && paiementsReliable) {
    paiementsSum = 0;
  }

  final buckets = _buildDemandesBuckets(
    prestations: prestations,
    start: start,
    end: end,
  );
  final bucketSum = buckets.fold<int>(0, (a, b) => a + b.count);
  final distributionReliable = bucketSum == demandes;

  final paiementsMetric = paiementsReliable
      ? StatAmountMetric.available(paiementsSum)
      : const StatAmountMetric.unavailable(
          'Date de paiement non traçable pour toutes les missions payées.',
        );

  return ProviderPeriodStatistics(
    period: period,
    loadedAt: loadedAt ?? DateTime.now(),
    demandesRecues: demandes,
    missionsTerminees: terminees,
    annulations: annulations,
    paiementsRecus: paiementsMetric,
    demandesBuckets: distributionReliable ? buckets : const [],
    demandesDistributionReliable: distributionReliable && demandes > 0,
    reviews: ReviewsPeriodSummary(
      count: reviewCount,
      averageNote: reviewCount > 0 ? reviewSum / reviewCount : null,
    ),
  );
}
