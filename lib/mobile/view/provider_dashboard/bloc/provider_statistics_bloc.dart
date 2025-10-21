import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'provider_statistics_event.dart';
import 'provider_statistics_state.dart';

// 🎯 BLoC POUR GÉRER LES STATISTIQUES PRESTATAIRE
class ProviderStatisticsBloc
    extends Bloc<ProviderStatisticsEvent, ProviderStatisticsState> {
  final Random _random = Random();

  ProviderStatisticsBloc() : super(ProviderStatisticsInitial()) {
    // 📊 CHARGER LES STATISTIQUES DU PRESTATAIRE
    on<LoadProviderStatistics>((event, emit) async {
      emit(ProviderStatisticsLoading());
      try {
        // Simulation d'un délai API
        await Future.delayed(const Duration(milliseconds: 1000));

        // Données simulées des revenus
        final revenus = {
          'total': 125000.0 + _random.nextDouble() * 50000,
          'pending': 25000.0 + _random.nextDouble() * 10000,
          'averagePerMission': 5200.0 + _random.nextDouble() * 1000,
          'target': 150000.0,
          'achievement': 0.83,
          'growth': 0.15,
          'breakdown': {
            'plomberie': 45000.0,
            'electricite': 35000.0,
            'peinture': 25000.0,
            'autres': 20000.0,
          },
        };

        // Données simulées des missions
        final missions = {
          'total': 24 + _random.nextInt(10),
          'completed': 22 + _random.nextInt(8),
          'ongoing': 2 + _random.nextInt(3),
          'successRate': 0.96,
          'averageTime': 2.5,
          'satisfaction': 4.8,
          'growth': 0.12,
        };

        // Données simulées des clients
        final clients = {
          'total': 18 + _random.nextInt(5),
          'loyal': 12 + _random.nextInt(3),
          'new': 6 + _random.nextInt(2),
          'satisfaction': 4.8,
          'retention': 0.67,
          'growth': 0.18,
        };

        // Données simulées de la performance
        final performance = {
          'efficiency': 0.92,
          'punctuality': 0.98,
          'quality': 4.8,
          'availability': 0.95,
          'responseTime': 2.0,
          'growth': 0.08,
        };

        // Récompenses simulées
        final achievements = [
          {
            'id': '1',
            'title': 'Expert',
            'description': 'Plus de 20 missions terminées',
            'icon': 'star',
            'color': 'amber',
            'unlocked': true,
            'progress': 1.0,
          },
          {
            'id': '2',
            'title': 'Fiable',
            'description': 'Note moyenne supérieure à 4.5',
            'icon': 'verified',
            'color': 'green',
            'unlocked': true,
            'progress': 1.0,
          },
          {
            'id': '3',
            'title': 'Rapide',
            'description': 'Temps de réponse inférieur à 2h',
            'icon': 'speed',
            'color': 'blue',
            'unlocked': true,
            'progress': 1.0,
          },
        ];

        // Top clients simulés
        final topClients = [
          {
            'id': '1',
            'name': 'Marie K.',
            'missions': 4,
            'amount': 45000.0,
            'rating': 5.0,
            'lastMission': '2024-01-15',
          },
          {
            'id': '2',
            'name': 'Paul M.',
            'missions': 3,
            'amount': 35000.0,
            'rating': 4.8,
            'lastMission': '2024-01-12',
          },
          {
            'id': '3',
            'name': 'Ahmed T.',
            'missions': 2,
            'amount': 25000.0,
            'rating': 4.5,
            'lastMission': '2024-01-10',
          },
        ];

        // Activité récente simulée
        final recentActivity = [
          {
            'id': '1',
            'type': 'mission_completed',
            'title': 'Mission terminée',
            'description': 'Réparation plomberie - Client Marie',
            'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
            'icon': 'check_circle',
            'color': 'green',
          },
          {
            'id': '2',
            'type': 'new_mission',
            'title': 'Nouvelle mission',
            'description': 'Installation électrique - Client Paul',
            'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
            'icon': 'assignment',
            'color': 'blue',
          },
          {
            'id': '3',
            'type': 'review_received',
            'title': 'Avis reçu',
            'description': '5 étoiles - Excellent travail !',
            'timestamp': DateTime.now().subtract(const Duration(days: 1)),
            'icon': 'star',
            'color': 'amber',
          },
        ];

        // Graphiques simulés
        final charts = {
          'revenus': {
            'type': 'line',
            'data': List.generate(
                30,
                (index) => {
                      'date':
                          DateTime.now().subtract(Duration(days: 29 - index)),
                      'value': 1000 + _random.nextDouble() * 2000,
                    }),
          },
          'missions': {
            'type': 'bar',
            'data': List.generate(
                7,
                (index) => {
                      'day': [
                        'Lun',
                        'Mar',
                        'Mer',
                        'Jeu',
                        'Ven',
                        'Sam',
                        'Dim'
                      ][index],
                      'value': _random.nextInt(5) + 1,
                    }),
          },
          'clients': {
            'type': 'pie',
            'data': [
              {'label': 'Nouveaux', 'value': 6, 'color': 'blue'},
              {'label': 'Fidèles', 'value': 12, 'color': 'green'},
            ],
          },
          'performance': {
            'type': 'radar',
            'data': {
              'efficiency': 0.92,
              'punctuality': 0.98,
              'quality': 0.96,
              'availability': 0.95,
            },
          },
        };

        emit(ProviderStatisticsLoaded(
          revenus: revenus,
          missions: missions,
          clients: clients,
          performance: performance,
          achievements: achievements,
          topClients: topClients,
          recentActivity: recentActivity,
          charts: charts,
        ));
      } catch (e) {
        emit(ProviderStatisticsError(
            message: 'Erreur lors du chargement des statistiques: $e'));
      }
    });

    // 📊 CHARGER LES STATISTIQUES PAR PÉRIODE
    on<LoadStatisticsByPeriod>((event, emit) async {
      emit(ProviderStatisticsLoading());
      try {
        await Future.delayed(const Duration(milliseconds: 800));

        // Simulation de données par période
        final multiplier = event.period == 'week'
            ? 0.25
            : event.period == 'month'
                ? 1.0
                : 12.0;

        final revenus = {
          'total': (125000.0 * multiplier) + _random.nextDouble() * 10000,
          'growth': 0.15 + _random.nextDouble() * 0.1,
        };

        emit(RevenusStatisticsLoaded(
          revenus: revenus,
          revenusChart: [],
          breakdown: {},
        ));
      } catch (e) {
        emit(ProviderStatisticsError(
            message: 'Erreur lors du chargement par période: $e'));
      }
    });

    // 📊 CHARGER LES STATISTIQUES DE REVENUS
    on<LoadRevenusStatistics>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        final revenus = {
          'total': 125000.0 + _random.nextDouble() * 50000,
          'pending': 25000.0 + _random.nextDouble() * 10000,
          'averagePerMission': 5200.0 + _random.nextDouble() * 1000,
          'target': 150000.0,
          'achievement': 0.83,
          'growth': 0.15,
        };

        final revenusChart = List.generate(
            30,
            (index) => {
                  'date': DateTime.now().subtract(Duration(days: 29 - index)),
                  'value': 1000 + _random.nextDouble() * 2000,
                });

        final breakdown = {
          'plomberie': 45000.0,
          'electricite': 35000.0,
          'peinture': 25000.0,
          'autres': 20000.0,
        };

        emit(RevenusStatisticsLoaded(
          revenus: revenus,
          revenusChart: revenusChart,
          breakdown: breakdown,
        ));
      } catch (e) {
        emit(ProviderStatisticsError(
            message: 'Erreur lors du chargement des revenus: $e'));
      }
    });

    // 📊 CHARGER LES STATISTIQUES DE MISSIONS
    on<LoadMissionsStatistics>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        final missions = {
          'total': 24 + _random.nextInt(10),
          'completed': 22 + _random.nextInt(8),
          'ongoing': 2 + _random.nextInt(3),
          'successRate': 0.96,
          'averageTime': 2.5,
          'satisfaction': 4.8,
          'growth': 0.12,
        };

        final missionsChart = List.generate(
            7,
            (index) => {
                  'day': [
                    'Lun',
                    'Mar',
                    'Mer',
                    'Jeu',
                    'Ven',
                    'Sam',
                    'Dim'
                  ][index],
                  'value': _random.nextInt(5) + 1,
                });

        final timeline = [
          {
            'id': '1',
            'type': 'mission_completed',
            'title': 'Mission terminée',
            'description': 'Réparation plomberie - Client Marie',
            'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
            'icon': 'check_circle',
            'color': 'green',
          },
          {
            'id': '2',
            'type': 'new_mission',
            'title': 'Nouvelle mission',
            'description': 'Installation électrique - Client Paul',
            'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
            'icon': 'assignment',
            'color': 'blue',
          },
        ];

        emit(MissionsStatisticsLoaded(
          missions: missions,
          missionsChart: missionsChart,
          timeline: timeline,
        ));
      } catch (e) {
        emit(ProviderStatisticsError(
            message: 'Erreur lors du chargement des missions: $e'));
      }
    });

    // 📊 CHARGER LES STATISTIQUES DE CLIENTS
    on<LoadClientsStatistics>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        final clients = {
          'total': 18 + _random.nextInt(5),
          'loyal': 12 + _random.nextInt(3),
          'new': 6 + _random.nextInt(2),
          'satisfaction': 4.8,
          'retention': 0.67,
          'growth': 0.18,
        };

        final clientsChart = [
          {'label': 'Nouveaux', 'value': 6, 'color': 'blue'},
          {'label': 'Fidèles', 'value': 12, 'color': 'green'},
        ];

        final topClients = [
          {
            'id': '1',
            'name': 'Marie K.',
            'missions': 4,
            'amount': 45000.0,
            'rating': 5.0,
          },
          {
            'id': '2',
            'name': 'Paul M.',
            'missions': 3,
            'amount': 35000.0,
            'rating': 4.8,
          },
        ];

        emit(ClientsStatisticsLoaded(
          clients: clients,
          clientsChart: clientsChart,
          topClients: topClients,
        ));
      } catch (e) {
        emit(ProviderStatisticsError(
            message: 'Erreur lors du chargement des clients: $e'));
      }
    });

    // 📊 CHARGER LES STATISTIQUES DE PERFORMANCE
    on<LoadPerformanceStatistics>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        final performance = {
          'efficiency': 0.92,
          'punctuality': 0.98,
          'quality': 4.8,
          'availability': 0.95,
          'responseTime': 2.0,
          'growth': 0.08,
        };

        final performanceChart = [
          {
            'efficiency': 0.92,
            'punctuality': 0.98,
            'quality': 0.96,
            'availability': 0.95,
          }
        ];

        final achievements = [
          {
            'id': '1',
            'title': 'Expert',
            'description': 'Plus de 20 missions terminées',
            'icon': 'star',
            'color': 'amber',
            'unlocked': true,
          },
          {
            'id': '2',
            'title': 'Fiable',
            'description': 'Note moyenne supérieure à 4.5',
            'icon': 'verified',
            'color': 'green',
            'unlocked': true,
          },
        ];

        emit(PerformanceStatisticsLoaded(
          performance: performance,
          performanceChart: performanceChart,
          achievements: achievements,
        ));
      } catch (e) {
        emit(ProviderStatisticsError(
            message: 'Erreur lors du chargement de la performance: $e'));
      }
    });

    // 📊 CHARGER LES GRAPHIQUES
    on<LoadCharts>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        List<dynamic> chartData = [];
        Map<String, dynamic> chartConfig = {};

        switch (event.chartType) {
          case 'revenus':
            chartData = List.generate(
                30,
                (index) => {
                      'date':
                          DateTime.now().subtract(Duration(days: 29 - index)),
                      'value': 1000 + _random.nextDouble() * 2000,
                    });
            chartConfig = {'type': 'line', 'color': 'green'};
            break;
          case 'missions':
            chartData = List.generate(
                7,
                (index) => {
                      'day': [
                        'Lun',
                        'Mar',
                        'Mer',
                        'Jeu',
                        'Ven',
                        'Sam',
                        'Dim'
                      ][index],
                      'value': _random.nextInt(5) + 1,
                    });
            chartConfig = {'type': 'bar', 'color': 'blue'};
            break;
          case 'clients':
            chartData = [
              {'label': 'Nouveaux', 'value': 6, 'color': 'blue'},
              {'label': 'Fidèles', 'value': 12, 'color': 'green'},
            ];
            chartConfig = {
              'type': 'pie',
              'colors': ['blue', 'green']
            };
            break;
          case 'performance':
            chartData = [
              {
                'efficiency': 0.92,
                'punctuality': 0.98,
                'quality': 0.96,
                'availability': 0.95,
              }
            ];
            chartConfig = {'type': 'radar', 'color': 'purple'};
            break;
        }

        emit(ChartsLoaded(
          chartType: event.chartType,
          chartData: chartData,
          chartConfig: chartConfig,
        ));
      } catch (e) {
        emit(ProviderStatisticsError(
            message: 'Erreur lors du chargement des graphiques: $e'));
      }
    });

    // 📊 CHARGER LES RÉCOMPENSES
    on<LoadAchievements>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        final achievements = [
          {
            'id': '1',
            'title': 'Expert',
            'description': 'Plus de 20 missions terminées',
            'icon': 'star',
            'color': 'amber',
            'unlocked': true,
            'progress': 1.0,
          },
          {
            'id': '2',
            'title': 'Fiable',
            'description': 'Note moyenne supérieure à 4.5',
            'icon': 'verified',
            'color': 'green',
            'unlocked': true,
            'progress': 1.0,
          },
          {
            'id': '3',
            'title': 'Rapide',
            'description': 'Temps de réponse inférieur à 2h',
            'icon': 'speed',
            'color': 'blue',
            'unlocked': true,
            'progress': 1.0,
          },
        ];

        final unlockedAchievements =
            achievements.where((a) => a['unlocked'] == true).toList();
        final lockedAchievements = [];

        emit(AchievementsLoaded(
          achievements: achievements,
          unlockedAchievements: unlockedAchievements,
          lockedAchievements: lockedAchievements,
        ));
      } catch (e) {
        emit(ProviderStatisticsError(
            message: 'Erreur lors du chargement des récompenses: $e'));
      }
    });

    // 📊 CHARGER LES TOP CLIENTS
    on<LoadTopClients>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        final topClients = [
          {
            'id': '1',
            'name': 'Marie K.',
            'missions': 4,
            'amount': 45000.0,
            'rating': 5.0,
            'lastMission': '2024-01-15',
          },
          {
            'id': '2',
            'name': 'Paul M.',
            'missions': 3,
            'amount': 35000.0,
            'rating': 4.8,
            'lastMission': '2024-01-12',
          },
          {
            'id': '3',
            'name': 'Ahmed T.',
            'missions': 2,
            'amount': 25000.0,
            'rating': 4.5,
            'lastMission': '2024-01-10',
          },
        ];

        emit(TopClientsLoaded(
          topClients: topClients,
          totalClients: 18,
          averageSpending: 35000.0,
        ));
      } catch (e) {
        emit(ProviderStatisticsError(
            message: 'Erreur lors du chargement des top clients: $e'));
      }
    });

    // 📊 CHARGER L'ACTIVITÉ RÉCENTE
    on<LoadRecentActivity>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        final activities = [
          {
            'id': '1',
            'type': 'mission_completed',
            'title': 'Mission terminée',
            'description': 'Réparation plomberie - Client Marie',
            'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
            'icon': 'check_circle',
            'color': 'green',
          },
          {
            'id': '2',
            'type': 'new_mission',
            'title': 'Nouvelle mission',
            'description': 'Installation électrique - Client Paul',
            'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
            'icon': 'assignment',
            'color': 'blue',
          },
          {
            'id': '3',
            'type': 'review_received',
            'title': 'Avis reçu',
            'description': '5 étoiles - Excellent travail !',
            'timestamp': DateTime.now().subtract(const Duration(days: 1)),
            'icon': 'star',
            'color': 'amber',
          },
        ];

        emit(RecentActivityLoaded(
          activities: activities,
          totalActivities: activities.length,
          lastUpdate: DateTime.now(),
        ));
      } catch (e) {
        emit(ProviderStatisticsError(
            message: 'Erreur lors du chargement de l\'activité: $e'));
      }
    });

    // 📊 EXPORTER LES STATISTIQUES
    on<ExportStatistics>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 1000));

        final fileName =
            'statistiques_${event.prestataireId}_${DateTime.now().millisecondsSinceEpoch}.${event.format}';
        final filePath = '/downloads/$fileName';

        emit(StatisticsExported(
          format: event.format,
          filePath: filePath,
          fileName: fileName,
        ));
      } catch (e) {
        emit(ProviderStatisticsError(message: 'Erreur lors de l\'export: $e'));
      }
    });

    // 📊 ACTUALISER LES STATISTIQUES
    on<RefreshStatistics>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        final updatedStatistics = {
          'lastRefresh': DateTime.now().toIso8601String(),
          'prestataireId': event.prestataireId,
        };

        emit(StatisticsRefreshed(
          updatedStatistics: updatedStatistics,
          refreshTime: DateTime.now(),
        ));
      } catch (e) {
        emit(ProviderStatisticsError(
            message: 'Erreur lors de l\'actualisation: $e'));
      }
    });
  }
}
