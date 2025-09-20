import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';

class RegisterPageStateM extends Equatable {
  final String fullName;
  final String phone;
  final String password;
  final String confirmPassword;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final Utilisateur? utilisateur;

  const RegisterPageStateM({
    this.fullName = '',
    this.phone = '',
    this.password = '',
    this.confirmPassword = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.utilisateur,
  });

  RegisterPageStateM copyWith({
    String? fullName,
    String? phone,
    String? password,
    String? confirmPassword,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    Utilisateur? utilisateur
  }) {
    return RegisterPageStateM(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      utilisateur: utilisateur
    );
  }

  @override
  List<Object?> get props =>
      [fullName, phone, password, confirmPassword, isSubmitting, isSuccess, errorMessage, utilisateur];
}
