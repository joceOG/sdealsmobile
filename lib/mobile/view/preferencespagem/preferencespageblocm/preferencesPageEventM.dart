import 'package:equatable/equatable.dart';

abstract class PreferencesPageEventM extends Equatable {
  const PreferencesPageEventM();

  @override
  List<Object?> get props => [];
}

// 📋 CHARGER LES PRÉFÉRENCES
class LoadPreferencesM extends PreferencesPageEventM {
  final String utilisateurId;

  const LoadPreferencesM({required this.utilisateurId});

  @override
  List<Object?> get props => [utilisateurId];
}

// 🌍 METTRE À JOUR LA LANGUE
class UpdateLanguageM extends PreferencesPageEventM {
  final String utilisateurId;
  final String langue;

  const UpdateLanguageM({
    required this.utilisateurId,
    required this.langue,
  });

  @override
  List<Object?> get props => [utilisateurId, langue];
}

// 💰 METTRE À JOUR LA DEVISE
class UpdateCurrencyM extends PreferencesPageEventM {
  final String utilisateurId;
  final String devise;

  const UpdateCurrencyM({
    required this.utilisateurId,
    required this.devise,
  });

  @override
  List<Object?> get props => [utilisateurId, devise];
}

// 🌍 METTRE À JOUR LE PAYS
class UpdateCountryM extends PreferencesPageEventM {
  final String utilisateurId;
  final String pays;

  const UpdateCountryM({
    required this.utilisateurId,
    required this.pays,
  });

  @override
  List<Object?> get props => [utilisateurId, pays];
}

// 🕐 METTRE À JOUR LE FUSEAU HORAIRE
class UpdateTimezoneM extends PreferencesPageEventM {
  final String utilisateurId;
  final String fuseauHoraire;

  const UpdateTimezoneM({
    required this.utilisateurId,
    required this.fuseauHoraire,
  });

  @override
  List<Object?> get props => [utilisateurId, fuseauHoraire];
}

// 📅 METTRE À JOUR LE FORMAT DE DATE
class UpdateDateFormatM extends PreferencesPageEventM {
  final String utilisateurId;
  final String formatDate;

  const UpdateDateFormatM({
    required this.utilisateurId,
    required this.formatDate,
  });

  @override
  List<Object?> get props => [utilisateurId, formatDate];
}

// 🕐 METTRE À JOUR LE FORMAT D'HEURE
class UpdateTimeFormatM extends PreferencesPageEventM {
  final String utilisateurId;
  final String formatHeure;

  const UpdateTimeFormatM({
    required this.utilisateurId,
    required this.formatHeure,
  });

  @override
  List<Object?> get props => [utilisateurId, formatHeure];
}

// 💰 METTRE À JOUR LE FORMAT MONÉTAIRE
class UpdateMonetaryFormatM extends PreferencesPageEventM {
  final String utilisateurId;
  final String formatMonetaire;

  const UpdateMonetaryFormatM({
    required this.utilisateurId,
    required this.formatMonetaire,
  });

  @override
  List<Object?> get props => [utilisateurId, formatMonetaire];
}

// 🎨 METTRE À JOUR LE THÈME
class UpdateThemeM extends PreferencesPageEventM {
  final String utilisateurId;
  final String theme;

  const UpdateThemeM({
    required this.utilisateurId,
    required this.theme,
  });

  @override
  List<Object?> get props => [utilisateurId, theme];
}

// 🔔 METTRE À JOUR LES NOTIFICATIONS
class UpdateNotificationsM extends PreferencesPageEventM {
  final String utilisateurId;
  final bool email;
  final bool push;
  final bool sms;
  final String langue;
  final Map<String, bool>? types;

  const UpdateNotificationsM({
    required this.utilisateurId,
    required this.email,
    required this.push,
    required this.sms,
    required this.langue,
    this.types,
  });

