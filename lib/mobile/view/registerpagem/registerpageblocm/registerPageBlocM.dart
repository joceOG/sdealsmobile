import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../../../../data/errors/api_exception.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/utils/phone_canonicalizer.dart';
import 'registerPageStateM.dart';
import 'registerPageEventM.dart';

/// Cooldown UI aligné sur le backend (RESEND_COOLDOWN_MS = 60s).
const int kOtpResendCooldownSeconds = 60;

class RegisterPageBlocM extends Bloc<RegisterPageEventM, RegisterPageStateM> {
  RegisterPageBlocM({
    ApiClient? apiClient,
    this.resendCooldownSeconds = kOtpResendCooldownSeconds,
  })  : _apiClient = apiClient ?? ApiClient(),
        super(const RegisterPageStateM()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<OtpCodeSubmitted>(_onOtpCodeSubmitted);
    on<OtpResendRequested>(_onOtpResendRequested);
    on<RegisterOtpStepCancelled>(_onOtpStepCancelled);
    on<RegisterPhoneChanged>(_onPhoneChanged);
    on<RegisterResendTick>(_onResendTick);
    on<RegisterClearError>(_onClearError);
  }

  final ApiClient _apiClient;
  final int resendCooldownSeconds;
  Timer? _resendTimer;

  /// Compteurs de concurrence (tests STAB-08).
  int sendInFlight = 0;
  int verifyInFlight = 0;
  int registerInFlight = 0;

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    return super.close();
  }

  void _startResendCountdown(Emitter<RegisterPageStateM> emit, {int? seconds}) {
    _resendTimer?.cancel();
    final secs = seconds ?? resendCooldownSeconds;
    emit(state.copyWith(
      resendCooldownSeconds: secs,
      otpSentAt: DateTime.now(),
    ));
    if (secs <= 0) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const RegisterResendTick());
    });
  }

  void _onResendTick(
    RegisterResendTick event,
    Emitter<RegisterPageStateM> emit,
  ) {
    final next = state.resendCooldownSeconds - 1;
    if (next <= 0) {
      _resendTimer?.cancel();
      _resendTimer = null;
      emit(state.copyWith(resendCooldownSeconds: 0));
    } else {
      emit(state.copyWith(resendCooldownSeconds: next));
    }
  }

  void _onClearError(
    RegisterClearError event,
    Emitter<RegisterPageStateM> emit,
  ) {
    emit(state.copyWith(clearErrorMessage: true));
  }

  void _invalidateVerification(Emitter<RegisterPageStateM> emit) {
    _resendTimer?.cancel();
    _resendTimer = null;
    emit(state.copyWith(
      phase: RegisterPhase.initial,
      clearPhoneVerificationToken: true,
      clearPending: true,
      clearOtpSentAt: true,
      resendCooldownSeconds: 0,
      clearErrorMessage: true,
    ));
  }

  void _onPhoneChanged(
    RegisterPhoneChanged event,
    Emitter<RegisterPageStateM> emit,
  ) {
    if (state.phoneVerificationToken == null &&
        state.pendingE164Phone == null) {
      return;
    }
    // Tout changement de numéro après OTP invalide le token A.
    _invalidateVerification(emit);
  }

  void _onOtpStepCancelled(
    RegisterOtpStepCancelled event,
    Emitter<RegisterPageStateM> emit,
  ) {
    _invalidateVerification(emit);
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterPageStateM> emit,
  ) async {
    // Un seul envoi OTP en vol / déjà en step OTP (anti double-tap).
    if (state.isBusy) return;
    if (state.phase == RegisterPhase.otpSent ||
        state.phase == RegisterPhase.verified ||
        state.phase == RegisterPhase.success) {
      return;
    }

    if (event.password != event.confirmPassword) {
      emit(state.copyWith(
        phase: RegisterPhase.error,
        errorMessage: 'Les mots de passe ne correspondent pas',
      ));
      return;
    }

    final nomTrim = event.nom.trim();
    final prenomTrim = event.prenom.trim();
    if (nomTrim.length < 2) {
      emit(state.copyWith(
        phase: RegisterPhase.error,
        errorMessage: 'Le nom doit contenir au moins 2 caractères',
        fieldErrors: const {'nom': 'Le nom doit contenir au moins 2 caractères'},
      ));
      return;
    }
    if (prenomTrim.isNotEmpty && prenomTrim.length < 2) {
      emit(state.copyWith(
        phase: RegisterPhase.error,
        errorMessage: 'Le prénom doit contenir au moins 2 caractères',
        fieldErrors: const {
          'prenom': 'Le prénom doit contenir au moins 2 caractères',
        },
      ));
      return;
    }

    final config = await _apiClient.fetchPhoneVerificationConfig();

    // STAB-12D — mode deferred : email obligatoire, téléphone facultatif, pas d'OTP bloquant.
    if (!config.signupRequiresOtp) {
      final emailTrim = event.email.trim();
      if (emailTrim.isEmpty || !emailTrim.contains('@')) {
        emit(state.copyWith(
          phase: RegisterPhase.error,
          errorMessage: 'Email requis pour l\'inscription',
        ));
        return;
      }

      String? e164Phone;
      final phoneRaw = event.phone.trim();
      if (phoneRaw.isNotEmpty) {
        try {
          final iso = IsoCode.values.byName(event.phoneCountry.toUpperCase());
          e164Phone = PhoneCanonicalizer.toE164(phoneRaw, isoCode: iso);
        } on PhoneCanonicalizationException catch (e) {
          emit(state.copyWith(
            phase: RegisterPhase.error,
            errorMessage: e.message,
          ));
          return;
        } catch (_) {
          emit(state.copyWith(
            phase: RegisterPhase.error,
            errorMessage:
                'Numéro de téléphone invalide pour le pays sélectionné.',
          ));
          return;
        }
      }

      emit(state.copyWith(
        phase: RegisterPhase.registering,
        clearErrorMessage: true,
        clearFieldErrors: true,
        pendingE164Phone: e164Phone,
        pendingPhoneCountry: event.phoneCountry.toUpperCase(),
        pendingPrenom: prenomTrim.isEmpty ? null : prenomTrim,
        pendingNom: nomTrim,
        pendingEmail: emailTrim,
        pendingPassword: event.password,
      ));
      registerInFlight += 1;
      try {
        final newuser = await _apiClient.registerUser(
          nom: nomTrim,
          prenom: prenomTrim.isEmpty ? null : prenomTrim,
          phone: e164Phone ?? '',
          phoneCountry: event.phoneCountry.toUpperCase(),
          password: event.password,
          email: emailTrim,
          role: 'Client',
        );

        if (newuser['utilisateur'] != null && newuser['token'] != null) {
          final userData = newuser['utilisateur'] as Map<String, dynamic>;
          final token = newuser['token'].toString();
          final utilisateurCree = Utilisateur(
            idutilisateur: userData['_id'] ?? '',
            nom: userData['nom'] ?? '',
            prenom: userData['prenom'] ?? '',
            email: userData['email'],
            password: '',
            telephone: userData['telephone']?.toString() ?? '',
            genre: userData['genre'] ?? '',
            note: userData['note'],
            photoProfil: userData['photoProfil'],
            dateNaissance: userData['datedenaissance'],
            role: userData['role'] ?? 'Client',
            telephoneVerified: userData['telephoneVerified'] == true,
          );
          emit(state.copyWith(
            phase: RegisterPhase.success,
            utilisateur: utilisateurCree,
            token: token,
            clearPhoneVerificationToken: true,
            clearPending: true,
          ));
        } else {
          emit(state.copyWith(
            phase: RegisterPhase.error,
            errorMessage: 'Inscription incomplète. Réessayez.',
          ));
        }
      } catch (e) {
        emit(state.copyWith(
          phase: RegisterPhase.error,
          errorMessage: _userFacing(e),
          fieldErrors: _fieldErrors(e),
        ));
      } finally {
        registerInFlight = 0;
      }
      return;
    }

    late final String e164Phone;
    try {
      final iso = IsoCode.values.byName(event.phoneCountry.toUpperCase());
      e164Phone = PhoneCanonicalizer.toE164(
        event.phone,
        isoCode: iso,
      );
    } on PhoneCanonicalizationException catch (e) {
      emit(state.copyWith(
        phase: RegisterPhase.error,
        errorMessage: e.message,
      ));
      return;
    } catch (_) {
      emit(state.copyWith(
        phase: RegisterPhase.error,
        errorMessage:
            'Numéro de téléphone invalide pour le pays sélectionné.',
      ));
      return;
    }

    // Changement de numéro vs pending → drop ancien token
    if (state.pendingE164Phone != null &&
        state.pendingE164Phone != e164Phone) {
      emit(state.copyWith(clearPhoneVerificationToken: true));
    }

    emit(state.copyWith(
      phase: RegisterPhase.sendingOtp,
      clearErrorMessage: true,
      clearFieldErrors: true,
      clearPhoneVerificationToken: true,
      pendingE164Phone: e164Phone,
      pendingPhoneCountry: event.phoneCountry.toUpperCase(),
      pendingPrenom: prenomTrim.isEmpty ? null : prenomTrim,
      pendingNom: nomTrim,
      pendingEmail: event.email.trim(),
      pendingPassword: event.password,
    ));

    sendInFlight += 1;
    try {
      await _apiClient.sendPhoneOtp(
        telephone: e164Phone,
        phoneCountry: event.phoneCountry.toUpperCase(),
      );
      emit(state.copyWith(phase: RegisterPhase.otpSent));
      _startResendCountdown(emit);
    } catch (e) {
      emit(state.copyWith(
        phase: RegisterPhase.error,
        errorMessage: _userFacing(e),
        fieldErrors: _fieldErrors(e),
        clearPending: true,
        clearPhoneVerificationToken: true,
        clearOtpSentAt: true,
        resendCooldownSeconds: 0,
      ));
    } finally {
      sendInFlight = 0;
    }
  }

  Future<void> _onOtpResendRequested(
    OtpResendRequested event,
    Emitter<RegisterPageStateM> emit,
  ) async {
    if (state.isBusy) return;
    if (state.resendCooldownSeconds > 0) return;
    final phone = state.pendingE164Phone;
    final country = state.pendingPhoneCountry;
    if (phone == null || country == null) return;

    emit(state.copyWith(
      phase: RegisterPhase.sendingOtp,
      clearErrorMessage: true,
      clearFieldErrors: true,
      clearPhoneVerificationToken: true,
    ));

    sendInFlight += 1;
    try {
      await _apiClient.sendPhoneOtp(
        telephone: phone,
        phoneCountry: country,
      );
      emit(state.copyWith(phase: RegisterPhase.otpSent));
      _startResendCountdown(emit);
    } catch (e) {
      emit(state.copyWith(
        phase: RegisterPhase.error,
        errorMessage: _userFacing(e),
        fieldErrors: _fieldErrors(e),
      ));
    } finally {
      sendInFlight = 0;
    }
  }

  Future<void> _onOtpCodeSubmitted(
    OtpCodeSubmitted event,
    Emitter<RegisterPageStateM> emit,
  ) async {
    if (state.isBusy) return;
    if (state.phase == RegisterPhase.success) return;
    final phone = state.pendingE164Phone;
    final country = state.pendingPhoneCountry;
    final nom = state.pendingNom;
    final prenom = state.pendingPrenom;
    final password = state.pendingPassword;
    if (phone == null ||
        country == null ||
        nom == null ||
        password == null) {
      return;
    }

    final code = event.code.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      emit(state.copyWith(
        phase: RegisterPhase.error,
        errorMessage: 'Saisissez le code à 6 chiffres.',
      ));
      return;
    }

    emit(state.copyWith(
      phase: RegisterPhase.verifyingOtp,
      clearErrorMessage: true,
      clearFieldErrors: true,
    ));

    verifyInFlight += 1;
    String? verificationToken;
    try {
      final verified = await _apiClient.verifyPhoneOtp(
        telephone: phone,
        code: code,
        phoneCountry: country,
      );
      verificationToken =
          verified['phoneVerificationToken']?.toString();
      if (verificationToken == null || verificationToken.isEmpty) {
        emit(state.copyWith(
          phase: RegisterPhase.error,
          errorMessage: 'Vérification incomplète. Réessayez.',
        ));
        return;
      }
      // Le téléphone renvoyé doit matcher (défense défense en profondeur).
      final verifiedPhone = verified['telephone']?.toString();
      if (verifiedPhone != null &&
          verifiedPhone.isNotEmpty &&
          verifiedPhone != phone) {
        emit(state.copyWith(
          phase: RegisterPhase.error,
          clearPhoneVerificationToken: true,
          errorMessage: 'Le numéro vérifié ne correspond pas. Recommencez.',
        ));
        return;
      }

      emit(state.copyWith(
        phase: RegisterPhase.verified,
        phoneVerificationToken: verificationToken,
      ));
    } catch (e) {
      emit(state.copyWith(
        phase: RegisterPhase.error,
        errorMessage: _userFacing(e),
        fieldErrors: _fieldErrors(e),
      ));
      return;
    } finally {
      verifyInFlight = 0;
    }

    // Enchaîne register immédiatement après verify réussi.
    await _registerAfterVerify(emit, verificationToken!);
  }

  Future<void> _registerAfterVerify(
    Emitter<RegisterPageStateM> emit,
    String phoneVerificationToken,
  ) async {
    if (registerInFlight > 0) return;

    final phone = state.pendingE164Phone!;
    final country = state.pendingPhoneCountry!;
    final nom = state.pendingNom!;
    final prenom = state.pendingPrenom;
    final password = state.pendingPassword!;
    final email = state.pendingEmail;

    emit(state.copyWith(phase: RegisterPhase.registering));
    registerInFlight += 1;
    try {
      final newuser = await _apiClient.registerUser(
        nom: nom,
        prenom: prenom,
        phone: phone,
        phoneCountry: country,
        password: password,
        email: (email == null || email.isEmpty) ? null : email,
        phoneVerificationToken: phoneVerificationToken,
        role: 'Client',
      );

      if (newuser['utilisateur'] != null && newuser['token'] != null) {
        final userData = newuser['utilisateur'] as Map<String, dynamic>;
        final token = newuser['token'].toString();

        final utilisateurCree = Utilisateur(
          idutilisateur: userData['_id'] ?? '',
          nom: userData['nom'] ?? '',
          prenom: userData['prenom'] ?? '',
          email: userData['email'],
          password: '',
          telephone: userData['telephone'] ?? phone,
          genre: userData['genre'] ?? '',
          note: userData['note'],
          photoProfil: userData['photoProfil'],
          dateNaissance: userData['datedenaissance'],
          role: userData['role'] ?? 'Client',
        );

        _resendTimer?.cancel();
        emit(state.copyWith(
          phase: RegisterPhase.success,
          utilisateur: utilisateurCree,
          token: token,
          clearPhoneVerificationToken: true,
          clearPending: true,
          resendCooldownSeconds: 0,
          clearOtpSentAt: true,
        ));
      } else {
        emit(state.copyWith(
          phase: RegisterPhase.error,
          clearPhoneVerificationToken: true,
          errorMessage: 'Inscription incomplète. Réessayez.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        phase: RegisterPhase.error,
        errorMessage: _userFacing(e),
        fieldErrors: _fieldErrors(e),
      ));
    } finally {
      registerInFlight = 0;
    }
  }

  String _userFacing(Object e) => ApiException.userFacing(e);

  Map<String, String> _fieldErrors(Object e) =>
      e is ApiException ? e.fieldErrors : const {};
}
