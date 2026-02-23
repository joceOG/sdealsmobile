import 'package:flutter/material.dart';

/// Système d'animations Soutrali Deals
/// Basé sur Material Design 3 Motion System
/// 
/// **Utilisation:**
/// ```dart
/// AnimatedContainer(
///   duration: SDAnimations.medium,
///   curve: SDAnimations.emphasized,
/// )
/// ```
class SDAnimations {
  // ═══════════════════════════════════════
  // DURÉES (Material Design 3)
  // ═══════════════════════════════════════
  
  /// Ultra short - 100ms
  /// Usage: Micro-interactions, button press feedback
  static const ultraShort = Duration(milliseconds: 100);
  
  /// Short - 200ms ✅ Default
  /// Usage: Standard transitions, card taps, simple animations
  static const short = Duration(milliseconds: 200);
  
  /// Medium - 300ms
  /// Usage: Page transitions, modal open/close
  static const medium = Duration(milliseconds: 300);
  
  /// Long - 400ms
  /// Usage: Hero animations, complex transitions
  static const long = Duration(milliseconds: 400);
  
  /// Extra long - 500ms
  /// Usage: Full screen modals, major UI changes
  static const extraLong = Duration(milliseconds: 500);
  
  // ═══════════════════════════════════════
  // CURVES (Easing functions)
  // ═══════════════════════════════════════
  
  /// Emphasized - easeInOutCubic ✅ Most used
  /// Usage: Standard animations, balanced feel
  static const emphasized = Curves.easeInOutCubic;
  
  /// Decelerated - easeOut
  /// Usage: Elements entering screen (fade in, slide in)
  static const decelerated = Curves.easeOut;
  
  /// Accelerated - easeIn
  /// Usage: Elements leaving screen (fade out, slide out)
  static const accelerated = Curves.easeIn;
  
  /// Standard - easeInOut
  /// Usage: Neutral transitions
  static const standard = Curves.easeInOut;
  
  /// Bounce - elasticOut
  /// Usage: Fun interactions, playful feedback
  static const bounce = Curves.elasticOut;
  
  /// Linear - no easing
  /// Usage: Progress indicators, loading spinners
  static const linear = Curves.linear;
  
  // ═══════════════════════════════════════
  // PRESET ANIMATIONS
  // ═══════════════════════════════════════
  
  /// Fade in animation
  /// 
  /// Usage:
  /// ```dart
  /// SDAnimations.fadeIn(
  ///   child: MyWidget(),
  ///   duration: SDAnimations.medium,
  /// )
  /// ```
  static Widget fadeIn({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? medium,
      curve: curve ?? decelerated,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: child,
    );
  }
  
  /// Slide from bottom animation
  /// 
  /// Usage:
  /// ```dart
  /// SDAnimations.slideFromBottom(
  ///   child: MyWidget(),
  /// )
  /// ```
  static Widget slideFromBottom({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, 0.1), end: Offset.zero),
      duration: duration ?? medium,
      curve: curve ?? emphasized,
      builder: (context, value, child) => Transform.translate(
        offset: value * 100,
        child: child,
      ),
      child: child,
    );
  }
  
  /// Scale bounce animation
  /// 
  /// Usage:
  /// ```dart
  /// SDAnimations.scaleBounce(
  ///   child: MyWidget(),
  /// )
  /// ```
  static Widget scaleBounce({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: duration ?? medium,
      curve: curve ?? bounce,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: child,
      ),
      child: child,
    );
  }
  
  /// Slide from left animation
  static Widget slideFromLeft({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(-0.1, 0), end: Offset.zero),
      duration: duration ?? medium,
      curve: curve ?? emphasized,
      builder: (context, value, child) => Transform.translate(
        offset: value * 100,
        child: child,
      ),
      child: child,
    );
  }
  
  /// Slide from right animation
  static Widget slideFromRight({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0.1, 0), end: Offset.zero),
      duration: duration ?? medium,
      curve: curve ?? emphasized,
      builder: (context, value, child) => Transform.translate(
        offset: value * 100,
        child: child,
      ),
      child: child,
    );
  }
  
  // ═══════════════════════════════════════
  // PAGE TRANSITIONS
  // ═══════════════════════════════════════
  
  /// Page route avec slide transition
  /// 
  /// Usage:
  /// ```dart
  /// Navigator.push(
  ///   context,
  ///   SDAnimations.slidePageRoute(NextPage()),
  /// )
  /// ```
  static PageRouteBuilder<T> slidePageRoute<T>(
    Widget page, {
    Duration? duration,
    Curve? curve,
    SlideDirection direction = SlideDirection.right,
  }) {
    Offset beginOffset;
    switch (direction) {
      case SlideDirection.right:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideDirection.left:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.up:
        beginOffset = const Offset(0.0, -1.0);
        break;
      case SlideDirection.down:
        beginOffset = const Offset(0.0, 1.0);
        break;
    }
    
    return PageRouteBuilder<T>(
      transitionDuration: duration ?? medium,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve ?? emphasized,
          )),
          child: child,
        );
      },
    );
  }
  
  /// Page route avec fade transition
  static PageRouteBuilder<T> fadePageRoute<T>(
    Widget page, {
    Duration? duration,
    Curve? curve,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration ?? medium,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve ?? decelerated,
          ),
          child: child,
        );
      },
    );
  }
}

/// Directions pour les slide transitions
enum SlideDirection {
  left,
  right,
  up,
  down,
}

/// Animation configuration presets
class SDAnimationConfig {
  /// Button press animation config
  static const buttonPress = AnimationConfig(
    duration: SDAnimations.ultraShort,
    curve: SDAnimations.emphasized,
    scaleFrom: 0.95,
    scaleTo: 1.0,
  );
  
  /// Card tap animation config
  static const cardTap = AnimationConfig(
    duration: SDAnimations.short,
    curve: SDAnimations.emphasized,
    scaleFrom: 0.98,
    scaleTo: 1.0,
  );
  
  /// List item appear animation config
  static const listItemAppear = AnimationConfig(
    duration: SDAnimations.medium,
    curve: SDAnimations.decelerated,
    opacityFrom: 0.0,
    opacityTo: 1.0,
  );
}

/// Animation configuration class
class AnimationConfig {
  final Duration duration;
  final Curve curve;
  final double? scaleFrom;
  final double? scaleTo;
  final double? opacityFrom;
  final double? opacityTo;
  
  const AnimationConfig({
    required this.duration,
    required this.curve,
    this.scaleFrom,
    this.scaleTo,
    this.opacityFrom,
    this.opacityTo,
  });
}
