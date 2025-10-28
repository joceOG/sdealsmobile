import 'package:equatable/equatable.dart';

// 🎯 ÉVÉNEMENTS POUR LES NOTIFICATIONS CLIENT
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

// 📱 Charger les notifications d'un utilisateur
class LoadUserNotifications extends NotificationEvent {
  final String userId;
  final String? statut;
  final int limit;
  final int offset;

  const LoadUserNotifications({
    required this.userId,
    this.statut,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [userId, statut, limit, offset];
}

// 🔔 Marquer une notification comme lue
class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

// ✅ Marquer toutes les notifications comme lues
class MarkAllNotificationsAsRead extends NotificationEvent {
  final String userId;

  const MarkAllNotificationsAsRead(this.userId);

  @override
  List<Object?> get props => [userId];
}

// 🗑️ Supprimer une notification
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

// 🔄 Rafraîchir les notifications
class RefreshNotifications extends NotificationEvent {
  final String userId;

  const RefreshNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

// 🔍 Filtrer les notifications
class FilterNotifications extends NotificationEvent {
  final String? statut;
  final String? type;

  const FilterNotifications({this.statut, this.type});

  @override
  List<Object?> get props => [statut, type];
}

// 📊 Charger le nombre de notifications non lues
class LoadUnreadCount extends NotificationEvent {
  final String userId;

  const LoadUnreadCount(this.userId);

  @override
  List<Object?> get props => [userId];
}
