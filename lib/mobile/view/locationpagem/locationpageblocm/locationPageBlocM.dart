import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../design_system/client_foundations.dart';
import 'locationPageEventM.dart';
import 'locationPageStateM.dart';

class LocationPageBlocM extends Bloc<LocationPageEventM, LocationPageStateM> {
  LocationPageBlocM() : super(LocationPageStateM.initial()) {
    on<RequestLocationPermissionM>(_onRequestLocationPermissionM);
    on<GetCurrentLocationM>(_onGetCurrentLocationM);
    on<ToggleLocationServiceM>(_onToggleLocationServiceM);
    on<SearchNearbyServicesM>(_onSearchNearbyServicesM);
    on<UpdateUserLocationM>(_onUpdateUserLocationM);
    on<SearchLocationQueryM>(_onSearchLocationQueryM);
    on<SelectLocationSuggestionM>(_onSelectLocationSuggestionM);
    on<ReverseGeocodeLocationM>(_onReverseGeocodeLocationM);
  }

  @visibleForTesting
  static Future<List<LocationSuggestion>> Function(String query)? debugSearch;

  @visibleForTesting
  static Future<LocationSuggestion?> Function()? debugGps;

  @visibleForTesting
  static Future<LocationSuggestion> Function(double lat, double lng)?
      debugReverse;

  @visibleForTesting
  static void debugReset() {
    debugSearch = null;
    debugGps = null;
    debugReverse = null;
  }

  Future<void> _onRequestLocationPermissionM(
    RequestLocationPermissionM event,
    Emitter<LocationPageStateM> emit,
  ) async {
    emit(
        state.copyWith(isLocating: true, clearError: true, clearGpsHint: true));

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        emit(state.copyWith(
          isLocating: false,
          hasPermission: false,
          gpsHint:
              'Autorisation refusée. Cherchez une commune ou choisissez sur la carte.',
        ));
        return;
      }

