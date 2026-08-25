import 'package:flutter/material.dart';
import '../colors.dart';
import '../responsive.dart';
import '../spacing.dart';
import '../typography.dart';
import 'sd_button.dart';

/// STAB-13 — État vide harmonisé (listes, boutiques, freelance…).
class SDEmptyState extends StatelessWidget {
  const SDEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SDSpacing.lg,
        vertical: SDSpacing.md,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: SDColors.neutral300),
          SDSpacing.verticalSmallGap,
          Text(
            title,
            textAlign: TextAlign.center,
            style: SDTypography.titleSmall.copyWith(color: SDColors.neutral900),
          ),
          SDSpacing.verticalTinyGap,
          Text(
            message,
            textAlign: TextAlign.center,
            style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
          ),
          if (action != null) ...[
            SDSpacing.verticalMediumGap,
            action!,
          ],
        ],
      ),
    );
  }
}

/// STAB-13 — Erreur inline avec action Réessayer.
class SDErrorState extends StatelessWidget {
  const SDErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Réessayer',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SDSpacing.md,
        vertical: SDSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: SDColors.error500, size: 20),
              SDSpacing.horizontalTinyGap,
              Expanded(
                child: Text(
                  message,
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.error600,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            SDSpacing.verticalSmallGap,
            SDButton(
              text: retryLabel,
              type: SDButtonType.outlined,
              size: SDButtonSize.small,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// STAB-13 — Mur d'authentification invité (Messages, Profil, Publier…).
class GuestAuthState extends StatelessWidget {
  const GuestAuthState({
    super.key,
    this.pageTitle,
    required this.title,
    required this.description,
    this.icon,
    this.illustrationAsset,
    this.illustrationHeight = 160,
    this.onPrimary,
    this.onSecondary,
    this.primaryLabel = 'Se connecter',
    this.secondaryLabel = 'Créer un compte',
    this.centerVertically = true,
  }) : assert(
          icon != null || illustrationAsset != null,
          'Fournir icon ou illustrationAsset',
        );

  static const double horizontalPadding = 24;

  final String? pageTitle;
  final String title;
  final String description;
  final IconData? icon;
  final String? illustrationAsset;
  final double illustrationHeight;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final String primaryLabel;
  final String secondaryLabel;
  final bool centerVertically;

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);

    if (pageTitle == null) {
      return body;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 8),
          child: Text(
            pageTitle!,
            style: SDTypography.displayMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (centerVertically)
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: SDSpacing.lg),
                child: body,
              ),
            ),
          )
        else
          body,
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVisual(context),
          const SizedBox(height: SDSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: SDTypography.titleLarge.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
              fontSize: 21,
              height: 1.3,
            ),
          ),
          const SizedBox(height: SDSpacing.xs),
          Text(
            description,
            textAlign: TextAlign.center,
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: SDSpacing.md),
          SDButton(
            text: primaryLabel,
            fullWidth: true,
            onPressed: onPrimary,
          ),
          const SizedBox(height: SDSpacing.sm),
          SDButton(
            text: secondaryLabel,
            type: SDButtonType.outlined,
            fullWidth: true,
            onPressed: onSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildVisual(BuildContext context) {
    // Illustration / icône adaptive : plafonnée à 25 % du viewport.
    final effectiveIllustrationH =
        SDResponsive.illustrationHeight(context, preferred: illustrationHeight);
    // Cercle icône : max 22 % du viewport (reste lisible à 320×568).
    final circleSize =
        (MediaQuery.sizeOf(context).height * 0.22).clamp(80.0, 112.0);

    if (illustrationAsset != null) {
      return SizedBox(
        height: effectiveIllustrationH,
        width: double.infinity,
        child: Image.asset(
          illustrationAsset!,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => _buildIconVisual(circleSize),
        ),
      );
    }
    return _buildIconVisual(circleSize);
  }

  Widget _buildIconVisual(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: SDColors.primary50,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? Icons.lock_outline_rounded,
        size: size * 0.46,
        color: SDColors.primary600,
      ),
    );
  }
}

/// STAB-13 — Chargement inline compact (sections listes).
class SDLoadingInline extends StatelessWidget {
  const SDLoadingInline({
    super.key,
    this.message = 'Chargement…',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SDSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: SDColors.primary600,
            ),
          ),
          SDSpacing.horizontalSmallGap,
          Flexible(
            child: Text(
              message,
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
