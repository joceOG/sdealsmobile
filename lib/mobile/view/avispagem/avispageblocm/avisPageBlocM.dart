import 'dart:convert';
import 'package:sdealsmobile/mobile/view/avispagem/avispageblocm/avisPageEventM.dart';
import 'package:sdealsmobile/mobile/view/avispagem/avispageblocm/avisPageStateM.dart';
import 'package:sdealsmobile/data/models/avis.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:bloc/bloc.dart';

class AvisPageBlocM extends Bloc<AvisPageEventM, AvisPageStateM> {
  final ApiClient _apiClient = ApiClient();

  AvisPageBlocM() : super(AvisPageStateM.initial()) {
    // 📋 ÉVÉNEMENTS DE CHARGEMENT
    on<LoadAvisDataM>(_onLoadAvisDataM);
    on<SearchAvisM>(_onSearchAvisM);
    on<LoadAvisRecentsM>(_onLoadAvisRecentsM);

    // ✏️ ÉVÉNEMENTS DE CRÉATION/MODIFICATION
    on<CreateAvisM>(_onCreateAvisM);
    on<UpdateAvisM>(_onUpdateAvisM);
    on<DeleteAvisM>(_onDeleteAvisM);

    // 🎯 ÉVÉNEMENTS D'INTERACTION
    on<MarquerUtileM>(_onMarquerUtileM);
    on<RepondreAvisM>(_onRepondreAvisM);
    on<SignalerAvisM>(_onSignalerAvisM);

    // 📊 ÉVÉNEMENTS DE STATISTIQUES
    on<LoadStatsObjetM>(_onLoadStatsObjetM);
    on<RefreshAvisM>(_onRefreshAvisM);
  }

