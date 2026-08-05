import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'missions_event.dart';
import 'missions_state.dart';

/// Missions prestataire — aligné sur planning_bloc (token + prestataireId).
class MissionsBloc extends Bloc<MissionsEvent, MissionsState> {
  final ApiClient _apiClient = ApiClient();
  String? _currentToken;
  String? _currentPrestataireId;

  void setToken(String token) {
    _currentToken = token;
  }

  void setPrestataireId(String prestataireId) {
    _currentPrestataireId = prestataireId;
  }

  MissionsBloc() : super(MissionsInitial()) {
    on<LoadAvailableMissions>(_onLoadAvailable);
    on<LoadOngoingMissions>(_onLoadOngoing);
    on<LoadCompletedMissions>(_onLoadCompleted);
    on<ApplyToMission>(_onApply);
    on<AcceptMission>(_onAccept);
    on<RejectMission>(_onReject);
    on<CompleteMission>(_onComplete);
    on<FilterMissions>(_onFilter);
  }

  String? get _prestatairePath {
    final id = _currentPrestataireId;
    if (id == null || id.isEmpty) return null;
    return '/prestations/prestataire/$id';
  }

  Future<void> _onLoadAvailable(
      LoadAvailableMissions event, Emitter<MissionsState> emit) async {
    emit(MissionsLoading());
    try {
      // Demandes en attente (marché) — auth requise côté backend pour PII
      final response = await _apiClient.get(
        '/prestations?statut=EN_ATTENTE',
        token: _currentToken,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> prestations = data['prestations'] ?? data;
        emit(MissionsLoaded(availableMissions: prestations));
      } else {
        emit(MissionsError('Erreur lors du chargement des missions'));
      }
    } catch (e) {
      emit(MissionsError('Erreur de connexion: $e'));
    }
  }

  Future<void> _onLoadOngoing(
      LoadOngoingMissions event, Emitter<MissionsState> emit) async {
    emit(MissionsLoading());
    try {
      final base = _prestatairePath;
      if (base == null) {
        emit(MissionsError('Prestataire non identifié'));
        return;
      }
      final response = await _apiClient.get(
        '$base?statut=ACCEPTEE,EN_COURS',
        token: _currentToken,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> prestations = data['prestations'] ?? data;
        emit(MissionsLoaded(ongoingMissions: prestations));
      } else {
        emit(MissionsError('Erreur lors du chargement des missions en cours'));
      }
    } catch (e) {
      emit(MissionsError('Erreur de connexion: $e'));
    }
  }

  Future<void> _onLoadCompleted(
      LoadCompletedMissions event, Emitter<MissionsState> emit) async {
    emit(MissionsLoading());
    try {
      final base = _prestatairePath;
      if (base == null) {
        emit(MissionsError('Prestataire non identifié'));
        return;
      }
      final response = await _apiClient.get(
        '$base?statut=TERMINEE',
        token: _currentToken,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> prestations = data['prestations'] ?? data;
        emit(MissionsLoaded(completedMissions: prestations));
      } else {
        emit(MissionsError('Erreur lors du chargement des missions terminées'));
      }
    } catch (e) {
      emit(MissionsError('Erreur de connexion: $e'));
    }
  }

  Future<void> _mutateStatut({
    required String missionId,
    required String statut,
    String? notes,
    List<dynamic>? photos,
    required Emitter<MissionsState> emit,
    required MissionsState successState,
    required void Function() reload,
  }) async {
    emit(MissionsLoading());
    try {
      if (_currentToken == null || _currentToken!.isEmpty) {
        emit(MissionsError('Session expirée — reconnectez-vous'));
        return;
      }
      // PATCH /prestation/:id/statut — seul endpoint qui accepte le changement de statut
      final body = <String, dynamic>{
        'statut': statut,
        if (notes != null && notes.isNotEmpty) 'commentaire': notes,
      };
      final response = await _apiClient.patch(
        '/prestation/$missionId/statut',
        body: body,
        token: _currentToken,
      );
      if (response.statusCode == 200) {
        emit(successState);
        reload();
      } else {
        emit(MissionsError('Erreur (${response.statusCode})'));
      }
    } catch (e) {
      emit(MissionsError('Erreur de connexion: $e'));
    }
  }

  Future<void> _onApply(
      ApplyToMission event, Emitter<MissionsState> emit) async {
    await _mutateStatut(
      missionId: event.missionId,
      statut: 'ACCEPTEE',
      notes: event.message,
      emit: emit,
      successState: MissionAppliedSuccessfully(),
      reload: () => add(LoadAvailableMissions()),
    );
  }

  Future<void> _onAccept(
      AcceptMission event, Emitter<MissionsState> emit) async {
    await _mutateStatut(
      missionId: event.missionId,
      statut: 'ACCEPTEE',
      emit: emit,
      successState: MissionAcceptedSuccessfully(),
      reload: () => add(LoadOngoingMissions()),
    );
  }

  Future<void> _onReject(
      RejectMission event, Emitter<MissionsState> emit) async {
    await _mutateStatut(
      missionId: event.missionId,
      statut: 'REFUSEE',
      notes: event.reason,
      emit: emit,
      successState: MissionRejectedSuccessfully(),
      reload: () => add(LoadAvailableMissions()),
    );
  }

  Future<void> _onComplete(
      CompleteMission event, Emitter<MissionsState> emit) async {
    await _mutateStatut(
      missionId: event.missionId,
      statut: 'TERMINEE',
      notes: event.completionNotes,
      photos: event.photos,
      emit: emit,
      successState: MissionCompletedSuccessfully(),
      reload: () => add(LoadCompletedMissions()),
    );
  }

  Future<void> _onFilter(
      FilterMissions event, Emitter<MissionsState> emit) async {
    emit(MissionsLoading());
    try {
      final Map<String, String> queryParams = {};
      if (event.searchQuery.isNotEmpty) {
        queryParams['search'] = event.searchQuery;
      }
      if (event.location != 'Toutes') {
        queryParams['location'] = event.location;
      }
      if (event.priceRange != 'Tous') {
        queryParams['priceRange'] = event.priceRange;
      }
      if (event.urgency != 'Toutes') {
        queryParams['urgency'] = event.urgency;
      }
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _apiClient.get(
        '/prestations?$queryString',
        token: _currentToken,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> prestations = data['prestations'] ?? data;
        emit(MissionsLoaded(availableMissions: prestations));
      } else {
        emit(MissionsError('Erreur lors du filtrage'));
      }
    } catch (e) {
      emit(MissionsError('Erreur de connexion: $e'));
    }
  }
}
