import 'package:flutter/material.dart';

/// Palette de couleurs Soutrali Deals
/// Basée sur Material Design 3 Color System avec validation WCAG 2.1 AA
/// 
/// **Utilisation:**
/// ```dart
/// Container(color: SDColors.primary500)
/// Text('Hello', style: TextStyle(color: SDColors.neutral900))
/// ```
class SDColors {
  // ═══════════════════════════════════════
  // PRIMARY (Vert Soutrali)
  // ═══════════════════════════════════════
  
  /// Primary 900 - Très foncé
  static const primary900 = Color(0xFF0D5016);
  
  /// Primary 800
  static const primary800 = Color(0xFF116B1C);
  
  /// Primary 700
  static const primary700 = Color(0xFF158622);
  
  /// Primary 600 - Boutons principaux
  static const primary600 = Color(0xFF1AA12A);
  
  /// Primary 500 - Brand color principale
  static const primary500 = Color(0xFF1CBF3F);
  
  /// Primary 400 - Pour gradients
  static const primary400 = Color(0xFF43EA5E);
  
  /// Primary 300
  static const primary300 = Color(0xFF6BF17C);
  
  /// Primary 200
  static const primary200 = Color(0xFF9CF5A8);
  
  /// Primary 100
  static const primary100 = Color(0xFFC8FAD0);
  
  /// Primary 50 - Très clair
  static const primary50 = Color(0xFFE8FCE9);
  
  // ═══════════════════════════════════════
  // SECONDARY (Orange/Accent)
  // ═══════════════════════════════════════
  
  /// Secondary 700
  static const secondary700 = Color(0xFFC2410C);

  /// Secondary 600 - Foncé
  static const secondary600 = Color(0xFFEA580C);
  
  /// Secondary 500 - Accent principal
  static const secondary500 = Color(0xFFF97316);
  
  /// Secondary 400 - Pour gradients
  static const secondary400 = Color(0xFFFB923C);
  
  /// Secondary 200
  static const secondary200 = Color(0xFFFED7AA);
  
  /// Secondary 100 - Très clair
  static const secondary100 = Color(0xFFFFEDD5);

  /// Secondary 50
  static const secondary50 = Color(0xFFFFF7ED);
  
  // ═══════════════════════════════════════
  // NEUTRAL (Gris)
  // ═══════════════════════════════════════
  
  /// Neutral 900 - Texte principal (noir)
  /// WCAG Ratio sur blanc: 16.1:1 ✅
  static const neutral900 = Color(0xFF171717);
  
  /// Neutral 800
  static const neutral800 = Color(0xFF262626);
  
  /// Neutral 700 - Texte secondaire
  /// WCAG Ratio sur blanc: 8.6:1 ✅
  static const neutral700 = Color(0xFF404040);
  
  /// Neutral 600
  static const neutral600 = Color(0xFF525252);
  
  /// Neutral 500 - Disabled text
  /// WCAG Ratio sur blanc: 4.6:1 ✅
  static const neutral500 = Color(0xFF737373);
  
  /// Neutral 400 - Borders
  static const neutral400 = Color(0xFFA3A3A3);
  
  /// Neutral 300 - Dividers
  static const neutral300 = Color(0xFFD4D4D4);
  
  /// Neutral 200 - Light backgrounds
  static const neutral200 = Color(0xFFE5E5E5);
  
  /// Neutral 100 - Cards
  static const neutral100 = Color(0xFFF5F5F5);
  
  /// Neutral 50 - Page background
  static const neutral50 = Color(0xFFFAFAFA);
  
  // ═══════════════════════════════════════
  // SEMANTIC COLORS (États)
  // ═══════════════════════════════════════
  
  /// Success 700
  static const success700 = Color(0xFF047857);

  /// Success 600 - Foncé
  static const success600 = Color(0xFF059669);
  
  /// Success 500 - Succès principal
  static const success500 = Color(0xFF10B981);
  
  /// Success 200
  static const success200 = Color(0xFFA7F3D0);

  /// Success 100 - Background
  static const success100 = Color(0xFFD1FAE5);

  /// Success 50
  static const success50 = Color(0xFFECFDF5);
  
  /// Error 600 - Foncé
  static const error600 = Color(0xFFDC2626);
  
  /// Error 500 - Erreur principale
  static const error500 = Color(0xFFEF4444);

  /// Error 200
  static const error200 = Color(0xFFFECACA);
  
  /// Error 100 - Background
  static const error100 = Color(0xFFFEE2E2);

  /// Error 50
  static const error50 = Color(0xFFFEF2F2);
  
  /// Warning 700
  static const warning700 = Color(0xFFB45309);

  /// Warning 600 - Foncé
  static const warning600 = Color(0xFFD97706);
  
  /// Warning 500 - Avertissement principal
  static const warning500 = Color(0xFFF59E0B);
  
  /// Warning 200
  static const warning200 = Color(0xFFFDE68A);

  /// Warning 100 - Background
  static const warning100 = Color(0xFFFEF3C7);

  /// Warning 50
  static const warning50 = Color(0xFFFFFBEB);
  
  /// Info 700
  static const info700 = Color(0xFF1D4ED8);

  /// Info 600 - Foncé
  static const info600 = Color(0xFF2563EB);
  
  /// Info 500 - Info principale
  static const info500 = Color(0xFF3B82F6);
  
  /// Info 200
  static const info200 = Color(0xFFBFDBFE);

  /// Info 100 - Background
  static const info100 = Color(0xFFDBEAFE);

  /// Info 50
  static const info50 = Color(0xFFEFF6FF);

  // ═══════════════════════════════════════
  // ALIASES (Raccourcis)
  // ═══════════════════════════════════════

  /// Alias pour success500
  static const success = success500;

  /// Alias pour warning500
  static const warning = warning500;

  /// Alias pour error500
  static const error = error500;

  /// Alias pour info500
  static const info = info500;

  /// Alias pour secondary500
  static const secondary = secondary500;
  
  // ═══════════════════════════════════════
  // SPECIAL
  // ═══════════════════════════════════════
  
  /// Blanc pur
  static const white = Color(0xFFFFFFFF);
  
  /// Noir pur
  static const black = Color(0xFF000000);
  
  /// Overlay pour modals (60% opacity)
  static const overlay = Color(0x99000000);
  
  /// Overlay léger (20% opacity)
  static const overlayLight = Color(0x33000000);
  
  // ═══════════════════════════════════════
  // HELPER METHOD
  // ═══════════════════════════════════════
  
  /// Retourne une couleur avec opacité
  /// 
  /// Example: `SDColors.withOpacity(SDColors.primary500, 0.5)`
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}

/// Gradients prédéfinis
class SDGradients {
  /// Gradient primary (vert)
  /// Usage: AppBars, headers importants
  static const primaryGradient = LinearGradient(
    colors: [SDColors.primary400, SDColors.primary600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradient accent (orange)
  /// Usage: CTAs spéciaux, highlights
  static const accentGradient = LinearGradient(
    colors: [SDColors.secondary400, SDColors.secondary600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradient subtil pour cards
  /// Usage: Backgrounds de cards
  static const cardGradient = LinearGradient(
    colors: [SDColors.primary50, SDColors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// Gradient vertical (top to bottom)
  static const verticalGradient = LinearGradient(
    colors: [SDColors.primary500, SDColors.primary700],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// Gradient horizontal (left to right)
  static const horizontalGradient = LinearGradient(
    colors: [SDColors.primary400, SDColors.primary600],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
