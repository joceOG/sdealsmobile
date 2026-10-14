import 'package:flutter/material.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';

/// Raccourci service plein cadre (Métiers / Freelance Explorer).
///
/// Image ou illustration + dégradé bas + libellé blanc — pas de bloc blanc sous l'image.
class UniverseServiceShortcutCard extends StatelessWidget {
  const UniverseServiceShortcutCard({
    super.key,
    required this.label,
    required this.onTap,
    this.imageUrl,
    this.semanticsLabel,
    this.fallbackIcon = Icons.work_outline_rounded,
    this.width = 116,
    this.height = 128,
  });

  final String label;
  final String? semanticsLabel;
  final String? imageUrl;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  AppImage(imageUrl: imageUrl!, fit: BoxFit.cover)
                else
                  ColoredBox(
                    color: SDColors.primary100,
                    child: Center(
                      child: Icon(
                        fallbackIcon,
                        color: SDColors.primary500,
                        size: 36,
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.70),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  right: 4,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
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
