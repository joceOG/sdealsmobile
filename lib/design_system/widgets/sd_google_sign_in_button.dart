import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

/// Bouton style « Continuez avec Google » (fond blanc, bordure légère, logo G).
class SDGoogleSignInButton extends StatelessWidget {
  const SDGoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Continuez avec Google',
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  static const String _logoAsset = 'assets/logos/google_g.png';

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return Material(
      color: SDColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: SDColors.neutral300, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: effectiveOnPressed,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SDColors.neutral600,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Image.asset(
                        _logoAsset,
                        width: 22,
                        height: 22,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.g_mobiledata,
                          size: 28,
                          color: SDColors.neutral800,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: SDTypography.labelLarge.copyWith(
                            color: SDColors.neutral900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 22),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
