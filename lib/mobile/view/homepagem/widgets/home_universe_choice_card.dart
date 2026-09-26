import 'package:flutter/material.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

/// Carte d’entrée univers (texte + photo à droite, lisible sur petit écran).
class HomeUniverseChoiceCard extends StatelessWidget {
  const HomeUniverseChoiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.onTap,
    this.height = 108,
  });

  final String title;
  final String subtitle;
  final String imageAsset;
  final VoidCallback onTap;
  final double height;

  static const _textFlex = 11;
  static const _imageFlex = 9;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: SDColors.primary50,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
          side: const BorderSide(color: SDColors.neutral200, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: _textFlex,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              SDColors.primary50,
                              SDColors.primary50.withValues(alpha: 0.92),
                              SDColors.white.withValues(alpha: 0.55),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          SDSpacing.spaceRelated,
                          SDSpacing.spaceSmall,
                          SDSpacing.spaceSmall,
                          SDSpacing.spaceSmall,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SDTypography.cardTitle.copyWith(
                                      color: SDColors.neutral900,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: SDTypography.caption.copyWith(
                                      color: SDColors.neutral700,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: SDColors.neutral500,
                              size: SDSpacing.iconStandard,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: _imageFlex,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: SDColors.primary100.withValues(alpha: 0.4),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: SDColors.neutral400,
                      ),
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
