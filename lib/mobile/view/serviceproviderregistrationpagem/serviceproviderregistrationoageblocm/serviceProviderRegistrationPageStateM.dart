import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/professional_capabilities.dart';

abstract class ServiceProviderRegistrationStateM extends Equatable {
  @override
  List<Object?> get props => [];
}

class ServiceProviderRegistrationInitial extends ServiceProviderRegistrationStateM {}

class ServiceProviderRegistrationLoading extends ServiceProviderRegistrationStateM {}

class ServiceProviderRegistrationSuccess extends ServiceProviderRegistrationStateM {
  final String message;
  final ProfessionalProfileSnapshot? prestataireSnapshot;

  ServiceProviderRegistrationSuccess({
    required this.message,
    this.prestataireSnapshot,
  });

  @override
  List<Object?> get props => [message, prestataireSnapshot];
}

class ServiceProviderRegistrationFailure extends ServiceProviderRegistrationStateM {
  final String error;

  ServiceProviderRegistrationFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
