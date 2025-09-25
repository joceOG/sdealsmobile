import 'package:equatable/equatable.dart';

abstract class LocationPageEventM extends Equatable {
  const LocationPageEventM();

  @override
  List<Object> get props => [];
}

/// Demander la permission de géolocalisation
class RequestLocationPermissionM extends LocationPageEventM {
  const RequestLocationPermissionM();
}

/// Obtenir la position actuelle de l'utilisateur
class GetCurrentLocationM extends LocationPageEventM {
  const GetCurrentLocationM();
}

/// Activer/désactiver le service de géolocalisation
class ToggleLocationServiceM extends LocationPageEventM {
  const ToggleLocationServiceM();
}

/// Rechercher des services autour de la position
class SearchNearbyServicesM extends LocationPageEventM {
  final double latitude;
  final double longitude;
  final double radius; // en kilomètres

  const SearchNearbyServicesM({
    required this.latitude,
    required this.longitude,
    this.radius = 5.0,
  });

  @override
  List<Object> get props => [latitude, longitude, radius];
}

/// Mettre à jour la position de l'utilisateur
class UpdateUserLocationM extends LocationPageEventM {
  final double latitude;
  final double longitude;

  const UpdateUserLocationM({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [latitude, longitude];
}






