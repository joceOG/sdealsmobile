import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../data/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'registerPageStateM.dart';
import 'registerPageEventM.dart';

class RegisterPageBlocM extends Bloc<RegisterPageEventM, RegisterPageStateM> {
  RegisterPageBlocM() : super(const RegisterPageStateM()) {
    on<RegisterFullNameChanged>((event, emit) {
      emit(state.copyWith(fullName: event.fullName));
    });

    on<RegisterPhoneChanged>((event, emit) {
      emit(state.copyWith(phone: event.phone));
    });

    on<RegisterPasswordChanged>((event, emit) {
      emit(state.copyWith(password: event.password));
    });

    on<RegisterConfirmPasswordChanged>((event, emit) {
      emit(state.copyWith(confirmPassword: event.confirmPassword));
    });

    on<RegisterSubmitted>((event, emit) async {
      if (state.password != state.confirmPassword) {
        emit(state.copyWith(
            errorMessage: "Les mots de passe ne correspondent pas"));
        return;
      }

      emit(state.copyWith(isSubmitting: true, errorMessage: null));
      final apiClient = ApiClient();

      try {
        // Découper nom et prénom
        final fullName = (state.fullName).trim();
        final parts = fullName.split(" ");
        final nom = parts.isNotEmpty ? parts.first : "";
        final prenom = parts.length > 1 ? parts.sublist(1).join(" ") : "";

        // Construire l’utilisateur (minimum requis)
        final utilisateur = Utilisateur(
          idutilisateur: "",
          nom: nom,
          prenom: prenom,
          email: null,
          password: state.password,
          telephone: state.phone,
          genre: "", // valeur par défaut
          note: null,
          photoProfil: null,
          dateNaissance: null,
          role: "Client",
        );

        // Appel API
        final newuser = await apiClient.registerUser(
          fullName: state.fullName,
          phone: state.phone,
          password: state.password,
        );

        emit(state.copyWith(
            isSubmitting: false, isSuccess: true, utilisateur: utilisateur));
      } catch (e) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: e.toString(),
        ));
      }
    });
  }
}
