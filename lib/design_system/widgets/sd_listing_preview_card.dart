import 'package:flutter/material.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

/// Carte type Airbnb : image dominante, texte **léger** en dessous
/// (pas de gros bloc blanc, pas d’ombre sur la carte).
///
/// - [squareImage] `false` : bannière 16:9 (ex. section services freelance).
/// - [squareImage] `true` : image **carrée** imposante (autres listes d’accueil).
class SDListingPreviewCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final IconData fallbackIcon;
  final String? imageUrl;
  final String? ratingText;
  final String? metaText;
  final String? priceText;
  final String? badgeText;
  /// Pastille haut-droite (ex. PROMO, -20 %).
  final String? promoBadgeText;
  /// Cœur favori haut-droite (style Airbnb) — section Métiers.
  final bool showFavoriteHeart;
  final VoidCallback? onFavoriteTap;
  final bool squareImage;
  final VoidCallback? onTap;

  static const double _aspectWidthOverHeight = 16 / 9;

  /// Hauteur utile pour un `ListView` horizontal (image + texte compact).
  static double totalHeightForWidth(double width, {bool squareImage = false}) {
    final imageHeight =
        squareImage ? width : width / _aspectWidthOverHeight;
    // Titre (2 lignes max) + sous-titre + prix + note·lieu + espacement
    return imageHeight + 126;
  }

  const SDListingPreviewCard({
    super.key,
    required this.width,
    required this.title,
    required this.subtitle,
    required this.fallbackIcon,
    this.imageUrl,
    this.ratingText,
    this.metaText,
    this.priceText,
    this.badgeText,
    this.promoBadgeText,
    this.showFavoriteHeart = false,
    this.onFavoriteTap,
    this.squareImage = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = 12.0;
    final imageHeight =
        squareImage ? width : width / _aspectWidthOverHeight;
    final hasRating = ratingText != null && ratingText!.isNotEmpty;
    final hasMeta = metaText != null && metaText!.isNotEmpty;
    final showStar =
        hasRating && RegExp(r'[0-9]').hasMatch(ratingText!);

    final detailParts = <String>[];
    if (hasRating) {
      detailParts.add(showStar ? '★ $ratingText' : ratingText!);
    }
    if (hasMeta) {
      detailParts.add(metaText!);
    }
    // Le sous-titre (ex. métier du prestataire) a sa propre ligne — ne pas le noyer dans note·lieu.
    final detailsLine = detailParts.join(' · ');

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius + 2),
          splashColor: SDColors.primary100.withOpacity(0.35),
          highlightColor: SDColors.primary50.withOpacity(0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: SizedBox(
                  height: imageHeight,
                  width: width,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: SDColors.neutral100,
                        child: imageUrl != null && imageUrl!.isNotEmpty
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                width: width,
                                height: imageHeight,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: SDColors.primary600,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    fallbackIcon,
                                    size: 40,
                                    color: SDColors.neutral400,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  fallbackIcon,
                                  size: 40,
                                  color: SDColors.neutral400,
                                ),
                              ),
                      ),
                      if (badgeText != null && badgeText!.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SDColors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: SDColors.neutral900.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              badgeText!,
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.neutral900,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      if (promoBadgeText != null && promoBadgeText!.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: showFavoriteHeart ? 44 : 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SDColors.error500,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              promoBadgeText!,
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      if (showFavoriteHeart)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Material(
                            color: SDColors.white.withOpacity(0.92),
                            shape: const CircleBorder(),
                            elevation: 1,
                            shadowColor: SDColors.neutral900.withOpacity(0.12),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onFavoriteTap,
                              child: const SizedBox(
                                width: 34,
                                height: 34,
                                child: Icon(
                                  Icons.favorite_border_rounded,
                                  size: 18,
                                  color: SDColors.neutral900,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 2, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.labelLarge.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.primary800,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                    if (priceText != null && priceText!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        priceText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral800,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ],
                    if (detailsLine.isNotEmpty) ...[
                      SizedBox(height: priceText != null && priceText!.isNotEmpty ? 2 : 4),
                      Text(
                        detailsLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral600,
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
