import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../data/models/phone_verification_config.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/services/protected_action_intent.dart';
import '../../../../data/services/google_auth_service.dart';
import '../../../../data/services/token_store.dart';
import '../registerpageblocm/registerPageBlocM.dart';
import '../registerpageblocm/registerPageEventM.dart';
import '../registerpageblocm/registerPageStateM.dart';

import '../../common/auth_completion.dart';
import '../../../../design_system/design_system.dart';
import '../../common/utils/app_snackbar.dart';
import '../../common/widgets/auth_form_widgets.dart';
import '../../common/widgets/auth_phone_otp_form.dart';
import '../../common/widgets/phone_country_field.dart';

class RegisterPageScreenM extends StatefulWidget {
  const RegisterPageScreenM({super.key});

  /// Évite l’appel réseau dans les tests widget.
  @visibleForTesting
  static PhoneVerificationConfig? debugPhoneConfig;

  @visibleForTesting
  static void debugReset() => debugPhoneConfig = null;

  @override
  State<RegisterPageScreenM> createState() => _RegisterPageScreenMState();
}

class _RegisterPageScreenMState extends State<RegisterPageScreenM> {
  bool _successPopAllowed = false;
  bool agreeToTerms = false;

  late final TextEditingController _prenomController;
  late final TextEditingController _nomController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _otpController;
  late final ValueNotifier<bool> _canSubmitNotifier;
  PhoneCountryOption _selectedPhoneCountry = kDefaultPhoneCountries.first;
  String? _lastCanonicalPhone;
  PhoneVerificationConfig? _phoneConfig;
  bool _showRequirements = false;

