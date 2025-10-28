import 'package:equatable/equatable.dart';

// 🎯 ÉVÉNEMENTS POUR LES NOTIFICATIONS CLIENT
abstract class ClientNotificationsEvent extends Equatable {
  const ClientNotificationsEvent();

  @override
  List<Object?> get props => [];
}

// ✅ Charger les notifications d'un client
class LoadClientNotifications extends ClientNotificationsEvent {
  final String userId;
  final String? statut;
  final int limit;
  final int offset;

  const LoadClientNotifications(
    this.userId, {
    this.statut,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [userId, statut, limit, offset];
}

// ✅ Marquer une notification comme lue
class MarkNotificationAsRead extends ClientNotificationsEvent {
  final String notificationId;

  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

// ✅ Marquer toutes les notifications comme lues
class MarkAllNotificationsAsRead extends ClientNotificationsEvent {
  final String userId;

  const MarkAllNotificationsAsRead(this.userId);

  @override
  List<Object?> get props => [userId];
}

// ✅ Supprimer une notification
class DeleteNotification extends ClientNotificationsEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

// ✅ Obtenir le nombre de notifications non lues
class GetUnreadNotificationCount extends ClientNotificationsEvent {
  final String userId;

  const GetUnreadNotificationCount(this.userId);

  @override
  List<Object?> get props => [userId];
}

// ✅ Rafraîchir les notifications
class RefreshNotifications extends ClientNotificationsEvent {
  final String userId;

  const RefreshNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

// ✅ Filtrer les notifications
class FilterNotifications extends ClientNotificationsEvent {
  final String? statut;
  final String? type;
  final String? priorite;

  const FilterNotifications({
    this.statut,
    this.type,
    this.priorite,
  });

  @override
  List<Object?> get props => [statut, type, priorite];
}
