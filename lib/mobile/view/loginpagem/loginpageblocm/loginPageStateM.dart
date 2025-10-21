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

  LoginPageSuccessM({
    required this.token, 
    required this.utilisateur,
    this.shouldUpdateAuth = false,
  });
  
  @override
  List<Object?> get props => [token, utilisateur, shouldUpdateAuth];
}


class LoginPageFailureM extends LoginPageStateM {
  final String error;

  LoginPageFailureM({required this.error});

  @override
  List<Object?> get props => [error];
}
