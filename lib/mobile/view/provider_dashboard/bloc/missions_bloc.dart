import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'missions_event.dart';
import 'missions_state.dart';

// 🎯 BLoC POUR GÉRER LES MISSIONS PRESTATAIRE
class MissionsBloc extends Bloc<MissionsEvent, MissionsState> {
  final ApiClient _apiClient = ApiClient();

  MissionsBloc() : super(MissionsInitial()) {
    // 🎯 CHARGER LES MISSIONS DISPONIBLES
    on<LoadAvailableMissions>((event, emit) async {
      emit(MissionsLoading());
      try {
        final response = await _apiClient.get('/prestations?statut=EN_ATTENTE');
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
    });

    // 🎯 CHARGER LES PRESTATIONS EN COURS (ACCEPTEE, EN_COURS)
    on<LoadOngoingMissions>((event, emit) async {
      emit(MissionsLoading());
      try {
        final response =
            await _apiClient.get('/prestations?statut=ACCEPTEE,EN_COURS');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> prestations = data['prestations'] ?? data;
          emit(MissionsLoaded(ongoingMissions: prestations));
        } else {
          emit(
              MissionsError('Erreur lors du chargement des missions en cours'));
        }
      } catch (e) {
        emit(MissionsError('Erreur de connexion: $e'));
      }
    });

    // 🎯 CHARGER LES MISSIONS TERMINÉES
    on<LoadCompletedMissions>((event, emit) async {
      emit(MissionsLoading());
      try {
        final response = await _apiClient.get('/prestations?statut=TERMINEE');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> prestations = data['prestations'] ?? data;
          emit(MissionsLoaded(completedMissions: prestations));
        } else {
          emit(MissionsError(
              'Erreur lors du chargement des missions terminées'));
        }
      } catch (e) {
        emit(MissionsError('Erreur de connexion: $e'));
      }
    });

    // 🎯 ACCEPTER UNE PRESTATION
    on<ApplyToMission>((event, emit) async {
      emit(MissionsLoading());
      try {
        final response = await _apiClient.put(
          '/prestation/${event.missionId}',
          body: {
            'statut': 'ACCEPTEE',
            'notesPrestataire': event.message,
          },
        );
        if (response.statusCode == 200) {
          emit(MissionAppliedSuccessfully());
          // Recharger les prestations disponibles
          add(LoadAvailableMissions());
        } else {
          emit(MissionsError('Erreur lors de l\'acceptation'));
        }
      } catch (e) {
        emit(MissionsError('Erreur de connexion: $e'));
      }
    });

    // 🎯 ACCEPTER UNE MISSION
    on<AcceptMission>((event, emit) async {
      emit(MissionsLoading());
      try {
        final response = await _apiClient.put(
          '/prestataire/missions/${event.missionId}/accept',
        );
        if (response.statusCode == 200) {
          emit(MissionAcceptedSuccessfully());
          // Recharger les missions en cours
          add(LoadOngoingMissions());
        } else {
          emit(MissionsError('Erreur lors de l\'acceptation'));
        }
      } catch (e) {
        emit(MissionsError('Erreur de connexion: $e'));
      }
    });

    // 🎯 REFUSER UNE PRESTATION
    on<RejectMission>((event, emit) async {
      emit(MissionsLoading());
      try {
        final response = await _apiClient.put(
          '/prestation/${event.missionId}',
          body: {
            'statut': 'REFUSEE',
            'notesPrestataire': event.reason,
          },
        );
        if (response.statusCode == 200) {
          emit(MissionRejectedSuccessfully());
          // Recharger les prestations disponibles
          add(LoadAvailableMissions());
        } else {
          emit(MissionsError('Erreur lors du refus'));
        }
      } catch (e) {
        emit(MissionsError('Erreur de connexion: $e'));
      }
    });

    // 🎯 TERMINER UNE PRESTATION
    on<CompleteMission>((event, emit) async {
      emit(MissionsLoading());
      try {
        final response = await _apiClient.put(
          '/prestation/${event.missionId}',
          body: {
            'statut': 'TERMINEE',
            'notesPrestataire': event.completionNotes,
            'photosApres': event.photos,
          },
        );
        if (response.statusCode == 200) {
          emit(MissionCompletedSuccessfully());
          // Recharger les prestations terminées
          add(LoadCompletedMissions());
        } else {
          emit(MissionsError('Erreur lors de la finalisation'));
        }
      } catch (e) {
        emit(MissionsError('Erreur de connexion: $e'));
      }
    });

    // 🎯 FILTRER LES PRESTATIONS
    on<FilterMissions>((event, emit) async {
      emit(MissionsLoading());
      try {
        // Construire les paramètres de recherche
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

        // Construire l'URL avec les paramètres
        String queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');

        final response = await _apiClient.get('/prestations?$queryString');

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
    });
  }
}
