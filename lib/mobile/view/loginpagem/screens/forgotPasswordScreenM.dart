import 'package:flutter/material.dart';

import '../../../../data/services/api_client.dart';
import '../../../../design_system/design_system.dart';
import '../../common/utils/app_snackbar.dart';
import '../../common/widgets/auth_form_widgets.dart';

/// Récupération de compte : canal e-mail, lien de réinitialisation (API existante).
class ForgotPasswordScreenM extends StatefulWidget {
  const ForgotPasswordScreenM({
    super.key,
    this.initialEmail = '',
    this.apiClient,
  });

  final String initialEmail;

  @visibleForTesting
  final ApiClient? apiClient;

  @override
  State<ForgotPasswordScreenM> createState() => _ForgotPasswordScreenMState();
}

class _ForgotPasswordScreenMState extends State<ForgotPasswordScreenM> {
  late final TextEditingController _emailController;
  String? _fieldError;
  String? _submitError;
  bool _sending = false;
  bool _touched = false;

  ApiClient get _api => widget.apiClient ?? ApiClient();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _emailController.addListener(() {
      if (!mounted) return;
      setState(() {
        _submitError = null;
        if (_touched) _validateLocal();
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String raw) {
    final email = raw.trim();
    return email.contains('@') && email.contains('.') && email.length >= 6;
  }

  void _validateLocal() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _fieldError = 'Saisissez votre adresse e-mail.';
    } else if (!_isValidEmail(email)) {
      _fieldError = 'Adresse e-mail invalide.';
    } else {
      _fieldError = null;
    }
  }

  bool get _canSubmit => !_sending && _isValidEmail(_emailController.text);

  void _goBackToLogin() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
  }

  Future<void> _submit() async {
    setState(() {
      _touched = true;
      _submitError = null;
      _validateLocal();
    });
    if (_fieldError != null || !_isValidEmail(_emailController.text)) return;
    if (_sending) return;

    setState(() => _sending = true);
    try {
      await _api.forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      AppSnackBar.success(
        context,
        'Si cet email existe, un lien de réinitialisation a été envoyé.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = ApiException.userFacing(e);
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: SDColors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthCompactBrandBar(onBack: _goBackToLogin),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    SDSpacing.md,
                    SDSpacing.xs,
                    SDSpacing.md,
                    SDSpacing.md + mq.viewPadding.bottom + mq.viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: AuthMintIcon(icon: Icons.vpn_key_outlined),
                      ),
                      const SizedBox(height: SDSpacing.md),
                      Text(
                        'Mot de passe oublié ?',
                        style: SDTypography.displayMedium.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: SDSpacing.xxs),
                      Text(
                        'Retrouvez l’accès à votre compte.',
                        style: SDTypography.bodyLarge.copyWith(
                          color: SDColors.neutral600,
                        ),
                      ),
                      const SizedBox(height: SDSpacing.sm),
                      Text(
                        'Indiquez l’adresse e-mail utilisée pour vous connecter.',
                        style: SDTypography.bodyLarge.copyWith(
                          color: SDColors.neutral700,
                        ),
                      ),
                      const SizedBox(height: SDSpacing.md),
                      SDInput(
                        label: 'Adresse e-mail',
                        hint: 'vous@exemple.com',
                        labelAbove: true,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        prefixIcon: Icons.email_outlined,
                        errorText: _touched ? (_fieldError ?? _submitError) : _submitError,
                        enabled: !_sending,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: SDSpacing.md),
                      SDButton(
                        text: 'Envoyer le lien',
                        fullWidth: true,
                        isLoading: _sending,
                        onPressed: _canSubmit ? _submit : null,
                      ),
                      const SizedBox(height: SDSpacing.sm),
                      TextButton(
                        onPressed: _sending ? null : _goBackToLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: SDColors.primary700,
                          minimumSize: const Size(48, 48),
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        child: Text(
                          'Retour à la connexion',
                          style: SDTypography.labelLarge.copyWith(
                            color: SDColors.primary700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