      emit(state.copyWith(
        isLocating: false,
        hasPermission: true,
        clearGpsHint: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLocating: false,
        hasPermission: false,
        gpsHint:
            'Position indisponible. Cherchez une commune ou choisissez sur la carte.',
      ));
    }
  }

  Future<void> _onGetCurrentLocationM(
    GetCurrentLocationM event,
    Emitter<LocationPageStateM> emit,
  ) async {
    emit(
        state.copyWith(isLocating: true, clearError: true, clearGpsHint: true));

    try {
      if (debugGps != null) {
        final suggestion = await debugGps!();
        if (suggestion == null) {
          emit(state.copyWith(
            isLocating: false,
            hasPermission: false,
            gpsHint:
                'Autorisation refusée. Cherchez une commune ou choisissez sur la carte.',
          ));
          return;
        }
        emit(_withSuggestion(suggestion, locating: false, permission: true));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
          isLocating: false,
          hasPermission: false,
          gpsHint:
              'Autorisation refusée. Cherchez une commune ou choisissez sur la carte.',
        ));
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(state.copyWith(
          isLocating: false,
          hasPermission: true,
          gpsHint:
              'GPS désactivé. Cherchez une commune ou choisissez sur la carte.',
        ));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      final suggestion = await _suggestionFromCoordinates(
        position.latitude,
        position.longitude,
      );
      emit(_withSuggestion(suggestion, locating: false, permission: true));
    } catch (_) {
      emit(state.copyWith(
        isLocating: false,
        gpsHint:
            'Position indisponible. Cherchez une commune ou choisissez sur la carte.',
      ));
    }
  }

  Future<void> _onToggleLocationServiceM(
    ToggleLocationServiceM event,
    Emitter<LocationPageStateM> emit,
  ) async {
    if (state.isLocationEnabled) {
      emit(state.copyWith(
        isLocationEnabled: false,
        clearError: true,
      ));
    } else {
      add(const GetCurrentLocationM());
    }
  }

  Future<void> _onSearchNearbyServicesM(
    SearchNearbyServicesM event,
    Emitter<LocationPageStateM> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null) {
        throw Exception('URL API non configurée');
      }

      final response = await http.get(
        Uri.parse(
            '$apiUrl/services/nearby?lat=${event.latitude}&lng=${event.longitude}&radius=${event.radius}'),
      );

      if (response.statusCode == 200) {
        jsonDecode(response.body);
        emit(state.copyWith(isLoading: false, clearError: true));
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur recherche services: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateUserLocationM(
    UpdateUserLocationM event,
    Emitter<LocationPageStateM> emit,
  ) async {
    final suggestion = await _suggestionFromCoordinates(
      event.latitude,
      event.longitude,
    );
    emit(_withSuggestion(suggestion, locating: false, permission: true));
  }

  Future<void> _onSearchLocationQueryM(
    SearchLocationQueryM event,
    Emitter<LocationPageStateM> emit,
  ) async {
    final query = event.query.trim();
    emit(state.copyWith(
      query: event.query,
      isSearching: query.length >= 2,
      suggestions: query.length >= 2 ? state.suggestions : const [],
      clearError: true,
    ));

    if (query.length < 2) return;

    try {
      if (debugSearch != null) {
        final results = await debugSearch!(query);
        emit(state.copyWith(
          isSearching: false,
          suggestions: results,
        ));
        return;
      }

      final locations = await locationFromAddress('$query, Côte d\'Ivoire');
      final suggestions = <LocationSuggestion>[];
      for (final loc in locations.take(8)) {
        suggestions.add(
          await _suggestionFromCoordinates(loc.latitude, loc.longitude, query),
        );
      }
      emit(state.copyWith(isSearching: false, suggestions: suggestions));
    } catch (_) {
      emit(state.copyWith(isSearching: false, suggestions: const []));
    }
  }

  void _onSelectLocationSuggestionM(
    SelectLocationSuggestionM event,
    Emitter<LocationPageStateM> emit,
  ) {
    emit(_withSuggestion(event.suggestion, locating: false));
  }

  Future<void> _onReverseGeocodeLocationM(
    ReverseGeocodeLocationM event,
    Emitter<LocationPageStateM> emit,
  ) async {
    try {
      if (debugReverse != null) {
        final suggestion = await debugReverse!(event.latitude, event.longitude);
        emit(_withSuggestion(suggestion, locating: false));
        return;
      }
      final suggestion = await _suggestionFromCoordinates(
        event.latitude,
        event.longitude,
      );
      emit(_withSuggestion(suggestion, locating: false));
    } catch (_) {
      emit(_withSuggestion(
        LocationSuggestion(
          title: SDClientLocationPolicy.fallbackCity,
          subtitle: "Côte d'Ivoire",
          latitude: event.latitude,
          longitude: event.longitude,
        ),
        locating: false,
      ));
    }
  }

  LocationPageStateM _withSuggestion(
    LocationSuggestion suggestion, {
    required bool locating,
    bool? permission,
  }) {
    return state.copyWith(
      isLocating: locating,
      isLocationEnabled: true,
      hasPermission: permission ?? state.hasPermission,
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
      currentCity: suggestion.title,
      address: suggestion.subtitle,
      selected: suggestion,
      clearGpsHint: true,
      clearError: true,
    );
  }

  Future<LocationSuggestion> _suggestionFromCoordinates(
    double latitude,
    double longitude, [
    String? fallbackTitle,
  ]) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return LocationSuggestion(
          title: fallbackTitle?.trim().isNotEmpty == true
              ? fallbackTitle!.trim()
              : SDClientLocationPolicy.fallbackCity,
          subtitle: "Côte d'Ivoire",
          latitude: latitude,
          longitude: longitude,
        );
      }
      final place = placemarks.first;
      final names = [
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        fallbackTitle,
      ]
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final title =
          names.isEmpty ? SDClientLocationPolicy.fallbackCity : names.first;
      final subtitle = [
        if (place.locality != null &&
            place.locality!.trim().isNotEmpty &&
            place.locality!.trim().toLowerCase() != title.toLowerCase())
          place.locality!.trim(),
        if (place.administrativeArea != null &&
            place.administrativeArea!.trim().isNotEmpty)
          place.administrativeArea!.trim(),
        if (place.country != null && place.country!.trim().isNotEmpty)
          place.country!.trim(),
      ].join(', ');
      return LocationSuggestion(
        title: title,
        subtitle: subtitle.isEmpty ? "Côte d'Ivoire" : subtitle,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      return LocationSuggestion(
        title: fallbackTitle?.trim().isNotEmpty == true
            ? fallbackTitle!.trim()
            : SDClientLocationPolicy.fallbackCity,
        subtitle: "Côte d'Ivoire",
        latitude: latitude,
        longitude: longitude,
      );
    }
  }
}
