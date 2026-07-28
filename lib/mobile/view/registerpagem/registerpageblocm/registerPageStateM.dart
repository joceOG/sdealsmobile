import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';

class RegisterPageStateM extends Equatable {
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final Utilisateur? utilisateur;
  final String? token;

  const RegisterPageStateM({
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.utilisateur,
    this.token,
  });

  RegisterPageStateM copyWith({
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearErrorMessage = false,
    Utilisateur? utilisateur,
    String? token,
  }) {
    return RegisterPageStateM(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      utilisateur: utilisateur ?? this.utilisateur,
      token: token ?? this.token,
    );
  }

  @override
  List<Object?> get props => [
        isSubmitting,
        isSuccess,
        errorMessage,
        utilisateur,
        token,
      ];
}
