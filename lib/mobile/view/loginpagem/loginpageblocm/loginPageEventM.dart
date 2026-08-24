import 'package:equatable/equatable.dart';

abstract class LoginPageEventM extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginSubmittedM extends LoginPageEventM {
  final String identifiant;
  final String password;
  final bool rememberMe;
  final String? phoneCountry;

  LoginSubmittedM({
    required this.identifiant,
    required this.password,
    this.rememberMe = false,
    this.phoneCountry,
  });

  @override
  List<Object?> get props => [identifiant, password, rememberMe, phoneCountry];
}

class GoogleLoginSubmittedM extends LoginPageEventM {
  final bool rememberMe;

  GoogleLoginSubmittedM({this.rememberMe = true});

  @override
  List<Object?> get props => [rememberMe];
}

class GooglePhoneSubmittedM extends LoginPageEventM {
  final String phone;
  final String phoneCountry;

  GooglePhoneSubmittedM({
    required this.phone,
    required this.phoneCountry,
  });

  @override
  List<Object?> get props => [phone, phoneCountry];
}

class GoogleOtpSubmittedM extends LoginPageEventM {
  final String code;

  GoogleOtpSubmittedM(this.code);

  @override
  List<Object?> get props => [code];
}

class GoogleOtpResendRequestedM extends LoginPageEventM {}

class GooglePhoneCancelledM extends LoginPageEventM {}

/// STAB-12D — ignorer la vérification facultative (mode deferred).
class GooglePhoneSkippedM extends LoginPageEventM {}

/// STAB-12D — démarrer vérification téléphone après session deferred.
class StartDeferredPhoneVerifyM extends LoginPageEventM {
  final String token;
  final String? refreshToken;
  final Map<String, dynamic> utilisateur;
  final bool rememberMe;

  StartDeferredPhoneVerifyM({
    required this.token,
    required this.utilisateur,
    this.refreshToken,
    this.rememberMe = true,
  });

  @override
  List<Object?> get props => [token, refreshToken, utilisateur, rememberMe];
}

class GooglePhoneChangedM extends LoginPageEventM {
  final String phone;
  final String phoneCountry;

  GooglePhoneChangedM({required this.phone, required this.phoneCountry});

  @override
  List<Object?> get props => [phone, phoneCountry];
}

class GoogleResendTickM extends LoginPageEventM {}
