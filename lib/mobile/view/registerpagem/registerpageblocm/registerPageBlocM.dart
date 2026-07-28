import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../data/services/api_client.dart';
import 'registerPageStateM.dart';
import 'registerPageEventM.dart';

class RegisterPageBlocM extends Bloc<RegisterPageEventM, RegisterPageStateM> {
  RegisterPageBlocM() : super(const RegisterPageStateM()) {
    on<RegisterSubmitted>((event, emit) async {
      if (event.password != event.confirmPassword) {
        emit(state.copyWith(
          errorMessage: "Les mots de passe ne correspondent pas",
        ));
        return;
      }

      emit(state.copyWith(isSubmitting: true, clearErrorMessage: true));
      final apiClient = ApiClient();

      try {
        final newuser = await apiClient.registerUser(
          fullName: event.fullName,
          phone: event.phone,
          password: event.password,
          email: event.email.trim().isEmpty ? null : event.email.trim(),
          role: "Client",
        );

        if (newuser['utilisateur'] != null && newuser['token'] != null) {
          final userData = newuser['utilisateur'];
          final token = newuser['token'];

          final utilisateurCree = Utilisateur(
            idutilisateur: userData['_id'] ?? '',
            nom: userData['nom'] ?? '',
            prenom: userData['prenom'] ?? '',
            email: userData['email'],
            password: '',
            telephone: userData['telephone'] ?? '',
            genre: userData['genre'] ?? '',
            note: userData['note'],
            photoProfil: userData['photoProfil'],
            dateNaissance: userData['datedenaissance'],
            role: userData['role'] ?? 'Client',
          );

          emit(state.copyWith(
            isSubmitting: false,
            isSuccess: true,
            utilisateur: utilisateurCree,
            token: token,
          ));
        } else {
          final fullName = event.fullName.trim();
          final utilisateurDefaut = Utilisateur(
            idutilisateur: '',
            nom: fullName.split(' ').first,
            prenom: fullName.split(' ').length > 1
                ? fullName.split(' ').last
                : '',
            email: '',
            password: '',
            telephone: event.phone,
            genre: '',
            note: '0',
            photoProfil: '',
            dateNaissance: '',
            role: 'Client',
          );

          emit(state.copyWith(
            isSubmitting: false,
            isSuccess: true,
            utilisateur: utilisateurDefaut,
          ));
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
