import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// ✅ import de ton AuthCubit
import '../../../../data/models/utilisateur.dart';
import '../../../../data/services/authCubit.dart';
import '../loginpageblocm/loginPageBlocM.dart';
import '../loginpageblocm/loginPageEventM.dart';
import '../loginpageblocm/loginPageStateM.dart';
import '../../common/auth_completion.dart';
import '../../common/utils/app_snackbar.dart';
import '../../common/widgets/auth_form_widgets.dart';
import '../../common/widgets/auth_phone_otp_form.dart';
import '../../common/widgets/phone_country_field.dart';
import '../../common/widgets/phone_verification_invite_sheet.dart';
import 'forgotPasswordScreenM.dart';

// ✅ Design System
import '../../../../design_system/design_system.dart';

/// Fournit toujours [LoginPageBlocM] (go_router ou MaterialPageRoute).
class LoginPageScreenM extends StatefulWidget {
  const LoginPageScreenM({super.key});

  @override
  State<LoginPageScreenM> createState() => _LoginPageScreenMState();
}

class _LoginPageScreenMState extends State<LoginPageScreenM> {
  AuthLoginMode _loginMode = AuthLoginMode.phone;
  late final VoidCallback _fieldsListener;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController _googlePhoneController = TextEditingController();
  final TextEditingController _googleOtpController = TextEditingController();
  PhoneCountryOption _selectedPhoneCountry = kDefaultPhoneCountries.first;
  PhoneCountryOption _googlePhoneCountry = kDefaultPhoneCountries.first;
  bool _phoneInviteHandled = false;
  bool _deferredPhonePrefillDone = false;

