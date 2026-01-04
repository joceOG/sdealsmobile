import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String? placeholderAsset; // Asset local si null ou erreur
  final Color? color; // Pour les icônes colorées
  final BlendMode? colorBlendMode;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholderAsset,
    this.color,
    this.colorBlendMode,
  });

  @override
  Widget build(BuildContext context) {
    // Si l'URL est vide ou invalide, afficher placeholder
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        color: color,
        colorBlendMode: colorBlendMode,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
        fadeInDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: placeholderAsset != null
            ? Image.asset(
                placeholderAsset!,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) => _buildErrorIcon(),
              )
            : _buildErrorIcon(),
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade400,
        size: (width != null && width! < 40) ? 16 : 24,
      ),
    );
  }
}
