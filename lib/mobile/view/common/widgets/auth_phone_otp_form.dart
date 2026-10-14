import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/utils/phone_otp_code.dart';
import '../../../../design_system/design_system.dart';
import 'auth_form_widgets.dart';

export '../../../../data/utils/phone_otp_code.dart';

/// Saisie du code reçu pour confirmer un numéro (parcours existant).
class AuthPhoneOtpForm extends StatelessWidget {
  const AuthPhoneOtpForm({
    super.key,
    required this.e164Phone,
    required this.codeController,
    required this.onVerify,
    this.errorText,
    this.isBusy = false,
    this.isVerifying = false,
    this.canResend = false,
    this.resendCooldownSeconds = 0,
    this.onResend,
    this.onChangeNumber,
    this.verifyLabel = 'Vérifier mon numéro',
    this.onCodeChanged,
  });

  final String e164Phone;
  final TextEditingController codeController;
  final VoidCallback onVerify;
  final String? errorText;
  final bool isBusy;
  final bool isVerifying;
  final bool canResend;
  final int resendCooldownSeconds;
  final VoidCallback? onResend;
  final VoidCallback? onChangeNumber;
  final String verifyLabel;
  final ValueChanged<String>? onCodeChanged;

  @override
  Widget build(BuildContext context) {
    final codeReady = isPhoneOtpCode(codeController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          'Saisissez le code reçu pour confirmer votre numéro de téléphone.',
          style: SDTypography.bodyLarge.copyWith(
            color: SDColors.neutral600,
          ),
        ),
        const SizedBox(height: SDSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SDSpacing.sm,
            vertical: SDSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: SDColors.primary50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SDColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_android_outlined,
                  color: SDColors.primary700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Numéro à vérifier',
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.primary700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      maskPhoneForDisplay(e164Phone),
                      style: SDTypography.titleSmall.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (onChangeNumber != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: isBusy ? null : onChangeNumber,
              style: TextButton.styleFrom(
                foregroundColor: SDColors.primary700,
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Text(
                'Modifier le numéro',
                style: SDTypography.labelLarge.copyWith(
                  color: SDColors.primary700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          const SizedBox(height: SDSpacing.sm),
        SDInput(
          label: 'Code de vérification',
          hint: 'Saisissez le code',
          labelAbove: true,
          controller: codeController,
          enabled: !isBusy,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          maxLength: kPhoneOtpCodeLength,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(kPhoneOtpCodeLength),
          ],
          errorText: errorText,
          onChanged: onCodeChanged,
          onSubmitted: isBusy || !codeReady ? null : (_) => onVerify(),
        ),
        const SizedBox(height: SDSpacing.sm),
        SDButton(
          text: verifyLabel,
          fullWidth: true,
          isLoading: isVerifying,
          onPressed: isBusy || !codeReady ? null : onVerify,
        ),
        const SizedBox(height: SDSpacing.md),
        Text(
          'Vous n’avez pas reçu de code ?',
          textAlign: TextAlign.center,
          style: SDTypography.bodyMedium.copyWith(
            color: SDColors.neutral600,
          ),
        ),
        TextButton(
          onPressed: canResend && !isBusy ? onResend : null,
          style: TextButton.styleFrom(
            foregroundColor: SDColors.primary700,
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Text(
            canResend
                ? 'Renvoyer le code'
                : (resendCooldownSeconds > 0
                    ? 'Nouveau code dans ${resendCooldownSeconds}s'
                    : 'Renvoyer le code'),
            style: SDTypography.labelLarge.copyWith(
              color: canResend && !isBusy
                  ? SDColors.primary700
                  : SDColors.neutral400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
