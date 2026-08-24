import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/google_auth_service.dart';
import 'package:sdealsmobile/data/services/token_store.dart';
import 'package:sdealsmobile/data/utils/phone_canonicalizer.dart';
import '../../../../data/models/utilisateur.dart';
import 'loginPageEventM.dart';
import 'loginPageStateM.dart';

const int _kGoogleResendCooldown = 60;

class LoginPageBlocM extends Bloc<LoginPageEventM, LoginPageStateM> {
  LoginPageBlocM({
    ApiClient? apiClient,
    GoogleSignInGateway? googleAuth,
    this.resendCooldownSeconds = _kGoogleResendCooldown,
  })  : _api = apiClient ?? ApiClient(),
        _google = googleAuth ?? GoogleAuthService.instance,
        super(LoginPageInitialM()) {
    on<LoginSubmittedM>(_onLoginSubmitted);
    on<GoogleLoginSubmittedM>(_onGoogleLoginSubmitted);
    on<GooglePhoneSubmittedM>(_onGooglePhoneSubmitted);
    on<GoogleOtpSubmittedM>(_onGoogleOtpSubmitted);
    on<GoogleOtpResendRequestedM>(_onGoogleResend);
    on<GooglePhoneCancelledM>(_onGooglePhoneCancelled);
    on<GooglePhoneChangedM>(_onGooglePhoneChanged);
    on<GoogleResendTickM>(_onResendTick);
  }

