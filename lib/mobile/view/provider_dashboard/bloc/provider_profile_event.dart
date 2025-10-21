// 🎯 ÉVÉNEMENTS POUR LE BLoC PROFIL PRESTATAIRE
abstract class ProviderProfileEvent {}

// 👤 CHARGER LE PROFIL DU PRESTATAIRE
class LoadProviderProfile extends ProviderProfileEvent {
  final String prestataireId;
  LoadProviderProfile(this.prestataireId);
}

// 👤 METTRE À JOUR LE PROFIL
class UpdateProviderProfile extends ProviderProfileEvent {
  final String prestataireId;
  final Map<String, dynamic> profileData;
  UpdateProviderProfile(this.prestataireId, this.profileData);
}

// 👤 CHARGER LES STATISTIQUES
class LoadProviderStats extends ProviderProfileEvent {
  final String prestataireId;
  LoadProviderStats(this.prestataireId);
}

// 👤 CHARGER L'ACTIVITÉ RÉCENTE
class LoadRecentActivity extends ProviderProfileEvent {
  final String prestataireId;
  final int limit;
  LoadRecentActivity(this.prestataireId, {this.limit = 10});
}

// 👤 CHARGER LES RÉCOMPENSES
class LoadAchievements extends ProviderProfileEvent {
  final String prestataireId;
  LoadAchievements(this.prestataireId);
}

// 👤 CHARGER LES PARAMÈTRES
class LoadProviderSettings extends ProviderProfileEvent {
  final String prestataireId;
  LoadProviderSettings(this.prestataireId);
}

// 👤 METTRE À JOUR LES PARAMÈTRES
class UpdateProviderSettings extends ProviderProfileEvent {
  final String prestataireId;
  final Map<String, dynamic> settings;
  UpdateProviderSettings(this.prestataireId, this.settings);
}

// 👤 CHARGER LES NOTIFICATIONS
class LoadNotificationSettings extends ProviderProfileEvent {
  final String prestataireId;
  LoadNotificationSettings(this.prestataireId);
}

// 👤 METTRE À JOUR LES NOTIFICATIONS
class UpdateNotificationSettings extends ProviderProfileEvent {
  final String prestataireId;
  final Map<String, bool> notificationSettings;
  UpdateNotificationSettings(this.prestataireId, this.notificationSettings);
}

// 👤 CHARGER LES SERVICES
class LoadProviderServices extends ProviderProfileEvent {
  final String prestataireId;
  LoadProviderServices(this.prestataireId);
}

// 👤 METTRE À JOUR LES SERVICES
class UpdateProviderServices extends ProviderProfileEvent {
  final String prestataireId;
  final List<String> services;
  UpdateProviderServices(this.prestataireId, this.services);
}

// 👤 CHARGER LA ZONE DE SERVICE
class LoadServiceZone extends ProviderProfileEvent {
  final String prestataireId;
  LoadServiceZone(this.prestataireId);
}

// 👤 METTRE À JOUR LA ZONE DE SERVICE
class UpdateServiceZone extends ProviderProfileEvent {
  final String prestataireId;
  final Map<String, dynamic> zoneData;
  UpdateServiceZone(this.prestataireId, this.zoneData);
}

// 👤 CHARGER LES DOCUMENTS
class LoadProviderDocuments extends ProviderProfileEvent {
  final String prestataireId;
  LoadProviderDocuments(this.prestataireId);
}

// 👤 UPLOADER UN DOCUMENT
class UploadDocument extends ProviderProfileEvent {
  final String prestataireId;
  final String documentType;
  final String filePath;
  UploadDocument(this.prestataireId, this.documentType, this.filePath);
}

// 👤 SUPPRIMER UN DOCUMENT
class DeleteDocument extends ProviderProfileEvent {
  final String prestataireId;
  final String documentId;
  DeleteDocument(this.prestataireId, this.documentId);
}

// 👤 CHANGER LE MOT DE PASSE
class ChangePassword extends ProviderProfileEvent {
  final String prestataireId;
  final String currentPassword;
  final String newPassword;
  ChangePassword(this.prestataireId, this.currentPassword, this.newPassword);
}

// 👤 DÉSACTIVER LE COMPTE
class DeactivateAccount extends ProviderProfileEvent {
  final String prestataireId;
  final String reason;
  DeactivateAccount(this.prestataireId, this.reason);
}

// 👤 SUPPRIMER LE COMPTE
class DeleteAccount extends ProviderProfileEvent {
  final String prestataireId;
  final String reason;
  DeleteAccount(this.prestataireId, this.reason);
}

// 👤 ACTUALISER LE PROFIL
class RefreshProviderProfile extends ProviderProfileEvent {
  final String prestataireId;
  RefreshProviderProfile(this.prestataireId);
}
