import 'package:intl/intl.dart';

enum ProviderStatsPeriodPreset {
  thisMonth,
  lastMonth,
  last30Days,
}

class ProviderStatsPeriod {
  const ProviderStatsPeriod({
    required this.preset,
    required this.start,
    required this.end,
  });

  final ProviderStatsPeriodPreset preset;
  final DateTime start;
  final DateTime end;

  static ProviderStatsPeriod resolve(
    ProviderStatsPeriodPreset preset, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final local = DateTime(today.year, today.month, today.day);
    switch (preset) {
      case ProviderStatsPeriodPreset.thisMonth:
        final start = DateTime(local.year, local.month, 1);
        return ProviderStatsPeriod(
          preset: preset,
          start: start,
          end: local,
        );
      case ProviderStatsPeriodPreset.lastMonth:
        final firstThis = DateTime(local.year, local.month, 1);
        final end = firstThis.subtract(const Duration(days: 1));
        final start = DateTime(end.year, end.month, 1);
        return ProviderStatsPeriod(
          preset: preset,
          start: start,
          end: end,
        );
      case ProviderStatsPeriodPreset.last30Days:
        return ProviderStatsPeriod(
          preset: preset,
          start: local.subtract(const Duration(days: 29)),
          end: local,
        );
    }
  }

  String get presetLabel {
    switch (preset) {
      case ProviderStatsPeriodPreset.thisMonth:
        return 'Ce mois-ci';
      case ProviderStatsPeriodPreset.lastMonth:
        return 'Mois dernier';
      case ProviderStatsPeriodPreset.last30Days:
        return '30 derniers jours';
    }
  }

  String get rangeLabelFr {
    final df = DateFormat('d MMMM yyyy', 'fr_FR');
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return df.format(start);
    }
    if (start.year == end.year && start.month == end.month) {
      return 'Du ${start.day} au ${end.day} ${DateFormat('MMMM yyyy', 'fr_FR').format(end)}';
    }
    return 'Du ${df.format(start)} au ${df.format(end)}';
  }
}
