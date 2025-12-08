import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/api_client.dart';
import 'notification_event.dart';
import 'notification_state.dart';

// 🎯 BLOC POUR LES NOTIFICATIONS CLIENT
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiClient _apiClient;
  String? _currentToken;

  NotificationBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(NotificationInitial()) {
    // 📱 Charger les notifications d'un utilisateur
    on<LoadUserNotifications>(_onLoadUserNotifications);

    // 🔔 Marquer une notification comme lue
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);

    // ✅ Marquer toutes les notifications comme lues
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);

    // 🗑️ Supprimer une notification
    on<DeleteNotification>(_onDeleteNotification);

    // 🔄 Rafraîchir les notifications
    on<RefreshNotifications>(_onRefreshNotifications);

    // 🔍 Filtrer les notifications
    on<FilterNotifications>(_onFilterNotifications);

    // 📊 Charger le nombre de notifications non lues
    on<LoadUnreadCount>(_onLoadUnreadCount);

    // 📄 Charger plus de notifications (pagination)
    on<LoadMoreNotifications>(_onLoadMoreNotifications);
  }

  // 🔑 Définir le token d'authentification
  void setToken(String token) {
    _currentToken = token;
  }

  // 📱 CHARGER LES NOTIFICATIONS D'UN UTILISATEUR
  Future<void> _onLoadUserNotifications(
    LoadUserNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(NotificationLoading());

      if (_currentToken == null) {
        emit(const NotificationError('Token d\'authentification manquant'));
        return;
      }

      final notifications = await _apiClient.getUserNotifications(
        token: _currentToken!,
        userId: event.userId,
        statut: event.statut,
        limit: event.limit,
        offset: event.offset,
      );

      final unreadCount = await _apiClient.getUserUnreadNotificationCount(
        token: _currentToken!,
        userId: event.userId,
      );

      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
        currentFilter: event.statut,
        hasMore: notifications.length >= event.limit,
      ));
    } catch (e) {
      emit(NotificationError('Erreur lors du chargement: $e'));
    }
  }

  // 🔔 MARQUER UNE NOTIFICATION COMME LUE
  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (_currentToken == null) {
        emit(const NotificationError('Token d\'authentification manquant'));
        return;
      }

      await _apiClient.markUserNotificationAsRead(
        token: _currentToken!,
        notificationId: event.notificationId,
      );

      // Recharger les notifications pour mettre à jour l'état
      final currentState = state;
      if (currentState is NotificationLoaded) {
        // Trouver l'userId depuis l'état actuel ou utiliser un événement de rechargement
        add(RefreshNotifications(''));
      }
    } catch (e) {
      emit(NotificationError('Erreur lors de la mise à jour: $e'));
    }
  }

  // ✅ MARQUER TOUTES LES NOTIFICATIONS COMME LUES
  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (_currentToken == null) {
        emit(const NotificationError('Token d\'authentification manquant'));
        return;
      }

      await _apiClient.markAllUserNotificationsAsRead(
        token: _currentToken!,
        userId: event.userId,
      );

      // Recharger les notifications
      add(LoadUserNotifications(userId: event.userId));
    } catch (e) {
      emit(NotificationError('Erreur lors de la mise à jour: $e'));
    }
  }

  // 🗑️ SUPPRIMER UNE NOTIFICATION
  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (_currentToken == null) {
        emit(const NotificationError('Token d\'authentification manquant'));
        return;
      }

      // ✅ Appeler API pour supprimer
      final success = await _apiClient.deleteNotification(
        token: _currentToken!,
        notificationId: event.notificationId,
      );

      if (success) {
        // Retirer localement
        final currentState = state;
        if (currentState is NotificationLoaded) {
          final updatedNotifs = currentState.notifications
              .where((n) => n['_id'] != event.notificationId)
              .toList();

          emit(currentState.copyWith(
            notifications: updatedNotifs,
          ));
        }
      } else {
        emit(const NotificationError('Impossible de supprimer'));
      }
    } catch (e) {
      emit(NotificationError('Erreur lors de la suppression: $e'));
    }
  }

  // 🔄 RAFRAÎCHIR LES NOTIFICATIONS
  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is NotificationLoaded) {
        emit(NotificationRefreshing(
          notifications: currentState.notifications,
          unreadCount: currentState.unreadCount,
        ));
      }

      // Recharger avec l'userId actuel
      final currentState2 = state;
      if (currentState2 is NotificationLoaded) {
        // Utiliser l'userId du dernier état chargé
        add(LoadUserNotifications(userId: event.userId));
      }
    } catch (e) {
      emit(NotificationError('Erreur lors du rafraîchissement: $e'));
    }
  }

  // 🔍 FILTRER LES NOTIFICATIONS
  Future<void> _onFilterNotifications(
    FilterNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (_currentToken == null) {
        emit(const NotificationError('Token d\'authentification manquant'));
        return;
      }

      // Trouver l'userId depuis l'état actuel
      final currentState = state;
      if (currentState is NotificationLoaded) {
        add(LoadUserNotifications(
          userId: '', // Sera défini par l'écran
          statut: event.statut,
        ));
      }
    } catch (e) {
      emit(NotificationError('Erreur lors du filtrage: $e'));
    }
  }

  // 📊 CHARGER LE NOMBRE DE NOTIFICATIONS NON LUES
  Future<void> _onLoadUnreadCount(
    LoadUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (_currentToken == null) {
        return;
      }

      final unreadCount = await _apiClient.getUserUnreadNotificationCount(
        token: _currentToken!,
        userId: event.userId,
      );

      final currentState = state;
      if (currentState is NotificationLoaded) {
        emit(NotificationLoaded(
          notifications: currentState.notifications,
          unreadCount: unreadCount,
          currentFilter: currentState.currentFilter,
          hasMore: currentState.hasMore,
        ));
      }
    } catch (e) {
      // Ne pas faire échouer l'état principal pour une erreur de comptage
      print('Erreur chargement compteur: $e');
    }
  }

  // 📄 CHARGER PLUS DE NOTIFICATIONS (PAGINATION)
  Future<void> _onLoadMoreNotifications(
    LoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! NotificationLoaded) return;
      if (!currentState.hasMore) return; // Déjà tout chargé

      if (_currentToken == null) return;

      final currentOffset = currentState.notifications.length;

      final moreNotifications = await _apiClient.getUserNotifications(
        token: _currentToken!,
        userId: event.userId,
        statut: currentState.currentFilter,
        limit: 50,
        offset: currentOffset,
      );

      if (moreNotifications.isEmpty) {
        // Plus de notifications
        emit(currentState.copyWith(hasMore: false));
        return;
      }

      final allNotifications = [
        ...currentState.notifications,
        ...moreNotifications,
      ];

      emit(NotificationLoaded(
        notifications: allNotifications,
        unreadCount: currentState.unreadCount,
        currentFilter: currentState.currentFilter,
        hasMore: moreNotifications.length >= 50,
      ));
    } catch (e) {
      print('Erreur chargement pagination: $e');
      // Ne pas fail, garder l'état actuel
    }
  }
}
