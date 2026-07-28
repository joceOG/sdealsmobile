import 'package:equatable/equatable.dart';

abstract class LoginPageStateM extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginPageInitialM extends LoginPageStateM {}

class LoginPageLoadingM extends LoginPageStateM {}

class LoginPageSuccessM extends LoginPageStateM {
  final String token;
  final Map<String, dynamic> utilisateur;
  final bool shouldUpdateAuth;
  final String? refreshToken;

  LoginPageSuccessM({
    required this.token,
    required this.utilisateur,
    this.shouldUpdateAuth = false,
    this.refreshToken,
  });

  @override
  List<Object?> get props => [token, utilisateur, shouldUpdateAuth, refreshToken];
}

class LoginPageFailureM extends LoginPageStateM {
  final String error;

  LoginPageFailureM({required this.error});

  @override
  List<Object?> get props => [error];
}
