import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../animations.dart';

/// Illustration Lottie du Design System.
///
/// Le JSON porte l'animation interne. L'entrée dans l'écran (fondu, léger
/// décalage, légère échelle) est commune à toutes les illustrations.
/// En Reduce Motion, la frame de repos s'affiche sans mouvement.
class SDIllustration extends StatelessWidget {
  const SDIllustration({
    super.key,
    required this.asset,
    this.maxWidth = nominalWidth,
    this.aspectRatio = nominalAspectRatio,
    this.loop = true,
    this.animate = true,
    this.fallback,
    this.semanticLabel,
  });

  /// 264 dp. La hauteur suit le ratio, elle n'est pas fixée à part.
  static const double nominalWidth = 264;

  /// Canvas 1000×800, soit 5:4. 264 dp de large donnent environ 211 dp de haut.
  static const double nominalAspectRatio = 5 / 4;

  static const Duration entranceDuration = Duration(milliseconds: 220);

  final String asset;
  final double maxWidth;
  final double aspectRatio;
  final bool loop;
  final bool animate;
  final Widget? fallback;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduce = SDClientMotion.reduceMotion(context);

    Widget illustration = LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final width = available.isFinite
            ? math.min(maxWidth, math.max(0.0, available))
            : maxWidth;
        final height = aspectRatio == 0 ? 0.0 : width / aspectRatio;

        return SizedBox(
          width: width,
          height: height,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: reduce ? 1.0 : 0.0, end: 1.0),
            duration: reduce ? Duration.zero : entranceDuration,
            curve: Curves.easeOutCubic,
            child: Lottie.asset(
              asset,
              width: width,
              height: height,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              repeat: loop,
              animate: animate && !reduce,
              errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
            ),
            builder: (context, t, child) {
              final dy = reduce ? 0.0 : (1 - t) * 6;
              final scale = reduce ? 1.0 : 0.985 + (0.015 * t);
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (semanticLabel == null) {
      illustration = ExcludeSemantics(child: illustration);
    } else {
      illustration = Semantics(
        label: semanticLabel,
        child: illustration,
      );
    }
    return illustration;
  }
}
