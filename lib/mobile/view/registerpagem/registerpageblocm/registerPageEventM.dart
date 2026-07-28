import 'package:equatable/equatable.dart';

abstract class RegisterPageEventM extends Equatable {
  const RegisterPageEventM();

  @override
  List<Object?> get props => [];
}

class RegisterSubmitted extends RegisterPageEventM {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;

  const RegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props =>
      [fullName, email, phone, password, confirmPassword];
}