  @override
  void initState() {
    super.initState();
    final debugCfg = RegisterPageScreenM.debugPhoneConfig;
    if (debugCfg != null) {
      _phoneConfig = debugCfg;
    } else {
      ApiClient().fetchPhoneVerificationConfig().then((cfg) {
        if (mounted) setState(() => _phoneConfig = cfg);
      });
    }
    _prenomController = TextEditingController();
    _nomController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _otpController = TextEditingController();
    _canSubmitNotifier = ValueNotifier(false);

    void syncCanSubmit() {
      final v = _computeCanSubmit();
      if (_canSubmitNotifier.value != v) {
        _canSubmitNotifier.value = v;
      }
    }

    _prenomController.addListener(syncCanSubmit);
    _nomController.addListener(syncCanSubmit);
    _emailController.addListener(syncCanSubmit);
    _phoneController.addListener(() {
      syncCanSubmit();
      _notifyPhoneChanged();
    });
    _passwordController.addListener(syncCanSubmit);
    _confirmPasswordController.addListener(syncCanSubmit);
    _otpController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _notifyPhoneChanged() {
    if (!mounted) return;
    final bloc = context.read<RegisterPageBlocM>();
    final phone = _phoneController.text.trim();
    final country = _selectedPhoneCountry.isoCode.name;
    final key = '$country|$phone';
    if (_lastCanonicalPhone == key) return;
    _lastCanonicalPhone = key;
    if (bloc.state.pendingE164Phone != null ||
        bloc.state.phoneVerificationToken != null) {
      bloc.add(RegisterPhoneChanged(phone: phone, phoneCountry: country));
      _otpController.clear();
    }
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _canSubmitNotifier.dispose();
    super.dispose();
  }

  bool get _isDeferredSignup =>
      _phoneConfig != null &&
      _phoneConfig!.isDeferred &&
      !_phoneConfig!.signupRequiresOtp;

  bool _computeCanSubmit() {
    final deferredSignup = _isDeferredSignup;
    final emailOk =
        !deferredSignup || _emailController.text.trim().contains('@');
    final phoneOk = deferredSignup || _phoneController.text.trim().isNotEmpty;
    return agreeToTerms &&
        _nomController.text.trim().length >= 2 &&
        emailOk &&
        phoneOk &&
        _passwordController.text.length >= 6 &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
  }

  String? _requirementsHint() {
    if (!agreeToTerms) {
      return 'Acceptez les conditions pour créer votre compte.';
    }
    if (_nomController.text.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères.';
    }
    if (_isDeferredSignup && !_emailController.text.trim().contains('@')) {
      return 'Saisissez une adresse e-mail valide.';
    }
    if (!_isDeferredSignup && _phoneController.text.trim().isEmpty) {
      return 'Saisissez votre numéro de téléphone.';
    }
    if (_passwordController.text.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  void _handleBack() {
    if (!mounted) return;
    final bloc = context.read<RegisterPageBlocM>();
    if (bloc.state.showOtpStep && !bloc.state.isSuccess) {
      bloc.add(const RegisterOtpStepCancelled());
      _otpController.clear();
      return;
    }
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (keyboardOpen) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      _goLoginKeepingEntry(context);
    }
  }

  void _goLoginKeepingEntry(BuildContext context) {
    final extra =
        routeIsProtectedAuth(context) ? AuthEntryMode.protectedAction : null;
    context.go('/login', extra: extra);
  }

  void _returnAfterAuth(BuildContext context) {
    if (!ProtectedActionStore.instance.hasPending) {
      AuthCompletion.goAfterSuccess(context);
      return;
    }
    if (_successPopAllowed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) AuthCompletion.goAfterSuccess(context);
      });
      return;
    }
    setState(() => _successPopAllowed = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) AuthCompletion.goAfterSuccess(context);
    });
  }

  void _submit(BuildContext context) {
    context.read<RegisterPageBlocM>().add(
          RegisterSubmitted(
            prenom: _prenomController.text.trim(),
            nom: _nomController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            phoneCountry: _selectedPhoneCountry.isoCode.name,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          ),
        );
  }

  void _submitOtp(BuildContext context) {
    context.read<RegisterPageBlocM>().add(
          OtpCodeSubmitted(_otpController.text.trim()),
        );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final idToken = await GoogleAuthService.instance.signInForIdToken();
      if (idToken == null || !context.mounted) return;

      try {
        final response = await ApiClient().loginWithGoogle(idToken: idToken);
        final token = response['token']?.toString() ?? '';
        final refreshToken = response['refreshToken']?.toString();
        final utilisateurData =
            response['utilisateur'] as Map<String, dynamic>? ?? {};
        if (token.isEmpty) {
          throw Exception('Token manquant');
        }

        final utilisateur = Utilisateur.fromMap(utilisateurData);
        await TokenStore.saveTokens(
          accessToken: token,
          refreshToken: refreshToken,
        );

        if (!context.mounted) return;
        final role = utilisateur.role.toUpperCase();
        context.read<AuthCubit>().setAuthenticated(
              token: token,
              utilisateur: utilisateur,
              roles: [role],
              activeRole: role,
              refreshToken: refreshToken,
            );
        if (!context.mounted) return;
        _returnAfterAuth(context);
      } on GooglePhoneVerificationRequiredException {
        if (!context.mounted) return;
        await GoogleAuthService.instance.signOut();
        AppSnackBar.error(
          context,
          'Vérifiez votre téléphone via Connexion Google pour finaliser.',
        );
        _goLoginKeepingEntry(context);
      } on GoogleAccountLinkRequiredException catch (e) {
        if (!context.mounted) return;
        await GoogleAuthService.instance.signOut();
        AppSnackBar.error(context, e.toString());
        _goLoginKeepingEntry(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('ApiException') ||
          msg.contains('PlatformException') ||
          msg.contains('DEVELOPER_ERROR')) {
        AppSnackBar.error(
          context,
          'Configuration Google invalide. Réessayez plus tard.',
        );
      } else {
        AppSnackBar.error(context, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _successPopAllowed,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (!context.mounted) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: SDColors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthCompactBrandBar(onBack: _handleBack),
              Expanded(
                child: BlocConsumer<RegisterPageBlocM, RegisterPageStateM>(
                  listenWhen: (prev, curr) =>
                      prev.phase != curr.phase ||
                      prev.errorMessage != curr.errorMessage,
                  listener: (context, state) {
                    if (state.isSuccess) {
                      if (state.utilisateur != null && state.token != null) {
                        context.read<AuthCubit>().setAuthenticated(
                              token: state.token!,
                              utilisateur: state.utilisateur!,
                              roles: [state.utilisateur!.role],
                              activeRole: state.utilisateur!.role,
                            );

                        AppSnackBar.success(
                          context,
                          'Inscription réussie',
                          subtitle: 'Vous êtes maintenant connecté.',
                        );
                      } else {
                        AppSnackBar.success(context, 'Inscription réussie');
                      }
                      _returnAfterAuth(context);
                    }
                    if (state.errorMessage != null &&
                        state.phase == RegisterPhase.error &&
                        state.showOtpStep) {
                      AppSnackBar.error(context, state.errorMessage!);
                    }
                  },
                  builder: (context, state) {
                    final mq = MediaQuery.of(context);
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          SDSpacing.md,
                          SDSpacing.xs,
                          SDSpacing.md,
                          SDSpacing.md +
                              mq.viewPadding.bottom +
                              mq.viewInsets.bottom,
                        ),
                        child: state.showOtpStep
                            ? _buildOtpStep(context, state)
                            : _buildFormStep(context, state),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormStep(BuildContext context, RegisterPageStateM state) {
    final phoneOptional = _isDeferredSignup;
    final phoneLabel = phoneOptional ? 'Téléphone (facultatif)' : 'Téléphone';
    final phoneHelper =
        phoneOptional ? 'Vous pourrez le vérifier plus tard.' : null;
    final apiError = (!state.showOtpStep &&
            state.phase == RegisterPhase.error &&
            (state.errorMessage ?? '').trim().isNotEmpty)
        ? state.errorMessage!.trim()
        : '';

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Créer un compte',
            style: SDTypography.displayMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: SDSpacing.xxs),
          Text(
            'Vos échanges et vos demandes, au même endroit.',
            style: SDTypography.bodyLarge.copyWith(
              color: SDColors.neutral600,
            ),
          ),
          const SizedBox(height: SDSpacing.md),
          SDInput(
            label: 'Prénom',
            hint: 'Votre prénom',
            labelAbove: true,
            controller: _prenomController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
            keyboardType: TextInputType.name,
            errorText: _fieldError(state, const ['prenom']),
          ),
          const SizedBox(height: SDSpacing.sm),
          SDInput(
            label: 'Nom',
            hint: 'Votre nom',
            labelAbove: true,
            controller: _nomController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.familyName],
            keyboardType: TextInputType.name,
            errorText: _fieldError(state, const ['nom']),
          ),
          const SizedBox(height: SDSpacing.sm),
          SDInput(
            label: 'Adresse e-mail',
            hint: 'vous@exemple.com',
            labelAbove: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            controller: _emailController,
            errorText: _fieldError(state, const ['email']),
          ),
          const SizedBox(height: SDSpacing.sm),
          PhoneCountryField(
            controller: _phoneController,
            selectedCountry: _selectedPhoneCountry,
            label: phoneLabel,
            helperText: phoneHelper,
            hint: '07 00 00 00 00',
            errorText: _fieldError(state, const ['telephone', 'phone']),
            onCountryChanged: (c) {
              setState(() {
                _selectedPhoneCountry = c;
                _canSubmitNotifier.value = _computeCanSubmit();
              });
              _notifyPhoneChanged();
            },
          ),
          const SizedBox(height: SDSpacing.sm),
          SDInput(
            label: 'Mot de passe',
            hint: 'Votre mot de passe',
            helperText: '6 caractères minimum',
            labelAbove: true,
            obscureText: true,
            controller: _passwordController,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            errorText: _fieldError(state, const ['password']),
          ),
          const SizedBox(height: SDSpacing.sm),
          SDInput(
            label: 'Confirmer le mot de passe',
            hint: 'Saisissez à nouveau votre mot de passe',
            labelAbove: true,
            obscureText: true,
            controller: _confirmPasswordController,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            errorText: _fieldError(state, const ['confirmPassword']),
          ),
          const SizedBox(height: SDSpacing.sm),
          AuthTermsAcceptance(
            value: agreeToTerms,
            onChanged: (value) {
              setState(() => agreeToTerms = value);
              final v = _computeCanSubmit();
              if (_canSubmitNotifier.value != v) {
                _canSubmitNotifier.value = v;
              }
            },
          ),
          if (apiError.isNotEmpty) ...[
            const SizedBox(height: SDSpacing.sm),
            Text(
              apiError,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.error500,
              ),
            ),
          ],
          const SizedBox(height: SDSpacing.sm),
          ValueListenableBuilder<bool>(
            valueListenable: _canSubmitNotifier,
            builder: (context, canSubmit, _) {
              final hint = _showRequirements ? _requirementsHint() : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: state.isBusy || canSubmit
                        ? null
                        : () => setState(() => _showRequirements = true),
                    child: IgnorePointer(
                      ignoring: !canSubmit || state.isBusy,
                      child: SDButton(
                        text: state.phase == RegisterPhase.registering
                            ? 'Création du compte…'
                            : 'Créer mon compte',
                        fullWidth: true,
                        isLoading: state.isBusy,
                        onPressed: state.isBusy || !canSubmit
                            ? null
                            : () => _submit(context),
                      ),
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: SDSpacing.xs),
                    Text(
                      hint,
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral600,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: SDSpacing.sm),
          const AuthOrDivider(label: 'ou'),
          const SizedBox(height: SDSpacing.sm),
          SDGoogleSignInButton(
            isLoading: state.isBusy,
            onPressed: state.isBusy ? null : () => _signInWithGoogle(context),
          ),
          const SizedBox(height: SDSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Vous avez déjà un compte ?',
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral800,
                ),
              ),
              TextButton(
                onPressed:
                    state.isBusy ? null : () => _goLoginKeepingEntry(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: SDSpacing.xxs,
                    vertical: SDSpacing.xxxs,
                  ),
                  minimumSize: const Size(48, 44),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: Text(
                  'Se connecter',
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
    );
  }

  Widget _buildOtpStep(BuildContext context, RegisterPageStateM state) {
    final phone = state.pendingE164Phone ?? '';
    final cooldown = state.resendCooldownSeconds;
    final canResend = cooldown <= 0 && !state.isBusy;

    return AuthPhoneOtpForm(
      e164Phone: phone,
      codeController: _otpController,
      errorText: _fieldError(state, const ['code', 'otp']),
      isBusy: state.isBusy,
      isVerifying: state.phase == RegisterPhase.verifyingOtp ||
          state.phase == RegisterPhase.registering,
      canResend: canResend,
      resendCooldownSeconds: cooldown,
      verifyLabel: state.phase == RegisterPhase.registering
          ? 'Création du compte…'
          : 'Vérifier et créer mon compte',
      onCodeChanged: (_) => setState(() {}),
      onVerify: () => _submitOtp(context),
      onResend: () =>
          context.read<RegisterPageBlocM>().add(const OtpResendRequested()),
      onChangeNumber: () {
        context.read<RegisterPageBlocM>().add(const RegisterOtpStepCancelled());
        _otpController.clear();
      },
    );
  }

  String? _fieldError(RegisterPageStateM state, List<String> keys) {
    for (final k in keys) {
      final v = state.fieldErrors[k];
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }
}
