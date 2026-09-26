import 'package:flutter/material.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

/// Carte compacte d'accueil. Ne remplace pas [SDListingPreviewCard],
/// trop haute pour « près de vous » et partagée avec d'autres listes.
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

  static double heightFor(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final lines = scaler.scale(16) * 1.3 +
        scaler.scale(13) * 1.4 * 3 +
        scaler.scale(16) * 1.3;
    return lines + SDSpacing.spaceRelated * 2 + SDSpacing.spaceSmall;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: SDColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
          side: const BorderSide(color: SDColors.neutral100),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(SDSpacing.spaceSmall),
            child: Row(
              children: [
                _Photo(imageUrl: imageUrl, name: name),
                const SizedBox(width: SDSpacing.spaceSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.cardTitle
                            .copyWith(color: SDColors.neutral900),
                      ),
                      if (metier != null && metier!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          metier!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SDTypography.caption
                              .copyWith(color: SDColors.neutral700),
                        ),
                      ],
                      if (price != null && price!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          price!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SDTypography.price.copyWith(
                            color: SDColors.neutral900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (place != null && place!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const ExcludeSemantics(
                              child: Icon(
                                Icons.location_on,
                                size: 14,
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
                      if (verifiedLabel != null &&
                          verifiedLabel!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const ExcludeSemantics(
                              child: Icon(
                                Icons.verified,
                                size: 14,
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
                Semantics(
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
                    icon: Icon(
                      favoriteSelected ? Icons.favorite : Icons.favorite_border,
                      size: SDSpacing.iconInformative,
                      color: favoriteSelected
                          ? SDColors.primary600
                          : SDColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    final url = imageUrl?.trim() ?? '';
    final initial =
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return ClipOval(
      child: ColoredBox(
        color: SDColors.primary100,
        child: SizedBox(
          width: size,
          height: size,
          child: url.isEmpty
              ? Center(
                  child: Text(
                    initial,
                    style: SDTypography.cardTitle.copyWith(
                      color: SDColors.primary800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      initial,
                      style: SDTypography.cardTitle.copyWith(
                        color: SDColors.primary800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
