import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:sdealsmobile/data/services/api_client.dart';
import 'dart:convert';

import '../../../../data/models/prestataire.dart';
import 'serviceProviderRegistrationPageEventM.dart';
import 'serviceProviderRegistrationPageStateM.dart';

class ServiceProviderRegistrationBlocM extends Bloc<ServiceProviderRegistrationEventM, ServiceProviderRegistrationStateM> {
  ServiceProviderRegistrationBlocM() : super(ServiceProviderRegistrationInitial()) {
    on<SubmitServiceProviderRegistrationEvent>(_onSubmitRegistration);
  }

  Future<void> _onSubmitRegistration(
      SubmitServiceProviderRegistrationEvent event,
      Emitter<ServiceProviderRegistrationStateM> emit,
      ) async {
    emit(ServiceProviderRegistrationLoading());
    final apiClient = ApiClient();

    try {
      final data = await apiClient.registerPrestataire(event.formData);
      print("✅ Réponse API: $data");
      // ⚡ Mapper la réponse API en Prestataire
      emit(ServiceProviderRegistrationSuccess(
        message: "Inscription réussie !",
        utilisateur: data, // on envoie maintenant l'objet Prestataire
      ));
    } catch (e) {
      emit(ServiceProviderRegistrationFailure(error: e.toString()));
    }
  }
}
