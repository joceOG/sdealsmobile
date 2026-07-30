import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'provider_profile_event.dart';
import 'provider_profile_state.dart';

// 🎯 BLoC POUR GÉRER LE PROFIL PRESTATAIRE
class ProviderProfileBloc
    extends Bloc<ProviderProfileEvent, ProviderProfileState> {
  final ApiClient _apiClient = ApiClient();
  String? _currentToken;

  double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(',', '.').trim();
      return double.tryParse(normalized) ?? fallback;
    }
    return fallback;
  }

  void setToken(String token) {
    _currentToken = token;
  }

  ProviderProfileBloc() : super(ProviderProfileInitial()) {
    // 👤 CHARGER LE PROFIL DU PRESTATAIRE
    on<LoadProviderProfile>((event, emit) async {
      emit(ProviderProfileLoading());
      try {
        // Appel API réel
        final response = await _apiClient.get(
          '/prestataire/${event.prestataireId}',
          token: _currentToken,
        );

        Map<String, dynamic> profile;
        Map<String, dynamic> stats;
        List<String> services;
        Map<String, dynamic> serviceZone;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final utilisateur = data['utilisateur'] as Map<String, dynamic>? ?? {};

          profile = {
            'id': data['_id'] ?? event.prestataireId,
            'fullName': '${utilisateur['prenom'] ?? ''} ${utilisateur['nom'] ?? ''}'.trim(),
            'email': utilisateur['email'] ?? '',
            'phone': utilisateur['telephone'] ?? '',
            'joinDate': data['createdAt'] ?? '',
            'status': data['status'] ?? 'pending',
            'profileImage': utilisateur['photoProfil'],
            'bio': data['description'] ?? '',
            'location': data['localisation'] is Map
                ? '${data['localisation']['ville'] ?? ''}, ${data['localisation']['pays'] ?? ''}'.trim()
                : (data['localisation']?.toString() ?? 'Abidjan'),
            'serviceRadius': _asDouble(data['rayonIntervention'], fallback: 10),
            'availability': '7j/7',
            'note': _asDouble(data['note']),
            'nbMission': data['nbMission'] ?? 0,
            'verifier': data['verifier'] ?? false,
            'prixprestataire': data['prixprestataire'] ?? 0,
            'anneeExperience': data['anneeExperience'] ?? 0,
          };

          stats = {
            'missionsCompleted': data['nbMission'] ?? 0,
            'averageRating': _asDouble(data['note']),
            'totalReviews': data['nbMission'] ?? 0,
            'monthlyEarnings': _asDouble(data['revenus']),
            'successRate': 90.0,
            'responseTime': '2h',
            'completionRate': 95.0,
          };

          services = data['specialite'] is List
              ? (data['specialite'] as List).map((e) => e.toString()).toList()
              : <String>[];

          serviceZone = {
            'address': data['localisation'] is Map
                ? data['localisation']['adresse'] ?? 'Abidjan'
                : (data['localisation']?.toString() ?? 'Abidjan'),
            'latitude': _asDouble(data['localisationmaps']?['latitude'], fallback: 5.3600),
            'longitude': _asDouble(data['localisationmaps']?['longitude'], fallback: -4.0083),
            'radius': _asDouble(data['rayonIntervention'], fallback: 10),
            'coverage': 'Zone d\'intervention',
          };
        } else {
          // Fallback avec données vides
          profile = {'id': event.prestataireId, 'fullName': '', 'status': 'unknown'};
          stats = {'missionsCompleted': 0, 'averageRating': 0.0, 'monthlyEarnings': 0.0};
          services = <String>[];
          serviceZone = {'address': 'Abidjan', 'radius': 10.0};
        }

        // Activité récente (placeholder — pas d'API dédiée)
        final recentActivity = <Map<String, dynamic>>[];

        // Récompenses (placeholder)
        final achievements = <Map<String, dynamic>>[];

        // Paramètres par défaut
        final settings = {
          'language': 'fr',
          'currency': 'FCFA',
          'timezone': 'Africa/Abidjan',
          'theme': 'light',
          'autoAccept': false,
          'maxDistance': 15.0,
        };

        // Paramètres de notification par défaut
        final notificationSettings = {
          'newMissions': true,
          'messages': true,
          'payments': true,
          'reviews': true,
          'promotions': false,
          'system': true,
        };

        // Documents (placeholder — à connecter via /prestataire/:id/documents)
        final documents = <Map<String, dynamic>>[];

        emit(ProviderProfileLoaded(
          profile: profile,
          stats: stats,
          recentActivity: recentActivity,
          achievements: achievements,
          settings: settings,
          notificationSettings: notificationSettings,
          services: services,
          serviceZone: serviceZone,
          documents: documents,
        ));
      } catch (e) {
        emit(ProviderProfileError('Erreur lors du chargement du profil: $e'));
      }
    });

    // 👤 METTRE À JOUR LE PROFIL
    on<UpdateProviderProfile>((event, emit) async {
      emit(ProviderProfileLoading());
      try {
        final response = await _apiClient.put(
          '/prestataire/${event.prestataireId}',
          body: event.profileData,
          token: _currentToken,
        );
        if (response.statusCode == 200) {
          final updatedProfile = jsonDecode(response.body) as Map<String, dynamic>;
          emit(ProviderProfileUpdated(updatedProfile));
        } else {
          emit(ProviderProfileError('Erreur mise à jour (${response.statusCode})'));
        }
      } catch (e) {
        emit(ProviderProfileError('Erreur lors de la mise à jour: $e'));
      }
    });

    // 👤 Stats / activité / badges — plus de Random() fictif
    on<LoadProviderStats>((event, emit) async {
      emit(ProviderProfileError(
          'Stats profil : utilisez l\'écran Statistiques (données serveur)'));
    });

    on<LoadRecentActivity>((event, emit) async {
      emit(RecentActivityLoaded(const []));
    });

    on<LoadAchievements>((event, emit) async {
      emit(AchievementsLoaded(const []));
    });

    // 👤 CHARGER LES PARAMÈTRES (local-only defaults — pas d'API dédiée)
    on<LoadProviderSettings>((event, emit) async {
      emit(ProviderSettingsLoaded({
        'language': 'fr',
        'currency': 'FCFA',
        'timezone': 'Africa/Abidjan',
        'theme': 'light',
        'autoAccept': false,
        'maxDistance': 15.0,
        '_localOnly': true,
      }));
    });

    on<UpdateProviderSettings>((event, emit) async {
      emit(ProviderProfileError(
          'Sauvegarde des paramètres non branchée au serveur — action annulée'));
    });

    on<LoadNotificationSettings>((event, emit) async {
      emit(NotificationSettingsLoaded({
        'newMissions': true,
        'messages': true,
        'payments': true,
        'reviews': true,
        'promotions': false,
        'system': true,
        '_localOnly': true,
      }));
    });

    on<UpdateNotificationSettings>((event, emit) async {
      emit(ProviderProfileError(
          'Sauvegarde des notifications non branchée au serveur — action annulée'));
    });

    on<LoadProviderServices>((event, emit) async {
      emit(ProviderServicesLoaded(const []));
    });

    on<UpdateProviderServices>((event, emit) async {
      emit(ProviderProfileError(
          'Mise à jour des services non branchée au serveur — action annulée'));
    });

    on<LoadServiceZone>((event, emit) async {
      emit(ServiceZoneLoaded({
        'address': '',
        'latitude': null,
        'longitude': null,
        'radius': null,
        '_localOnly': true,
      }));
    });

    on<UpdateServiceZone>((event, emit) async {
      emit(ProviderProfileError(
          'Mise à jour de la zone non branchée au serveur — action annulée'));
    });

    on<LoadProviderDocuments>((event, emit) async {
      // Plus de documents fictifs « verified »
      emit(ProviderDocumentsLoaded(const []));
    });

    // 👤 UPLOADER UN DOCUMENT
    on<UploadDocument>((event, emit) async {
      emit(ProviderProfileError(
          'Upload de documents non branché au serveur — action annulée'));
    });

    // 👤 SUPPRIMER UN DOCUMENT
    on<DeleteDocument>((event, emit) async {
      emit(ProviderProfileError(
          'Suppression de document non branchée au serveur — action annulée'));
    });

    // 👤 CHANGER LE MOT DE PASSE
    on<ChangePassword>((event, emit) async {
      try {
        if (_currentToken == null || _currentToken!.isEmpty) {
          emit(ProviderProfileError('Session expirée — reconnectez-vous'));
          return;
        }
        final response = await _apiClient.patch(
          '/utilisateur/password',
          body: {
            'currentPassword': event.currentPassword,
            'newPassword': event.newPassword,
          },
          token: _currentToken,
        );
        if (response.statusCode == 200) {
          emit(PasswordChanged());
        } else {
          String message = 'Erreur changement mot de passe (${response.statusCode})';
          try {
            final data = jsonDecode(response.body);
            if (data is Map && data['error'] != null) {
              message = data['error'].toString();
            }
          } catch (_) {}
          emit(ProviderProfileError(message));
        }
      } catch (e) {
        emit(ProviderProfileError(
            'Erreur lors du changement de mot de passe: $e'));
      }
    });

    // 👤 DÉSACTIVER LE COMPTE
    on<DeactivateAccount>((event, emit) async {
      emit(ProviderProfileError(
          'Désactivation de compte non disponible pour le moment'));
    });

    // 👤 SUPPRIMER LE COMPTE
    on<DeleteAccount>((event, emit) async {
      emit(ProviderProfileError(
          'Suppression de compte non branchée — contactez le support'));
    });

    // 👤 ACTUALISER LE PROFIL
    on<RefreshProviderProfile>((event, emit) async {
      add(LoadProviderProfile(event.prestataireId));
    });
  }
}
