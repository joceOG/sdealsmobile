import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

/// Liens juridiques / conformité (soulignés). Les pages peuvent être branchées plus tard.
class SDLegalFooterLinks extends StatelessWidget {
  const SDLegalFooterLinks({super.key});

  static void _placeholder(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title — contenu à venir.',
          style: SDTypography.bodyMedium.copyWith(color: SDColors.white),
        ),
        backgroundColor: SDColors.neutral700,
      ),
    );
  }

  static final List<String> _labels = [
    'Conditions générales d\'utilisation',
    'Politique de confidentialité',
    'Politique des cookies',
    'Mentions légales',
  ];

  @override
  Widget build(BuildContext context) {
    final baseStyle = SDTypography.bodySmall.copyWith(
      color: SDColors.primary700,
      decoration: TextDecoration.underline,
      decorationColor: SDColors.primary700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Conformité et documents légaux',
          textAlign: TextAlign.center,
          style: SDTypography.labelMedium.copyWith(
            color: SDColors.neutral600,
          ),
        ),
        SDSpacing.verticalTinyGap,
        ..._labels.map(
          (label) => Padding(
            padding: EdgeInsets.only(bottom: SDSpacing.xxs),
            child: Center(
              child: GestureDetector(
                onTap: () => _placeholder(context, label),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: baseStyle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
