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
  List<Object?> get props =>
      [token, utilisateur, shouldUpdateAuth, refreshToken];
}

class LoginPageFailureM extends LoginPageStateM {
  final String error;

  LoginPageFailureM({required this.error});

  @override
  List<Object?> get props => [error];
}

/// STAB-09 — Google a réussi, téléphone à vérifier (idToken en mémoire uniquement).
enum GooglePhonePhase {
  collectPhone,
  sendingOtp,
  otpSent,
  verifyingOtp,
  completing,
  error,
}

class LoginGooglePhoneRequiredM extends LoginPageStateM {
  /// Preuve Google temporaire — jamais TokenStore.
  final String googleIdToken;
  final String? email;
  final bool rememberMe;
  final GooglePhonePhase phase;
  final String? e164Phone;
  final String? phoneCountry;
  final String? phoneVerificationToken;
  final String? errorMessage;
  final int resendCooldownSeconds;

  LoginGooglePhoneRequiredM({
    required this.googleIdToken,
    required this.rememberMe,
    this.email,
    this.phase = GooglePhonePhase.collectPhone,
    this.e164Phone,
    this.phoneCountry,
    this.phoneVerificationToken,
    this.errorMessage,
    this.resendCooldownSeconds = 0,
  });

  bool get isBusy =>
      phase == GooglePhonePhase.sendingOtp ||
      phase == GooglePhonePhase.verifyingOtp ||
      phase == GooglePhonePhase.completing;

  LoginGooglePhoneRequiredM copyWith({
    GooglePhonePhase? phase,
    String? e164Phone,
    String? phoneCountry,
    String? phoneVerificationToken,
    bool clearPhoneVerificationToken = false,
    String? errorMessage,
    bool clearError = false,
    int? resendCooldownSeconds,
  }) {
    return LoginGooglePhoneRequiredM(
      googleIdToken: googleIdToken,
      email: email,
      rememberMe: rememberMe,
      phase: phase ?? this.phase,
      e164Phone: e164Phone ?? this.e164Phone,
      phoneCountry: phoneCountry ?? this.phoneCountry,
      phoneVerificationToken: clearPhoneVerificationToken
          ? null
          : (phoneVerificationToken ?? this.phoneVerificationToken),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      resendCooldownSeconds:
          resendCooldownSeconds ?? this.resendCooldownSeconds,
    );
  }

  @override
  List<Object?> get props => [
        googleIdToken,
        email,
        rememberMe,
        phase,
        e164Phone,
        phoneCountry,
        phoneVerificationToken,
        errorMessage,
        resendCooldownSeconds,
      ];
}
