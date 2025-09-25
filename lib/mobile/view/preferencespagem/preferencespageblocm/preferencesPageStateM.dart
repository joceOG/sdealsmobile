import 'package:equatable/equatable.dart';
import '../../../../data/models/user_preferences.dart';

abstract class PreferencesPageStateM extends Equatable {
  const PreferencesPageStateM();

  @override
  List<Object?> get props => [];
}

// 🔄 ÉTAT INITIAL
class PreferencesPageInitialM extends PreferencesPageStateM {
  const PreferencesPageInitialM();
}

// ⏳ ÉTAT DE CHARGEMENT
class PreferencesPageLoadingM extends PreferencesPageStateM {
  const PreferencesPageLoadingM();
}

// ✅ ÉTAT DE SUCCÈS - PRÉFÉRENCES CHARGÉES
class PreferencesPageLoadedM extends PreferencesPageStateM {
  final UserPreferences preferences;

  const PreferencesPageLoadedM({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

// ❌ ÉTAT D'ERREUR
class PreferencesPageErrorM extends PreferencesPageStateM {
  final String message;
  final String? code;

  const PreferencesPageErrorM({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

// 🌍 ÉTAT DE SUCCÈS - LANGUE MISES À JOUR
class LanguageUpdatedM extends PreferencesPageStateM {
  final String langue;

  const LanguageUpdatedM({required this.langue});

  @override
  List<Object?> get props => [langue];
}

// 💰 ÉTAT DE SUCCÈS - DEVISE MISE À JOUR
class CurrencyUpdatedM extends PreferencesPageStateM {
  final String devise;

  const CurrencyUpdatedM({required this.devise});

  @override
  List<Object?> get props => [devise];
}

// 🌍 ÉTAT DE SUCCÈS - PAYS MIS À JOUR
class CountryUpdatedM extends PreferencesPageStateM {
  final String pays;

  const CountryUpdatedM({required this.pays});

  @override
  List<Object?> get props => [pays];
}

// 🕐 ÉTAT DE SUCCÈS - FUSEAU HORAIRE MIS À JOUR
class TimezoneUpdatedM extends PreferencesPageStateM {
  final String fuseauHoraire;

  const TimezoneUpdatedM({required this.fuseauHoraire});

  @override
  List<Object?> get props => [fuseauHoraire];
}

// 📅 ÉTAT DE SUCCÈS - FORMAT DE DATE MIS À JOUR
class DateFormatUpdatedM extends PreferencesPageStateM {
  final String formatDate;

  const DateFormatUpdatedM({required this.formatDate});

  @override
  List<Object?> get props => [formatDate];
}

// 🕐 ÉTAT DE SUCCÈS - FORMAT D'HEURE MIS À JOUR
class TimeFormatUpdatedM extends PreferencesPageStateM {
  final String formatHeure;

  const TimeFormatUpdatedM({required this.formatHeure});

  @override
  List<Object?> get props => [formatHeure];
}

// 💰 ÉTAT DE SUCCÈS - FORMAT MONÉTAIRE MIS À JOUR
class MonetaryFormatUpdatedM extends PreferencesPageStateM {
  final String formatMonetaire;

  const MonetaryFormatUpdatedM({required this.formatMonetaire});

  @override
  List<Object?> get props => [formatMonetaire];
}

// 🎨 ÉTAT DE SUCCÈS - THÈME MIS À JOUR
class ThemeUpdatedM extends PreferencesPageStateM {
  final String theme;

  const ThemeUpdatedM({required this.theme});

  @override
  List<Object?> get props => [theme];
}

// 🔔 ÉTAT DE SUCCÈS - NOTIFICATIONS MISES À JOUR
class NotificationsUpdatedM extends PreferencesPageStateM {
  final bool email;
  final bool push;
  final bool sms;
  final String langue;

  const NotificationsUpdatedM({
    required this.email,
    required this.push,
    required this.sms,
    required this.langue,
  });

  @override
  List<Object?> get props => [email, push, sms, langue];
}

// 📍 ÉTAT DE SUCCÈS - LOCALISATION MISE À JOUR
class LocationUpdatedM extends PreferencesPageStateM {
  final String? ville;
  final String? codePostal;
  final double? latitude;
  final double? longitude;

  const LocationUpdatedM({
    this.ville,
    this.codePostal,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [ville, codePostal, latitude, longitude];
}

// 🔍 ÉTAT DE SUCCÈS - PRÉFÉRENCES DE RECHERCHE MISES À JOUR
class SearchPreferencesUpdatedM extends PreferencesPageStateM {
  final int rayon;
  final String triParDefaut;
  final bool afficherPrix;

  const SearchPreferencesUpdatedM({
    required this.rayon,
    required this.triParDefaut,
    required this.afficherPrix,
  });

  @override
  List<Object?> get props => [rayon, triParDefaut, afficherPrix];
}

// 🔒 ÉTAT DE SUCCÈS - PRÉFÉRENCES DE SÉCURITÉ MISES À JOUR
class SecurityPreferencesUpdatedM extends PreferencesPageStateM {
  final bool authentificationDoubleFacteur;
  final bool notificationsConnexion;
  final bool partageDonnees;

  const SecurityPreferencesUpdatedM({
    required this.authentificationDoubleFacteur,
    required this.notificationsConnexion,
    required this.partageDonnees,
  });

  @override
  List<Object?> get props =>
      [authentificationDoubleFacteur, notificationsConnexion, partageDonnees];
}

// ♿ ÉTAT DE SUCCÈS - PRÉFÉRENCES D'ACCESSIBILITÉ MISES À JOUR
class AccessibilityPreferencesUpdatedM extends PreferencesPageStateM {
  final String taillePolice;
  final String contraste;
  final bool lecteurEcran;

  const AccessibilityPreferencesUpdatedM({
    required this.taillePolice,
    required this.contraste,
    required this.lecteurEcran,
  });

  @override
  List<Object?> get props => [taillePolice, contraste, lecteurEcran];
}

// 📱 ÉTAT DE SUCCÈS - PRÉFÉRENCES MOBILE MISES À JOUR
class MobilePreferencesUpdatedM extends PreferencesPageStateM {
  final bool vibrations;
  final bool son;
  final String orientation;

  const MobilePreferencesUpdatedM({
    required this.vibrations,
    required this.son,
    required this.orientation,
  });

  @override
  List<Object?> get props => [vibrations, son, orientation];
}

// 🔄 ÉTAT DE SUCCÈS - PRÉFÉRENCES RÉINITIALISÉES
class PreferencesResetM extends PreferencesPageStateM {
  const PreferencesResetM();
}

// 💾 ÉTAT DE SUCCÈS - PRÉFÉRENCES SAUVEGARDÉES
class PreferencesSavedM extends PreferencesPageStateM {
  final UserPreferences preferences;

  const PreferencesSavedM({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

// 📊 ÉTAT DE SUCCÈS - STATISTIQUES CHARGÉES
class PreferencesStatsLoadedM extends PreferencesPageStateM {
  final Map<String, dynamic> stats;

  const PreferencesStatsLoadedM({required this.stats});

  @override
  List<Object?> get props => [stats];
}

// 🔄 ÉTAT DE SUCCÈS - PRÉFÉRENCES ACTUALISÉES
class PreferencesRefreshedM extends PreferencesPageStateM {
  final UserPreferences preferences;

  const PreferencesRefreshedM({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}



