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
  /// STAB-12D — proposer vérification téléphone facultative (mode deferred).
  final bool phoneVerificationSuggested;

  LoginPageSuccessM({
    required this.token,
    required this.utilisateur,
    this.shouldUpdateAuth = false,
    this.refreshToken,
    this.phoneVerificationSuggested = false,
  });

  @override
  List<Object?> get props =>
      [token, utilisateur, shouldUpdateAuth, refreshToken, phoneVerificationSuggested];
}

class LoginPageFailureM extends LoginPageStateM {
  final String error;
  final Map<String, String> fieldErrors;

  LoginPageFailureM({
    required this.error,
    this.fieldErrors = const {},
  });

  @override
  List<Object?> get props => [error, fieldErrors];
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
  /// Preuve Google temporaire — jamais TokenStore. Vide en mode deferred optional.
  final String googleIdToken;
  final String? email;
  final bool rememberMe;
  final GooglePhonePhase phase;
  final String? e164Phone;
  final String? phoneCountry;
  final String? phoneVerificationToken;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final int resendCooldownSeconds;
  /// STAB-12D — vérification facultative après session deferred.
  final bool isDeferredOptional;
  final String? pendingToken;
  final String? pendingRefreshToken;
  final Map<String, dynamic>? pendingUtilisateur;

  LoginGooglePhoneRequiredM({
    required this.googleIdToken,
    required this.rememberMe,
    this.email,
    this.phase = GooglePhonePhase.collectPhone,
    this.e164Phone,
    this.phoneCountry,
    this.phoneVerificationToken,
    this.errorMessage,
    this.fieldErrors = const {},
    this.resendCooldownSeconds = 0,
    this.isDeferredOptional = false,
    this.pendingToken,
    this.pendingRefreshToken,
    this.pendingUtilisateur,
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
    Map<String, String>? fieldErrors,
    bool clearFieldErrors = false,
    int? resendCooldownSeconds,
    bool? isDeferredOptional,
    String? pendingToken,
    String? pendingRefreshToken,
    Map<String, dynamic>? pendingUtilisateur,
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
      fieldErrors: clearFieldErrors
          ? const {}
          : (fieldErrors ?? this.fieldErrors),
      resendCooldownSeconds:
          resendCooldownSeconds ?? this.resendCooldownSeconds,
      isDeferredOptional: isDeferredOptional ?? this.isDeferredOptional,
      pendingToken: pendingToken ?? this.pendingToken,
      pendingRefreshToken: pendingRefreshToken ?? this.pendingRefreshToken,
      pendingUtilisateur: pendingUtilisateur ?? this.pendingUtilisateur,
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
        fieldErrors,
        resendCooldownSeconds,
        isDeferredOptional,
        pendingToken,
        pendingRefreshToken,
        pendingUtilisateur,
      ];
}