  bool get _canSubmit {
    if (_loginMode == AuthLoginMode.email) {
      return _emailController.text.trim().contains('@') &&
          passwordController.text.isNotEmpty;
    }
    return _phoneController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _fieldsListener = () {
      if (mounted) setState(() {});
    };
    _phoneController.addListener(_fieldsListener);
    _emailController.addListener(_fieldsListener);
    passwordController.addListener(_fieldsListener);
    _googleOtpController.addListener(_fieldsListener);
    _googlePhoneController.addListener(_fieldsListener);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_fieldsListener);
    _emailController.removeListener(_fieldsListener);
    passwordController.removeListener(_fieldsListener);
    _googleOtpController.removeListener(_fieldsListener);
    _googlePhoneController.removeListener(_fieldsListener);
    _phoneController.dispose();
    _emailController.dispose();
    passwordController.dispose();
    _googlePhoneController.dispose();
    _googleOtpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginPageBlocM(),
      // Builder = context *sous* le provider (sinon Google Sign-In plante).
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: SDColors.white,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthCompactBrandBar(
                    onBack: () => _handleAuthBack(context),
                  ),
                  Expanded(
                    child: BlocListener<LoginPageBlocM, LoginPageStateM>(
                      listenWhen: (previous, current) {
                        if (current is LoginPageSuccessM) return true;
                        if (current is LoginGooglePhoneRequiredM) {
                          if (previous is! LoginGooglePhoneRequiredM) {
                            return true;
                          }
                          return previous.phase != current.phase ||
                              previous.errorMessage != current.errorMessage ||
                              previous.infoMessage != current.infoMessage;
                        }
                        return false;
                      },
                      listener: (context, state) {
                        if (state is LoginPageSuccessM) {
                          if (state.phoneVerificationSuggested &&
                              !_phoneInviteHandled) {
                            _phoneInviteHandled = true;
                            _promptOptionalPhoneVerification(context, state);
                            return;
                          }
                          _finishLogin(context, state);
                        } else if (state is LoginGooglePhoneRequiredM) {
                          _prefillDeferredPhoneOnce(state);
                          if (state.infoMessage != null &&
                              state.infoMessage!.isNotEmpty) {
                            AppSnackBar.success(context, state.infoMessage!);
                          }
                          if (state.errorMessage != null &&
                              state.phase == GooglePhonePhase.error &&
                              state.fieldErrors.isEmpty) {
                            AppSnackBar.error(context, state.errorMessage!);
                          }
                        }
                      },
                      child: BlocBuilder<LoginPageBlocM, LoginPageStateM>(
                        builder: (context, state) {
                          if (state is LoginGooglePhoneRequiredM) {
                            return _buildGooglePhoneStep(context, state);
                          }
                          return _buildLoginForm(context, state);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _loginFinished = false;

  void _finishLogin(BuildContext context, LoginPageSuccessM state) {
    if (_loginFinished || !context.mounted) return;
    _loginFinished = true;
    final utilisateur = Utilisateur.fromMap(state.utilisateur);
    final userRole = utilisateur.role.toUpperCase();
    final roles = [userRole];
    final activeRole = userRole;

    context.read<AuthCubit>().setAuthenticated(
          token: state.token,
          utilisateur: utilisateur,
          roles: roles,
          activeRole: activeRole,
          refreshToken: state.refreshToken,
        );
    unawaited(context.read<AuthCubit>().refreshRoles());
    AuthCompletion.goAfterSuccess(context);
  }

  Future<void> _promptOptionalPhoneVerification(
    BuildContext context,
    LoginPageSuccessM state,
  ) async {
    final verify = await PhoneVerificationInviteSheet.show(context);
    if (!context.mounted) return;
    if (verify == true) {
      context.read<LoginPageBlocM>().add(
            StartDeferredPhoneVerifyM(
              token: state.token,
              refreshToken: state.refreshToken,
              utilisateur: state.utilisateur,
            ),
          );
    } else {
      _finishLogin(context, state);
    }
  }

  void _prefillDeferredPhoneOnce(LoginGooglePhoneRequiredM state) {
    if (_deferredPhonePrefillDone || !state.isDeferredOptional) return;
    _deferredPhonePrefillDone = true;
    final raw = state.pendingUtilisateur?['telephone']?.toString().trim() ?? '';
    if (raw.isNotEmpty && _googlePhoneController.text.trim().isEmpty) {
      _googlePhoneController.text = raw;
    }
  }

  bool _isOtpPhase(LoginGooglePhoneRequiredM state) {
    switch (state.phase) {
      case GooglePhonePhase.otpSent:
      case GooglePhonePhase.verifyingOtp:
      case GooglePhonePhase.completing:
        return true;
      case GooglePhonePhase.error:
        return state.e164Phone != null &&
            (state.resendCooldownSeconds > 0 ||
                state.fieldErrors.containsKey('code') ||
                state.fieldErrors.containsKey('otp'));
      case GooglePhonePhase.collectPhone:
      case GooglePhonePhase.sendingOtp:
        return false;
    }
  }

  void _handleAuthBack(BuildContext context) {
    final state = context.read<LoginPageBlocM>().state;
    if (state is LoginGooglePhoneRequiredM) {
      if (state.isBusy) return;
      if (_isOtpPhase(state)) {
        _googleOtpController.clear();
        context.read<LoginPageBlocM>().add(GooglePhoneChangedM(
              phone: _googlePhoneController.text.trim(),
              phoneCountry: _googlePhoneCountry.isoCode.name,
            ));
        return;
      }
      if (state.isDeferredOptional) {
        context.read<LoginPageBlocM>().add(GooglePhoneSkippedM());
        return;
      }
      _googlePhoneController.clear();
      _googleOtpController.clear();
      context.read<LoginPageBlocM>().add(GooglePhoneCancelledM());
      return;
    }
    Navigator.of(context).maybePop();
  }

  String? _loginFieldError(LoginPageStateM state, List<String> keys) {
    final map = state is LoginPageFailureM
        ? state.fieldErrors
        : state is LoginGooglePhoneRequiredM
            ? state.fieldErrors
            : const <String, String>{};
    for (final k in keys) {
      final v = map[k];
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  Widget _buildGooglePhoneStep(
    BuildContext context,
    LoginGooglePhoneRequiredM state,
  ) {
    final showOtp = _isOtpPhase(state);
    final cooldown = state.resendCooldownSeconds;
    final canResend = cooldown <= 0 && !state.isBusy;
    final phoneDraft = _googlePhoneController.text.trim();

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SDSpacing.md,
          SDSpacing.xs,
          SDSpacing.md,
          SDSpacing.md +
              MediaQuery.viewPaddingOf(context).bottom +
              MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!showOtp) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: AuthMintIcon(icon: Icons.phone_outlined),
              ),
              const SizedBox(height: SDSpacing.md),
              Text(
                'Vérifier mon numéro',
                style: SDTypography.displaySmall.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: SDSpacing.xxs),
              Text(
                state.isDeferredOptional
                    ? 'Indiquez le numéro à confirmer. Le code ne sera envoyé qu’après votre action.'
                    : (state.email != null
                        ? 'Compte Google ${state.email}. Ajoutez un numéro pour continuer.'
                        : 'Ajoutez un numéro pour finaliser la connexion Google.'),
                style: SDTypography.bodyLarge.copyWith(
                  color: SDColors.neutral600,
                ),
              ),
              const SizedBox(height: SDSpacing.md),
              PhoneCountryField(
                controller: _googlePhoneController,
                selectedCountry: _googlePhoneCountry,
                errorText:
                    _loginFieldError(state, const ['telephone', 'phone']),
                onCountryChanged: (c) {
                  setState(() => _googlePhoneCountry = c);
                  context.read<LoginPageBlocM>().add(GooglePhoneChangedM(
                        phone: _googlePhoneController.text.trim(),
                        phoneCountry: c.isoCode.name,
                      ));
                },
              ),
              const AuthFieldGap(),
              SDButton(
                text: 'Envoyer le code',
                fullWidth: true,
                isLoading: state.phase == GooglePhonePhase.sendingOtp,
                onPressed: state.isBusy || phoneDraft.isEmpty
                    ? null
                    : () {
                        context.read<LoginPageBlocM>().add(
                              GooglePhoneSubmittedM(
                                phone: phoneDraft,
                                phoneCountry: _googlePhoneCountry.isoCode.name,
                              ),
                            );
                      },
              ),
              if (state.isDeferredOptional)
                TextButton(
                  onPressed: state.isBusy
                      ? null
                      : () {
                          _googlePhoneController.clear();
                          _googleOtpController.clear();
                          context
                              .read<LoginPageBlocM>()
                              .add(GooglePhoneSkippedM());
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: SDColors.primary700,
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(
                    'Plus tard',
                    style: SDTypography.labelLarge.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: state.isBusy
                      ? null
                      : () {
                          _googlePhoneController.clear();
                          _googleOtpController.clear();
                          context
                              .read<LoginPageBlocM>()
                              .add(GooglePhoneCancelledM());
                        },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(
                    'Annuler',
                    style: SDTypography.labelLarge.copyWith(
                      color: SDColors.neutral600,
                    ),
                  ),
                ),
            ] else
              AuthPhoneOtpForm(
                e164Phone: state.e164Phone ?? '',
                codeController: _googleOtpController,
                errorText: _loginFieldError(state, const ['code', 'otp']),
                isBusy: state.isBusy,
                isVerifying: state.phase == GooglePhonePhase.verifyingOtp ||
                    state.phase == GooglePhonePhase.completing,
                canResend: canResend,
                resendCooldownSeconds: cooldown,
                verifyLabel: state.phase == GooglePhonePhase.completing
                    ? 'Finalisation…'
                    : 'Vérifier mon numéro',
                onCodeChanged: (_) => setState(() {}),
                onVerify: () {
                  context.read<LoginPageBlocM>().add(
                        GoogleOtpSubmittedM(_googleOtpController.text.trim()),
                      );
                },
                onResend: () => context
                    .read<LoginPageBlocM>()
                    .add(GoogleOtpResendRequestedM()),
                onChangeNumber: () {
                  _googleOtpController.clear();
                  context.read<LoginPageBlocM>().add(GooglePhoneChangedM(
                        phone: _googlePhoneController.text.trim(),
                        phoneCountry: _googlePhoneCountry.isoCode.name,
                      ));
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, LoginPageStateM state) {
    final loading = state is LoginPageLoadingM;
    final apiError = state is LoginPageFailureM ? state.error.trim() : '';

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SDSpacing.md,
          SDSpacing.xs,
          SDSpacing.md,
          SDSpacing.md +
              MediaQuery.viewPaddingOf(context).bottom +
              MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connexion',
              style: SDTypography.displayMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: SDSpacing.xxs),
            Text(
              'Retrouvez votre compte Soutrali Deals.',
              style: SDTypography.bodyLarge.copyWith(
                color: SDColors.neutral600,
              ),
            ),
            const SizedBox(height: SDSpacing.md),
            AuthLoginModeToggle(
              mode: _loginMode,
              onChanged: (mode) => setState(() => _loginMode = mode),
            ),
            const SizedBox(height: SDSpacing.sm),
            if (_loginMode == AuthLoginMode.phone)
              PhoneCountryField(
                controller: _phoneController,
                selectedCountry: _selectedPhoneCountry,
                onCountryChanged: (c) {
                  setState(() => _selectedPhoneCountry = c);
                },
                label: 'Numéro de téléphone',
                hint: '07 00 00 00 00',
                errorText: _loginFieldError(
                  state,
                  const ['telephone', 'phone', 'identifiant'],
                ),
              )
            else
              SDInput(
                label: 'Adresse e-mail',
                hint: 'nom@exemple.com',
                labelAbove: true,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
                errorText:
                    _loginFieldError(state, const ['email', 'identifiant']),
              ),
            const SizedBox(height: SDSpacing.sm),
            SDInput(
              label: 'Mot de passe',
              hint: 'Votre mot de passe',
              labelAbove: true,
              controller: passwordController,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              errorText: _loginFieldError(state, const ['password']),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : _openForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(48, 44),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: Text(
                  'Mot de passe oublié ?',
                  style: SDTypography.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: SDColors.primary700,
                  ),
                ),
              ),
            ),
            if (apiError.isNotEmpty) ...[
              const SizedBox(height: SDSpacing.xs),
              Text(
                apiError,
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.error500,
                ),
              ),
              const SizedBox(height: SDSpacing.sm),
            ] else
              const SizedBox(height: SDSpacing.xs),
            SDButton(
              text: 'Se connecter',
              fullWidth: true,
              isLoading: loading,
              onPressed:
                  loading || !_canSubmit ? null : () => _submitLogin(context),
            ),
            const SizedBox(height: SDSpacing.sm),
            const AuthOrDivider(label: 'ou'),
            const SizedBox(height: SDSpacing.sm),
            SDGoogleSignInButton(
              isLoading: loading,
              onPressed: loading
                  ? null
                  : () => context
                      .read<LoginPageBlocM>()
                      .add(GoogleLoginSubmittedM()),
            ),
            const SizedBox(height: SDSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Pas encore de compte ?',
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.neutral800,
                  ),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final protected = routeIsProtectedAuth(context);
                          final ok = await context.push<bool>(
                            '/register',
                            extra: protected
                                ? AuthEntryMode.protectedAction
                                : null,
                          );
                          if (ok == true && protected && context.mounted) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) {
                                Navigator.of(context).pop(true);
                              }
                            });
                          }
                        },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: SDSpacing.xxs,
                      vertical: SDSpacing.xxxs,
                    ),
                    minimumSize: const Size(48, 44),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: Text(
                    'Créer un compte',
                    style: SDTypography.labelLarge.copyWith(
                      color: SDColors.primary600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: SDSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _submitLogin(BuildContext context) {
    final id = _loginMode == AuthLoginMode.email
        ? _emailController.text.trim()
        : _phoneController.text.trim();
    context.read<LoginPageBlocM>().add(
          LoginSubmittedM(
            identifiant: id,
            password: passwordController.text,
            rememberMe: true,
            phoneCountry: _loginMode == AuthLoginMode.email
                ? null
                : _selectedPhoneCountry.isoCode.name,
          ),
        );
  }

  void _openForgotPassword() {
    final initial = _loginMode == AuthLoginMode.email
        ? _emailController.text.trim()
        : '';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordScreenM(initialEmail: initial),
      ),
    );
  }
}
