import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/categorie.dart';

abstract class JobPageEventM extends Equatable {
  const JobPageEventM();

  @override
  List<Object> get props => [];
}

class LoadCategorieDataJobM extends JobPageEventM {}

class LoadServiceDataJobM extends JobPageEventM {}

class LoadPriceEstimationM extends JobPageEventM {
  final String serviceType;
  final String location;
  final String jobDescription;

  const LoadPriceEstimationM({
    required this.serviceType,
    required this.location,
    required this.jobDescription,
  });

  @override
  List<Object> get props => [serviceType, location, jobDescription];
}

class LoadProviderMatchingM extends JobPageEventM {
  final String serviceType;
  final String location;
  final List<String>? preferences;

  const LoadProviderMatchingM({
    required this.serviceType,
    required this.location,
    this.preferences,
  });

  @override
  List<Object> get props => [serviceType, location, preferences ?? []];
}

// ✅ NOUVEAU : Événements de géolocalisation
class LoadNearbyProvidersM extends JobPageEventM {
  final double latitude;
  final double longitude;
  final double radius; // en km
  final String? category;
  final String? service;

  const LoadNearbyProvidersM({
    required this.latitude,
    required this.longitude,
    this.radius = 5.0,
    this.category,
    this.service,
  });

  @override
  List<Object> get props =>
      [latitude, longitude, radius, category ?? '', service ?? ''];
}

class LoadProvidersByCategoryM extends JobPageEventM {
  final String category;
  final double? latitude;
  final double? longitude;
  final double radius;

  const LoadProvidersByCategoryM({
    required this.category,
    this.latitude,
    this.longitude,
    this.radius = 5.0,
  });

  @override
  List<Object> get props => [category, latitude ?? 0, longitude ?? 0, radius];
}

class LoadUrgentProvidersM extends JobPageEventM {
  final double? latitude;
  final double? longitude;
  final double radius;

  const LoadUrgentProvidersM({
    this.latitude,
    this.longitude,
    this.radius = 10.0,
  });

  @override
  List<Object> get props => [latitude ?? 0, longitude ?? 0, radius];
}
