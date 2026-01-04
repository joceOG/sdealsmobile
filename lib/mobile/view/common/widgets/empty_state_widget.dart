import 'package:flutter/material.dart';

/// Widget d'état vide réutilisable avec illustration, titre, message et action optionnelle
/// 
/// Utilisé pour afficher des écrans vides de manière engageante et cohérente
/// à travers toute l'application.
class EmptyStateWidget extends StatelessWidget {
  /// Chemin de l'asset d'illustration (ex: 'assets/panier_vide.png')
  final String imagePath;
  
  /// Titre principal affiché sous l'illustration
  final String title;
  
  /// Message descriptif/encouragement
  final String message;
  
  /// Widget d'action optionnel (ex: bouton "Découvrir" ou "Rafraîchir")
  final Widget? action;
  
  /// Taille de l'illustration (par défaut 200x200)
  final double imageSize;

  const EmptyStateWidget({
    super.key,
    required this.imagePath,
    required this.title,
    required this.message,
    this.action,
    this.imageSize = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Image.asset(
              imagePath,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si l'image ne charge pas
                return Icon(
                  Icons.inbox_outlined,
                  size: imageSize * 0.6,
                  color: Colors.grey.shade300,
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Titre
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Action (bouton optionnel)
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
