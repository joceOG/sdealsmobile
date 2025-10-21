import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../data/services/api_client.dart';
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
        // Préparation des données pour l'inscription

        // Appel API
        final newuser = await apiClient.registerUser(
          fullName: state.fullName,
          phone: state.phone,
          password: state.password,
          role: "Client", // ✅ Spécifier le rôle
        );

        // ✅ CONNEXION AUTOMATIQUE APRÈS INSCRIPTION
        if (newuser['utilisateur'] != null && newuser['token'] != null) {
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
          // Créer un utilisateur par défaut en cas d'échec de récupération des données
          final utilisateurDefaut = Utilisateur(
            idutilisateur: '',
            nom: state.fullName.split(' ').first,
            prenom: state.fullName.split(' ').length > 1
                ? state.fullName.split(' ').last
                : '',
            email: '',
            password: '',
            telephone: state.phone,
            genre: '',
            note: '0',
            photoProfil: '',
            dateNaissance: '',
            role: 'Client',
          );

          emit(state.copyWith(
              isSubmitting: false,
              isSuccess: true,
              utilisateur: utilisateurDefaut));
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
