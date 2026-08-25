import 'package:flutter/material.dart';
import '../colors.dart';
import '../typography.dart';
import 'sd_app_bar_icon_button.dart';

/// AppBar blanche (charte Freelance / commandes / marketplace).
///
/// Fond blanc, texte [neutral900], séparateur fin en bas (sauf si [bottom] fourni).
class SDWhiteAppBar {
  SDWhiteAppBar._();

  static PreferredSizeWidget appBar({
    String? title,
    Widget? titleWidget,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    bool centerTitle = false,
    PreferredSizeWidget? bottom,
    Color? backgroundColor,
    double? toolbarHeight,
    /// Style personnalisé pour le titre. Par défaut `displayMedium` (28sp).
    /// Utiliser `SDTypography.titleLarge` pour les titres longs.
    TextStyle? titleStyle,
  }) {
    assert(
      title != null || titleWidget != null,
      'SDWhiteAppBar.appBar: fournir title ou titleWidget',
    );

    final Widget effectiveTitle = titleWidget ??
        Text(
          title!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (titleStyle ?? SDTypography.displayMedium).copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w700,
          ),
        );

    final resolvedBottom = bottom ??
        PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: SDColors.neutral200),
        );

    return SDAppBarIconThemed(
      style: SDAppBarIconStyles.onLightSurface,
      bar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: toolbarHeight ?? 64,
        titleSpacing: 20,
        backgroundColor: backgroundColor ?? SDColors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: SDColors.neutral900,
        iconTheme: const IconThemeData(color: SDColors.neutral900, size: 22),
        actionsIconTheme:
            const IconThemeData(color: SDColors.neutral900, size: 22),
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: leading,
        centerTitle: centerTitle,
        title: effectiveTitle,
        actions: actions,
        bottom: resolvedBottom,
      ),
    );
  }
}
