import 'package:flutter/material.dart';
import '../colors.dart';
import '../spacing.dart';
import '../animations.dart';

/// Card standardisée Soutrali Deals
/// 
/// **Utilisation:**
/// ```dart
/// SDCard(
///   onTap: () => navigateToDetails(),
///   child: Column(
///     children: [
///       Text('Titre', style: SDTypography.titleMedium),
///       Text('Description', style: SDTypography.bodyMedium),
///     ],
///   ),
/// )
/// ```
class SDCard extends StatefulWidget {
  /// Contenu de la card
  final Widget child;
  
  /// Callback au tap
  final VoidCallback? onTap;
  
  /// Padding personnalisé
  final EdgeInsetsGeometry? padding;
  
  /// Margin personnalisé
  final EdgeInsetsGeometry? margin;
  
  /// Couleur de fond
  final Color? backgroundColor;
  
  /// Élévation de la shadow
  final double elevation;
  
  /// Border radius
  final double? borderRadius;
  
  /// Border color (optionnel)
  final Color? borderColor;
  
  /// Border width
  final double borderWidth;
  
  /// Afficher hover effect
  final bool showHoverEffect;
  
  const SDCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation = 2,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 0,
    this.showHoverEffect = true,
  });
  
  @override
  State<SDCard> createState() => _SDCardState();
}

class _SDCardState extends State<SDCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  
  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? SDSpacing.borderRadiusLarge;
    
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _isPressed = false)
          : null,
      child: MouseRegion(
        onEnter: widget.showHoverEffect
            ? (_) => setState(() => _isHovered = true)
            : null,
        onExit: widget.showHoverEffect
            ? (_) => setState(() => _isHovered = false)
            : null,
        child: AnimatedContainer(
          duration: SDAnimations.short,
          curve: SDAnimations.emphasized,
          margin: widget.margin,
          transform: _isPressed
              ? (Matrix4.identity()..scale(0.98))
              : (_isHovered
                  ? (Matrix4.identity()..translate(0.0, -2.0, 0.0))
                  : Matrix4.identity()),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? SDColors.white,
            borderRadius: BorderRadius.circular(radius),
            border: widget.borderColor != null
                ? Border.all(
                    color: widget.borderColor!,
                    width: widget.borderWidth,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: SDColors.neutral900.withOpacity(
                  _isHovered ? 0.15 : 0.08,
                ),
                blurRadius: _isHovered ? 12 : widget.elevation * 2,
                offset: Offset(0, _isHovered ? 4 : widget.elevation),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(radius),
              splashColor: SDColors.primary100,
              highlightColor: SDColors.primary50,
              child: Padding(
                padding: widget.padding ?? SDSpacing.cardPadding,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card avec gradient
class SDGradientCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient gradient;
  final double? borderRadius;
  
  const SDGradientCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.gradient = const LinearGradient(
      colors: [SDColors.primary400, SDColors.primary600],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? SDSpacing.borderRadiusLarge;
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: SDColors.primary500.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: padding ?? SDSpacing.cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Card compacte pour listes
class SDListTileCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  
  const SDListTileCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return SDCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SDSpacing.sm,
        vertical: SDSpacing.xs,
      ),
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SDSpacing.horizontalDefaultGap,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: SDColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SDSpacing.horizontalDefaultGap,
            trailing!,
          ],
        ],
      ),
    );
  }
}
