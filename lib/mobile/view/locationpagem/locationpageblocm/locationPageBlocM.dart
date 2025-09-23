import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'locationPageEventM.dart';
import 'locationPageStateM.dart';

class LocationPageBlocM extends Bloc<LocationPageEventM, LocationPageStateM> {
  LocationPageBlocM() : super(LocationPageStateM.initial()) {
    on<RequestLocationPermissionM>(_onRequestLocationPermissionM);
    on<GetCurrentLocationM>(_onGetCurrentLocationM);
    on<ToggleLocationServiceM>(_onToggleLocationServiceM);
    on<SearchNearbyServicesM>(_onSearchNearbyServicesM);
    on<UpdateUserLocationM>(_onUpdateUserLocationM);
  }

  /// Demander la permission de géolocalisation
  Future<void> _onRequestLocationPermissionM(
    RequestLocationPermissionM event,
    Emitter<LocationPageStateM> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
          isLoading: false,
          hasPermission: false,
          error:
              'Les permissions de géolocalisation sont définitivement refusées',
        ));
        return;
      }

      if (permission == LocationPermission.denied) {
        emit(state.copyWith(
          isLoading: false,
          hasPermission: false,
          error: 'Permission de géolocalisation refusée',
        ));
        return;
      }

      emit(state.copyWith(
        isLoading: false,
        hasPermission: true,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        hasPermission: false,
        error: 'Erreur lors de la demande de permission: ${e.toString()}',
      ));
    }
  }

  /// Obtenir la position actuelle
  Future<void> _onGetCurrentLocationM(
    GetCurrentLocationM event,
    Emitter<LocationPageStateM> emit,
  ) async {
    if (!state.hasPermission) {
      add(const RequestLocationPermissionM());
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Les services de localisation sont désactivés',
        ));
        return;
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Géocodage inverse pour obtenir l'adresse
      String? address;
      String? city;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address = '${place.street}, ${place.locality}, ${place.country}';
          city = place.locality ?? place.administrativeArea;
        }
      } catch (e) {
        print('Erreur géocodage inverse: $e');
        // Continuer sans adresse si le géocodage échoue
      }

      emit(state.copyWith(
        isLoading: false,
        isLocationEnabled: true,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        currentCity: city,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur de géolocalisation: ${e.toString()}',
      ));
    }
  }

  /// Activer/désactiver le service de géolocalisation
  Future<void> _onToggleLocationServiceM(
    ToggleLocationServiceM event,
    Emitter<LocationPageStateM> emit,
  ) async {
    if (state.isLocationEnabled) {
      // Désactiver la géolocalisation
      emit(state.copyWith(
        isLocationEnabled: false,
        latitude: null,
        longitude: null,
        address: null,
        currentCity: null,
        error: null,
      ));
    } else {
      // Activer la géolocalisation
      add(const GetCurrentLocationM());
    }
  }

  /// Rechercher des services à proximité
  Future<void> _onSearchNearbyServicesM(
    SearchNearbyServicesM event,
    Emitter<LocationPageStateM> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Ici tu peux appeler ton API backend pour rechercher des services
      // autour des coordonnées données
      final apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null) {
        throw Exception('URL API non configurée');
      }

      // Exemple d'appel API pour rechercher des services à proximité
      final response = await http.get(
        Uri.parse(
            '$apiUrl/services/nearby?lat=${event.latitude}&lng=${event.longitude}&radius=${event.radius}'),
      );

      if (response.statusCode == 200) {
        // Traiter la réponse de l'API
        final data = jsonDecode(response.body);
        print('Services trouvés: ${data.length}');

        emit(state.copyWith(
          isLoading: false,
          error: null,
        ));
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

  /// Mettre à jour la position de l'utilisateur
  Future<void> _onUpdateUserLocationM(
    UpdateUserLocationM event,
    Emitter<LocationPageStateM> emit,
  ) async {
    emit(state.copyWith(
      latitude: event.latitude,
      longitude: event.longitude,
      isLocationEnabled: true,
    ));

    // Optionnel: faire un géocodage inverse pour obtenir l'adresse
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        event.latitude,
        event.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.locality}, ${place.country}';
        String? city = place.locality ?? place.administrativeArea;

        emit(state.copyWith(
          address: address,
          currentCity: city,
        ));
      }
    } catch (e) {
      print('Erreur géocodage inverse: $e');
    }
  }
}

