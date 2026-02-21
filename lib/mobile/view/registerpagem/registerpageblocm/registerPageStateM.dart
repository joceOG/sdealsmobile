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
<<<<<<< HEAD
  final String? token; // ✅ Ajouter le token
=======
  final String? token;   // ✅ Ajout du token
>>>>>>> 94ba01a (MAJ SDEALS MOBILE BETA)

  const RegisterPageStateM({
    this.fullName = '',
    this.phone = '',
    this.password = '',
    this.confirmPassword = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.utilisateur,
<<<<<<< HEAD
    this.token, // ✅ Ajouter le token
=======
    this.token,  // ✅ Ajout du token
>>>>>>> 94ba01a (MAJ SDEALS MOBILE BETA)
  });

  RegisterPageStateM copyWith({
    String? fullName,
    String? phone,
    String? password,
    String? confirmPassword,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    Utilisateur? utilisateur,
<<<<<<< HEAD
    String? token, // ✅ Ajouter le token
=======
    String? token,   // ✅ Ajout du token
>>>>>>> 94ba01a (MAJ SDEALS MOBILE BETA)
  }) {
    return RegisterPageStateM(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
<<<<<<< HEAD
      utilisateur: utilisateur,
      token: token ?? this.token, // ✅ Ajouter le token
=======
      utilisateur: utilisateur ?? this.utilisateur,
      token: token ?? this.token,  // ✅ Ajout du token
>>>>>>> 94ba01a (MAJ SDEALS MOBILE BETA)
    );
  }

  @override
  List<Object?> get props => [
<<<<<<< HEAD
        fullName,
        phone,
        password,
        confirmPassword,
        isSubmitting,
        isSuccess,
        errorMessage,
        utilisateur,
        token
      ];
=======
    fullName,
    phone,
    password,
    confirmPassword,
    isSubmitting,
    isSuccess,
    errorMessage,
    utilisateur,
    token, // ✅ Ajout du token
  ];
>>>>>>> 94ba01a (MAJ SDEALS MOBILE BETA)
}
