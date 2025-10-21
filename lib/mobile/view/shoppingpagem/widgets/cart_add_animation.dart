import 'package:flutter/material.dart';

/// 🎬 Widget d'animation "Ajout au panier" avec effet de vol
///
/// Affiche une animation où l'icône du produit "vole" vers l'icône du panier
class CartAddAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onComplete;
  final GlobalKey cartIconKey; // Clé globale de l'icône panier cible

  const CartAddAnimation({
    super.key,
    required this.child,
    required this.cartIconKey,
    this.onComplete,
  });

  @override
  State<CartAddAnimation> createState() => _CartAddAnimationState();
}

class _CartAddAnimationState extends State<CartAddAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animation d'échelle : grossit puis rétrécit
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_controller);

    // Animation d'opacité : visible puis disparaît
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_controller);

    // Lancer l'animation et appeler le callback à la fin
    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// 🌟 Effet de pulsation pour le badge du panier
class CartBadgePulse extends StatefulWidget {
  final Widget child;

  const CartBadgePulse({super.key, required this.child});

  @override
  State<CartBadgePulse> createState() => _CartBadgePulseState();
}

class _CartBadgePulseState extends State<CartBadgePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// 🎯 Méthode utilitaire pour afficher une animation d'ajout au panier
///
/// Affiche une icône qui "vole" vers le panier dans l'AppBar
void showAddToCartAnimation({
  required BuildContext context,
  required Offset startPosition,
  required GlobalKey cartIconKey,
}) {
  // Récupérer la position du panier
  final RenderBox? cartBox =
      cartIconKey.currentContext?.findRenderObject() as RenderBox?;
  if (cartBox == null) return;

  final cartPosition = cartBox.localToGlobal(Offset.zero);

  // Créer un overlay pour l'animation
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return TweenAnimationBuilder<Offset>(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        tween: Tween<Offset>(
          begin: startPosition,
          end: cartPosition,
        ),
        builder: (context, offset, child) {
          return Positioned(
            left: offset.dx,
            top: offset.dy,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween<double>(begin: 1.0, end: 0.0),
              curve: Curves.easeIn,
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
              onEnd: () {
                // Supprimer l'overlay à la fin de l'animation
                overlayEntry.remove();
              },
            ),
          );
        },
      );
    },
  );

  overlay.insert(overlayEntry);
}




