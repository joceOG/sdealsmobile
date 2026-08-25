import 'package:flutter/material.dart';
import '../colors.dart';

/// Styles d’[IconButton] pour les barres d’outils (AppBar, etc.).
abstract final class SDAppBarIconStyles {
  /// Fond clair (AppBar blanche / surface claire).
  /// Zone de tap : 48×48 dp (Android Material guideline).
  /// Visuel icône : 22 dp, disque 40 dp rendu par padding interne.
  static ButtonStyle onLightSurface = IconButton.styleFrom(
    foregroundColor: SDColors.neutral900,
    backgroundColor: SDColors.neutral100,
    padding: const EdgeInsets.all(8),
    minimumSize: const Size(48, 48),
    maximumSize: const Size(48, 48),
    // tapTargetSize par défaut (padded) → zone interactive ≥ 48×48 dp.
    iconSize: 22,
    shape: const CircleBorder(
      side: BorderSide(color: SDColors.neutral200, width: 1),
    ),
  );

  /// Fond primary / dégradé vert (icônes blanches).
  static ButtonStyle onPrimary = IconButton.styleFrom(
    foregroundColor: SDColors.white,
    backgroundColor: SDColors.white.withOpacity(0.18),
    padding: const EdgeInsets.all(8),
    minimumSize: const Size(48, 48),
    maximumSize: const Size(48, 48),
    iconSize: 22,
    shape: CircleBorder(
      side: BorderSide(color: SDColors.white.withOpacity(0.35), width: 1),
    ),
  );
}

/// Applique [style] aux [IconButton] sous une [AppBar] sans utiliser le paramètre
/// [AppBar.iconButtonTheme] (absent sur Flutter &lt; 3.22).
class SDAppBarIconThemed extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget bar;
  final ButtonStyle style;

  const SDAppBarIconThemed({
    super.key,
    required this.bar,
    required this.style,
  });

  @override
  Size get preferredSize => bar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        iconButtonTheme: IconButtonThemeData(style: style),
      ),
      child: bar as Widget,
    );
  }
}

/// Bouton d’action AppBar avec le style disque standard (surface claire).
class SDAppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final ButtonStyle? style;

  const SDAppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: style ?? SDAppBarIconStyles.onLightSurface,
    );
  }
}
