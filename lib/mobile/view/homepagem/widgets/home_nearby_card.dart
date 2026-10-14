import 'package:flutter/material.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';

/// Carte portrait pour le carrousel « Découvrir des professionnels » de l'accueil.
///
/// Mise en page :
///   • Photo pleine largeur (ObjectFit.cover) dans le tiers supérieur.
///   • ❤️ en overlay haut-droit (bouton favori, 48 dp touch target).
///   • Nom (gras) + métier (vert) + prix FCFA + localisation en dessous.
class HomeNearbyCard extends StatelessWidget {
  const HomeNearbyCard({
    super.key,
    required this.width,
    required this.name,
    this.metier,
    this.price,
    this.place,
    this.verifiedLabel,
    this.imageUrl,
    this.onTap,
    this.onFavorite,
    this.favoriteSelected = false,
  });

  final double width;
  final String name;
  final String? metier;
  final String? price;
  final String? place;
  final String? verifiedLabel;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool favoriteSelected;

  /// Hauteur de la photo (fixe, indépendante de la largeur).
  static const double _photoHeight = 148.0;

  /// Hauteur totale de la carte selon le text scaler courant.
  ///
  /// Calculée pour le pire cas (toutes les lignes visibles) :
  /// nom 14px + métier 12px + prix 12px + lieu 12px + vérifié 12px + 5 gaps + padding.
  static double heightFor(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final textH = scaler.scale(14) * 1.3 + // nom
        scaler.scale(12) * 1.4 * 4 + // métier + prix + lieu + vérifié
        5 * 4.0 + // 5 micro-espaces
        SDSpacing.spaceSmall * 2; // padding haut + bas de la section
    return _photoHeight + textH;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: SDColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        ),
        elevation: 2,
        shadowColor: const Color(0x1A000000),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo + bouton favori ──────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(SDSpacing.radiusCard),
                    ),
                    child: _PortraitPhoto(
                      imageUrl: imageUrl,
                      name: name,
                      height: _photoHeight,
                      width: width,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Semantics(
                      button: true,
                      selected: favoriteSelected,
                      container: true,
                      label: favoriteSelected
                          ? 'Retirer des favoris'
                          : 'Ajouter aux favoris',
                      child: IconButton(
                        onPressed: onFavorite,
                        tooltip: favoriteSelected
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
                        constraints: const BoxConstraints(
                          minWidth: SDSpacing.minTouchTarget,
                          minHeight: SDSpacing.minTouchTarget,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              SDColors.white.withValues(alpha: 0.88),
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        icon: Icon(
                          favoriteSelected
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: SDSpacing.iconInformative,
                          color: favoriteSelected
                              ? SDColors.primary600
                              : SDColors.neutral500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // ── Infos ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SDSpacing.spaceSmall,
                  SDSpacing.spaceSmall,
                  SDSpacing.spaceSmall,
                  SDSpacing.spaceSmall,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.labelMedium.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Métier (vert)
                    if (metier != null && metier!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        metier!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.caption.copyWith(
                          color: SDColors.primary600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    // Prix
                    if (price != null && price!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        price!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.caption.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    // Localisation
                    if (place != null && place!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              Icons.location_on,
                              size: 12,
                              color: SDColors.primary600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              place!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.caption
                                  .copyWith(color: SDColors.neutral600),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Badge identité vérifiée
                    if (verifiedLabel != null &&
                        verifiedLabel!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              Icons.verified,
                              size: 12,
                              color: SDColors.primary600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              verifiedLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.caption.copyWith(
                                color: SDColors.primary700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internes
// ─────────────────────────────────────────────────────────────────────────────

class _PortraitPhoto extends StatelessWidget {
  const _PortraitPhoto({
    this.imageUrl,
    required this.name,
    required this.height,
    required this.width,
  });

  final String? imageUrl;
  final String name;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();

    if (url.isEmpty) {
      return _PortraitPlaceholder(initial: initial, height: height, width: width);
    }
    return AppImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }
}

class _PortraitPlaceholder extends StatelessWidget {
  const _PortraitPlaceholder({
    required this.initial,
    required this.height,
    required this.width,
  });

  final String initial;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: SDColors.primary100,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: SDTypography.displaySmall.copyWith(
          color: SDColors.primary700,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
