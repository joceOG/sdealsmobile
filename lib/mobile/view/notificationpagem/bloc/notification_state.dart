import 'package:equatable/equatable.dart';

// 🎯 ÉTATS POUR LES NOTIFICATIONS CLIENT
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

// ⏳ État initial
class NotificationInitial extends NotificationState {}

// 📱 Chargement des notifications
class NotificationLoading extends NotificationState {}

// ✅ Notifications chargées avec succès
class NotificationLoaded extends NotificationState {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final String? currentFilter;
  final bool hasMore;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
    this.currentFilter,
    this.hasMore = false,
  });

  @override
  List<Object?> get props =>
      [notifications, unreadCount, currentFilter, hasMore];
}

// ❌ Erreur lors du chargement
class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

// 🔄 Rafraîchissement en cours
class NotificationRefreshing extends NotificationState {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;

  const NotificationRefreshing({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}

// ✅ Action réussie (marquer comme lu, supprimer, etc.)
class NotificationActionSuccess extends NotificationState {
  final String message;
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;

  const NotificationActionSuccess({
    required this.message,
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [message, notifications, unreadCount];
}
