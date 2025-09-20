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


