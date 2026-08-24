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
import '../../common/widgets/phone_country_field.dart';

// ✅ Design System
import '../../../../design_system/design_system.dart';

/// Fournit toujours [LoginPageBlocM] (go_router ou MaterialPageRoute).
class LoginPageScreenM extends StatefulWidget {
  const LoginPageScreenM({super.key});

  @override
  State<LoginPageScreenM> createState() => _LoginPageScreenMState();
}

class _LoginPageScreenMState extends State<LoginPageScreenM>
    with SingleTickerProviderStateMixin {
  bool rememberMe = false;
  bool isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _logoScale;
  late final VoidCallback _fieldsListener;
  final TextEditingController identifiantController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController _googlePhoneController = TextEditingController();
  final TextEditingController _googleOtpController = TextEditingController();
  PhoneCountryOption _selectedPhoneCountry = kDefaultPhoneCountries.first;
  PhoneCountryOption _googlePhoneCountry = kDefaultPhoneCountries.first;

  bool get _isEmailIdentifiant =>
      identifiantController.text.trim().contains('@');

  bool get _canSubmit =>
      identifiantController.text.trim().isNotEmpty &&
      passwordController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _fieldsListener = () {
      if (mounted) setState(() {});
    };
    identifiantController.addListener(_fieldsListener);
    passwordController.addListener(_fieldsListener);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    identifiantController.removeListener(_fieldsListener);
    passwordController.removeListener(_fieldsListener);
    _animationController.dispose();
    identifiantController.dispose();
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
          title: '', // Empty title for minimal look
          useGradient: false,
          backgroundColor: SDColors.white,
          centerTitle: false,
          leading: SDCircleCloseButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: BlocListener<LoginPageBlocM, LoginPageStateM>(
          listener: (context, state) {
            if (state is LoginPageSuccessM) {
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
              return _buildLoginForm(context);
            },
          ),
        ),
      );
        },
      ),
    );
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
              state.email != null
                  ? 'Compte Google ${state.email}\nAjoutez un numéro pour continuer.'
                  : 'Ajoutez un numéro pour finaliser la connexion Google.',
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
                onCountryChanged: (c) {
                  setState(() => _googlePhoneCountry = c);
                  context.read<LoginPageBlocM>().add(GooglePhoneChangedM(
                        phone: _googlePhoneController.text.trim(),
                        phoneCountry: c.isoCode.name,
                      ));
                },
              ),
              SDSpacing.verticalTinyGap,
              Text(
                'Pays disponibles : CI, TN, SN, BF, ML, FR',
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral500,
                ),
              ),
              SDSpacing.verticalMediumGap,
              SDButton(
                text: 'ENVOYER LE CODE',
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
              SDSpacing.verticalMediumGap,
              TextField(
                controller: _googleOtpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Code à 6 chiffres',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SDSpacing.verticalMediumGap,
              SDButton(
                text: state.phase == GooglePhonePhase.completing
                    ? 'FINALISATION…'
                    : 'VÉRIFIER ET CONTINUER',
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
              onPressed: () {
                _googlePhoneController.clear();
                _googleOtpController.clear();
                context.read<LoginPageBlocM>().add(GooglePhoneCancelledM());
              },
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                SDSpacing.md,
                0,
                SDSpacing.md,
                SDSpacing.lg +
                    MediaQuery.viewPaddingOf(context).bottom +
                    MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SDSpacing.verticalMediumGap,
                  Center(
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        'assets/logo1.png',
                        height: 120,
                      ),
                    ),
                  ),
                  SDSpacing.verticalLargeGap,
                  Text(
                    "Bienvenue !",
                    textAlign: TextAlign.center,
                    style: SDTypography.displayMedium.copyWith(
                      color: SDColors.neutral900,
                    ),
                  ),
                  SDSpacing.verticalTinyGap,
                  Text(
                    "Connectez-vous pour continuer",
                    textAlign: TextAlign.center,
                    style: SDTypography.bodyLarge.copyWith(
                      color: SDColors.neutral600,
                    ),
                  ),
                  SDSpacing.verticalLargeGap,
                  
                  // STAB-07 : pays explicite pour téléphone ; email ignore le pays
                  PhoneCountryField(
                    controller: identifiantController,
                    selectedCountry: _selectedPhoneCountry,
                    onCountryChanged: (c) {
                      setState(() => _selectedPhoneCountry = c);
                    },
                    label: 'Téléphone ou Email',
                    hint: _isEmailIdentifiant
                        ? 'nom@exemple.com'
                        : 'Ex: 20113786 ou +216…',
                  ),
                  SDSpacing.verticalMediumGap,
                  SDInput(
                    label: "Mot de passe",
                    hint: "Entrez votre mot de passe",
                    controller: passwordController,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                  
                  SDSpacing.verticalSmallGap,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: rememberMe,
                            activeColor: SDColors.primary600,
                            onChanged: (value) {
                              setState(() {
                                rememberMe = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              "Se souvenir de moi",
                              style: SDTypography.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: SDSpacing.xs,
                              vertical: SDSpacing.xxxs,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Mot de passe oublié ?",
                            style: SDTypography.labelMedium.copyWith(
                              color: SDColors.primary700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SDSpacing.verticalMediumGap,
                  
                  BlocBuilder<LoginPageBlocM, LoginPageStateM>(
                    builder: (context, state) {
                      final loading = state is LoginPageLoadingM;
                      return SDButton(
                        text: "SE CONNECTER",
                        fullWidth: true,
                        isLoading: loading,
                        onPressed: loading || !_canSubmit
                            ? null
                            : () {
                                final id =
                                    identifiantController.text.trim();
                                context.read<LoginPageBlocM>().add(
                                      LoginSubmittedM(
                                        identifiant: id,
                                        password:
                                            passwordController.text.trim(),
                                        rememberMe: rememberMe,
                                        phoneCountry: id.contains('@')
                                            ? null
                                            : _selectedPhoneCountry
                                                .isoCode.name,
                                      ),
                                    );
                              },
                      );
                    },
                  ),
                  
                  SDSpacing.verticalLargeGap,
                  Row(
                    children: [
                      Expanded(child: Divider(color: SDColors.neutral300)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm),
                        child: Text(
                          "OU",
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: SDColors.neutral300)),
                    ],
                  ),
                  SDSpacing.verticalMediumGap,
                  SDGoogleSignInButton(
                    onPressed: () {
                      context
                          .read<LoginPageBlocM>()
                          .add(GoogleLoginSubmittedM());
                    },
                  ),
                  SDSpacing.verticalMediumGap,
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Vous n\'avez pas de compte ?',
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.neutral800,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.push("/register");
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: SDSpacing.xs, vertical: SDSpacing.xxxs),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'S\'inscrire',
                          style: SDTypography.labelLarge.copyWith(
                            color: SDColors.primary600,
                            decoration: TextDecoration.underline,
                            decorationColor: SDColors.primary600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SDSpacing.verticalMediumGap,
                  Text(
                    'En utilisant l’application, vous pouvez consulter nos documents légaux ci-dessous.',
                    textAlign: TextAlign.center,
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral500,
                    ),
                  ),
                  SDSpacing.verticalSmallGap,
                  const SDLegalFooterLinks(),
                  SDSpacing.verticalSmallGap,
                ],
              ),
            ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailField = TextEditingController(
      text: identifiantController.text.trim().contains('@')
          ? identifiantController.text.trim()
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
