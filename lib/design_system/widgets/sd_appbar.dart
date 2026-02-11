import 'package:flutter/material.dart';
import '../colors.dart';
import '../typography.dart';
import '../spacing.dart';

/// AppBar standardisée Soutrali Deals
/// Hauteur: 56px (standard Material Design)
/// 
/// **Utilisation:**
/// ```dart
/// Scaffold(
///   appBar: SDAppBar(
///     title: 'Mes Commandes',
///     showSearch: true,
///     onSearch: () => context.go('/search'),
///   ),
/// )
/// ```
class SDAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Titre de la page
  final String title;
  
  /// Actions personnalisées à droite
  final List<Widget>? actions;
  
  /// Afficher le bouton retour
  final bool showBackButton;
  
  /// Callback custom pour le bouton retour
  final VoidCallback? onBackPressed;
  
  /// Afficher le bouton search
  final bool showSearch;
  
  /// Callback search
  final VoidCallback? onSearch;
  
  /// Utiliser un gradient (par défaut: true)
  final bool useGradient;
  
  /// Couleur de fond si gradient désactivé
  final Color? backgroundColor;
  
  /// Centrer le titre
  final bool centerTitle;
  
  /// Leading widget custom (remplace le back button)
  final Widget? leading;
  
  const SDAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.showSearch = false,
    this.onSearch,
    this.useGradient = true,
    this.backgroundColor,
    this.centerTitle = true,
    this.leading,
  });
  
  @override
  Size get preferredSize => const Size.fromHeight(SDSpacing.appBarHeight);
  
  @override
  Widget build(BuildContext context) {
    // Actions list
    final List<Widget> appBarActions = [];
    
    // Add search if needed
    if (showSearch && onSearch != null) {
      appBarActions.add(
        IconButton(
          icon: const Icon(Icons.search, size: 24, color: SDColors.white),
          onPressed: onSearch,
          tooltip: 'Rechercher',
        ),
      );
    }
    
    // Add custom actions
    if (actions != null) {
      appBarActions.addAll(actions!);
    }
    
    // Leading widget
    Widget? leadingWidget;
    if (leading != null) {
      leadingWidget = leading;
    } else if (showBackButton && Navigator.of(context).canPop()) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back, size: 24, color: SDColors.white),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        tooltip: 'Retour',
      );
    }
    
    return Container(
      decoration: useGradient
          ? const BoxDecoration(
              gradient: LinearGradient(
                colors: [SDColors.primary400, SDColors.primary600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x331CBF3F), // primary500 @ 20%
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            )
          : BoxDecoration(
              color: backgroundColor ?? SDColors.primary500,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x331CBF3F),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: centerTitle,
        leading: leadingWidget,
        title: Text(
          title,
          style: SDTypography.titleLarge.copyWith(
            color: SDColors.white,
          ),
        ),
        actions: appBarActions.isNotEmpty ? appBarActions : null,
      ),
    );
  }
}

/// AppBar avec search bar intégrée
/// Hauteur: 110px (+ search bar)
class SDAppBarWithSearch extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TextEditingController? searchController;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final List<Widget>? actions;
  
  const SDAppBarWithSearch({
    super.key,
    required this.title,
    this.searchController,
    this.searchHint = 'Rechercher...',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.actions,
  });
  
  @override
  Size get preferredSize => const Size.fromHeight(110);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [SDColors.primary400, SDColors.primary600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SDSpacing.sm,
            vertical: SDSpacing.xxs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: SDTypography.titleLarge.copyWith(
                        color: SDColors.white,
                      ),
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
              SDSpacing.verticalTinyGap,
              // Search bar
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  onSubmitted: (value) => onSearchSubmitted?.call(),
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: searchHint,
                    hintStyle: SDTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: SDColors.white,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: SDSpacing.sm,
                      vertical: SDSpacing.xs,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
