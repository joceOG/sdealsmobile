import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/api_client.dart';
import 'notification_event.dart';
import 'notification_state.dart';

/// Intervalles alignés sur soutralideals-web (`useNotifications` / `useUnreadCount`).
const _kUnreadPollInterval = Duration(seconds: 90);
const _kListPollInterval = Duration(seconds: 120);

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiClient _apiClient;
  bool _hasSession = false;
  String? _currentUserId;
  Timer? _unreadTimer;
  Timer? _listTimer;

  NotificationBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(NotificationInitial()) {
    on<LoadUserNotifications>(_onLoadUserNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<FilterNotifications>(_onFilterNotifications);
    on<LoadUnreadCount>(_onLoadUnreadCount);
    on<LoadMoreNotifications>(_onLoadMoreNotifications);
    on<StartNotificationPolling>(_onStartPolling);
    on<StopNotificationPolling>(_onStopPolling);
    on<PollUnreadCountTick>(_onPollUnreadCountTick);
    on<PollNotificationsTick>(_onPollNotificationsTick);
  }

  void setToken(String token) {
    _hasSession = token.isNotEmpty;
  }

  void _clearPolling() {
    _unreadTimer?.cancel();
    _listTimer?.cancel();
    _unreadTimer = null;
    _listTimer = null;
  }

  Future<void> _onStartPolling(
    StartNotificationPolling event,
    Emitter<NotificationState> emit,
  ) async {
    _currentUserId = event.userId;
    _clearPolling();
    add(LoadUnreadCount(event.userId));

    _unreadTimer = Timer.periodic(_kUnreadPollInterval, (_) {
      if (_currentUserId == null || _currentUserId!.isEmpty) return;
      add(PollUnreadCountTick(_currentUserId!));
    });

    _listTimer = Timer.periodic(_kListPollInterval, (_) {
      if (_currentUserId == null || _currentUserId!.isEmpty) return;
      add(PollNotificationsTick(_currentUserId!));
    });
  }

  Future<void> _onStopPolling(
    StopNotificationPolling event,
    Emitter<NotificationState> emit,
  ) async {
    _clearPolling();
  }

  Future<void> _onPollUnreadCountTick(
    PollUnreadCountTick event,
    Emitter<NotificationState> emit,
  ) async {
    if (!_hasSession) return;
    try {
      final unreadCount = await _apiClient.getUserUnreadNotificationCount(
        userId: event.userId,
      );
      final currentState = state;
      if (currentState is NotificationLoaded) {
        if (currentState.unreadCount == unreadCount) return;
        emit(NotificationLoaded(
          notifications: currentState.notifications,
          unreadCount: unreadCount,
          currentFilter: currentState.currentFilter,
          hasMore: currentState.hasMore,
        ));
      } else {
        emit(NotificationLoaded(
          notifications: const [],
          unreadCount: unreadCount,
          hasMore: true,
        ));
      }
    } catch (_) {}
  }

  Future<void> _onPollNotificationsTick(
    PollNotificationsTick event,
    Emitter<NotificationState> emit,
  ) async {
    if (!_hasSession) return;
    if (state is! NotificationLoaded && state is! NotificationRefreshing) {
      add(PollUnreadCountTick(event.userId));
      return;
    }
    final filter = state is NotificationLoaded
        ? (state as NotificationLoaded).currentFilter
        : null;
    try {
      final notifications = await _apiClient.getUserNotifications(
        userId: event.userId,
        statut: filter,
        limit: 50,
        offset: 0,
      );
      final unreadCount = await _apiClient.getUserUnreadNotificationCount(
        userId: event.userId,
      );
      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
        currentFilter: filter,
        hasMore: notifications.length >= 50,
      ));
    } catch (_) {}
  }

  Future<void> _onLoadUserNotifications(
    LoadUserNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(NotificationLoading());

      if (!_hasSession) {
        emit(const NotificationError('Token d\'authentification manquant'));
        return;
      }

      if (event.userId.isNotEmpty) _currentUserId = event.userId;

      final notifications = await _apiClient.getUserNotifications(
        userId: event.userId,
        statut: event.statut,
        limit: event.limit,
        offset: event.offset,
      );

      final unreadCount = await _apiClient.getUserUnreadNotificationCount(
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

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (!_hasSession) {
        emit(const NotificationError('Token d\'authentification manquant'));
        return;
      }

      await _apiClient.markUserNotificationAsRead(
        notificationId: event.notificationId,
      );

      if (state is NotificationLoaded) {
        add(RefreshNotifications(_currentUserId ?? ''));
      }
    } catch (e) {
      emit(NotificationError('Erreur lors de la mise à jour: $e'));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (!_hasSession) {
        emit(const NotificationError('Token d\'authentification manquant'));
        return;
      }

      await _apiClient.markAllUserNotificationsAsRead(
        userId: event.userId,
      );

      add(LoadUserNotifications(userId: event.userId));
    } catch (e) {
      emit(NotificationError('Erreur lors de la mise à jour: $e'));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (!_hasSession) {
        emit(const NotificationError('Token d\'authentification manquant'));
        return;
      }

      final success = await _apiClient.deleteNotification(
        notificationId: event.notificationId,
      );

      if (success) {
        final currentState = state;
        if (currentState is NotificationLoaded) {
          final updatedNotifs = currentState.notifications
              .where((n) => n['_id'] != event.notificationId)
              .toList();
          emit(currentState.copyWith(notifications: updatedNotifs));
        }
      } else {
        emit(const NotificationError('Impossible de supprimer'));
      }
    } catch (e) {
      emit(NotificationError('Erreur lors de la suppression: $e'));
    }
  }

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

      final userId =
          event.userId.isNotEmpty ? event.userId : (_currentUserId ?? '');
      if (userId.isNotEmpty) {
        add(LoadUserNotifications(userId: userId));
      }
    } catch (e) {
      emit(NotificationError('Erreur lors du rafraîchissement: $e'));
    }
  }

  Future<void> _onFilterNotifications(
    FilterNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (!_hasSession) {
        emit(const NotificationError('Token d\'authentification manquant'));
        return;
      }

      final userId = _currentUserId ?? '';
      if (userId.isNotEmpty) {
        add(LoadUserNotifications(
          userId: userId,
          statut: event.statut,
        ));
      }
    } catch (e) {
      emit(NotificationError('Erreur lors du filtrage: $e'));
    }
  }

  Future<void> _onLoadUnreadCount(
    LoadUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (!_hasSession) return;

      final unreadCount = await _apiClient.getUserUnreadNotificationCount(
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
      } else {
        emit(NotificationLoaded(
          notifications: const [],
          unreadCount: unreadCount,
          hasMore: true,
        ));
      }
    } catch (e) {
      print('Erreur chargement compteur: $e');
    }
  }

  Future<void> _onLoadMoreNotifications(
    LoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! NotificationLoaded) return;
      if (!currentState.hasMore) return;
      if (!_hasSession) return;

      final moreNotifications = await _apiClient.getUserNotifications(
        userId: event.userId,
        statut: currentState.currentFilter,
        limit: 50,
        offset: currentState.notifications.length,
      );

      if (moreNotifications.isEmpty) {
        emit(currentState.copyWith(hasMore: false));
        return;
      }

      emit(NotificationLoaded(
        notifications: [...currentState.notifications, ...moreNotifications],
        unreadCount: currentState.unreadCount,
        currentFilter: currentState.currentFilter,
        hasMore: moreNotifications.length >= 50,
      ));
    } catch (e) {
      print('Erreur chargement pagination: $e');
    }
  }

  @override
  Future<void> close() {
    _clearPolling();
    return super.close();
  }
}
