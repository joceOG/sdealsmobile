// 🎯 ÉTATS POUR LE BLoC NOTIFICATIONS PRESTATAIRE
abstract class NotificationsState {}

// 🔔 ÉTAT INITIAL
class NotificationsInitial extends NotificationsState {}

// 🔔 CHARGEMENT EN COURS
class NotificationsLoading extends NotificationsState {}

// 🔔 NOTIFICATIONS CHARGÉES
class NotificationsLoaded extends NotificationsState {
  final List<dynamic> notifications;
  final int totalUnread;
  final Map<String, dynamic>? stats;
  final bool hasMore;
  final int currentPage;

  NotificationsLoaded({
    required this.notifications,
    required this.totalUnread,
    this.stats,
    required this.hasMore,
    required this.currentPage,
  });

  NotificationsLoaded copyWith({
    List<dynamic>? notifications,
    int? totalUnread,
    Map<String, dynamic>? stats,
    bool? hasMore,
    int? currentPage,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      totalUnread: totalUnread ?? this.totalUnread,
      stats: stats ?? this.stats,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// 🔔 NOTIFICATION MARQUÉE COMME LUE
class NotificationMarkedAsRead extends NotificationsState {
  final String notificationId;
  NotificationMarkedAsRead(this.notificationId);
}

// 🔔 TOUTES LES NOTIFICATIONS MARQUÉES COMME LUES
class AllNotificationsMarkedAsRead extends NotificationsState {
  final int modifiedCount;
  AllNotificationsMarkedAsRead(this.modifiedCount);
}

// 🔔 NOTIFICATION ARCHIVÉE
class NotificationArchived extends NotificationsState {
  final String notificationId;
  NotificationArchived(this.notificationId);
}

// 🔔 NOTIFICATION SUPPRIMÉE
class NotificationDeleted extends NotificationsState {
  final String notificationId;
  NotificationDeleted(this.notificationId);
}

// 🔔 STATISTIQUES CHARGÉES
class NotificationStatsLoaded extends NotificationsState {
  final Map<String, dynamic> stats;
  NotificationStatsLoaded(this.stats);
}

// 🔔 RECHERCHE EFFECTUÉE
class NotificationsSearched extends NotificationsState {
  final List<dynamic> results;
  final String query;
  NotificationsSearched(this.results, this.query);
}

// 🔔 NOTIFICATIONS ACTUALISÉES
class NotificationsRefreshed extends NotificationsState {
  final List<dynamic> notifications;
  final int totalUnread;
  NotificationsRefreshed(this.notifications, this.totalUnread);
}

// 🔔 ERREUR
class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
}
