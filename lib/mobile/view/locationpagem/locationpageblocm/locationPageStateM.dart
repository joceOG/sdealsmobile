import 'package:equatable/equatable.dart';

class LocationPageStateM extends Equatable {
  final bool isLoading;
  final bool isLocationEnabled;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? error;
  final bool hasPermission;
  final String? currentCity;

  const LocationPageStateM({
    this.isLoading = false,
    this.isLocationEnabled = false,
    this.latitude,
    this.longitude,
    this.address,
    this.error,
    this.hasPermission = false,
    this.currentCity,
  });

  factory LocationPageStateM.initial() {
    return const LocationPageStateM(
      isLoading: false,
      isLocationEnabled: false,
      hasPermission: false,
    );
  }

  LocationPageStateM copyWith({
    bool? isLoading,
    bool? isLocationEnabled,
    double? latitude,
    double? longitude,
    String? address,
    String? error,
    bool? hasPermission,
    String? currentCity,
  }) {
    return LocationPageStateM(
      isLoading: isLoading ?? this.isLoading,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      error: error ?? this.error,
      hasPermission: hasPermission ?? this.hasPermission,
      currentCity: currentCity ?? this.currentCity,
    );
  }

  /// Vérifie si la géolocalisation est disponible
  bool get isLocationAvailable =>
      hasPermission && latitude != null && longitude != null;

  /// Obtient les coordonnées sous forme de Map
  Map<String, double>? get coordinates {
    if (latitude != null && longitude != null) {
      return {
        'latitude': latitude!,
        'longitude': longitude!,
      };
    }
    return null;
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLocationEnabled,
        latitude,
        longitude,
        address,
        error,
        hasPermission,
        currentCity,
      ];
}

