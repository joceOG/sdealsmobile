import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

// 🎯 BLoC POUR GÉRER LES NOTIFICATIONS PRESTATAIRE
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final ApiClient _apiClient = ApiClient();
  String? _currentToken;

  NotificationsBloc() : super(NotificationsInitial()) {
    // 🔔 CHARGER LES NOTIFICATIONS DU PRESTATAIRE
    on<LoadPrestataireNotifications>((event, emit) async {
      emit(NotificationsLoading());
      try {
        if (_currentToken == null) {
          emit(NotificationsError('Token d\'authentification manquant'));
          return;
        }

        final notifications = await _apiClient.getNotifications(
          token: _currentToken!,
          userId: event.prestataireId,
        );

        final unreadCount = await _apiClient.getUnreadNotificationCount(
          token: _currentToken!,
          userId: event.prestataireId,
        );

        emit(NotificationsLoaded(
          notifications: notifications,
          totalUnread: unreadCount,
          hasMore: false,
          currentPage: 1,
        ));
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });

    // 🔔 CHARGER LES NOTIFICATIONS NON LUES
    on<LoadUnreadNotifications>((event, emit) async {
      emit(NotificationsLoading());
      try {
        final response = await _apiClient.get(
            '/notification/user/${event.prestataireId}?nonLuesUniquement=true');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> notifications = data['notifications'] ?? [];
          final int totalUnread = data['nonLues'] ?? 0;

          emit(NotificationsLoaded(
            notifications: notifications,
            totalUnread: totalUnread,
            hasMore: false,
            currentPage: 1,
          ));
        } else {
          emit(NotificationsError(
              'Erreur lors du chargement des notifications non lues'));
        }
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });

    // 🔔 CHARGER LES NOTIFICATIONS PAR TYPE
    on<LoadNotificationsByType>((event, emit) async {
      emit(NotificationsLoading());
      try {
        final response = await _apiClient.get(
            '/notification/user/${event.prestataireId}?type=${event.type}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> notifications = data['notifications'] ?? [];
          final int totalUnread = data['nonLues'] ?? 0;
          final bool hasMore = data['currentPage'] < data['totalPages'];
          final int currentPage = data['currentPage'] ?? 1;

          emit(NotificationsLoaded(
            notifications: notifications,
            totalUnread: totalUnread,
            hasMore: hasMore,
            currentPage: currentPage,
          ));
        } else {
          emit(NotificationsError(
              'Erreur lors du chargement des notifications'));
        }
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });

    // 🔔 CHARGER LES NOTIFICATIONS PAR PRIORITÉ
    on<LoadNotificationsByPriority>((event, emit) async {
      emit(NotificationsLoading());
      try {
        final response = await _apiClient.get(
            '/notification/user/${event.prestataireId}?priorite=${event.priority}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> notifications = data['notifications'] ?? [];
          final int totalUnread = data['nonLues'] ?? 0;
          final bool hasMore = data['currentPage'] < data['totalPages'];
          final int currentPage = data['currentPage'] ?? 1;

          emit(NotificationsLoaded(
            notifications: notifications,
            totalUnread: totalUnread,
            hasMore: hasMore,
            currentPage: currentPage,
          ));
        } else {
          emit(NotificationsError(
              'Erreur lors du chargement des notifications'));
        }
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });

    // 🔔 MARQUER UNE NOTIFICATION COMME LUE
    on<MarkNotificationAsRead>((event, emit) async {
      try {
        final response =
            await _apiClient.put('/notification/${event.notificationId}/read');
        if (response.statusCode == 200) {
          emit(NotificationMarkedAsRead(event.notificationId));
          // Recharger les notifications
          add(LoadPrestataireNotifications(event.prestataireId));
        } else {
          emit(
              NotificationsError('Erreur lors du marquage de la notification'));
        }
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });

    // 🔔 MARQUER TOUTES LES NOTIFICATIONS COMME LUES
    on<MarkAllNotificationsAsRead>((event, emit) async {
      try {
        final response = await _apiClient
            .put('/notification/user/${event.prestataireId}/mark-all-read');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          emit(AllNotificationsMarkedAsRead(data['modifiedCount'] ?? 0));
          // Recharger les notifications
          add(LoadPrestataireNotifications(event.prestataireId));
        } else {
          emit(NotificationsError('Erreur lors du marquage des notifications'));
        }
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });

    // 🔔 ARCHIVER UNE NOTIFICATION
    on<ArchiveNotification>((event, emit) async {
      try {
        final response = await _apiClient
            .put('/notification/${event.notificationId}/archive');
        if (response.statusCode == 200) {
          emit(NotificationArchived(event.notificationId));
          // Recharger les notifications
          add(LoadPrestataireNotifications(event.prestataireId));
        } else {
          emit(NotificationsError('Erreur lors de l\'archivage'));
        }
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });

    // 🔔 SUPPRIMER UNE NOTIFICATION
    on<DeleteNotification>((event, emit) async {
      try {
        final response =
            await _apiClient.delete('/notification/${event.notificationId}');
        if (response.statusCode == 200) {
          emit(NotificationDeleted(event.notificationId));
          // Recharger les notifications
          add(LoadPrestataireNotifications(event.prestataireId));
        } else {
          emit(NotificationsError('Erreur lors de la suppression'));
        }
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });

    // 🔔 CHARGER LES STATISTIQUES
    on<LoadNotificationStats>((event, emit) async {
      try {
        final response = await _apiClient
            .get('/notification/stats?userId=${event.prestataireId}');
        if (response.statusCode == 200) {
          final stats = jsonDecode(response.body);
          emit(NotificationStatsLoaded(stats));
        } else {
          emit(
              NotificationsError('Erreur lors du chargement des statistiques'));
        }
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });

    // 🔔 FILTRER LES NOTIFICATIONS
    on<FilterNotifications>((event, emit) async {
      emit(NotificationsLoading());
      try {
        List<String> params = [];

        if (event.type != null) params.add('type=${event.type}');
        if (event.priority != null) params.add('priorite=${event.priority}');
        if (event.status != null) params.add('statut=${event.status}');
        if (event.dateDebut != null)
          params.add('dateDebut=${event.dateDebut!.toIso8601String()}');
        if (event.dateFin != null)
          params.add('dateFin=${event.dateFin!.toIso8601String()}');

        final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
        final response = await _apiClient
            .get('/notification/user/${event.prestataireId}$queryString');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> notifications = data['notifications'] ?? [];
          final int totalUnread = data['nonLues'] ?? 0;
          final bool hasMore = data['currentPage'] < data['totalPages'];
          final int currentPage = data['currentPage'] ?? 1;

          emit(NotificationsLoaded(
            notifications: notifications,
            totalUnread: totalUnread,
            hasMore: hasMore,
            currentPage: currentPage,
          ));
        } else {
          emit(NotificationsError('Erreur lors du filtrage'));
        }
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });

    // 🔔 CHARGER PLUS DE NOTIFICATIONS (PAGINATION)
    on<LoadMoreNotifications>((event, emit) async {
      try {
        final response = await _apiClient.get(
            '/notification/user/${event.prestataireId}?page=${event.page}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> newNotifications = data['notifications'] ?? [];
          final bool hasMore = data['currentPage'] < data['totalPages'];

          // Si on a déjà des notifications chargées, les combiner
          if (state is NotificationsLoaded) {
            final currentState = state as NotificationsLoaded;
            final combinedNotifications = [
              ...currentState.notifications,
              ...newNotifications
            ];

            emit(NotificationsLoaded(
              notifications: combinedNotifications,
              totalUnread: currentState.totalUnread,
              stats: currentState.stats,
              hasMore: hasMore,
              currentPage: event.page,
            ));
          } else {
            emit(NotificationsLoaded(
              notifications: newNotifications,
              totalUnread: data['nonLues'] ?? 0,
              hasMore: hasMore,
              currentPage: event.page,
            ));
          }
        } else {
          emit(NotificationsError(
              'Erreur lors du chargement des notifications'));
        }
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });

    // 🔔 RECHERCHER DANS LES NOTIFICATIONS
    on<SearchNotifications>((event, emit) async {
      emit(NotificationsLoading());
      try {
        final response = await _apiClient.get(
            '/notification/search?userId=${event.prestataireId}&query=${event.query}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> results = data['notifications'] ?? [];
          emit(NotificationsSearched(results, event.query));
        } else {
          emit(NotificationsError('Erreur lors de la recherche'));
        }
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });

    // 🔔 ACTUALISER LES NOTIFICATIONS
    on<RefreshNotifications>((event, emit) async {
      try {
        final response =
            await _apiClient.get('/notification/user/${event.prestataireId}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> notifications = data['notifications'] ?? [];
          final int totalUnread = data['nonLues'] ?? 0;

          emit(NotificationsRefreshed(notifications, totalUnread));
        } else {
          emit(NotificationsError('Erreur lors de l\'actualisation'));
        }
      } catch (e) {
        emit(NotificationsError('Erreur de connexion: $e'));
      }
    });
  }

  void setToken(String token) {
    _currentToken = token;
  }
}
