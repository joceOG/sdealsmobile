import 'package:equatable/equatable.dart';

abstract class ServiceProviderRegistrationEventM extends Equatable {
  @override
  List<Object?> get props => [];
}

// Quand on envoie le formulaire complet
class SubmitServiceProviderRegistrationEvent extends ServiceProviderRegistrationEventM {
  final Map<String, dynamic> formData;
  final String? token;

  SubmitServiceProviderRegistrationEvent({required this.formData, this.token});

  @override
  List<Object?> get props => [formData, token];
}
