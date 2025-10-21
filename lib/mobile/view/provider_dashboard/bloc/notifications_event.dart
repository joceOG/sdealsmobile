// 🎯 ÉVÉNEMENTS POUR LE BLoC NOTIFICATIONS PRESTATAIRE
abstract class NotificationsEvent {}

// 🔔 CHARGER LES NOTIFICATIONS DU PRESTATAIRE
class LoadPrestataireNotifications extends NotificationsEvent {
  final String prestataireId;
  LoadPrestataireNotifications(this.prestataireId);
}

// 🔔 CHARGER LES NOTIFICATIONS NON LUES
class LoadUnreadNotifications extends NotificationsEvent {
  final String prestataireId;
  LoadUnreadNotifications(this.prestataireId);
}

// 🔔 CHARGER LES NOTIFICATIONS PAR TYPE
class LoadNotificationsByType extends NotificationsEvent {
  final String prestataireId;
  final String type;
  LoadNotificationsByType(this.prestataireId, this.type);
}

// 🔔 CHARGER LES NOTIFICATIONS PAR PRIORITÉ
class LoadNotificationsByPriority extends NotificationsEvent {
  final String prestataireId;
  final String priority;
  LoadNotificationsByPriority(this.prestataireId, this.priority);
}

// 🔔 MARQUER UNE NOTIFICATION COMME LUE
class MarkNotificationAsRead extends NotificationsEvent {
  final String notificationId;
  final String prestataireId;
  MarkNotificationAsRead(this.notificationId, this.prestataireId);
}

// 🔔 MARQUER TOUTES LES NOTIFICATIONS COMME LUES
class MarkAllNotificationsAsRead extends NotificationsEvent {
  final String prestataireId;
  MarkAllNotificationsAsRead(this.prestataireId);
}

// 🔔 ARCHIVER UNE NOTIFICATION
class ArchiveNotification extends NotificationsEvent {
  final String notificationId;
  final String prestataireId;
  ArchiveNotification(this.notificationId, this.prestataireId);
}

// 🔔 SUPPRIMER UNE NOTIFICATION
class DeleteNotification extends NotificationsEvent {
  final String notificationId;
  final String prestataireId;
  DeleteNotification(this.notificationId, this.prestataireId);
}

// 🔔 CHARGER LES STATISTIQUES
class LoadNotificationStats extends NotificationsEvent {
  final String prestataireId;
  LoadNotificationStats(this.prestataireId);
}

// 🔔 FILTRER LES NOTIFICATIONS
class FilterNotifications extends NotificationsEvent {
  final String prestataireId;
  final String? type;
  final String? priority;
  final String? status;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  FilterNotifications(
    this.prestataireId, {
    this.type,
    this.priority,
    this.status,
    this.dateDebut,
    this.dateFin,
  });
}

// 🔔 CHARGER PLUS DE NOTIFICATIONS (PAGINATION)
class LoadMoreNotifications extends NotificationsEvent {
  final String prestataireId;
  final int page;
  LoadMoreNotifications(this.prestataireId, this.page);
}

// 🔔 RECHERCHER DANS LES NOTIFICATIONS
class SearchNotifications extends NotificationsEvent {
  final String prestataireId;
  final String query;
  SearchNotifications(this.prestataireId, this.query);
}

// 🔔 ACTUALISER LES NOTIFICATIONS
class RefreshNotifications extends NotificationsEvent {
  final String prestataireId;
  RefreshNotifications(this.prestataireId);
}
