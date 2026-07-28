import 'dart:convert';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'provider_profile_event.dart';
import 'provider_profile_state.dart';

// 🎯 BLoC POUR GÉRER LE PROFIL PRESTATAIRE
class ProviderProfileBloc
    extends Bloc<ProviderProfileEvent, ProviderProfileState> {
  final ApiClient _apiClient = ApiClient();
  final Random _random = Random();
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

    // 👤 CHARGER LES STATISTIQUES
    on<LoadProviderStats>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        final stats = {
          'missionsCompleted': 24 + _random.nextInt(10),
          'averageRating': 4.8 + _random.nextDouble() * 0.2,
          'totalReviews': 18 + _random.nextInt(5),
          'monthlyEarnings': 125000.0 + _random.nextDouble() * 50000,
          'successRate': 96.0 + _random.nextDouble() * 4,
          'responseTime': '2h',
          'completionRate': 98.0 + _random.nextDouble() * 2,
        };

        emit(ProviderStatsLoaded(stats));
      } catch (e) {
        emit(ProviderProfileError(
            'Erreur lors du chargement des statistiques: $e'));
      }
    });

    // 👤 CHARGER L'ACTIVITÉ RÉCENTE
    on<LoadRecentActivity>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 400));

        final activities = List.generate(
            event.limit,
            (index) => {
                  'id': '${index + 1}',
                  'type': [
                    'mission_completed',
                    'new_mission',
                    'review_received'
                  ][index % 3],
                  'title': [
                    'Mission terminée',
                    'Nouvelle mission',
                    'Avis reçu'
                  ][index % 3],
                  'description': 'Description de l\'activité ${index + 1}',
                  'timestamp':
                      DateTime.now().subtract(Duration(hours: index + 1)),
                  'icon': ['check_circle', 'assignment', 'star'][index % 3],
                  'color': ['green', 'blue', 'amber'][index % 3],
                });

        emit(RecentActivityLoaded(activities));
      } catch (e) {
        emit(ProviderProfileError(
            'Erreur lors du chargement de l\'activité: $e'));
      }
    });

    // 👤 CHARGER LES RÉCOMPENSES
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
          },
          {
            'id': '2',
            'title': 'Fiable',
            'description': 'Note moyenne supérieure à 4.5',
            'icon': 'verified',
            'color': 'green',
            'unlocked': true,
          },
          {
            'id': '3',
            'title': 'Rapide',
            'description': 'Temps de réponse inférieur à 2h',
            'icon': 'speed',
            'color': 'blue',
            'unlocked': true,
          },
        ];

        emit(AchievementsLoaded(achievements));
      } catch (e) {
        emit(ProviderProfileError(
            'Erreur lors du chargement des récompenses: $e'));
      }
    });

    // 👤 CHARGER LES PARAMÈTRES
    on<LoadProviderSettings>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        final settings = {
          'language': 'fr',
          'currency': 'FCFA',
          'timezone': 'Africa/Abidjan',
          'theme': 'light',
          'autoAccept': false,
          'maxDistance': 15.0,
        };

        emit(ProviderSettingsLoaded(settings));
      } catch (e) {
        emit(ProviderProfileError(
            'Erreur lors du chargement des paramètres: $e'));
      }
    });

    // 👤 METTRE À JOUR LES PARAMÈTRES
    on<UpdateProviderSettings>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        emit(ProviderSettingsUpdated(event.settings));
      } catch (e) {
        emit(ProviderProfileError(
            'Erreur lors de la mise à jour des paramètres: $e'));
      }
    });

    // 👤 CHARGER LES NOTIFICATIONS
    on<LoadNotificationSettings>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        final notificationSettings = {
          'newMissions': true,
          'messages': true,
          'payments': true,
          'reviews': true,
          'promotions': false,
          'system': true,
        };

        emit(NotificationSettingsLoaded(notificationSettings));
      } catch (e) {
        emit(ProviderProfileError(
            'Erreur lors du chargement des notifications: $e'));
      }
    });

    // 👤 METTRE À JOUR LES NOTIFICATIONS
    on<UpdateNotificationSettings>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 400));

        emit(NotificationSettingsUpdated(event.notificationSettings));
      } catch (e) {
        emit(ProviderProfileError(
            'Erreur lors de la mise à jour des notifications: $e'));
      }
    });

    // 👤 CHARGER LES SERVICES
    on<LoadProviderServices>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        final services = ['Plomberie', 'Électricité', 'Peinture', 'Menuiserie'];

        emit(ProviderServicesLoaded(services));
      } catch (e) {
        emit(
            ProviderProfileError('Erreur lors du chargement des services: $e'));
      }
    });

    // 👤 METTRE À JOUR LES SERVICES
    on<UpdateProviderServices>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        emit(ProviderServicesUpdated(event.services));
      } catch (e) {
        emit(ProviderProfileError(
            'Erreur lors de la mise à jour des services: $e'));
      }
    });

    // 👤 CHARGER LA ZONE DE SERVICE
    on<LoadServiceZone>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        final serviceZone = {
          'address': 'Abidjan, Côte d\'Ivoire',
          'latitude': 5.3600,
          'longitude': -4.0083,
          'radius': 15.0,
          'coverage': 'Toute la ville d\'Abidjan',
        };

        emit(ServiceZoneLoaded(serviceZone));
      } catch (e) {
        emit(ProviderProfileError('Erreur lors du chargement de la zone: $e'));
      }
    });

    // 👤 METTRE À JOUR LA ZONE DE SERVICE
    on<UpdateServiceZone>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        emit(ServiceZoneUpdated(event.zoneData));
      } catch (e) {
        emit(ProviderProfileError(
            'Erreur lors de la mise à jour de la zone: $e'));
      }
    });

    // 👤 CHARGER LES DOCUMENTS
    on<LoadProviderDocuments>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        final documents = [
          {
            'id': '1',
            'type': 'cni',
            'name': 'Carte d\'identité',
            'status': 'verified',
            'uploadDate': '2024-01-15',
          },
          {
            'id': '2',
            'type': 'selfie',
            'name': 'Photo de profil',
            'status': 'verified',
            'uploadDate': '2024-01-15',
          },
          {
            'id': '3',
            'type': 'certificate',
            'name': 'Certificat de formation',
            'status': 'pending',
            'uploadDate': '2024-01-20',
          },
        ];

        emit(ProviderDocumentsLoaded(documents));
      } catch (e) {
        emit(ProviderProfileError(
            'Erreur lors du chargement des documents: $e'));
      }
    });

    // 👤 UPLOADER UN DOCUMENT
    on<UploadDocument>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 1000));

        final uploadedDocument = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': event.documentType,
          'name': 'Document ${event.documentType}',
          'status': 'pending',
          'uploadDate': DateTime.now().toIso8601String(),
        };

        emit(DocumentUploaded(uploadedDocument));
      } catch (e) {
        emit(ProviderProfileError('Erreur lors de l\'upload: $e'));
      }
    });

    // 👤 SUPPRIMER UN DOCUMENT
    on<DeleteDocument>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        emit(DocumentDeleted(event.documentId));
      } catch (e) {
        emit(ProviderProfileError('Erreur lors de la suppression: $e'));
      }
    });

    // 👤 CHANGER LE MOT DE PASSE
    on<ChangePassword>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 800));

        emit(PasswordChanged());
      } catch (e) {
        emit(ProviderProfileError(
            'Erreur lors du changement de mot de passe: $e'));
      }
    });

    // 👤 DÉSACTIVER LE COMPTE
    on<DeactivateAccount>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 1000));

        emit(AccountDeactivated(event.reason));
      } catch (e) {
        emit(ProviderProfileError('Erreur lors de la désactivation: $e'));
      }
    });

    // 👤 SUPPRIMER LE COMPTE
    on<DeleteAccount>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 1500));

        emit(AccountDeleted(event.reason));
      } catch (e) {
        emit(ProviderProfileError('Erreur lors de la suppression: $e'));
      }
    });

    // 👤 ACTUALISER LE PROFIL
    on<RefreshProviderProfile>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        final refreshedProfile = {
          'id': event.prestataireId,
          'lastRefresh': DateTime.now().toIso8601String(),
        };

        emit(ProviderProfileRefreshed(refreshedProfile));
      } catch (e) {
        emit(ProviderProfileError('Erreur lors de l\'actualisation: $e'));
      }
    });
  }
}
