import 'package:equatable/equatable.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';

/// Phases explicites du parcours inscription + OTP (STAB-08).
enum RegisterPhase {
  initial,
  sendingOtp,
  otpSent,
  verifyingOtp,
  verified,
  registering,
  success,
  error,
}

class RegisterPageStateM extends Equatable {
  final RegisterPhase phase;
  final String? errorMessage;
  /// STAB-12A : erreurs par champ (telephone, email, password, code…).
  final Map<String, String> fieldErrors;
  final Utilisateur? utilisateur;
  /// JWT session après inscription réussie — PAS le phoneVerificationToken.
  final String? token;
  /// Éphémère : uniquement entre verify et register. Jamais TokenStore.
  final String? phoneVerificationToken;
  final String? pendingE164Phone;
  final String? pendingPhoneCountry;
  final String? pendingPrenom;
  final String? pendingNom;
  final String? pendingEmail;
  final String? pendingPassword;
  /// Secondes restantes avant resend (UI). Sécurité réelle = backend.
  final int resendCooldownSeconds;
  final DateTime? otpSentAt;

  const RegisterPageStateM({
    this.phase = RegisterPhase.initial,
    this.errorMessage,
    this.fieldErrors = const {},
    this.utilisateur,
    this.token,
    this.phoneVerificationToken,
    this.pendingE164Phone,
    this.pendingPhoneCountry,
    this.pendingPrenom,
    this.pendingNom,
    this.pendingEmail,
    this.pendingPassword,
    this.resendCooldownSeconds = 0,
    this.otpSentAt,
  });

  bool get isBusy =>
      phase == RegisterPhase.sendingOtp ||
      phase == RegisterPhase.verifyingOtp ||
      phase == RegisterPhase.registering;

  bool get showOtpStep =>
      phase == RegisterPhase.sendingOtp ||
      phase == RegisterPhase.otpSent ||
      phase == RegisterPhase.verifyingOtp ||
      phase == RegisterPhase.verified ||
      phase == RegisterPhase.registering ||
      (phase == RegisterPhase.error && otpSentAt != null);

  bool get isSuccess => phase == RegisterPhase.success;

  /// Compat UI existante.
  bool get isSubmitting => isBusy;

  RegisterPageStateM copyWith({
    RegisterPhase? phase,
    String? errorMessage,
    bool clearErrorMessage = false,
    Map<String, String>? fieldErrors,
    bool clearFieldErrors = false,
    Utilisateur? utilisateur,
    String? token,
    String? phoneVerificationToken,
    bool clearPhoneVerificationToken = false,
    String? pendingE164Phone,
    String? pendingPhoneCountry,
    String? pendingPrenom,
    String? pendingNom,
    String? pendingEmail,
    String? pendingPassword,
    bool clearPending = false,
    int? resendCooldownSeconds,
    DateTime? otpSentAt,
    bool clearOtpSentAt = false,
  }) {
    return RegisterPageStateM(
      phase: phase ?? this.phase,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      fieldErrors: clearFieldErrors
          ? const {}
          : (fieldErrors ?? this.fieldErrors),
      utilisateur: utilisateur ?? this.utilisateur,
      token: token ?? this.token,
      phoneVerificationToken: clearPhoneVerificationToken
          ? null
          : (phoneVerificationToken ?? this.phoneVerificationToken),
      pendingE164Phone:
          clearPending ? null : (pendingE164Phone ?? this.pendingE164Phone),
      pendingPhoneCountry: clearPending
          ? null
          : (pendingPhoneCountry ?? this.pendingPhoneCountry),
      pendingPrenom:
          clearPending ? null : (pendingPrenom ?? this.pendingPrenom),
      pendingNom: clearPending ? null : (pendingNom ?? this.pendingNom),
      pendingEmail: clearPending ? null : (pendingEmail ?? this.pendingEmail),
      pendingPassword:
          clearPending ? null : (pendingPassword ?? this.pendingPassword),
      resendCooldownSeconds:
          resendCooldownSeconds ?? this.resendCooldownSeconds,
      otpSentAt: clearOtpSentAt ? null : (otpSentAt ?? this.otpSentAt),
    );
  }

  @override
  List<Object?> get props => [
        phase,
        errorMessage,
        fieldErrors,
        utilisateur,
        token,
        phoneVerificationToken,
        pendingE164Phone,
        pendingPhoneCountry,
        pendingPrenom,
        pendingNom,
        pendingEmail,
        pendingPassword,
        resendCooldownSeconds,
        otpSentAt,
      ];
}
