import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../data/services/authCubit.dart';
import 'loginPageEventM.dart';
import 'loginPageStateM.dart'; // ton fichier API externe

class LoginPageBlocM extends Bloc<LoginPageEventM, LoginPageStateM> {
  LoginPageBlocM() : super(LoginPageInitialM()) {
    on<LoginSubmittedM>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedM event,
    Emitter<LoginPageStateM> emit,
  ) async {
    emit(LoginPageLoadingM());

    final apiClient = ApiClient();
    print('Api COnnexion');
    try {
      final response = await apiClient.loginUser(
        identifiant: event.identifiant,
        password: event.password,
        rememberMe: event.rememberMe,
      );

      // ✅ DEBUG : Afficher la réponse complète
      print("🔍 Réponse API login: $response");

      final token = response["token"] ?? "";
      final refreshToken = response["refreshToken"]?.toString();
      final utilisateurData = response["utilisateur"] ?? {};

      print("🔍 Token extrait: '$token'");
      print("🔍 Utilisateur extrait: $utilisateurData");

      if (token.isEmpty) {
        print("❌ Token manquant dans la réponse");
        emit(LoginPageFailureM(error: "Token manquant dans la réponse"));
        return;
      }

      // ✅ Construire l'objet utilisateur
      final utilisateur = Utilisateur.fromMap(utilisateurData);

      // ✅ Stockage local si rememberMe activé
      if (event.rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("utilisateur", jsonEncode(utilisateur.toMap()));
        if (refreshToken != null) {
          await prefs.setString("refresh_token", refreshToken);
        }
      }

      // ✅ Émettre l'état succès avec flag pour mise à jour AuthCubit
      emit(LoginPageSuccessM(
        token: token,
        utilisateur: utilisateur.toMap(),
        shouldUpdateAuth: true,
        refreshToken: refreshToken,
      ));
    } catch (error) {
      final errorMessage = (error is Exception)
          ? error.toString().replaceAll('Exception: ', '')
          : 'Erreur inconnue';
      emit(LoginPageFailureM(error: errorMessage));
    }
  }
}
