// 🎯 ÉTATS POUR LE BLoC PROFIL PRESTATAIRE
abstract class ProviderProfileState {}

// 👤 ÉTAT INITIAL
class ProviderProfileInitial extends ProviderProfileState {}

// 👤 CHARGEMENT EN COURS
class ProviderProfileLoading extends ProviderProfileState {}

// 👤 PROFIL CHARGÉ
class ProviderProfileLoaded extends ProviderProfileState {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> stats;
  final List<dynamic> recentActivity;
  final List<dynamic> achievements;
  final Map<String, dynamic> settings;
  final Map<String, bool> notificationSettings;
  final List<String> services;
  final Map<String, dynamic> serviceZone;
  final List<dynamic> documents;

  ProviderProfileLoaded({
    required this.profile,
    required this.stats,
    required this.recentActivity,
    required this.achievements,
    required this.settings,
    required this.notificationSettings,
    required this.services,
    required this.serviceZone,
    required this.documents,
  });

  ProviderProfileLoaded copyWith({
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    List<dynamic>? recentActivity,
    List<dynamic>? achievements,
    Map<String, dynamic>? settings,
    Map<String, bool>? notificationSettings,
    List<String>? services,
    Map<String, dynamic>? serviceZone,
    List<dynamic>? documents,
  }) {
    return ProviderProfileLoaded(
      profile: profile ?? this.profile,
      stats: stats ?? this.stats,
      recentActivity: recentActivity ?? this.recentActivity,
      achievements: achievements ?? this.achievements,
      settings: settings ?? this.settings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      services: services ?? this.services,
      serviceZone: serviceZone ?? this.serviceZone,
      documents: documents ?? this.documents,
    );
  }
}

// 👤 PROFIL MIS À JOUR
class ProviderProfileUpdated extends ProviderProfileState {
  final Map<String, dynamic> updatedProfile;
  ProviderProfileUpdated(this.updatedProfile);
}

// 👤 STATISTIQUES CHARGÉES
class ProviderStatsLoaded extends ProviderProfileState {
  final Map<String, dynamic> stats;
  ProviderStatsLoaded(this.stats);
}

// 👤 ACTIVITÉ CHARGÉE
class RecentActivityLoaded extends ProviderProfileState {
  final List<dynamic> activities;
  RecentActivityLoaded(this.activities);
}

// 👤 RÉCOMPENSES CHARGÉES
class AchievementsLoaded extends ProviderProfileState {
  final List<dynamic> achievements;
  AchievementsLoaded(this.achievements);
}

// 👤 PARAMÈTRES CHARGÉS
class ProviderSettingsLoaded extends ProviderProfileState {
  final Map<String, dynamic> settings;
  ProviderSettingsLoaded(this.settings);
}

// 👤 PARAMÈTRES MIS À JOUR
class ProviderSettingsUpdated extends ProviderProfileState {
  final Map<String, dynamic> updatedSettings;
  ProviderSettingsUpdated(this.updatedSettings);
}

// 👤 NOTIFICATIONS CHARGÉES
class NotificationSettingsLoaded extends ProviderProfileState {
  final Map<String, bool> notificationSettings;
  NotificationSettingsLoaded(this.notificationSettings);
}

// 👤 NOTIFICATIONS MISES À JOUR
class NotificationSettingsUpdated extends ProviderProfileState {
  final Map<String, bool> updatedNotificationSettings;
  NotificationSettingsUpdated(this.updatedNotificationSettings);
}

// 👤 SERVICES CHARGÉS
class ProviderServicesLoaded extends ProviderProfileState {
  final List<String> services;
  ProviderServicesLoaded(this.services);
}

// 👤 SERVICES MIS À JOUR
class ProviderServicesUpdated extends ProviderProfileState {
  final List<String> updatedServices;
  ProviderServicesUpdated(this.updatedServices);
}

// 👤 ZONE DE SERVICE CHARGÉE
class ServiceZoneLoaded extends ProviderProfileState {
  final Map<String, dynamic> serviceZone;
  ServiceZoneLoaded(this.serviceZone);
}

// 👤 ZONE DE SERVICE MISE À JOUR
class ServiceZoneUpdated extends ProviderProfileState {
  final Map<String, dynamic> updatedServiceZone;
  ServiceZoneUpdated(this.updatedServiceZone);
}

// 👤 DOCUMENTS CHARGÉS
class ProviderDocumentsLoaded extends ProviderProfileState {
  final List<dynamic> documents;
  ProviderDocumentsLoaded(this.documents);
}

// 👤 DOCUMENT UPLOADÉ
class DocumentUploaded extends ProviderProfileState {
  final Map<String, dynamic> uploadedDocument;
  DocumentUploaded(this.uploadedDocument);
}

// 👤 DOCUMENT SUPPRIMÉ
class DocumentDeleted extends ProviderProfileState {
  final String deletedDocumentId;
  DocumentDeleted(this.deletedDocumentId);
}

// 👤 MOT DE PASSE CHANGÉ
class PasswordChanged extends ProviderProfileState {
  PasswordChanged();
}

// 👤 COMPTE DÉSACTIVÉ
class AccountDeactivated extends ProviderProfileState {
  final String reason;
  AccountDeactivated(this.reason);
}

// 👤 COMPTE SUPPRIMÉ
class AccountDeleted extends ProviderProfileState {
  final String reason;
  AccountDeleted(this.reason);
}

// 👤 PROFIL ACTUALISÉ
class ProviderProfileRefreshed extends ProviderProfileState {
  final Map<String, dynamic> refreshedProfile;
  ProviderProfileRefreshed(this.refreshedProfile);
}

// 👤 ERREUR
class ProviderProfileError extends ProviderProfileState {
  final String message;
  ProviderProfileError(this.message);
}