  // 📋 CHARGEMENT DES AVIS
  Future<void> _onLoadAvisDataM(
      LoadAvisDataM event, Emitter<AvisPageStateM> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Construction des paramètres de requête
      final Map<String, String> queryParams = {};
      if (event.objetType != null) queryParams['objetType'] = event.objetType!;
      if (event.objetId != null) queryParams['objetId'] = event.objetId!;
      if (event.statut != null) queryParams['statut'] = event.statut!;
      if (event.note != null) queryParams['note'] = event.note.toString();
      if (event.searchTerm != null) queryParams['q'] = event.searchTerm!;

      // Appel API
      final response = await _apiClient.get('/avis');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<Avis> avisList = [];
        if (responseData['avis'] != null) {
          avisList = (responseData['avis'] as List)
              .map((json) => Avis.fromJson(json))
              .toList();
        }

        emit(state.copyWith(
          avis: avisList,
          isLoading: false,
          error: null,
          totalAvis: responseData['pagination']?['total'] ?? avisList.length,
          currentPage: responseData['pagination']?['page'] ?? 1,
          totalPages: responseData['pagination']?['pages'] ?? 1,
          hasMoreData: (responseData['pagination']?['page'] ?? 1) <
              (responseData['pagination']?['pages'] ?? 1),
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Erreur ${response.statusCode}: ${response.body}',
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des avis: ${error.toString()}',
      ));
    }
  }

  // 🔍 RECHERCHE D'AVIS
  Future<void> _onSearchAvisM(
      SearchAvisM event, Emitter<AvisPageStateM> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final response = await _apiClient
          .get('/avis/search?q=${Uri.encodeComponent(event.query)}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<Avis> avisList = [];
        if (responseData['avis'] != null) {
          avisList = (responseData['avis'] as List)
              .map((json) => Avis.fromJson(json))
              .toList();
        }

        emit(state.copyWith(
          avis: avisList,
          isLoading: false,
          error: null,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Erreur lors de la recherche: ${response.statusCode}',
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la recherche: ${error.toString()}',
      ));
    }
  }

  // 📅 AVIS RÉCENTS
  Future<void> _onLoadAvisRecentsM(
      LoadAvisRecentsM event, Emitter<AvisPageStateM> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final response = await _apiClient.get('/avis/recent');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<Avis> avisList = [];
        if (responseData['avis'] != null) {
          avisList = (responseData['avis'] as List)
              .map((json) => Avis.fromJson(json))
              .toList();
        }

        emit(state.copyWith(
          avis: avisList,
          isLoading: false,
          error: null,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error:
              'Erreur lors du chargement des avis récents: ${response.statusCode}',
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        isLoading: false,
        error:
            'Erreur lors du chargement des avis récents: ${error.toString()}',
      ));
    }
  }

  // ✏️ CRÉATION D'AVIS
  Future<void> _onCreateAvisM(
      CreateAvisM event, Emitter<AvisPageStateM> emit) async {
    emit(state.copyWith(isCreating: true, createError: null));

    try {
      final body = <String, dynamic>{
        'objetType': event.objetType,
        'objetId': event.objetId,
        'note': event.note,
        'recommande': event.recommande,
        'anonyme': event.anonyme,
      };
      if (event.titre != null && event.titre!.isNotEmpty) {
        body['titre'] = event.titre;
      }
      if (event.commentaire != null && event.commentaire!.isNotEmpty) {
        body['commentaire'] = event.commentaire;
      }
      if (event.tags != null && event.tags!.isNotEmpty) {
        body['tags'] = event.tags;
      }
      if (event.localisation != null) {
        body['localisation'] = event.localisation!.toJson();
      }
      final response = await _apiClient.post('/avis', body: body);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final avisJson = responseData['avis'] ?? responseData;
        final newAvis = Avis.fromJson(avisJson);

        // Ajouter le nouvel avis à la liste
        final updatedAvis = List<Avis>.from(state.avis ?? [])
          ..insert(0, newAvis);

        emit(state.copyWith(
          avis: updatedAvis,
          isCreating: false,
          createError: null,
        ));
      } else {
        emit(state.copyWith(
          isCreating: false,
          createError: 'Erreur lors de la création: ${response.statusCode}',
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        isCreating: false,
        createError: 'Erreur lors de la création: ${error.toString()}',
      ));
    }
  }

  // ✏️ MODIFICATION D'AVIS
  Future<void> _onUpdateAvisM(
      UpdateAvisM event, Emitter<AvisPageStateM> emit) async {
    emit(state.copyWith(isCreating: true, createError: null));

    try {
      final response = await _apiClient.put('/avis/${event.avisId}', body: {
        'note': event.note,
        'titre': event.titre,
        'commentaire': event.commentaire,
        'recommande': event.recommande,
        'tags': event.tags,
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final updatedAvis = Avis.fromJson(responseData);

        // Mettre à jour l'avis dans la liste
        final updatedAvisList = (state.avis ?? [])
            .map((avis) => avis.id == updatedAvis.id ? updatedAvis : avis)
            .toList();

        emit(state.copyWith(
          avis: updatedAvisList,
          isCreating: false,
          createError: null,
        ));
      } else {
        emit(state.copyWith(
          isCreating: false,
          createError: 'Erreur lors de la modification: ${response.statusCode}',
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        isCreating: false,
        createError: 'Erreur lors de la modification: ${error.toString()}',
      ));
    }
  }

  // 🗑️ SUPPRESSION D'AVIS
  Future<void> _onDeleteAvisM(
      DeleteAvisM event, Emitter<AvisPageStateM> emit) async {
    emit(state.copyWith(isCreating: true, createError: null));

    try {
      final response = await _apiClient.delete('/avis/${event.avisId}');

      if (response.statusCode == 200) {
        // Retirer l'avis de la liste
        final updatedAvisList = (state.avis ?? [])
            .where((avis) => avis.id != event.avisId)
            .toList();

        emit(state.copyWith(
          avis: updatedAvisList,
          isCreating: false,
          createError: null,
        ));
      } else {
        emit(state.copyWith(
          isCreating: false,
          createError: 'Erreur lors de la suppression: ${response.statusCode}',
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        isCreating: false,
        createError: 'Erreur lors de la suppression: ${error.toString()}',
      ));
    }
  }

  // 👍 MARQUER UTILE
  Future<void> _onMarquerUtileM(
      MarquerUtileM event, Emitter<AvisPageStateM> emit) async {
    try {
      final response =
          await _apiClient.post('/avis/${event.avisId}/utile', body: {
        'utile': event.utile,
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final updatedAvis = Avis.fromJson(responseData);

        // Mettre à jour l'avis dans la liste
        final updatedAvisList = (state.avis ?? [])
            .map((avis) => avis.id == updatedAvis.id ? updatedAvis : avis)
            .toList();

        emit(state.copyWith(avis: updatedAvisList));
      }
    } catch (error) {
      // Erreur silencieuse pour les interactions
    }
  }

  // 💬 RÉPONDRE À UN AVIS
  Future<void> _onRepondreAvisM(
      RepondreAvisM event, Emitter<AvisPageStateM> emit) async {
    try {
      final response =
          await _apiClient.post('/avis/${event.avisId}/reponse', body: {
        'contenu': event.contenu,
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final updatedAvis = Avis.fromJson(responseData);

        // Mettre à jour l'avis dans la liste
        final updatedAvisList = (state.avis ?? [])
            .map((avis) => avis.id == updatedAvis.id ? updatedAvis : avis)
            .toList();

        emit(state.copyWith(avis: updatedAvisList));
      }
    } catch (error) {
      // Erreur silencieuse pour les interactions
    }
  }

  // 🚨 SIGNALER UN AVIS
  Future<void> _onSignalerAvisM(
      SignalerAvisM event, Emitter<AvisPageStateM> emit) async {
    try {
      final response =
          await _apiClient.post('/avis/${event.avisId}/signaler', body: {
        'motifs': event.motifs,
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final updatedAvis = Avis.fromJson(responseData);

        // Mettre à jour l'avis dans la liste
        final updatedAvisList = (state.avis ?? [])
            .map((avis) => avis.id == updatedAvis.id ? updatedAvis : avis)
            .toList();

        emit(state.copyWith(avis: updatedAvisList));
      }
    } catch (error) {
      // Erreur silencieuse pour les interactions
    }
  }

  // 📊 STATISTIQUES D'OBJET
  Future<void> _onLoadStatsObjetM(
      LoadStatsObjetM event, Emitter<AvisPageStateM> emit) async {
    try {
      final response = await _apiClient.get('/avis/stats/${event.objetId}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        emit(state.copyWith(
          statsObjet: responseData,
        ));
      }
    } catch (error) {
      // Erreur silencieuse pour les statistiques
    }
  }

  // 🔄 ACTUALISATION
  Future<void> _onRefreshAvisM(
      RefreshAvisM event, Emitter<AvisPageStateM> emit) async {
    // Recharger les avis sans paramètres spécifiques
    add(const LoadAvisDataM());
  }
}
