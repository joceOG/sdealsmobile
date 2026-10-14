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
              const Icon(Icons.error_outline,
                  color: SDColors.error500, size: 20),
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
    this.illustration,
    this.illustrationHeight = 160,
    this.onPrimary,
    this.onSecondary,
    this.primaryLabel = 'Se connecter',
    this.secondaryLabel = 'Créer un compte',
    this.centerVertically = true,
  }) : assert(
          icon != null || illustrationAsset != null || illustration != null,
          'Fournir icon, illustrationAsset ou illustration',
        );

  static const double horizontalPadding = 24;

  final String? pageTitle;
  final String title;
  final String description;
  final IconData? icon;
  final String? illustrationAsset;
  final Widget? illustration;
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
          padding: const EdgeInsets.fromLTRB(
              horizontalPadding, 12, horizontalPadding, 8),
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

    if (illustration != null) return illustration!;

    if (illustrationAsset != null) {
      return SizedBox(
        height: effectiveIllustrationH,
        width: double.infinity,
        child: Image.asset(
          illustrationAsset!,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: child,
            );
          },
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

/// Contenu enregistré encore consultable, sans actualisation.
class SDOfflineSavedBanner extends StatelessWidget {
  const SDOfflineSavedBanner({
    super.key,
    this.offline = true,
    this.limitedExcerpt = false,
  });

  final bool offline;
  final bool limitedExcerpt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SDColors.neutral50,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
            size: 18,
            color: SDColors.neutral700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offline
                      ? 'Vous êtes hors ligne'
                      : 'Actualisation impossible',
                  style: SDTypography.labelLarge.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Informations enregistrées, non actualisées.',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral700,
                  ),
                ),
                if (limitedExcerpt) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Extrait enregistré, pas le catalogue complet.',
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section sans donnée locale.
class SDSectionNeedsConnection extends StatelessWidget {
  const SDSectionNeedsConnection({
    super.key,
    required this.detail,
    this.onRetry,
  });

  final String detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded, color: SDColors.neutral700),
          const SizedBox(height: 8),
          Text(
            'Cette section nécessite une connexion',
            style: SDTypography.titleSmall.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
          ),
          if (onRetry != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, SDSpacing.minTouchTarget),
                ),
                child: const Text('Réessayer'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Page entière sans contenu local.
class SDConnectionRequired extends StatelessWidget {
  const SDConnectionRequired({
    super.key,
    this.onRetry,
    this.onBack,
  });

  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: SDColors.neutral700),
            const SizedBox(height: 12),
            Text(
              'Connexion nécessaire',
              textAlign: TextAlign.center,
              style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: SDColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune information enregistrée n’est disponible pour cette page.',
              textAlign: TextAlign.center,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral600,
              ),
            ),
            const SizedBox(height: 16),
            if (onRetry != null)
              SDButton(
                text: 'Réessayer',
                size: SDButtonSize.medium,
                onPressed: onRetry,
              ),
            if (onBack != null)
              TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, SDSpacing.minTouchTarget),
                ),
                child: const Text('Retour'),
              ),
          ],
        ),
      ),
    );
  }
}
