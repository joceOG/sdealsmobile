import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/services/google_auth_service.dart';
import '../../../../data/services/token_store.dart';
import '../registerpageblocm/registerPageBlocM.dart';
import '../registerpageblocm/registerPageEventM.dart';
import '../registerpageblocm/registerPageStateM.dart';

import '../../../../design_system/design_system.dart';
import '../../common/utils/app_snackbar.dart';
import '../../common/widgets/phone_country_field.dart';

class RegisterPageScreenM extends StatefulWidget {
  const RegisterPageScreenM({super.key});

  @override
  State<RegisterPageScreenM> createState() => _RegisterPageScreenMState();
}

class _RegisterPageScreenMState extends State<RegisterPageScreenM>
    with SingleTickerProviderStateMixin {
  bool agreeToTerms = false;
  late AnimationController _animationController;
  late Animation<double> _logoScale;

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _otpController;
  late final ValueNotifier<bool> _canSubmitNotifier;
  PhoneCountryOption _selectedPhoneCountry = kDefaultPhoneCountries.first;
  String? _lastCanonicalPhone;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
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

    _fullNameController.addListener(syncCanSubmit);
    _emailController.addListener(syncCanSubmit);
    _phoneController.addListener(() {
      syncCanSubmit();
      _notifyPhoneChanged();
    });
    _passwordController.addListener(syncCanSubmit);
    _confirmPasswordController.addListener(syncCanSubmit);

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
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _canSubmitNotifier.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _computeCanSubmit() {
    return agreeToTerms &&
        _fullNameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
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
            fullName: _fullNameController.text.trim(),
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
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              size: 24,
              color: SDColors.neutral900,
            ),
            onPressed: _handleBack,
            tooltip: 'Retour',
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SDSpacing.verticalSmallGap,
        Center(
          child: ScaleTransition(
            scale: _logoScale,
            child: Image.asset('assets/logo1.png', height: 100),
          ),
        ),
        SDSpacing.verticalLargeGap,
        Text(
          'Créer un compte',
          textAlign: TextAlign.center,
          style: SDTypography.displayMedium.copyWith(
            color: SDColors.neutral900,
          ),
        ),
        SDSpacing.verticalTinyGap,
        Text(
          'Rejoignez Soutrali Deals pour commencer',
          textAlign: TextAlign.center,
          style: SDTypography.bodyLarge.copyWith(
            color: SDColors.neutral600,
          ),
        ),
        SDSpacing.verticalLargeGap,
        SDInput(
          label: 'Nom complet',
          hint: 'Entrez votre nom complet',
          prefixIcon: Icons.person_outline,
          controller: _fullNameController,
        ),
        SDSpacing.verticalDefaultGap,
        SDInput(
          label: 'Email (optionnel)',
          hint: 'Ex: nom@exemple.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          controller: _emailController,
        ),
        SDSpacing.verticalDefaultGap,
        PhoneCountryField(
          controller: _phoneController,
          selectedCountry: _selectedPhoneCountry,
          onCountryChanged: (c) {
            setState(() {
              _selectedPhoneCountry = c;
              _canSubmitNotifier.value = _computeCanSubmit();
            });
            _notifyPhoneChanged();
          },
          hint: 'Ex: 20113786',
        ),
        SDSpacing.verticalTinyGap,
        Text(
          'Pays disponibles : CI, TN, SN, BF, ML, FR',
          style: SDTypography.bodySmall.copyWith(
            color: SDColors.neutral500,
          ),
        ),
        SDSpacing.verticalDefaultGap,
        SDInput(
          label: 'Mot de passe',
          hint: 'Créez un mot de passe',
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          controller: _passwordController,
        ),
        SDSpacing.verticalDefaultGap,
        SDInput(
          label: 'Confirmez le mot de passe',
          hint: 'Répétez le mot de passe',
          obscureText: true,
          prefixIcon: Icons.lock_reset,
          controller: _confirmPasswordController,
        ),
        SDSpacing.verticalSmallGap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Checkbox(
                value: agreeToTerms,
                activeColor: SDColors.primary600,
                onChanged: (value) {
                  setState(() {
                    agreeToTerms = value ?? false;
                  });
                  final v = _computeCanSubmit();
                  if (_canSubmitNotifier.value != v) {
                    _canSubmitNotifier.value = v;
                  }
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  "J'accepte les termes et conditions",
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.neutral800,
                  ),
                ),
              ),
            ),
          ],
        ),
        SDSpacing.verticalMediumGap,
        ValueListenableBuilder<bool>(
          valueListenable: _canSubmitNotifier,
          builder: (context, canSubmit, _) {
            return SDButton(
              text: 'CONTINUER',
              fullWidth: true,
              isLoading: state.isBusy,
              onPressed: state.isBusy || !canSubmit
                  ? null
                  : () => _submit(context),
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
                'OU',
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
          isLoading: state.isBusy,
          onPressed: state.isBusy ? null : () => _signInWithGoogle(context),
        ),
        SDSpacing.verticalMediumGap,
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
                  horizontal: SDSpacing.xs,
                  vertical: SDSpacing.xxxs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Connectez-vous',
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
          'En vous inscrivant, vous reconnaissez avoir pris connaissance de nos documents légaux.',
          textAlign: TextAlign.center,
          style: SDTypography.bodySmall.copyWith(
            color: SDColors.neutral500,
          ),
        ),
        SDSpacing.verticalSmallGap,
        const SDLegalFooterLinks(),
        SDSpacing.verticalSmallGap,
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SDSpacing.verticalMediumGap,
        SDButton(
          text: state.phase == RegisterPhase.registering
              ? 'CRÉATION DU COMPTE…'
              : 'VÉRIFIER ET CRÉER MON COMPTE',
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
}
