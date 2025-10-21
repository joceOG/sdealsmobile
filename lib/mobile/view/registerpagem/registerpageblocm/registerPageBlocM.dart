import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
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

        // ✅ CONNEXION AUTOMATIQUE APRÈS INSCRIPTION
        if (newuser != null &&
            newuser['utilisateur'] != null &&
            newuser['token'] != null) {
          final userData = newuser['utilisateur'];
          final token = newuser['token'];

          // Créer l'objet Utilisateur avec les données du backend
          final utilisateurCree = Utilisateur(
            idutilisateur: userData['_id'] ?? '',
            nom: userData['nom'] ?? '',
            prenom: userData['prenom'] ?? '',
            email: userData['email'],
            password: '', // Ne pas stocker le mot de passe
            telephone: userData['telephone'] ?? '',
            genre: userData['genre'] ?? '',
            note: userData['note'],
            photoProfil: userData['photoProfil'],
            dateNaissance: userData['datedenaissance'],
            role: userData['role'] ?? 'Client',
          );

          // ✅ ÉMISSION D'UN ÉVÉNEMENT POUR CONNECTER L'UTILISATEUR
          emit(state.copyWith(
            isSubmitting: false,
            isSuccess: true,
            utilisateur: utilisateurCree,
            token: token, // ✅ Ajouter le token pour la connexion
          ));
        } else {
          emit(state.copyWith(
              isSubmitting: false, isSuccess: true, utilisateur: utilisateur));
        }
      } catch (e) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: e.toString(),
        ));
      }
    });
  }
}
