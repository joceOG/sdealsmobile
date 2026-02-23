import 'package:flutter/material.dart';
import '../colors.dart';
import '../typography.dart';
import '../spacing.dart';
import '../animations.dart';

/// Type de bouton
enum SDButtonType {
  /// Bouton primary avec fond vert
  primary,
  
  /// Bouton secondary avec fond orange
  secondary,
  
  /// Bouton outlined avec bordure
  outlined,
  
  /// Bouton text sans fond
  text,
}

/// Taille du bouton
enum SDButtonSize {
  /// Large - 56px height
  large,
  
  /// Medium - 48px height
  medium,
  
  /// Small - 40px height
  small,
}

/// Bouton standardisé Soutrali Deals
/// 
/// **Utilisation:**
/// ```dart
/// SDButton(
///   text: 'Ajouter au panier',
///   icon: Icons.shopping_cart,
///   onPressed: () => addToCart(),
/// )
/// ```
class SDButton extends StatefulWidget {
  /// Texte du bouton
  final String text;
  
  /// Callback au clic
  final VoidCallback? onPressed;
  
  /// Type de bouton
  final SDButtonType type;
  
  /// Taille du bouton
  final SDButtonSize size;
  
  /// Icône (optionnel)
  final IconData? icon;
  
  /// Position de l'icône
  final bool iconRight;
  
  /// État de chargement
  final bool isLoading;
  
  /// Prend toute la largeur
  final bool fullWidth;
  
  const SDButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = SDButtonType.primary,
    this.size = SDButtonSize.large,
    this.icon,
    this.iconRight = false,
    this.isLoading = false,
    this.fullWidth = false,
  });
  
  @override
  State<SDButton> createState() => _SDButtonState();
}

class _SDButtonState extends State<SDButton> {
  bool _isPressed = false;
  
  double get _buttonHeight {
    switch (widget.size) {
      case SDButtonSize.large:
        return SDSpacing.buttonHeight;
      case SDButtonSize.medium:
        return SDSpacing.buttonHeightCompact;
      case SDButtonSize.small:
        return 40.0;
    }
  }
  
  double get _fontSize {
    switch (widget.size) {
      case SDButtonSize.large:
        return 16;
      case SDButtonSize.medium:
        return 14;
      case SDButtonSize.small:
        return 12;
    }
  }
  
  double get _iconSize {
    switch (widget.size) {
      case SDButtonSize.large:
        return 20;
      case SDButtonSize.medium:
        return 18;
      case SDButtonSize.small:
        return 16;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final content = widget.isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.type == SDButtonType.outlined || widget.type == SDButtonType.text
                    ? SDColors.primary600
                    : SDColors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null && !widget.iconRight) ...[
                Icon(widget.icon, size: _iconSize),
                const SizedBox(width: SDSpacing.xxs),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.icon != null && widget.iconRight) ...[
                const SizedBox(width: SDSpacing.xxs),
                Icon(widget.icon, size: _iconSize),
              ],
            ],
          );
    
    Widget button;
    
    switch (widget.type) {
      case SDButtonType.primary:
        button = ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          onLongPress: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: SDColors.primary600,
            foregroundColor: SDColors.white,
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == SDButtonSize.small
                  ? SDSpacing.sm
                  : SDSpacing.md,
            ),
            minimumSize: Size(
              widget.fullWidth ? double.infinity : 120,
              _buttonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            ),
            elevation: 2,
            shadowColor: SDColors.primary600.withOpacity(0.3),
          ),
          child: content,
        );
        break;
        
      case SDButtonType.secondary:
        button = ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: SDColors.secondary500,
            foregroundColor: SDColors.white,
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == SDButtonSize.small
                  ? SDSpacing.sm
                  : SDSpacing.md,
            ),
            minimumSize: Size(
              widget.fullWidth ? double.infinity : 120,
              _buttonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            ),
            elevation: 2,
            shadowColor: SDColors.secondary500.withOpacity(0.3),
          ),
          child: content,
        );
        break;
        
      case SDButtonType.outlined:
        button = OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: SDColors.primary600,
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == SDButtonSize.small
                  ? SDSpacing.sm
                  : SDSpacing.md,
            ),
            minimumSize: Size(
              widget.fullWidth ? double.infinity : 120,
              _buttonHeight,
            ),
            side: const BorderSide(color: SDColors.primary600, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
            ),
          ),
          child: content,
        );
        break;
        
      case SDButtonType.text:
        button = TextButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: SDColors.primary600,
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == SDButtonSize.small
                  ? SDSpacing.sm
                  : SDSpacing.md,
            ),
            minimumSize: Size(
              widget.fullWidth ? double.infinity : 120,
              _buttonHeight,
            ),
          ),
          child: content,
        );
        break;
    }
    
    // Wrap avec animation de press
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: SDAnimations.ultraShort,
        curve: SDAnimations.emphasized,
        child: widget.fullWidth
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}
