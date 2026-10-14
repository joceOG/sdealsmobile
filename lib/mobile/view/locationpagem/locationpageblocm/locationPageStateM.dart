import 'package:equatable/equatable.dart';

import '../../../../design_system/client_foundations.dart';

class LocationSuggestion extends Equatable {
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;

  const LocationSuggestion({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });

  String get zoneLabel {
    final parts = [title, subtitle.split(',').first.trim()]
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length >= 2 && parts[0].toLowerCase() != parts[1].toLowerCase()) {
      return '${parts[0]}, ${parts[1]}';
    }
    return title;
  }

  @override
  List<Object?> get props => [title, subtitle, latitude, longitude];
}

class LocationPageStateM extends Equatable {
  final bool isLoading;
  final bool isLocating;
  final bool isSearching;
  final bool isLocationEnabled;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? error;
  final String? gpsHint;
  final bool hasPermission;
  final String? currentCity;
  final String query;
  final List<LocationSuggestion> suggestions;
  final LocationSuggestion? selected;

  const LocationPageStateM({
    this.isLoading = false,
    this.isLocating = false,
    this.isSearching = false,
    this.isLocationEnabled = false,
    this.latitude,
    this.longitude,
    this.address,
    this.error,
    this.gpsHint,
    this.hasPermission = false,
    this.currentCity,
    this.query = '',
    this.suggestions = const [],
    this.selected,
  });

  factory LocationPageStateM.initial() {
    return const LocationPageStateM(
      selected: LocationSuggestion(
        title: SDClientLocationPolicy.fallbackCity,
        subtitle: "Côte d'Ivoire",
        latitude: SDClientLocationPolicy.fallbackLatitude,
        longitude: SDClientLocationPolicy.fallbackLongitude,
      ),
    );
  }

  LocationPageStateM copyWith({
    bool? isLoading,
    bool? isLocating,
    bool? isSearching,
    bool? isLocationEnabled,
    double? latitude,
    double? longitude,
    String? address,
    String? error,
    String? gpsHint,
    bool? hasPermission,
    String? currentCity,
    String? query,
    List<LocationSuggestion>? suggestions,
    LocationSuggestion? selected,
    bool clearError = false,
    bool clearGpsHint = false,
  }) {
    return LocationPageStateM(
      isLoading: isLoading ?? this.isLoading,
      isLocating: isLocating ?? this.isLocating,
      isSearching: isSearching ?? this.isSearching,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      error: clearError ? null : (error ?? this.error),
      gpsHint: clearGpsHint ? null : (gpsHint ?? this.gpsHint),
      hasPermission: hasPermission ?? this.hasPermission,
      currentCity: currentCity ?? this.currentCity,
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      selected: selected ?? this.selected,
    );
  }

  bool get isLocationAvailable =>
      hasPermission && latitude != null && longitude != null;

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
        isLocating,
        isSearching,
        isLocationEnabled,
        latitude,
        longitude,
        address,
        error,
        gpsHint,
        hasPermission,
        currentCity,
        query,
        suggestions,
        selected,
      ];
}
