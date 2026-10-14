import 'package:equatable/equatable.dart';

import 'locationPageStateM.dart';

abstract class LocationPageEventM extends Equatable {
  const LocationPageEventM();

  @override
  List<Object?> get props => [];
}

class RequestLocationPermissionM extends LocationPageEventM {
  const RequestLocationPermissionM();
}

class GetCurrentLocationM extends LocationPageEventM {
  const GetCurrentLocationM();
}

class ToggleLocationServiceM extends LocationPageEventM {
  const ToggleLocationServiceM();
}

class SearchNearbyServicesM extends LocationPageEventM {
  final double latitude;
  final double longitude;
  final double radius;

  const SearchNearbyServicesM({
    required this.latitude,
    required this.longitude,
    this.radius = 5.0,
  });

  @override
  List<Object?> get props => [latitude, longitude, radius];
}

class UpdateUserLocationM extends LocationPageEventM {
  final double latitude;
  final double longitude;

  const UpdateUserLocationM({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

class SearchLocationQueryM extends LocationPageEventM {
  final String query;

  const SearchLocationQueryM(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectLocationSuggestionM extends LocationPageEventM {
  final LocationSuggestion suggestion;

  const SelectLocationSuggestionM(this.suggestion);

  @override
  List<Object?> get props => [suggestion];
}

class ReverseGeocodeLocationM extends LocationPageEventM {
  final double latitude;
  final double longitude;

  const ReverseGeocodeLocationM({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}
