import 'package:flutter/material.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';

/// Carte professionnelle client (Explorer / Métiers).
/// N'affiche que des données déjà validées par l'appelant (pas d'invention).
class ClientProviderListCard extends StatelessWidget {
  final String name;
  final String metier;
  final String? location;
  final String? priceLabel;
  final String? distanceLabel;
  final String? ratingLabel;
  final String? photoUrl;
  final bool verified;
  final bool? favorite;
  final VoidCallback onOpen;
  final VoidCallback onCall;
  final VoidCallback onAsk;
  final VoidCallback? onToggleFavorite;

  const ClientProviderListCard({
    super.key,
    required this.name,
    required this.metier,
    required this.onOpen,
    required this.onCall,
    required this.onAsk,
    this.location,
    this.priceLabel,
    this.distanceLabel,
    this.ratingLabel,
    this.photoUrl,
    this.verified = false,
    this.favorite,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Semantics(
      button: true,
      label: 'Professionnel $name, $metier',
      child: Material(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
              border: Border.all(color: SDColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipOval(
                      child: hasPhoto
                          ? AppImage(
                              imageUrl: photoUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              borderRadius: 28,
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: SDColors.primary50,
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: SDTypography.titleMedium.copyWith(
                                  color: SDColors.primary700,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: SDTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: SDColors.neutral900,
                                  ),
                                ),
                              ),
                              if (verified) ...[
                                const SizedBox(width: 4),
                                Semantics(
                                  label: 'Identité vérifiée',
                                  child: const Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: SDColors.primary600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metier,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (location != null && location!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.neutral500,
                              ),
                            ),
                          ],
                          if (ratingLabel != null || distanceLabel != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (ratingLabel != null) ...[
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Color(0xFFFBBF24),
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      ratingLabel!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: SDTypography.labelSmall.copyWith(
                                        color: SDColors.neutral600,
                                      ),
                                    ),
                                  ),
                                ],
                                if (ratingLabel != null &&
                                    distanceLabel != null)
                                  Text(
                                    ' · ',
                                    style: SDTypography.labelSmall.copyWith(
                                      color: SDColors.neutral400,
                                    ),
                                  ),
                                if (distanceLabel != null) ...[
                                  const Icon(
                                    Icons.place_outlined,
                                    size: 12,
                                    color: SDColors.neutral700,
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      distanceLabel!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: SDTypography.labelSmall.copyWith(
                                        color: SDColors.neutral600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (priceLabel != null && priceLabel!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              priceLabel!,
                              style: SDTypography.labelMedium.copyWith(
                                color: SDColors.primary700,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (favorite != null)
                      Semantics(
                        button: true,
                        label: favorite!
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
                        child: IconButton(
                          onPressed: onToggleFavorite,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: Icon(
                            favorite!
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: favorite!
                                ? SDColors.error500
                                : SDColors.neutral400,
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Appeler $name',
                        child: ElevatedButton.icon(
                          onPressed: onCall,
                          icon: const Icon(Icons.phone_rounded, size: 18),
                          label: const Text('Appeler'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SDColors.primary600,
                            foregroundColor: SDColors.white,
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Demander un service à $name',
                        child: OutlinedButton(
                          onPressed: onAsk,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SDColors.primary700,
                            side: const BorderSide(color: SDColors.primary600),
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Demander'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Libellé d'expérience sans double « ans ».
String? formatExperienceLabel(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final match = RegExp(r'(\d+)').firstMatch(trimmed);
  if (match == null) return null;
  final n = int.tryParse(match.group(1)!);
  if (n == null || n <= 0) return null;
  return n == 1 ? '1 an d’expérience' : '$n ans d’expérience';
}

/// Capitalisation affichage uniquement (ne modifie pas la valeur serveur).
String displayTitleCase(String raw) {
  final parts = raw.trim().split(RegExp(r'\s+'));
  return parts.where((p) => p.isNotEmpty).map((p) {
    if (p.length == 1) return p.toUpperCase();
    return '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}';
  }).join(' ');
}
