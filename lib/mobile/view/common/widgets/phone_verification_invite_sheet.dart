import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import 'auth_form_widgets.dart';

/// Invitation facultative à vérifier le téléphone (mode deferred).
/// N’envoie aucun code à l’ouverture.
class PhoneVerificationInviteSheet extends StatelessWidget {
  const PhoneVerificationInviteSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PhoneVerificationInviteSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: SDColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                SDSpacing.md,
                20,
                SDSpacing.md,
                24 + bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const Center(
                    child: AuthMintIcon(
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vérifier votre téléphone',
                    textAlign: TextAlign.center,
                    style: SDTypography.displaySmall.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confirmez que ce numéro vous appartient à l’aide d’un code de vérification.',
                    textAlign: TextAlign.center,
                    style: SDTypography.bodyLarge.copyWith(
                      color: SDColors.neutral600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vous pouvez aussi le faire plus tard depuis votre profil.',
                    textAlign: TextAlign.center,
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SDButton(
                    text: 'Vérifier maintenant',
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: SDColors.primary700,
                      minimumSize: const Size(48, 48),
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    child: Text(
                      'Plus tard',
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
      ),
    );
  }
}
