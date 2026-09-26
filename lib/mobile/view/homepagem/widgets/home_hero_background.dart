import 'package:flutter/material.dart';

/// Décor d’en-tête accueil : dégradé Soutrali + palmier discret (scroll avec le hero).
class HomeHeroBackground extends StatelessWidget {
  const HomeHeroBackground({
    super.key,
    required this.child,
    this.palmOpacity = 0.26,
    this.palmWidth = 260,
    this.palmTop = 16,
    this.palmRight = -28,
  });

  final Widget child;
  final double palmOpacity;
  final double palmWidth;
  final double palmTop;
  final double palmRight;

  static const String palmAssetPath = 'assets/home/palm_shadow.png';

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE7F5EB),
                  Color(0xFFF7F4EA),
                  Color(0xFFFBFCFA),
                ],
                stops: [0.0, 0.62, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: palmTop,
          right: palmRight,
          width: palmWidth,
          child: IgnorePointer(
            child: Opacity(
              opacity: palmOpacity,
              child: Image.asset(
                palmAssetPath,
                fit: BoxFit.contain,
                alignment: Alignment.topRight,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        // Non positionné : impose la hauteur du hero dans le ListView.
        child,
      ],
    );
  }
}
