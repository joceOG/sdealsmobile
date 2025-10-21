// 🎯 ÉTATS POUR LE BLoC STATISTIQUES PRESTATAIRE
abstract class ProviderStatisticsState {}

// 📊 ÉTAT INITIAL
class ProviderStatisticsInitial extends ProviderStatisticsState {}

// 📊 CHARGEMENT EN COURS
class ProviderStatisticsLoading extends ProviderStatisticsState {}

// 📊 STATISTIQUES CHARGÉES
class ProviderStatisticsLoaded extends ProviderStatisticsState {
  final Map<String, dynamic> revenus;
  final Map<String, dynamic> missions;
  final Map<String, dynamic> clients;
  final Map<String, dynamic> performance;
  final List<dynamic> achievements;
  final List<dynamic> topClients;
  final List<dynamic> recentActivity;
  final Map<String, dynamic> charts;

  ProviderStatisticsLoaded({
    required this.revenus,
    required this.missions,
    required this.clients,
    required this.performance,
    required this.achievements,
    required this.topClients,
    required this.recentActivity,
    required this.charts,
  });

  ProviderStatisticsLoaded copyWith({
    Map<String, dynamic>? revenus,
    Map<String, dynamic>? missions,
    Map<String, dynamic>? clients,
    Map<String, dynamic>? performance,
    List<dynamic>? achievements,
    List<dynamic>? topClients,
    List<dynamic>? recentActivity,
    Map<String, dynamic>? charts,
  }) {
    return ProviderStatisticsLoaded(
      revenus: revenus ?? this.revenus,
      missions: missions ?? this.missions,
      clients: clients ?? this.clients,
      performance: performance ?? this.performance,
      achievements: achievements ?? this.achievements,
      topClients: topClients ?? this.topClients,
      recentActivity: recentActivity ?? this.recentActivity,
      charts: charts ?? this.charts,
    );
  }
}

// 📊 STATISTIQUES DE REVENUS CHARGÉES
class RevenusStatisticsLoaded extends ProviderStatisticsState {
  final Map<String, dynamic> revenus;
  final List<dynamic> revenusChart;
  final Map<String, dynamic> breakdown;

  RevenusStatisticsLoaded({
    required this.revenus,
    required this.revenusChart,
    required this.breakdown,
  });
}

// 📊 STATISTIQUES DE MISSIONS CHARGÉES
class MissionsStatisticsLoaded extends ProviderStatisticsState {
  final Map<String, dynamic> missions;
  final List<dynamic> missionsChart;
  final List<dynamic> timeline;

  MissionsStatisticsLoaded({
    required this.missions,
    required this.missionsChart,
    required this.timeline,
  });
}

// 📊 STATISTIQUES DE CLIENTS CHARGÉES
class ClientsStatisticsLoaded extends ProviderStatisticsState {
  final Map<String, dynamic> clients;
  final List<dynamic> clientsChart;
  final List<dynamic> topClients;

  ClientsStatisticsLoaded({
    required this.clients,
    required this.clientsChart,
    required this.topClients,
  });
}

// 📊 STATISTIQUES DE PERFORMANCE CHARGÉES
class PerformanceStatisticsLoaded extends ProviderStatisticsState {
  final Map<String, dynamic> performance;
  final List<dynamic> performanceChart;
  final List<dynamic> achievements;

  PerformanceStatisticsLoaded({
    required this.performance,
    required this.performanceChart,
    required this.achievements,
  });
}

// 📊 GRAPHIQUES CHARGÉS
class ChartsLoaded extends ProviderStatisticsState {
  final String chartType;
  final List<dynamic> chartData;
  final Map<String, dynamic> chartConfig;

  ChartsLoaded({
    required this.chartType,
    required this.chartData,
    required this.chartConfig,
  });
}

// 📊 RÉCOMPENSES CHARGÉES
class AchievementsLoaded extends ProviderStatisticsState {
  final List<dynamic> achievements;
  final List<dynamic> unlockedAchievements;
  final List<dynamic> lockedAchievements;

  AchievementsLoaded({
    required this.achievements,
    required this.unlockedAchievements,
    required this.lockedAchievements,
  });
}

// 📊 TOP CLIENTS CHARGÉS
class TopClientsLoaded extends ProviderStatisticsState {
  final List<dynamic> topClients;
  final int totalClients;
  final double averageSpending;

  TopClientsLoaded({
    required this.topClients,
    required this.totalClients,
    required this.averageSpending,
  });
}

// 📊 ACTIVITÉ RÉCENTE CHARGÉE
class RecentActivityLoaded extends ProviderStatisticsState {
  final List<dynamic> activities;
  final int totalActivities;
  final DateTime lastUpdate;

  RecentActivityLoaded({
    required this.activities,
    required this.totalActivities,
    required this.lastUpdate,
  });
}

// 📊 STATISTIQUES EXPORTÉES
class StatisticsExported extends ProviderStatisticsState {
  final String format;
  final String filePath;
  final String fileName;

  StatisticsExported({
    required this.format,
    required this.filePath,
    required this.fileName,
  });
}

// 📊 STATISTIQUES ACTUALISÉES
class StatisticsRefreshed extends ProviderStatisticsState {
  final Map<String, dynamic> updatedStatistics;
  final DateTime refreshTime;

  StatisticsRefreshed({
    required this.updatedStatistics,
    required this.refreshTime,
  });
}

// 📊 ERREUR
class ProviderStatisticsError extends ProviderStatisticsState {
  final String message;
  final String? errorCode;
  final Map<String, dynamic>? errorDetails;

  ProviderStatisticsError({
    required this.message,
    this.errorCode,
    this.errorDetails,
  });
}
