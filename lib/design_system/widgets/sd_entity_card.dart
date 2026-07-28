import 'package:flutter/material.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';
import 'sd_card.dart';

enum SDEntityCardType { provider, freelance, product }

class SDEntityCard extends StatelessWidget {
  final SDEntityCardType type;
  final String title;
  final String subtitle;
  final IconData fallbackIcon;
  final String? imageUrl;
  final String? ratingText;
  final String? metaText;
  final String? statusText;
  final String? priceText;
  final String? promoText;
  final String? ctaLabel;
  final VoidCallback? onTap;

  const SDEntityCard({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.fallbackIcon,
    this.imageUrl,
    this.ratingText,
    this.metaText,
    this.statusText,
    this.priceText,
    this.promoText,
    this.ctaLabel,
    this.onTap,
  });

  Color _ctaColor() {
    switch (type) {
      case SDEntityCardType.provider:
        return SDColors.primary700;
      case SDEntityCardType.freelance:
        return SDColors.info600;
      case SDEntityCardType.product:
        return SDColors.secondary600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctaColor = _ctaColor();
    return SizedBox(
      width: 168,
      child: SDCard(
        onTap: onTap,
        elevation: 1.5,
        borderRadius: SDSpacing.borderRadiusLarge,
        borderColor: SDColors.neutral200,
        borderWidth: 1,
        padding: const EdgeInsets.all(8),
        showHoverEffect: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 210;
            final imageHeight = isCompact ? 68.0 : 102.0;
            final sectionGap = isCompact ? 4.0 : 8.0;
            final showStatus = !isCompact && statusText != null && statusText!.isNotEmpty;
            final showMetaLine = (ratingText != null && ratingText!.isNotEmpty) ||
                (metaText != null && metaText!.isNotEmpty);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: imageHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: SDColors.neutral100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: imageUrl != null && imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  fallbackIcon,
                                  size: isCompact ? 28 : 36,
                                  color: ctaColor,
                                ),
                              ),
                            )
                          : Icon(fallbackIcon, size: isCompact ? 28 : 36, color: ctaColor),
                    ),
                    if (promoText != null && promoText!.isNotEmpty)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SDColors.warning500,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            promoText!,
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: sectionGap),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SDTypography.labelLarge.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 13 : 14,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
                ),
                if (showMetaLine) ...[
                  SizedBox(height: isCompact ? 2 : 4),
                  Text(
                    '${ratingText ?? ''}${ratingText != null && metaText != null ? ' • ' : ''}${metaText ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelSmall.copyWith(color: SDColors.neutral600),
                  ),
                ],
                if (showStatus) ...[
                  const SizedBox(height: 2),
                  Text(
                    statusText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.success600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const Spacer(),
                if (priceText != null && priceText!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SDColors.neutral100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      priceText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                if (ctaLabel != null && ctaLabel!.isNotEmpty && !isCompact) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ctaLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.labelSmall.copyWith(
                        color: ctaColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