  @override
  List<Object?> get props => [utilisateurId, email, push, sms, langue, types];
}

// 📍 METTRE À JOUR LA LOCALISATION
class UpdateLocationM extends PreferencesPageEventM {
  final String utilisateurId;
  final String? ville;
  final String? codePostal;
  final double? latitude;
  final double? longitude;

  const UpdateLocationM({
    required this.utilisateurId,
    this.ville,
    this.codePostal,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props =>
      [utilisateurId, ville, codePostal, latitude, longitude];
}

// 🔍 METTRE À JOUR LES PRÉFÉRENCES DE RECHERCHE
class UpdateSearchPreferencesM extends PreferencesPageEventM {
  final String utilisateurId;
  final int rayon;
  final String triParDefaut;
  final bool afficherPrix;

  const UpdateSearchPreferencesM({
    required this.utilisateurId,
    required this.rayon,
    required this.triParDefaut,
    required this.afficherPrix,
  });

  @override
  List<Object?> get props => [utilisateurId, rayon, triParDefaut, afficherPrix];
}

// 🔒 METTRE À JOUR LES PRÉFÉRENCES DE SÉCURITÉ
class UpdateSecurityPreferencesM extends PreferencesPageEventM {
  final String utilisateurId;
  final bool authentificationDoubleFacteur;
  final bool notificationsConnexion;
  final bool partageDonnees;

  const UpdateSecurityPreferencesM({
    required this.utilisateurId,
    required this.authentificationDoubleFacteur,
    required this.notificationsConnexion,
    required this.partageDonnees,
  });

  @override
  List<Object?> get props => [
        utilisateurId,
        authentificationDoubleFacteur,
        notificationsConnexion,
        partageDonnees
      ];
}

// ♿ METTRE À JOUR LES PRÉFÉRENCES D'ACCESSIBILITÉ
class UpdateAccessibilityPreferencesM extends PreferencesPageEventM {
  final String utilisateurId;
  final String taillePolice;
  final String contraste;
  final bool lecteurEcran;

  const UpdateAccessibilityPreferencesM({
    required this.utilisateurId,
    required this.taillePolice,
    required this.contraste,
    required this.lecteurEcran,
  });

  @override
  List<Object?> get props =>
      [utilisateurId, taillePolice, contraste, lecteurEcran];
}

// 📱 METTRE À JOUR LES PRÉFÉRENCES MOBILE
class UpdateMobilePreferencesM extends PreferencesPageEventM {
  final String utilisateurId;
  final bool vibrations;
  final bool son;
  final String orientation;

  const UpdateMobilePreferencesM({
    required this.utilisateurId,
    required this.vibrations,
    required this.son,
    required this.orientation,
  });

  @override
  List<Object?> get props => [utilisateurId, vibrations, son, orientation];
}

// 🔄 RÉINITIALISER LES PRÉFÉRENCES
class ResetPreferencesM extends PreferencesPageEventM {
  final String utilisateurId;

  const ResetPreferencesM({required this.utilisateurId});

  @override
  List<Object?> get props => [utilisateurId];
}

// 💾 SAUVEGARDER TOUTES LES PRÉFÉRENCES
class SaveAllPreferencesM extends PreferencesPageEventM {
  final String utilisateurId;
  final Map<String, dynamic> preferences;

  const SaveAllPreferencesM({
    required this.utilisateurId,
    required this.preferences,
  });

  @override
  List<Object?> get props => [utilisateurId, preferences];
}

// 📊 CHARGER LES STATISTIQUES
class LoadPreferencesStatsM extends PreferencesPageEventM {
  const LoadPreferencesStatsM();
}

// 🔄 ACTUALISER LES PRÉFÉRENCES
class RefreshPreferencesM extends PreferencesPageEventM {
  final String utilisateurId;

  const RefreshPreferencesM({required this.utilisateurId});

  @override
  List<Object?> get props => [utilisateurId];
}



