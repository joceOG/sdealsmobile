import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/models/user_preferences.dart';
import 'preferencesPageEventM.dart';
import 'preferencesPageStateM.dart';

class PreferencesPageBlocM
    extends Bloc<PreferencesPageEventM, PreferencesPageStateM> {
  final ApiClient _apiClient = ApiClient();

  PreferencesPageBlocM() : super(const PreferencesPageInitialM()) {
    // 📋 CHARGER LES PRÉFÉRENCES
    on<LoadPreferencesM>(_onLoadPreferencesM);

    // 🌍 METTRE À JOUR LA LANGUE
    on<UpdateLanguageM>(_onUpdateLanguageM);

    // 💰 METTRE À JOUR LA DEVISE
    on<UpdateCurrencyM>(_onUpdateCurrencyM);

    // 🌍 METTRE À JOUR LE PAYS
    on<UpdateCountryM>(_onUpdateCountryM);

    // 🕐 METTRE À JOUR LE FUSEAU HORAIRE
    on<UpdateTimezoneM>(_onUpdateTimezoneM);

    // 📅 METTRE À JOUR LE FORMAT DE DATE
    on<UpdateDateFormatM>(_onUpdateDateFormatM);

    // 🕐 METTRE À JOUR LE FORMAT D'HEURE
    on<UpdateTimeFormatM>(_onUpdateTimeFormatM);

    // 💰 METTRE À JOUR LE FORMAT MONÉTAIRE
    on<UpdateMonetaryFormatM>(_onUpdateMonetaryFormatM);

    // 🎨 METTRE À JOUR LE THÈME
    on<UpdateThemeM>(_onUpdateThemeM);

    // 🔔 METTRE À JOUR LES NOTIFICATIONS
    on<UpdateNotificationsM>(_onUpdateNotificationsM);

    // 📍 METTRE À JOUR LA LOCALISATION
    on<UpdateLocationM>(_onUpdateLocationM);

    // 🔍 METTRE À JOUR LES PRÉFÉRENCES DE RECHERCHE
    on<UpdateSearchPreferencesM>(_onUpdateSearchPreferencesM);

    // 🔒 METTRE À JOUR LES PRÉFÉRENCES DE SÉCURITÉ
    on<UpdateSecurityPreferencesM>(_onUpdateSecurityPreferencesM);

    // ♿ METTRE À JOUR LES PRÉFÉRENCES D'ACCESSIBILITÉ
    on<UpdateAccessibilityPreferencesM>(_onUpdateAccessibilityPreferencesM);

    // 📱 METTRE À JOUR LES PRÉFÉRENCES MOBILE
    on<UpdateMobilePreferencesM>(_onUpdateMobilePreferencesM);

    // 🔄 RÉINITIALISER LES PRÉFÉRENCES
    on<ResetPreferencesM>(_onResetPreferencesM);

    // 💾 SAUVEGARDER TOUTES LES PRÉFÉRENCES
    on<SaveAllPreferencesM>(_onSaveAllPreferencesM);

    // 📊 CHARGER LES STATISTIQUES
    on<LoadPreferencesStatsM>(_onLoadPreferencesStatsM);

    // 🔄 ACTUALISER LES PRÉFÉRENCES
    on<RefreshPreferencesM>(_onRefreshPreferencesM);
  }

  // 📋 CHARGER LES PRÉFÉRENCES
  Future<void> _onLoadPreferencesM(
    LoadPreferencesM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      emit(const PreferencesPageLoadingM());

      final response =
          await _apiClient.get('/preferences/user/${event.utilisateurId}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final UserPreferences preferences =
            UserPreferences.fromJson(responseData['preferences']);

        emit(PreferencesPageLoadedM(preferences: preferences));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors du chargement des préférences',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🌍 METTRE À JOUR LA LANGUE
  Future<void> _onUpdateLanguageM(
    UpdateLanguageM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final previous = state is PreferencesPageLoadedM
          ? (state as PreferencesPageLoadedM).preferences
          : null;
      final response = await _apiClient.patch(
        '/preferences/user/${event.utilisateurId}/language',
        body: {'langue': event.langue},
      );

      if (response.statusCode == 200) {
        emit(LanguageUpdatedM(langue: event.langue));
        if (previous != null) {
          emit(PreferencesPageLoadedM(
            preferences: previous.copyWith(langue: event.langue),
          ));
        } else {
          add(LoadPreferencesM(utilisateurId: event.utilisateurId));
        }
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour de la langue',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 💰 METTRE À JOUR LA DEVISE
  Future<void> _onUpdateCurrencyM(
    UpdateCurrencyM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final previous = state is PreferencesPageLoadedM
          ? (state as PreferencesPageLoadedM).preferences
          : null;
      final response = await _apiClient.patch(
        '/preferences/user/${event.utilisateurId}/currency',
        body: {'devise': event.devise},
      );

      if (response.statusCode == 200) {
        emit(CurrencyUpdatedM(devise: event.devise));
        if (previous != null) {
          emit(PreferencesPageLoadedM(
            preferences: previous.copyWith(devise: event.devise),
          ));
        } else {
          add(LoadPreferencesM(utilisateurId: event.utilisateurId));
        }
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour de la devise',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🌍 METTRE À JOUR LE PAYS
  Future<void> _onUpdateCountryM(
    UpdateCountryM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/preferences/user/${event.utilisateurId}/country',
        body: {'pays': event.pays},
      );

      if (response.statusCode == 200) {
        emit(CountryUpdatedM(pays: event.pays));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour du pays',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🕐 METTRE À JOUR LE FUSEAU HORAIRE
  Future<void> _onUpdateTimezoneM(
    UpdateTimezoneM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.put(
        '/preferences/user/${event.utilisateurId}',
        body: {'fuseauHoraire': event.fuseauHoraire},
      );

      if (response.statusCode == 200) {
        emit(TimezoneUpdatedM(fuseauHoraire: event.fuseauHoraire));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour du fuseau horaire',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 📅 METTRE À JOUR LE FORMAT DE DATE
  Future<void> _onUpdateDateFormatM(
    UpdateDateFormatM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.put(
        '/preferences/user/${event.utilisateurId}',
        body: {'formatDate': event.formatDate},
      );

      if (response.statusCode == 200) {
        emit(DateFormatUpdatedM(formatDate: event.formatDate));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour du format de date',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🕐 METTRE À JOUR LE FORMAT D'HEURE
  Future<void> _onUpdateTimeFormatM(
    UpdateTimeFormatM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.put(
        '/preferences/user/${event.utilisateurId}',
        body: {'formatHeure': event.formatHeure},
      );

      if (response.statusCode == 200) {
        emit(TimeFormatUpdatedM(formatHeure: event.formatHeure));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour du format d\'heure',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 💰 METTRE À JOUR LE FORMAT MONÉTAIRE
  Future<void> _onUpdateMonetaryFormatM(
    UpdateMonetaryFormatM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.put(
        '/preferences/user/${event.utilisateurId}',
        body: {'formatMonetaire': event.formatMonetaire},
      );

      if (response.statusCode == 200) {
        emit(MonetaryFormatUpdatedM(formatMonetaire: event.formatMonetaire));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour du format monétaire',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🎨 METTRE À JOUR LE THÈME
  Future<void> _onUpdateThemeM(
    UpdateThemeM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.put(
        '/preferences/user/${event.utilisateurId}',
        body: {'theme': event.theme},
      );

      if (response.statusCode == 200) {
        emit(ThemeUpdatedM(theme: event.theme));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour du thème',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔔 METTRE À JOUR LES NOTIFICATIONS
  Future<void> _onUpdateNotificationsM(
    UpdateNotificationsM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.put(
        '/preferences/user/${event.utilisateurId}',
        body: {
          'notifications': {
            'email': event.email,
            'push': event.push,
            'sms': event.sms,
            'langue': event.langue,
            if (event.types != null) 'types': event.types,
          }
        },
      );

      if (response.statusCode == 200) {
        emit(NotificationsUpdatedM(
          email: event.email,
          push: event.push,
          sms: event.sms,
          langue: event.langue,
        ));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour des notifications',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 📍 METTRE À JOUR LA LOCALISATION
  Future<void> _onUpdateLocationM(
    UpdateLocationM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final Map<String, dynamic> body = {
        'localisation': {
          if (event.ville != null) 'ville': event.ville,
          if (event.codePostal != null) 'codePostal': event.codePostal,
          if (event.latitude != null && event.longitude != null)
            'coordonnees': {
              'latitude': event.latitude,
              'longitude': event.longitude,
            },
        }
      };

      final response = await _apiClient.put(
        '/preferences/user/${event.utilisateurId}',
        body: body,
      );

      if (response.statusCode == 200) {
        emit(LocationUpdatedM(
          ville: event.ville,
          codePostal: event.codePostal,
          latitude: event.latitude,
          longitude: event.longitude,
        ));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour de la localisation',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔍 METTRE À JOUR LES PRÉFÉRENCES DE RECHERCHE
  Future<void> _onUpdateSearchPreferencesM(
    UpdateSearchPreferencesM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.put(
        '/preferences/user/${event.utilisateurId}',
        body: {
          'recherche': {
            'rayon': event.rayon,
            'triParDefaut': event.triParDefaut,
            'afficherPrix': event.afficherPrix,
          }
        },
      );

      if (response.statusCode == 200) {
        emit(SearchPreferencesUpdatedM(
          rayon: event.rayon,
          triParDefaut: event.triParDefaut,
          afficherPrix: event.afficherPrix,
        ));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour des préférences de recherche',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔒 METTRE À JOUR LES PRÉFÉRENCES DE SÉCURITÉ
  Future<void> _onUpdateSecurityPreferencesM(
    UpdateSecurityPreferencesM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.put(
        '/preferences/user/${event.utilisateurId}',
        body: {
          'securite': {
            'authentificationDoubleFacteur':
                event.authentificationDoubleFacteur,
            'notificationsConnexion': event.notificationsConnexion,
            'partageDonnees': event.partageDonnees,
          }
        },
      );

      if (response.statusCode == 200) {
        emit(SecurityPreferencesUpdatedM(
          authentificationDoubleFacteur: event.authentificationDoubleFacteur,
          notificationsConnexion: event.notificationsConnexion,
          partageDonnees: event.partageDonnees,
        ));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour des préférences de sécurité',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // ♿ METTRE À JOUR LES PRÉFÉRENCES D'ACCESSIBILITÉ
  Future<void> _onUpdateAccessibilityPreferencesM(
    UpdateAccessibilityPreferencesM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.put(
        '/preferences/user/${event.utilisateurId}',
        body: {
          'accessibilite': {
            'taillePolice': event.taillePolice,
            'contraste': event.contraste,
            'lecteurEcran': event.lecteurEcran,
          }
        },
      );

      if (response.statusCode == 200) {
        emit(AccessibilityPreferencesUpdatedM(
          taillePolice: event.taillePolice,
          contraste: event.contraste,
          lecteurEcran: event.lecteurEcran,
        ));
      } else {
        emit(PreferencesPageErrorM(
          message:
              'Erreur lors de la mise à jour des préférences d\'accessibilité',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 📱 METTRE À JOUR LES PRÉFÉRENCES MOBILE
  Future<void> _onUpdateMobilePreferencesM(
    UpdateMobilePreferencesM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.put(
        '/preferences/user/${event.utilisateurId}',
        body: {
          'mobile': {
            'vibrations': event.vibrations,
            'son': event.son,
            'orientation': event.orientation,
          }
        },
      );

      if (response.statusCode == 200) {
        emit(MobilePreferencesUpdatedM(
          vibrations: event.vibrations,
          son: event.son,
          orientation: event.orientation,
        ));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la mise à jour des préférences mobile',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔄 RÉINITIALISER LES PRÉFÉRENCES
  Future<void> _onResetPreferencesM(
    ResetPreferencesM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/preferences/user/${event.utilisateurId}/reset',
      );

      if (response.statusCode == 200) {
        emit(const PreferencesResetM());
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la réinitialisation des préférences',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 💾 SAUVEGARDER TOUTES LES PRÉFÉRENCES
  Future<void> _onSaveAllPreferencesM(
    SaveAllPreferencesM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.put(
        '/preferences/user/${event.utilisateurId}',
        body: event.preferences,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final UserPreferences preferences =
            UserPreferences.fromJson(responseData['preferences']);

        emit(PreferencesSavedM(preferences: preferences));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors de la sauvegarde des préférences',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 📊 CHARGER LES STATISTIQUES
  Future<void> _onLoadPreferencesStatsM(
    LoadPreferencesStatsM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    try {
      final response = await _apiClient.get('/preferences/stats');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        emit(PreferencesStatsLoadedM(stats: responseData));
      } else {
        emit(PreferencesPageErrorM(
          message: 'Erreur lors du chargement des statistiques',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      emit(PreferencesPageErrorM(
        message: 'Erreur: ${e.toString()}',
      ));
    }
  }

  // 🔄 ACTUALISER LES PRÉFÉRENCES
  Future<void> _onRefreshPreferencesM(
    RefreshPreferencesM event,
    Emitter<PreferencesPageStateM> emit,
  ) async {
    add(LoadPreferencesM(utilisateurId: event.utilisateurId));
  }
}



