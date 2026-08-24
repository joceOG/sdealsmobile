import 'package:equatable/equatable.dart';

abstract class RegisterPageEventM extends Equatable {
  const RegisterPageEventM();

  @override
  List<Object?> get props => [];
}

/// Soumission du formulaire → canonise téléphone → POST /otp/send (pas /register).
class RegisterSubmitted extends RegisterPageEventM {
  final String prenom;
  final String nom;
  final String email;
  final String phone;
  final String phoneCountry;
  final String password;
  final String confirmPassword;

  const RegisterSubmitted({
    required this.prenom,
    required this.nom,
    required this.email,
    required this.phone,
    required this.phoneCountry,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props =>
      [prenom, nom, email, phone, phoneCountry, password, confirmPassword];
}

class OtpCodeSubmitted extends RegisterPageEventM {
  final String code;

  const OtpCodeSubmitted(this.code);

  @override
  List<Object?> get props => [code];
}

class OtpResendRequested extends RegisterPageEventM {
  const OtpResendRequested();
}

/// Retour au formulaire : invalide OTP / token locaux.
class RegisterOtpStepCancelled extends RegisterPageEventM {
  const RegisterOtpStepCancelled();
}

/// Téléphone modifié après OTP → invalide vérification précédente.
class RegisterPhoneChanged extends RegisterPageEventM {
  final String phone;
  final String phoneCountry;

  const RegisterPhoneChanged({
    required this.phone,
    required this.phoneCountry,
  });

  @override
  List<Object?> get props => [phone, phoneCountry];
}

class RegisterResendTick extends RegisterPageEventM {
  const RegisterResendTick();
}

class RegisterClearError extends RegisterPageEventM {
  const RegisterClearError();
}
