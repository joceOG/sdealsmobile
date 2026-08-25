import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// ✅ import de ton AuthCubit
import '../../../../data/models/utilisateur.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/services/api_client.dart';
import '../loginpageblocm/loginPageBlocM.dart';
import '../loginpageblocm/loginPageEventM.dart';
import '../loginpageblocm/loginPageStateM.dart';
import '../../common/utils/app_snackbar.dart';
import '../../common/widgets/auth_form_widgets.dart';
import '../../common/widgets/phone_country_field.dart';

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

  bool get _canSubmit {
    if (_loginMode == AuthLoginMode.email) {
      return _emailController.text.trim().contains('@') &&
          passwordController.text.trim().isNotEmpty;
    }
    return _phoneController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty;
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
  }

  @override
  void dispose() {
    _phoneController.removeListener(_fieldsListener);
    _emailController.removeListener(_fieldsListener);
    passwordController.removeListener(_fieldsListener);
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
        appBar: SDAppBar(
          title: '',
          useGradient: false,
          backgroundColor: SDColors.white,
          centerTitle: false,
          showBackButton: false,
          leading: AuthBackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: BlocListener<LoginPageBlocM, LoginPageStateM>(
          listener: (context, state) {
            if (state is LoginPageSuccessM) {
              if (state.phoneVerificationSuggested) {
                _promptOptionalPhoneVerification(context, state);
                return;
              }
              _finishLogin(context, state);
            } else if (state is LoginPageFailureM) {
              AppSnackBar.error(context, state.error);
            } else if (state is LoginGooglePhoneRequiredM &&
                state.errorMessage != null &&
                state.phase == GooglePhonePhase.error) {
              AppSnackBar.error(context, state.errorMessage!);
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
      );
        },
      ),
    );
  }

  void _finishLogin(BuildContext context, LoginPageSuccessM state) {
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

    final router = GoRouter.of(context);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    router.go('/homepage');
  }

  Future<void> _promptOptionalPhoneVerification(
    BuildContext context,
    LoginPageSuccessM state,
  ) async {
    final verify = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PhoneVerificationSheet(ctx),
    );
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
    final showOtp = state.phase == GooglePhonePhase.otpSent ||
        state.phase == GooglePhonePhase.verifyingOtp ||
        state.phase == GooglePhonePhase.completing ||
        (state.phase == GooglePhonePhase.error && state.e164Phone != null);
    final cooldown = state.resendCooldownSeconds;
    final canResend = cooldown <= 0 && !state.isBusy;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SDSpacing.md,
          SDSpacing.lg,
          SDSpacing.md,
          SDSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Vérifiez votre téléphone',
              textAlign: TextAlign.center,
              style: SDTypography.displayMedium.copyWith(
                color: SDColors.neutral900,
              ),
            ),
            SDSpacing.verticalTinyGap,
            Text(
              state.isDeferredOptional
                  ? 'Renforcez la sécurité de votre compte en vérifiant votre numéro.'
                  : (state.email != null
                      ? 'Compte Google ${state.email}\nAjoutez un numéro pour continuer.'
                      : 'Ajoutez un numéro pour finaliser la connexion Google.'),
              textAlign: TextAlign.center,
              style: SDTypography.bodyLarge.copyWith(
                color: SDColors.neutral600,
              ),
            ),
            SDSpacing.verticalLargeGap,
            if (!showOtp) ...[
              PhoneCountryField(
                controller: _googlePhoneController,
                selectedCountry: _googlePhoneCountry,
                errorText: _loginFieldError(state, const ['telephone', 'phone']),
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
                onPressed: state.isBusy
                    ? null
                    : () {
                        context.read<LoginPageBlocM>().add(
                              GooglePhoneSubmittedM(
                                phone: _googlePhoneController.text.trim(),
                                phoneCountry: _googlePhoneCountry.isoCode.name,
                              ),
                            );
                      },
              ),
            ] else ...[
              Text(
                'Code envoyé au ${state.e164Phone}',
                textAlign: TextAlign.center,
                style: SDTypography.bodyMedium,
              ),
              const AuthFieldGap(),
              TextField(
                controller: _googleOtpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Code à 6 chiffres',
                  counterText: '',
                  errorText: _loginFieldError(state, const ['code', 'otp']),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const AuthFieldGap(),
              SDButton(
                text: state.phase == GooglePhonePhase.completing
                    ? 'Finalisation…'
                    : 'Vérifier et continuer',
                fullWidth: true,
                isLoading: state.phase == GooglePhonePhase.verifyingOtp ||
                    state.phase == GooglePhonePhase.completing,
                onPressed: state.isBusy
                    ? null
                    : () {
                        context.read<LoginPageBlocM>().add(
                              GoogleOtpSubmittedM(
                                _googleOtpController.text.trim(),
                              ),
                            );
                      },
              ),
              TextButton(
                onPressed: canResend
                    ? () => context
                        .read<LoginPageBlocM>()
                        .add(GoogleOtpResendRequestedM())
                    : null,
                child: Text(
                  canResend
                      ? 'Renvoyer le code'
                      : 'Nouveau code dans ${cooldown}s',
                ),
              ),
              TextButton(
                onPressed: state.isBusy
                    ? null
                    : () {
                        _googleOtpController.clear();
                        context
                            .read<LoginPageBlocM>()
                            .add(GooglePhoneChangedM(
                              phone: _googlePhoneController.text.trim(),
                              phoneCountry: _googlePhoneCountry.isoCode.name,
                            ));
                      },
                child: const Text('Modifier le numéro'),
              ),
            ],
            TextButton(
              onPressed: state.isBusy
                  ? null
                  : () {
                      _googlePhoneController.clear();
                      _googleOtpController.clear();
                      if (state.isDeferredOptional) {
                        context
                            .read<LoginPageBlocM>()
                            .add(GooglePhoneSkippedM());
                      } else {
                        context
                            .read<LoginPageBlocM>()
                            .add(GooglePhoneCancelledM());
                      }
                    },
              child: Text(state.isDeferredOptional ? 'Plus tard' : 'Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, LoginPageStateM state) {
    final loading = state is LoginPageLoadingM;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SDSpacing.md,
          SDSpacing.xxs,
          SDSpacing.md,
          SDSpacing.md +
              MediaQuery.viewPaddingOf(context).bottom +
              MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthCompactHeader(
              title: 'Bienvenue !',
              subtitle: 'Connectez-vous pour continuer',
              logoHeight: 96,
            ),
            const AuthFieldGap(large: true),
            SDGoogleSignInButton(
              isLoading: loading,
              onPressed: loading
                  ? null
                  : () => context
                      .read<LoginPageBlocM>()
                      .add(GoogleLoginSubmittedM()),
            ),
            const AuthFieldGap(large: true),
            const AuthOrDivider(),
            const AuthFieldGap(large: true),
            AuthLoginModeToggle(
              mode: _loginMode,
              onChanged: (mode) => setState(() => _loginMode = mode),
            ),
            const AuthFieldGap(),
            if (_loginMode == AuthLoginMode.phone)
              PhoneCountryField(
                controller: _phoneController,
                selectedCountry: _selectedPhoneCountry,
                onCountryChanged: (c) {
                  setState(() => _selectedPhoneCountry = c);
                },
                label: 'Téléphone',
                hint: '07 00 00 00 00',
                errorText: _loginFieldError(
                  state,
                  const ['telephone', 'phone', 'identifiant'],
                ),
              )
            else
              SDInput(
                label: 'Email',
                hint: 'nom@exemple.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
                errorText: _loginFieldError(state, const ['email', 'identifiant']),
              ),
            const AuthFieldGap(),
            SDInput(
              label: 'Mot de passe',
              hint: 'Entrez votre mot de passe',
              helperText: '6 caractères minimum',
              controller: passwordController,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              errorText: _loginFieldError(state, const ['password']),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            const AuthFieldGap(large: true),
            SDButton(
              text: 'Se connecter',
              fullWidth: true,
              isLoading: loading,
              onPressed: loading || !_canSubmit ? null : () => _submitLogin(context),
            ),
            const AuthFieldGap(large: true),
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
                  onPressed: () => context.push('/register'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: SDSpacing.xxs,
                      vertical: SDSpacing.xxxs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Créer un compte',
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
            password: passwordController.text.trim(),
            rememberMe: true,
            phoneCountry: _loginMode == AuthLoginMode.email
                ? null
                : _selectedPhoneCountry.isoCode.name,
          ),
        );
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailField = TextEditingController(
      text: _loginMode == AuthLoginMode.email
          ? _emailController.text.trim()
          : '',
    );
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: TextField(
          controller: emailField,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'votre@email.com',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (submitted != true || !mounted) return;
    final email = emailField.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppSnackBar.error(context, 'Veuillez saisir un email valide.');
      return;
    }
    try {
      await ApiClient().forgotPassword(email: email);
      if (!mounted) return;
      AppSnackBar.success(
        context,
        'Si cet email existe, un lien de réinitialisation a été envoyé.',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Impossible d\'envoyer la demande : $e');
    }
  }
}

// ─── Bottom sheet vérification téléphone ──────────────────────────────────────

class _PhoneVerificationSheet extends StatelessWidget {
  const _PhoneVerificationSheet(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poignée
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SDColors.neutral200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Icône
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: SDColors.primary50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.phone_android_rounded,
                color: SDColors.primary600,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Titre
          Text(
            'Vérifier votre numéro',
            textAlign: TextAlign.center,
            style: SDTypography.titleLarge.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // Corps
          Text(
            'Ajoutez une couche de sécurité et facilitez vos échanges avec les prestataires. Vous pourrez aussi le faire plus tard depuis votre profil.',
            textAlign: TextAlign.center,
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          // CTA primaire
          SDButton(
            text: 'Vérifier maintenant',
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 12),
          // Action secondaire sobre
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: SDColors.neutral600,
            ),
            child: Text(
              'Plus tard',
              style: SDTypography.labelLarge.copyWith(
                color: SDColors.neutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
