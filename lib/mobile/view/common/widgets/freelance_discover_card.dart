import 'package:flutter/material.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/models/freelance_model.dart';

/// Carte freelance "Airbnb-style" — photo portrait + infos + bouton vert.
/// Identique sur tous les écrans (Explorer, Hub Freelance, liste complète).
class FreelanceDiscoverCard extends StatelessWidget {
  const FreelanceDiscoverCard({
    super.key,
    required this.freelance,
    required this.onViewProfile,
    this.onFavorite,
  });

  final FreelanceModel freelance;
  final VoidCallback onViewProfile;
  final VoidCallback? onFavorite;

  static String _formatRate(double rate) {
    final s = rate.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u00a0');
      buf.write(s[i]);
    }
    return '${buf.toString()} FCFA\u00a0/ heure';
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = freelance.imagePath.startsWith('http')
        ? freelance.imagePath
        : null;
    final initial = freelance.name.trim().isNotEmpty
        ? freelance.name.trim()[0].toUpperCase()
        : '?';
    final skills = freelance.skills
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(3)
        .toList();
    final hasRate = freelance.hourlyRate > 0;
    final hasLocation = freelance.location.isNotEmpty;
    final hasJob =
        freelance.job.isNotEmpty && freelance.job != 'Non renseigné';
    final hasRating = freelance.rating > 0;

    return Container(
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        border: Border.all(color: SDColors.neutral200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo portrait ──────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 100,
                  height: 120,
                  child: imgUrl != null
                      ? AppImage(imageUrl: imgUrl, fit: BoxFit.cover)
                      : ColoredBox(
                          color: SDColors.primary50,
                          child: Center(
                            child: Text(
                              initial,
                              style: SDTypography.titleLarge.copyWith(
                                color: SDColors.primary600,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // ── Infos ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            freelance.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SDTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: SDColors.neutral900,
                            ),
                          ),
                        ),
                        if (onFavorite != null)
                          GestureDetector(
                            onTap: onFavorite,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.favorite_border_rounded,
                                size: 20,
                                color: SDColors.neutral400,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (hasJob) ...[
                      const SizedBox(height: 2),
                      Text(
                        freelance.job,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.primary600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (hasLocation) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: SDColors.neutral400),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              freelance.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.neutral500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: skills
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: SDColors.neutral100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  s,
                                  style: SDTypography.labelSmall.copyWith(
                                    color: SDColors.neutral700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (hasRating || hasRate) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (hasRating) ...[
                            const Icon(Icons.star_rounded,
                                size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 3),
                            Text(
                              freelance.rating.toStringAsFixed(1),
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.neutral700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (hasRate) const SizedBox(width: 8),
                          ],
                          if (hasRate)
                            Expanded(
                              child: Text(
                                _formatRate(freelance.hourlyRate),
                                overflow: TextOverflow.ellipsis,
                                style: SDTypography.labelMedium.copyWith(
                                  color: SDColors.primary600,
                                  fontWeight: FontWeight.w800,
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
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onViewProfile,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            iconAlignment: IconAlignment.end,
            label: const Text('Voir le profil'),
            style: FilledButton.styleFrom(
              backgroundColor: SDColors.primary600,
              minimumSize:
                  const Size(double.infinity, SDSpacing.minTouchTarget),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(SDSpacing.radiusButton),
              ),
              textStyle: SDTypography.labelMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