  final ApiClient _api;
  final GoogleSignInGateway _google;
  final int resendCooldownSeconds;
  Timer? _resendTimer;
  bool _googleInFlight = false;

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedM event,
    Emitter<LoginPageStateM> emit,
  ) async {
    emit(LoginPageLoadingM());

    final rawId = event.identifiant.trim();
    String identifiant = rawId;
    String? phoneCountry = event.phoneCountry;

    if (!rawId.contains('@')) {
      IsoCode? iso;
      if (phoneCountry != null && phoneCountry.isNotEmpty) {
        try {
          iso = IsoCode.values.byName(phoneCountry.toUpperCase());
        } catch (_) {
          iso = null;
        }
      }
      try {
        if (PhoneCanonicalizer.isInternationalInput(rawId) || iso != null) {
          identifiant = PhoneCanonicalizer.toE164(rawId, isoCode: iso);
          phoneCountry = iso?.name ?? phoneCountry;
        } else {
          emit(LoginPageFailureM(
            error:
                'Numéro de téléphone invalide pour le pays sélectionné.',
          ));
          return;
        }
      } on PhoneCanonicalizationException catch (e) {
        emit(LoginPageFailureM(error: e.message));
        return;
      }
    }

    try {
      final response = await _api.loginUser(
        identifiant: identifiant,
        password: event.password,
        phoneCountry: phoneCountry,
        rememberMe: event.rememberMe,
      );

      final token = response["token"] ?? "";
      final refreshToken = response["refreshToken"]?.toString();
      final utilisateurData = response["utilisateur"] ?? {};

      if (token.isEmpty) {
        emit(LoginPageFailureM(error: "Token manquant dans la réponse"));
        return;
      }

      final utilisateur = Utilisateur.fromMap(utilisateurData);

      if (event.rememberMe) {
        await TokenStore.saveTokens(
          accessToken: token,
          refreshToken: refreshToken,
        );
      }

      emit(LoginPageSuccessM(
        token: token,
        utilisateur: utilisateur.toMap(),
        shouldUpdateAuth: true,
        refreshToken: refreshToken,
      ));
    } catch (error) {
      emit(LoginPageFailureM(error: _userFacing(error)));
    }
  }

  Future<void> _onGoogleLoginSubmitted(
    GoogleLoginSubmittedM event,
    Emitter<LoginPageStateM> emit,
  ) async {
    if (_googleInFlight) return;
    if (state is LoginPageLoadingM) return;
    _googleInFlight = true;
    emit(LoginPageLoadingM());
    try {
      final idToken = await _google.signInForIdToken();
      if (idToken == null) {
        emit(LoginPageInitialM());
        return;
      }

      try {
        final response = await _api.loginWithGoogle(idToken: idToken);
        await _emitGoogleSession(
          emit,
          response,
          rememberMe: event.rememberMe,
        );
      } on GooglePhoneVerificationRequiredException catch (e) {
        emit(LoginGooglePhoneRequiredM(
          googleIdToken: idToken,
          email: e.email,
          rememberMe: event.rememberMe,
        ));
      }
    } catch (error) {
      emit(LoginPageFailureM(error: _googleFacing(error)));
    } finally {
      _googleInFlight = false;
    }
  }

  Future<void> _emitGoogleSession(
    Emitter<LoginPageStateM> emit,
    Map<String, dynamic> response, {
    required bool rememberMe,
  }) async {
    final token = response["token"]?.toString() ?? "";
    final refreshToken = response["refreshToken"]?.toString();
    final utilisateurData =
        response["utilisateur"] as Map<String, dynamic>? ?? {};

    if (token.isEmpty) {
      emit(LoginPageFailureM(error: "Token manquant dans la réponse"));
      return;
    }

    final utilisateur = Utilisateur.fromMap(utilisateurData);
    if (rememberMe) {
      await TokenStore.saveTokens(
        accessToken: token,
        refreshToken: refreshToken,
      );
    }

    emit(LoginPageSuccessM(
      token: token,
      utilisateur: utilisateur.toMap(),
      shouldUpdateAuth: true,
      refreshToken: refreshToken,
    ));
  }

  Future<void> _onGooglePhoneSubmitted(
    GooglePhoneSubmittedM event,
    Emitter<LoginPageStateM> emit,
  ) async {
    final cur = state;
    if (cur is! LoginGooglePhoneRequiredM) return;
    if (cur.isBusy) return;

    late final String e164;
    try {
      final iso = IsoCode.values.byName(event.phoneCountry.toUpperCase());
      e164 = PhoneCanonicalizer.toE164(event.phone, isoCode: iso);
    } on PhoneCanonicalizationException catch (e) {
      emit(cur.copyWith(
        phase: GooglePhonePhase.error,
        errorMessage: e.message,
      ));
      return;
    } catch (_) {
      emit(cur.copyWith(
        phase: GooglePhonePhase.error,
        errorMessage:
            'Numéro de téléphone invalide pour le pays sélectionné.',
      ));
      return;
    }

    if (cur.e164Phone != null && cur.e164Phone != e164) {
      emit(cur.copyWith(clearPhoneVerificationToken: true));
    }

    emit(cur.copyWith(
      phase: GooglePhonePhase.sendingOtp,
      e164Phone: e164,
      phoneCountry: event.phoneCountry.toUpperCase(),
      clearPhoneVerificationToken: true,
      clearError: true,
    ));

    try {
      await _api.sendPhoneOtp(
        telephone: e164,
        phoneCountry: event.phoneCountry.toUpperCase(),
      );
      final next = state;
      if (next is! LoginGooglePhoneRequiredM) return;
      emit(next.copyWith(phase: GooglePhonePhase.otpSent));
      _startResend(emit);
    } catch (e) {
      final next = state;
      if (next is! LoginGooglePhoneRequiredM) return;
      emit(next.copyWith(
        phase: GooglePhonePhase.error,
        errorMessage: _userFacing(e),
      ));
    }
  }

  void _startResend(Emitter<LoginPageStateM> emit) {
    _resendTimer?.cancel();
    final cur = state;
    if (cur is! LoginGooglePhoneRequiredM) return;
    emit(cur.copyWith(resendCooldownSeconds: resendCooldownSeconds));
    if (resendCooldownSeconds <= 0) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(GoogleResendTickM());
    });
  }

  void _onResendTick(
    GoogleResendTickM event,
    Emitter<LoginPageStateM> emit,
  ) {
    final cur = state;
    if (cur is! LoginGooglePhoneRequiredM) {
      _resendTimer?.cancel();
      return;
    }
    final next = cur.resendCooldownSeconds - 1;
    if (next <= 0) {
      _resendTimer?.cancel();
      emit(cur.copyWith(resendCooldownSeconds: 0));
    } else {
      emit(cur.copyWith(resendCooldownSeconds: next));
    }
  }

  Future<void> _onGoogleResend(
    GoogleOtpResendRequestedM event,
    Emitter<LoginPageStateM> emit,
  ) async {
    final cur = state;
    if (cur is! LoginGooglePhoneRequiredM) return;
    if (cur.isBusy || cur.resendCooldownSeconds > 0) return;
    final phone = cur.e164Phone;
    final country = cur.phoneCountry;
    if (phone == null || country == null) return;

    emit(cur.copyWith(
      phase: GooglePhonePhase.sendingOtp,
      clearPhoneVerificationToken: true,
      clearError: true,
    ));
    try {
      await _api.sendPhoneOtp(telephone: phone, phoneCountry: country);
      final next = state;
      if (next is! LoginGooglePhoneRequiredM) return;
      emit(next.copyWith(phase: GooglePhonePhase.otpSent));
      _startResend(emit);
    } catch (e) {
      final next = state;
      if (next is! LoginGooglePhoneRequiredM) return;
      emit(next.copyWith(
        phase: GooglePhonePhase.error,
        errorMessage: _userFacing(e),
      ));
    }
  }

  Future<void> _onGoogleOtpSubmitted(
    GoogleOtpSubmittedM event,
    Emitter<LoginPageStateM> emit,
  ) async {
    final cur = state;
    if (cur is! LoginGooglePhoneRequiredM) return;
    if (cur.isBusy) return;
    final phone = cur.e164Phone;
    final country = cur.phoneCountry;
    if (phone == null || country == null) return;

    final code = event.code.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      emit(cur.copyWith(
        phase: GooglePhonePhase.error,
        errorMessage: 'Saisissez le code à 6 chiffres.',
      ));
      return;
    }

    emit(cur.copyWith(
      phase: GooglePhonePhase.verifyingOtp,
      clearError: true,
    ));

    try {
      final verified = await _api.verifyPhoneOtp(
        telephone: phone,
        code: code,
        phoneCountry: country,
      );
      final token = verified['phoneVerificationToken']?.toString();
      if (token == null || token.isEmpty) {
        final next = state;
        if (next is! LoginGooglePhoneRequiredM) return;
        emit(next.copyWith(
          phase: GooglePhonePhase.error,
          errorMessage: 'Vérification incomplète. Réessayez.',
        ));
        return;
      }

      final mid = state;
      if (mid is! LoginGooglePhoneRequiredM) return;
      emit(mid.copyWith(
        phase: GooglePhonePhase.completing,
        phoneVerificationToken: token,
      ));

      final response = await _api.completeGoogleSignIn(
        idToken: mid.googleIdToken,
        telephone: phone,
        phoneCountry: country,
        phoneVerificationToken: token,
        role: 'client',
      );
      _resendTimer?.cancel();
      await _emitGoogleSession(
        emit,
        response,
        rememberMe: mid.rememberMe,
      );
    } catch (e) {
      final next = state;
      if (next is! LoginGooglePhoneRequiredM) return;
      emit(next.copyWith(
        phase: GooglePhonePhase.error,
        clearPhoneVerificationToken: true,
        errorMessage: _userFacing(e),
      ));
    }
  }

  void _onGooglePhoneCancelled(
    GooglePhoneCancelledM event,
    Emitter<LoginPageStateM> emit,
  ) {
    _resendTimer?.cancel();
    emit(LoginPageInitialM());
  }

  void _onGooglePhoneChanged(
    GooglePhoneChangedM event,
    Emitter<LoginPageStateM> emit,
  ) {
    final cur = state;
    if (cur is! LoginGooglePhoneRequiredM) return;
    if (cur.phoneVerificationToken == null &&
        cur.phase == GooglePhonePhase.collectPhone) {
      return;
    }
    _resendTimer?.cancel();
    emit(LoginGooglePhoneRequiredM(
      googleIdToken: cur.googleIdToken,
      email: cur.email,
      rememberMe: cur.rememberMe,
      phase: GooglePhonePhase.collectPhone,
    ));
  }

  String _userFacing(Object error) {
    final msg = error.toString().replaceAll('Exception: ', '');
    if (msg.contains('Exception') ||
        msg.contains('Socket') ||
        msg.contains('ApiException') ||
        msg.contains('PlatformException')) {
      return 'Une erreur est survenue. Réessayez.';
    }
    return msg;
  }

  String _googleFacing(Object error) {
    final msg = error.toString();
    if (msg.contains('canceled') || msg.contains('annul')) {
      return 'Connexion Google annulée.';
    }
    if (msg.contains('ApiException: 10') ||
        msg.contains('DEVELOPER_ERROR') ||
        msg.contains('PlatformException')) {
      return 'Configuration Google invalide. Réessayez plus tard.';
    }
    return _userFacing(error);
  }
}
