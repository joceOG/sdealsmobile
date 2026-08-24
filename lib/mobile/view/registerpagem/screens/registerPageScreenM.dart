import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../data/models/phone_verification_config.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/services/google_auth_service.dart';
import '../../../../data/services/token_store.dart';
import '../registerpageblocm/registerPageBlocM.dart';
import '../registerpageblocm/registerPageEventM.dart';
import '../registerpageblocm/registerPageStateM.dart';

import '../../../../design_system/design_system.dart';
import '../../common/utils/app_snackbar.dart';
import '../../common/widgets/auth_form_widgets.dart';
import '../../common/widgets/phone_country_field.dart';

class RegisterPageScreenM extends StatefulWidget {
  const RegisterPageScreenM({super.key});

  @override
  State<RegisterPageScreenM> createState() => _RegisterPageScreenMState();
}

class _RegisterPageScreenMState extends State<RegisterPageScreenM> {
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

  @override
  void initState() {
    super.initState();
    ApiClient().fetchPhoneVerificationConfig().then((cfg) {
      if (mounted) setState(() => _phoneConfig = cfg);
    });
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
    final phoneOk =
        deferredSignup || _phoneController.text.trim().isNotEmpty;
    return agreeToTerms &&
        _nomController.text.trim().length >= 2 &&
        emailOk &&
        phoneOk &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
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
      context.go('/login');
    }
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
        context.push('/homepage');
      } on GooglePhoneVerificationRequiredException {
        if (!context.mounted) return;
        await GoogleAuthService.instance.signOut();
        AppSnackBar.error(
          context,
          'Vérifiez votre téléphone via Connexion Google pour finaliser.',
        );
        context.go('/login');
      } on GoogleAccountLinkRequiredException catch (e) {
        if (!context.mounted) return;
        await GoogleAuthService.instance.signOut();
        AppSnackBar.error(context, e.toString());
        context.go('/login');
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
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (!context.mounted) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: SDColors.white,
        appBar: SDAppBar(
          title: '',
          useGradient: false,
          backgroundColor: SDColors.white,
          centerTitle: false,
          leading: AuthBackButton(onPressed: _handleBack),
        ),
        body: BlocConsumer<RegisterPageBlocM, RegisterPageStateM>(
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.push('/homepage');
              });
            }
            if (state.errorMessage != null &&
                state.phase == RegisterPhase.error) {
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
                  0,
                  SDSpacing.md,
                  SDSpacing.lg +
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
    );
  }

  Widget _buildFormStep(BuildContext context, RegisterPageStateM state) {
    final phoneLabel = _isDeferredSignup
        ? 'Numéro de téléphone (facultatif)'
        : 'Numéro de téléphone';
    final phoneHelper = _isDeferredSignup
        ? 'Vous pourrez le vérifier plus tard.'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthCompactHeader(
          title: 'Créer un compte',
          subtitle: 'Rejoignez Soutrali Deals',
          logoHeight: 88,
        ),
        const AuthFieldGap(large: true),
        SDInput(
          label: 'Prénom',
          hint: 'Ex. Aïcha',
          prefixIcon: Icons.person_outline,
          controller: _prenomController,
          errorText: _fieldError(state, const ['prenom']),
        ),
        const AuthFieldGap(),
        SDInput(
          label: 'Nom',
          hint: 'Ex. Koné',
          prefixIcon: Icons.badge_outlined,
          controller: _nomController,
          errorText: _fieldError(state, const ['nom']),
        ),
        const AuthFieldGap(),
        SDInput(
          label: 'Email',
          hint: 'nom@exemple.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          controller: _emailController,
          errorText: _fieldError(state, const ['email']),
        ),
        const AuthFieldGap(),
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
        const AuthFieldGap(),
        SDInput(
          label: 'Mot de passe',
          hint: 'Créez un mot de passe',
          helperText: '6 caractères minimum',
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          controller: _passwordController,
          errorText: _fieldError(state, const ['password']),
        ),
        const AuthFieldGap(),
        SDInput(
          label: 'Confirmer le mot de passe',
          hint: 'Répétez le mot de passe',
          obscureText: true,
          prefixIcon: Icons.lock_reset,
          controller: _confirmPasswordController,
          errorText: _fieldError(state, const ['confirmPassword', 'password']),
        ),
        const AuthFieldGap(large: true),
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
        const AuthFieldGap(large: true),
        ValueListenableBuilder<bool>(
          valueListenable: _canSubmitNotifier,
          builder: (context, canSubmit, _) {
            return SDButton(
              text: 'Créer mon compte',
              fullWidth: true,
              isLoading: state.isBusy,
              onPressed: state.isBusy || !canSubmit
                  ? null
                  : () => _submit(context),
            );
          },
        ),
        const AuthFieldGap(large: true),
        const AuthOrDivider(label: 'ou'),
        const AuthFieldGap(),
        SDGoogleSignInButton(
          isLoading: state.isBusy,
          onPressed: state.isBusy ? null : () => _signInWithGoogle(context),
        ),
        const AuthFieldGap(),
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
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: SDSpacing.xxs,
                  vertical: SDSpacing.xxxs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Connectez-vous',
                style: SDTypography.labelLarge.copyWith(
                  color: SDColors.primary600,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: SDColors.primary600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: SDSpacing.sm),
      ],
    );
  }

  Widget _buildOtpStep(BuildContext context, RegisterPageStateM state) {
    final phone = state.pendingE164Phone ?? '';
    final cooldown = state.resendCooldownSeconds;
    final canResend = cooldown <= 0 && !state.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SDSpacing.verticalLargeGap,
        Text(
          'Vérifiez votre téléphone',
          textAlign: TextAlign.center,
          style: SDTypography.displayMedium.copyWith(
            color: SDColors.neutral900,
          ),
        ),
        SDSpacing.verticalTinyGap,
        Text(
          phone.isEmpty
              ? 'Entrez le code reçu par SMS'
              : 'Code envoyé au $phone',
          textAlign: TextAlign.center,
          style: SDTypography.bodyLarge.copyWith(
            color: SDColors.neutral600,
          ),
        ),
        SDSpacing.verticalLargeGap,
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: SDTypography.bodyLarge.copyWith(color: SDColors.neutral900),
          decoration: InputDecoration(
            labelText: 'Code à 6 chiffres',
            hintText: '••••••',
            counterText: '',
            prefixIcon: const Icon(Icons.sms_outlined),
            errorText: _fieldError(state, const ['code', 'otp']),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SDSpacing.verticalMediumGap,
        SDButton(
          text: state.phase == RegisterPhase.registering
              ? 'Création du compte…'
              : 'Vérifier et créer mon compte',
          fullWidth: true,
          isLoading: state.phase == RegisterPhase.verifyingOtp ||
              state.phase == RegisterPhase.registering ||
              state.phase == RegisterPhase.sendingOtp,
          onPressed: state.isBusy ? null : () => _submitOtp(context),
        ),
        SDSpacing.verticalMediumGap,
        TextButton(
          onPressed: canResend
              ? () => context
                  .read<RegisterPageBlocM>()
                  .add(const OtpResendRequested())
              : null,
          child: Text(
            canResend
                ? 'Renvoyer le code'
                : 'Vous pourrez demander un nouveau code dans ${cooldown}s',
            style: SDTypography.labelLarge.copyWith(
              color: canResend ? SDColors.primary600 : SDColors.neutral500,
            ),
          ),
        ),
        SDSpacing.verticalSmallGap,
        TextButton(
          onPressed: state.isBusy
              ? null
              : () {
                  context
                      .read<RegisterPageBlocM>()
                      .add(const RegisterOtpStepCancelled());
                  _otpController.clear();
                },
          child: Text(
            'Modifier le numéro',
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
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
