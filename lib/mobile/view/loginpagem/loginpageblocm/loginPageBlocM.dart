import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/google_auth_service.dart';
import 'package:sdealsmobile/data/services/token_store.dart';
import '../../../../data/models/utilisateur.dart';
import 'loginPageEventM.dart';
import 'loginPageStateM.dart';

class LoginPageBlocM extends Bloc<LoginPageEventM, LoginPageStateM> {
  LoginPageBlocM() : super(LoginPageInitialM()) {
    on<LoginSubmittedM>(_onLoginSubmitted);
    on<GoogleLoginSubmittedM>(_onGoogleLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedM event,
    Emitter<LoginPageStateM> emit,
  ) async {
    emit(LoginPageLoadingM());

    final apiClient = ApiClient();
    try {
      final response = await apiClient.loginUser(
        identifiant: event.identifiant,
        password: event.password,
        rememberMe: event.rememberMe,
      );

      final token = response["token"] ?? "";
      final refreshToken = response["refreshToken"]?.toString();
      final utilisateurData = response["utilisateur"] ?? {};

      if (token.isEmpty) {
        emit(LoginPageFailureM(error: "Token manquant dans la réponse"));
        return;
      }

      final utilisateur = Utilisateur.fromMap(utilisateurData);

      if (event.rememberMe) {
        await TokenStore.saveTokens(
          accessToken: token,
          refreshToken: refreshToken,
        );
      }

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

  Future<void> _onGoogleLoginSubmitted(
    GoogleLoginSubmittedM event,
    Emitter<LoginPageStateM> emit,
  ) async {
    emit(LoginPageLoadingM());
    try {
      final idToken = await GoogleAuthService.instance.signInForIdToken();
      if (idToken == null) {
        emit(LoginPageInitialM());
        return;
      }

      final response = await ApiClient().loginWithGoogle(idToken: idToken);
      final token = response["token"]?.toString() ?? "";
      final refreshToken = response["refreshToken"]?.toString();
      final utilisateurData =
          response["utilisateur"] as Map<String, dynamic>? ?? {};

      if (token.isEmpty) {
        emit(LoginPageFailureM(error: "Token manquant dans la réponse"));
        return;
      }

      final utilisateur = Utilisateur.fromMap(utilisateurData);

      if (event.rememberMe) {
        await TokenStore.saveTokens(
          accessToken: token,
          refreshToken: refreshToken,
        );
      }

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
