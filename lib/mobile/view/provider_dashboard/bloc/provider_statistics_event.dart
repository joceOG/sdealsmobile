// 🎯 ÉVÉNEMENTS POUR LE BLoC STATISTIQUES PRESTATAIRE
abstract class ProviderStatisticsEvent {}

// 📊 CHARGER LES STATISTIQUES DU PRESTATAIRE
class LoadProviderStatistics extends ProviderStatisticsEvent {
  final String prestataireId;
  LoadProviderStatistics(this.prestataireId);
}

// 📊 CHARGER LES STATISTIQUES PAR PÉRIODE
class LoadStatisticsByPeriod extends ProviderStatisticsEvent {
  final String prestataireId;
  final String period; // 'week', 'month', 'year'
  LoadStatisticsByPeriod(this.prestataireId, this.period);
}

// 📊 CHARGER LES STATISTIQUES DE REVENUS
class LoadRevenusStatistics extends ProviderStatisticsEvent {
  final String prestataireId;
  final String period;
  LoadRevenusStatistics(this.prestataireId, this.period);
}

// 📊 CHARGER LES STATISTIQUES DE MISSIONS
class LoadMissionsStatistics extends ProviderStatisticsEvent {
  final String prestataireId;
  final String period;
  LoadMissionsStatistics(this.prestataireId, this.period);
}

// 📊 CHARGER LES STATISTIQUES DE CLIENTS
class LoadClientsStatistics extends ProviderStatisticsEvent {
  final String prestataireId;
  final String period;
  LoadClientsStatistics(this.prestataireId, this.period);
}

// 📊 CHARGER LES STATISTIQUES DE PERFORMANCE
class LoadPerformanceStatistics extends ProviderStatisticsEvent {
  final String prestataireId;
  final String period;
  LoadPerformanceStatistics(this.prestataireId, this.period);
}

// 📊 CHARGER LES GRAPHIQUES
class LoadCharts extends ProviderStatisticsEvent {
  final String prestataireId;
  final String chartType; // 'revenus', 'missions', 'clients', 'performance'
  final String period;
  LoadCharts(this.prestataireId, this.chartType, this.period);
}

// 📊 CHARGER LES RÉCOMPENSES
class LoadAchievements extends ProviderStatisticsEvent {
  final String prestataireId;
  LoadAchievements(this.prestataireId);
}

// 📊 CHARGER LES TOP CLIENTS
class LoadTopClients extends ProviderStatisticsEvent {
  final String prestataireId;
  final int limit;
  LoadTopClients(this.prestataireId, {this.limit = 10});
}

// 📊 CHARGER L'ACTIVITÉ RÉCENTE
class LoadRecentActivity extends ProviderStatisticsEvent {
  final String prestataireId;
  final int limit;
  LoadRecentActivity(this.prestataireId, {this.limit = 10});
}

// 📊 EXPORTER LES STATISTIQUES
class ExportStatistics extends ProviderStatisticsEvent {
  final String prestataireId;
  final String format; // 'pdf', 'excel', 'csv'
  final String period;
  ExportStatistics(this.prestataireId, this.format, this.period);
}

// 📊 ACTUALISER LES STATISTIQUES
class RefreshStatistics extends ProviderStatisticsEvent {
  final String prestataireId;
  RefreshStatistics(this.prestataireId);
}
