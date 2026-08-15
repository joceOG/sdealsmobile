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

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  static double _asDouble(dynamic v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
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
        final statsParVille =
            statsData['statsParVille'] as List<dynamic>? ?? [];
        final prestationsParMois =
            statsData['prestationsParMois'] as List<dynamic>? ?? [];

        int completedMissions = 0;
        int ongoingMissions = 0;
        int countFromStatut = 0;

        for (var stat in statsParStatut) {
          final count = _asInt(stat is Map ? stat['count'] : null);
          countFromStatut += count;
          final id = (stat is Map ? stat['_id'] : null)?.toString();
          if (id == 'TERMINEE') completedMissions += count;
          if (id == 'EN_COURS' || id == 'ACCEPTEE') {
            ongoingMissions += count;
          }
        }

        final totalMissions = _asInt(
          statsData['totalPrestations'],
          fallback: countFromStatut,
        );
        final revenueTotal = _asDouble(statsData['revenueTotal']);
        final notesMoyenne = _asDouble(statsData['notesMoyenne']);

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
            'total': statsParVille.fold<int>(
              0,
              (sum, v) =>
                  sum + _asInt(v is Map ? v['count'] : null),
            ),
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
          charts: {
            'prestationsParMois': prestationsParMois,
            'statsParVille': statsParVille,
            'statsParStatut': statsParStatut,
            'totalPrestations': totalMissions,
            'revenueTotal': revenueTotal,
          },
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
