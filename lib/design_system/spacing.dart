import 'package:flutter/material.dart';

/// Système d'espacement Soutrali Deals
/// Basé sur grille 4px (Material Design 3)
/// 
/// **Utilisation:**
/// ```dart
/// Padding(padding: EdgeInsets.all(SDSpacing.sm)) // 16px
/// SizedBox(height: SDSpacing.md) // 24px
/// SDSpacing.defaultGap // SizedBox de 16px
/// ```
class SDSpacing {
  // ═══════════════════════════════════════
  // BASE UNIT (4px grid)
  // ═══════════════════════════════════════
  
  /// Base unit: 4px
  static const double unit = 4.0;
  
  // ═══════════════════════════════════════
  // SPACING SCALE (4px multiples)
  // ═══════════════════════════════════════
  
  /// Extra extra extra small - 4px
  /// Usage: Micro adjustments, très serré
  static const double xxxs = unit;
  
  /// Extra extra small - 8px
  /// Usage: Tight spacing, icônes + texte
  static const double xxs = unit * 2;
  
  /// Extra small - 12px
  /// Usage: Small gaps entre éléments proches
  static const double xs = unit * 3;
  
  /// Small - 16px ✅ DEFAULT
  /// Usage: Standard padding, gaps par défaut
  static const double sm = unit * 4;
  
  /// Medium - 24px
  /// Usage: Medium gaps, sections
  static const double md = unit * 6;
  
  /// Large - 32px
  /// Usage: Large sections, séparations importantes
  static const double lg = unit * 8;
  
  /// Extra large - 48px
  /// Usage: Major sections, espaces importants
  static const double xl = unit * 12;
  
  /// Extra extra large - 64px
  /// Usage: Hero spacing, très grands espaces
  static const double xxl = unit * 16;
  
  /// Extra extra extra large - 80px
  /// Usage: Exceptional spacing
  static const double xxxl = unit * 20;
  
  // ═══════════════════════════════════════
  // PADDING PRESETS
  // ═══════════════════════════════════════
  
  /// Card padding standard - 16px all
  static const cardPadding = EdgeInsets.all(sm);
  
  /// Card padding large - 24px all
  static const cardPaddingLarge = EdgeInsets.all(md);
  
  /// Screen padding horizontal - 16px H
  static const screenPadding = EdgeInsets.symmetric(horizontal: sm);
  
  /// Screen padding all - 16px all
  static const screenPaddingAll = EdgeInsets.all(sm);
  
  /// Section padding - 24px vertical
  static const sectionPadding = EdgeInsets.symmetric(vertical: md);
  
  /// Button padding - 24px H, 16px V
  static const buttonPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  
  /// Input padding - 16px H, 12px V
  static const inputPadding = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: xs,
  );
  
  /// List item padding - 16px all
  static const listItemPadding = EdgeInsets.all(sm);
  
  /// Chip padding - 12px H, 8px V
  static const chipPadding = EdgeInsets.symmetric(
    horizontal: xs,
    vertical: xxs,
  );
  
  // ═══════════════════════════════════════
  // SIZED BOX GAPS (Quick access)
  // ═══════════════════════════════════════
  
  /// Tiny gap - 8px
  static const tinyGap = SizedBox(height: xxs, width: xxs);
  
  /// Small gap - 12px
  static const smallGap = SizedBox(height: xs, width: xs);
  
  /// Default gap - 16px ✅ Most used
  static const defaultGap = SizedBox(height: sm, width: sm);
  
  /// Medium gap - 24px
  static const mediumGap = SizedBox(height: md, width: md);
  
  /// Large gap - 32px
  static const largeGap = SizedBox(height: lg, width: lg);
  
  /// Extra large gap - 48px
  static const extraLargeGap = SizedBox(height: xl, width: xl);
  
  // Vertical only gaps
  /// Vertical tiny gap - 8px height
  static const verticalTinyGap = SizedBox(height: xxs);
  
  /// Vertical small gap - 12px height
  static const verticalSmallGap = SizedBox(height: xs);
  
  /// Vertical default gap - 16px height
  static const verticalDefaultGap = SizedBox(height: sm);
  
  /// Vertical medium gap - 24px height
  static const verticalMediumGap = SizedBox(height: md);
  
  /// Vertical large gap - 32px height
  static const verticalLargeGap = SizedBox(height: lg);
  
  // Horizontal only gaps
  /// Horizontal tiny gap - 8px width
  static const horizontalTinyGap = SizedBox(width: xxs);
  
  /// Horizontal small gap - 12px width
  static const horizontalSmallGap = SizedBox(width: xs);
  
  /// Horizontal default gap - 16px width
  static const horizontalDefaultGap = SizedBox(width: sm);
  
  /// Horizontal medium gap - 24px width
  static const horizontalMediumGap = SizedBox(width: md);
  
  /// Horizontal large gap - 32px width
  static const horizontalLargeGap = SizedBox(width: lg);
  
  // ═══════════════════════════════════════
  // COMPONENT SIZES
  // ═══════════════════════════════════════
  
  /// AppBar standard height - 56px
  static const double appBarHeight = 56.0;
  
  /// AppBar with search height - 64px
  static const double appBarHeightWithSearch = 64.0;
  
  /// Button minimum height - 56px (Material touch target)
  static const double buttonHeight = 56.0;
  
  /// Button compact height - 48px
  static const double buttonHeightCompact = 48.0;
  
  /// Input field height - 56px
  static const double inputHeight = 56.0;
  
  /// Icon button size - 48px (44px minimum + 4px padding)
  static const double iconButtonSize = 48.0;
  
  /// Minimum touch target - 48px (Android Material guideline).
  /// WCAG minimum est 44px ; préférer 48px sur Android.
  static const double minTouchTarget = 48.0;
  
  /// Border radius small - 8px
  static const double borderRadiusSmall = 8.0;
  
  /// Border radius medium - 12px ✅ Default
  static const double borderRadiusMedium = 12.0;
  
  /// Border radius large - 16px
  static const double borderRadiusLarge = 16.0;
  
  /// Border radius extra large - 24px
  static const double borderRadiusXLarge = 24.0;
  
  // ═══════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════
  
  /// Create EdgeInsets.all() avec une valeur custom
  static EdgeInsets all(double value) => EdgeInsets.all(value);
  
  /// Create EdgeInsets.symmetric() horizontal
  static EdgeInsets horizontal(double value) => 
    EdgeInsets.symmetric(horizontal: value);
  
  /// Create EdgeInsets.symmetric() vertical
  static EdgeInsets vertical(double value) => 
    EdgeInsets.symmetric(vertical: value);
  
  /// Create SizedBox avec height custom
  static SizedBox gap(double value) => SizedBox(height: value, width: value);
  
  /// Create SizedBox vertical uniquement
  static SizedBox verticalGap(double value) => SizedBox(height: value);
  
  /// Create SizedBox horizontal uniquement
  static SizedBox horizontalGap(double value) => SizedBox(width: value);
}
