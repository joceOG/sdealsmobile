import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'planning_event.dart';
import 'planning_state.dart';

// 🎯 BLoC POUR GÉRER LE PLANNING PRESTATAIRE
class PlanningBloc extends Bloc<PlanningEvent, PlanningState> {
  final ApiClient _apiClient = ApiClient();

  PlanningBloc() : super(PlanningInitial()) {
    // 📅 CHARGER LES PRESTATIONS DU PRESTATAIRE
    on<LoadPrestationsPlanning>((event, emit) async {
      emit(PlanningLoading());
      try {
        final response = await _apiClient
            .get('/prestations/prestataire/${event.prestataireId}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> prestations = data['prestations'] ?? data;
          emit(PlanningLoaded(prestations: prestations));
        } else {
          emit(PlanningError('Erreur lors du chargement des prestations'));
        }
      } catch (e) {
        emit(PlanningError('Erreur de connexion: $e'));
      }
    });

    // 📅 CHARGER LES PRESTATIONS PAR DATE
    on<LoadPrestationsByDate>((event, emit) async {
      emit(PlanningLoading());
      try {
        final dateStr = event.date.toIso8601String().split('T')[0];
        final response =
            await _apiClient.get('/prestations?datePrestation=$dateStr');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> prestations = data['prestations'] ?? data;
          emit(PlanningLoaded(
            prestations: prestations,
            selectedDate: event.date,
          ));
        } else {
          emit(PlanningError('Erreur lors du chargement des prestations'));
        }
      } catch (e) {
        emit(PlanningError('Erreur de connexion: $e'));
      }
    });

    // 📅 CHARGER LES PRESTATIONS PAR STATUT
    on<LoadPrestationsByStatus>((event, emit) async {
      emit(PlanningLoading());
      try {
        final response =
            await _apiClient.get('/prestations?statut=${event.status}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> prestations = data['prestations'] ?? data;
          emit(PlanningLoaded(prestations: prestations));
        } else {
          emit(PlanningError('Erreur lors du chargement des prestations'));
        }
      } catch (e) {
        emit(PlanningError('Erreur de connexion: $e'));
      }
    });

    // 📅 FILTRER LES PRESTATIONS
    on<FilterPrestations>((event, emit) async {
      emit(PlanningLoading());
      try {
        final queryParams =
            event.filters.entries.map((e) => '${e.key}=${e.value}').join('&');
        final response = await _apiClient.get('/prestations?$queryParams');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> prestations = data['prestations'] ?? data;
          emit(PlanningLoaded(prestations: prestations));
        } else {
          emit(PlanningError('Erreur lors du filtrage'));
        }
      } catch (e) {
        emit(PlanningError('Erreur de connexion: $e'));
      }
    });

    // 📅 METTRE À JOUR LE STATUT D'UNE PRESTATION
    on<UpdatePrestationStatus>((event, emit) async {
      emit(PlanningLoading());
      try {
        final body = {
          'statut': event.newStatus,
          if (event.notes != null) 'notesPrestataire': event.notes,
        };
        final response = await _apiClient
            .put('/prestation/${event.prestationId}', body: body);
        if (response.statusCode == 200) {
          final prestation = jsonDecode(response.body);
          emit(PrestationUpdated(prestation));
          // Recharger les prestations
          add(LoadPrestationsPlanning(prestation['prestataire']['_id']));
        } else {
          emit(PlanningError('Erreur lors de la mise à jour'));
        }
      } catch (e) {
        emit(PlanningError('Erreur de connexion: $e'));
      }
    });

    // 📅 AJOUTER DES NOTES À UNE PRESTATION
    on<AddPrestationNotes>((event, emit) async {
      emit(PlanningLoading());
      try {
        final response = await _apiClient.put(
          '/prestation/${event.prestationId}',
          body: {'notesPrestataire': event.notes},
        );
        if (response.statusCode == 200) {
          emit(NotesAdded(event.prestationId, event.notes));
          // Recharger les prestations
          add(LoadPrestationsPlanning(event.prestationId));
        } else {
          emit(PlanningError('Erreur lors de l\'ajout des notes'));
        }
      } catch (e) {
        emit(PlanningError('Erreur de connexion: $e'));
      }
    });

    // 📅 CHARGER LES STATISTIQUES DU PLANNING
    on<LoadPlanningStats>((event, emit) async {
      try {
        final response = await _apiClient
            .get('/prestations/stats?prestataireId=${event.prestataireId}');
        if (response.statusCode == 200) {
          final stats = jsonDecode(response.body);
          emit(PlanningStatsLoaded(stats));
        } else {
          emit(PlanningError('Erreur lors du chargement des statistiques'));
        }
      } catch (e) {
        emit(PlanningError('Erreur de connexion: $e'));
      }
    });

    // 📅 CHARGER LES PRESTATIONS DU MOIS
    on<LoadMonthlyPrestations>((event, emit) async {
      emit(PlanningLoading());
      try {
        final startOfMonth = DateTime(event.month.year, event.month.month, 1);
        final endOfMonth = DateTime(event.month.year, event.month.month + 1, 0);
        final response = await _apiClient.get(
            '/prestations?dateDebut=${startOfMonth.toIso8601String()}&dateFin=${endOfMonth.toIso8601String()}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> prestations = data['prestations'] ?? data;
          emit(PlanningLoaded(
            prestations: prestations,
            monthlyPrestations: prestations,
            selectedView: 'month',
          ));
        } else {
          emit(PlanningError(
              'Erreur lors du chargement des prestations mensuelles'));
        }
      } catch (e) {
        emit(PlanningError('Erreur de connexion: $e'));
      }
    });

    // 📅 CHARGER LES PRESTATIONS DE LA SEMAINE
    on<LoadWeeklyPrestations>((event, emit) async {
      emit(PlanningLoading());
      try {
        final endOfWeek = event.weekStart.add(const Duration(days: 6));
        final response = await _apiClient.get(
            '/prestations?dateDebut=${event.weekStart.toIso8601String()}&dateFin=${endOfWeek.toIso8601String()}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> prestations = data['prestations'] ?? data;
          emit(PlanningLoaded(
            prestations: prestations,
            weeklyPrestations: prestations,
            selectedView: 'week',
          ));
        } else {
          emit(PlanningError(
              'Erreur lors du chargement des prestations hebdomadaires'));
        }
      } catch (e) {
        emit(PlanningError('Erreur de connexion: $e'));
      }
    });

    // 📅 CHARGER LES PRESTATIONS DU JOUR
    on<LoadDailyPrestations>((event, emit) async {
      emit(PlanningLoading());
      try {
        final dateStr = event.day.toIso8601String().split('T')[0];
        final response =
            await _apiClient.get('/prestations?datePrestation=$dateStr');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> prestations = data['prestations'] ?? data;
          emit(PlanningLoaded(
            prestations: prestations,
            dailyPrestations: prestations,
            selectedDate: event.day,
            selectedView: 'day',
          ));
        } else {
          emit(PlanningError(
              'Erreur lors du chargement des prestations quotidiennes'));
        }
      } catch (e) {
        emit(PlanningError('Erreur de connexion: $e'));
      }
    });
  }
}
