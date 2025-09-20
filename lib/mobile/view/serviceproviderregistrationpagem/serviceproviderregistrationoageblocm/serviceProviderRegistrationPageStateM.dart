import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';

abstract class ServiceProviderRegistrationStateM extends Equatable {
  @override
  List<Object?> get props => [];
}

class ServiceProviderRegistrationInitial extends ServiceProviderRegistrationStateM {}

class ServiceProviderRegistrationLoading extends ServiceProviderRegistrationStateM {}

class ServiceProviderRegistrationSuccess extends ServiceProviderRegistrationStateM {
  final String message;
  final Utilisateur utilisateur;

  ServiceProviderRegistrationSuccess({
    required this.message,
    required this.utilisateur,
  });

  @override
  List<Object?> get props => [message,utilisateur];
}

class ServiceProviderRegistrationFailure extends ServiceProviderRegistrationStateM {
  final String error;

  ServiceProviderRegistrationFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
