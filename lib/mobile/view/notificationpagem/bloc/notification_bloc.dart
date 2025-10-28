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

      final notifications = await _apiClient.getNotifications(
        token: _currentToken!,
        userId: event.userId,
        statut: event.statut,
        limit: event.limit,
        offset: event.offset,
      );

      final unreadCount = await _apiClient.getUnreadNotificationCount(
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

      await _apiClient.markNotificationAsRead(
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

      await _apiClient.markAllNotificationsAsRead(
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

      // Note: L'API de suppression n'est pas encore implémentée
      // await _apiClient.deleteNotification(
      //   token: _currentToken!,
      //   notificationId: event.notificationId,
      // );

      // Pour l'instant, on recharge les notifications
      final currentState = state;
      if (currentState is NotificationLoaded) {
        add(RefreshNotifications(''));
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

      final unreadCount = await _apiClient.getUnreadNotificationCount(
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
}
