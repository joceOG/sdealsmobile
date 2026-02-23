import 'package:flutter/material.dart';

/// Système typographique Soutrali Deals
/// Basé sur Material Design 3 Type Scale
/// 
/// **Utilisation:**
/// ```dart
/// Text('Titre', style: SDTypography.titleLarge)
/// ```
class SDTypography {
  // Font Family - Inter (Modern, readable, professional)
  // ✅ Font files installed in assets/fonts/
  static const String fontFamily = 'Inter';
  
  // ═══════════════════════════════════════
  // HEADINGS (Titres principaux)
  // ═══════════════════════════════════════
  
  /// Display Large - 32px Bold
  /// Usage: Hero titles, splash screens
  static const displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  /// Display Medium - 28px Bold
  /// Usage: Page titles principales
  static const displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.2,
  );
  
  /// Display Small - 24px SemiBold
  /// Usage: Section headers importantes
  static const displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );
  
  // ═══════════════════════════════════════
  // HEADLINES (Titres alternatifs / Material 3)
  // ═══════════════════════════════════════

  /// Headline Large - 32px Bold (Alias Display Large)
  static const headlineLarge = displayLarge;

  /// Headline Medium - 28px Bold (Alias Display Medium)
  static const headlineMedium = displayMedium;

  /// Headline Small - 24px SemiBold (Alias Display Small)
  static const headlineSmall = displaySmall;

  // ═══════════════════════════════════════
  // TITLES (Sous-titres)
  // ═══════════════════════════════════════
  
  /// Title Large - 20px SemiBold
  /// Usage: AppBar titles, card headers
  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );
  
  /// Title Medium - 18px SemiBold
  /// Usage: Card titles, list headers
  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
  );
  
  /// Title Small - 16px SemiBold
  /// Usage: Small section headers
  static const titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );
  
  // ═══════════════════════════════════════
  // BODY (Corps de texte)
  // ═══════════════════════════════════════
  
  /// Body Large - 16px Regular
  /// Usage: Main body text, descriptions
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );
  
  /// Body Medium - 14px Regular
  /// Usage: Secondary text, metadata
  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.5,
  );
  
  /// Body Small - 12px Regular
  /// Usage: Captions, hints, fine print
  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.5,
  );
  
  // ═══════════════════════════════════════
  // LABELS (Boutons, tabs, badges)
  // ═══════════════════════════════════════
  
  /// Label Large - 16px SemiBold
  /// Usage: Primary buttons, prominent CTAs
  static const labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );
  
  /// Label Medium - 14px SemiBold
  /// Usage: Secondary buttons, tabs
  static const labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );
  
  /// Label Small - 12px SemiBold
  /// Usage: Badges, chips, small buttons
  static const labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );
  
  // ═══════════════════════════════════════
  // SPECIAL (Prix, montants importants)
  // ═══════════════════════════════════════
  
  /// Price Display - 24px Bold
  /// Usage: Large price displays, important numbers
  static const priceDisplay = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.2,
  );
  
  /// Price Medium - 18px SemiBold
  /// Usage: Medium price displays
  static const priceMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );
  
  // ═══════════════════════════════════════
  // HELPER METHOD
  // ═══════════════════════════════════════
  
  /// Applique une couleur à un TextStyle
  /// 
  /// Example: `SDTypography.titleLarge.withColor(Colors.white)`
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
}
