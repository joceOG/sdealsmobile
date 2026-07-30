import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'provider_statistics_event.dart';
import 'provider_statistics_state.dart';

/// Stats prestataire : uniquement `/prestations/stats` réel.
/// Les handlers secondaires (Random/Marie K.) émettent une erreur honnête.
class ProviderStatisticsBloc
    extends Bloc<ProviderStatisticsEvent, ProviderStatisticsState> {
  final ApiClient _apiClient = ApiClient();
  String? _currentToken;

  void setToken(String token) {
    _currentToken = token;
  }

  static const _unavailable =
      'Cette vue stats n\'est pas encore branchée au serveur';

  ProviderStatisticsBloc() : super(ProviderStatisticsInitial()) {
    on<LoadProviderStatistics>((event, emit) async {
      emit(ProviderStatisticsLoading());
      try {
        final response = await _apiClient.get(
          '/prestations/stats?prestataireId=${event.prestataireId}',
          token: _currentToken,
        );

        Map<String, dynamic> statsData = {};
        if (response.statusCode == 200) {
          statsData = jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          emit(ProviderStatisticsError(
              message: 'Erreur stats (${response.statusCode})'));
          return;
        }

        final statsParStatut =
            statsData['statsParStatut'] as List<dynamic>? ?? [];
        int totalMissions = 0;
        int completedMissions = 0;
        int ongoingMissions = 0;

        for (var stat in statsParStatut) {
          final count = (stat['count'] as int? ?? 0);
          totalMissions += count;
          if (stat['_id'] == 'TERMINEE') completedMissions += count;
          if (stat['_id'] == 'EN_COURS' || stat['_id'] == 'ACCEPTEE') {
            ongoingMissions += count;
          }
        }

        final revenueTotal = (statsData['revenueTotal'] ?? 0).toDouble();
        final notesMoyenne = (statsData['notesMoyenne'] ?? 0).toDouble();

        emit(ProviderStatisticsLoaded(
          revenus: {
            'total': revenueTotal,
            'pending': 0.0,
            'averagePerMission':
                totalMissions > 0 ? revenueTotal / totalMissions : 0.0,
            'target': null,
            'achievement': null,
            'growth': null,
            'breakdown': statsData['revenueParService'] ?? {},
          },
          missions: {
            'total': totalMissions,
            'completed': completedMissions,
            'ongoing': ongoingMissions,
            'successRate':
                totalMissions > 0 ? completedMissions / totalMissions : 0.0,
            'averageTime': statsData['dureeMoyenne'],
            'satisfaction': notesMoyenne,
            'growth': null,
          },
          clients: {
            'total': statsData['nombreClients'] ?? 0,
            'loyal': null,
            'new': null,
            'satisfaction': notesMoyenne,
            'retention': null,
            'growth': null,
          },
          performance: {
            'efficiency': null,
            'punctuality': null,
            'quality': notesMoyenne > 0 ? notesMoyenne / 5.0 : null,
            'availability': null,
            'responseTime': null,
            'growth': null,
          },
          achievements: const [],
          topClients: const [],
          recentActivity: const [],
          charts: const {},
        ));
      } catch (e) {
        emit(ProviderStatisticsError(
            message: 'Erreur lors du chargement des statistiques: $e'));
      }
    });

    on<LoadStatisticsByPeriod>(
        (event, emit) async => emit(ProviderStatisticsError(message: _unavailable)));
    on<LoadRevenusStatistics>(
        (event, emit) async => emit(ProviderStatisticsError(message: _unavailable)));
    on<LoadMissionsStatistics>(
        (event, emit) async => emit(ProviderStatisticsError(message: _unavailable)));
    on<LoadClientsStatistics>(
        (event, emit) async => emit(ProviderStatisticsError(message: _unavailable)));
    on<LoadPerformanceStatistics>(
        (event, emit) async => emit(ProviderStatisticsError(message: _unavailable)));
    on<LoadCharts>(
        (event, emit) async => emit(ProviderStatisticsError(message: _unavailable)));
    on<LoadAchievements>(
        (event, emit) async => emit(ProviderStatisticsError(message: _unavailable)));
    on<LoadTopClients>(
        (event, emit) async => emit(ProviderStatisticsError(message: _unavailable)));
    on<LoadRecentActivity>(
        (event, emit) async => emit(ProviderStatisticsError(message: _unavailable)));
  }
}
