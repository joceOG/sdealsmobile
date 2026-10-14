import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';

import '../models/provider_statistics_aggregator.dart';
import '../models/provider_statistics_period.dart';
import 'provider_statistics_event.dart';
import 'provider_statistics_state.dart';

/// Stats prestataire : agrégation depuis `/prestations/prestataire/:id` (propriétaire).
class ProviderStatisticsBloc
    extends Bloc<ProviderStatisticsEvent, ProviderStatisticsState> {
  ProviderStatisticsBloc() : super(ProviderStatisticsInitial()) {
    on<LoadProviderStatistics>(_onLoad);
    on<RefreshStatistics>((event, emit) async {
      add(LoadProviderStatistics(
        event.prestataireId,
        periodPreset: _lastPreset,
      ));
    });
    on<LoadStatisticsByPeriod>(
        (event, emit) async => emit(_unavailable(event.prestataireId)));
    on<LoadRevenusStatistics>(
        (event, emit) async => emit(_unavailable(event.prestataireId)));
    on<LoadMissionsStatistics>(
        (event, emit) async => emit(_unavailable(event.prestataireId)));
    on<LoadClientsStatistics>(
        (event, emit) async => emit(_unavailable(event.prestataireId)));
    on<LoadPerformanceStatistics>(
        (event, emit) async => emit(_unavailable(event.prestataireId)));
    on<LoadCharts>(
        (event, emit) async => emit(_unavailable(event.prestataireId)));
    on<LoadAchievements>(
        (event, emit) async => emit(_unavailable(event.prestataireId)));
    on<LoadTopClients>(
        (event, emit) async => emit(_unavailable(event.prestataireId)));
    on<LoadRecentActivity>(
        (event, emit) async => emit(_unavailable(event.prestataireId)));
  }

  final ApiClient _apiClient = ApiClient();
  String? _token;
  ProviderStatsPeriodPreset _lastPreset = ProviderStatsPeriodPreset.thisMonth;

  void setToken(String token) {
    _token = token.isNotEmpty ? token : null;
  }

  ProviderStatisticsError _unavailable(String id) => ProviderStatisticsError(
        message:
            'Vue stats non disponible pour cette action (prestataire: $id).',
      );

  Future<void> _onLoad(
    LoadProviderStatistics event,
    Emitter<ProviderStatisticsState> emit,
  ) async {
    _lastPreset = event.periodPreset;
    emit(ProviderStatisticsLoading());
    try {
      if (_token == null) {
        emit(ProviderStatisticsError(
          message: 'Session expirée — reconnectez-vous',
        ));
        return;
      }

      final period = ProviderStatsPeriod.resolve(event.periodPreset);
      final prestations = await _apiClient.fetchAllPrestationsForPrestataire(
        token: _token!,
        prestataireId: event.prestataireId,
      );

      final stats = aggregateProviderPeriodStatistics(
        prestations: prestations,
        period: period,
        loadedAt: DateTime.now(),
      );

      emit(ProviderPeriodStatisticsLoaded(stats));
    } catch (e) {
      emit(ProviderStatisticsError(
        message: 'Impossible de charger les statistiques.',
      ));
    }
  }
}
