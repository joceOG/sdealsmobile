import 'package:flutter/material.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/data/utils/string_list_normalizer.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:sdealsmobile/mobile/view/homepagem/home_place_label.dart';

/// Carte prestataire verticale : photo plein-format en haut,
/// informations compactes en bas. Utilisée dans Explorer (grille 2 colonnes)
/// et l'accueil (carrousel horizontal).
///
/// Règles données :
/// - Jamais d'étoile 0.0 : [note] null ou ≤ 0 → section note masquée.
/// - Jamais "0 FCFA" : [tarifLabel] null → non affiché.
/// - Jamais de coordonnées GPS : [location] doit être une ville/commune lisible.
/// - Photo publique uniquement : passer null pour masquer proprement.
class ProviderPhotoCard extends StatelessWidget {
  final String name;
  final String? metier;
  final String? photoUrl;

  /// Note /5. Null ou ≤ 0 → masquée.
  final double? note;

  /// Tarif pré-formaté (ex. "15 000 FCFA"). Null → non affiché.
  final String? tarifLabel;

  /// Ville/commune lisible. Null → non affiché.
  final String? location;

  final bool verified;
  final bool isFavorited;
  final VoidCallback onTap;

  /// Null → bouton favori non affiché.
  final VoidCallback? onFavoriteTap;

  /// Largeur explicite pour le carrousel. Null → prend la largeur du parent (grille).
  final double? width;

  const ProviderPhotoCard({
    super.key,
    required this.name,
    required this.onTap,
    this.metier,
    this.photoUrl,
    this.note,
    this.tarifLabel,
    this.location,
    this.verified = false,
    this.isFavorited = false,
    this.onFavoriteTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final card = _CardBody(
      name: name,
      metier: metier,
      photoUrl: photoUrl,
      note: note,
      tarifLabel: tarifLabel,
      location: location,
      verified: verified,
      isFavorited: isFavorited,
      onTap: onTap,
      onFavoriteTap: onFavoriteTap,
    );
    if (width != null) return SizedBox(width: width, child: card);
    return card;
  }
}

class _CardBody extends StatelessWidget {
  final String name;
  final String? metier;
  final String? photoUrl;
  final double? note;
  final String? tarifLabel;
  final String? location;
  final bool verified;
  final bool isFavorited;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;

  const _CardBody({
    required this.name,
    required this.onTap,
    this.metier,
    this.photoUrl,
    this.note,
    this.tarifLabel,
    this.location,
    this.verified = false,
    this.isFavorited = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasNote = note != null && note! > 0;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Semantics(
      button: true,
      label: 'Profil de $name${metier != null ? ', $metier' : ''}',
      child: Material(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
              border: Border.all(color: SDColors.neutral200),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Zone photo — Expanded pour remplir l'espace dans la grille
                // sans dépasser la hauteur de la cellule.
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photo publique ou initiale
                      photoUrl != null && photoUrl!.isNotEmpty
                          ? AppImage(
                              imageUrl: photoUrl!,
                              fit: BoxFit.cover,
                            )
                          : ColoredBox(
                              color: SDColors.primary50,
                              child: Center(
                                child: Text(
                                  initial,
                                  style: SDTypography.titleLarge.copyWith(
                                    color: SDColors.primary600,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 28,
                                  ),
                                ),
                              ),
                            ),
                      // Badge vérifié
                      if (verified)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SDColors.primary600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded,
                                    size: 10, color: SDColors.white),
                                const SizedBox(width: 3),
                                Text(
                                  'Vérifié',
                                  style: SDTypography.labelSmall.copyWith(
                                    color: SDColors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Bouton favori
                      if (onFavoriteTap != null)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Semantics(
                            button: true,
                            label: isFavorited
                                ? 'Retirer des favoris'
                                : 'Ajouter aux favoris',
                            child: GestureDetector(
                              onTap: onFavoriteTap,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: SDColors.white
                                      .withValues(alpha: 0.88),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  isFavorited
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 17,
                                  color: isFavorited
                                      ? SDColors.primary600
                                      : SDColors.neutral500,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // ── Infos prestataire ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nom
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                          height: 1.25,
                        ),
                      ),
                      // Métier en vert Soutrali
                      if (metier != null && metier!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          metier!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.primary600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      // Tarif + note sur la même ligne
                      if (tarifLabel != null || hasNote) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (tarifLabel != null) ...[
                              Text(
                                tarifLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.neutral700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (hasNote) const Spacer(),
                            ],
                            if (hasNote) ...[
                              if (tarifLabel == null) const Spacer(),
                              Icon(Icons.star_rounded,
                                  size: 13, color: SDColors.warning500),
                              const SizedBox(width: 2),
                              Text(
                                note!.toStringAsFixed(1),
                                style: SDTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: SDColors.neutral700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      // Localisation
                      if (location != null && location!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 11, color: SDColors.neutral400),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                location!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.neutral500,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper — construit un [ProviderPhotoCard] depuis un [Map] brut API.
/// Utilisé par l'accueil (endpoint home-preview retournant des Maps).
class ProviderPhotoCardFromMap extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isFavorited;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final double? width;

  const ProviderPhotoCardFromMap({
    super.key,
    required this.data,
    required this.onTap,
    this.isFavorited = false,
    this.onFavoriteTap,
    this.width,
  });

  static String? _tarifLabel(Map<String, dynamic> p) {
    double? v;
    final raw = p['prixprestataire'];
    if (raw is num) v = raw.toDouble();
    if (v == null || v <= 0) return null;
    final digits = v.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('\u00a0');
      buf.write(digits[i]);
    }
    return '${buf.toString()} FCFA';
  }

  static double? _note(Map<String, dynamic> p) {
    final raw = p['note'];
    if (raw is num) {
      final v = raw.toDouble();
      return v > 0 ? v : null;
    }
    if (raw is String) {
      final v = double.tryParse(raw.replaceAll(',', '.'));
      return (v != null && v > 0) ? v : null;
    }
    return null;
  }

  static String? _location(Map<String, dynamic> p) {
    final zones = normalizeStringList(p['zoneIntervention']);
    return firstReadablePlace([
      p['commune']?.toString(),
      p['quartier']?.toString(),
      p['ville']?.toString(),
      ...zones,
      p['localisation']?.toString(),
      p['adresse']?.toString(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = data['utilisateur'] is Map
        ? Map<String, dynamic>.from(data['utilisateur'] as Map)
        : const <String, dynamic>{};

    // Nom
    final prenom = utilisateur['prenom']?.toString().trim() ?? '';
    final nom = utilisateur['nom']?.toString().trim() ?? '';
    final parts = [prenom, nom].where((s) => s.isNotEmpty);
    final name =
        parts.isEmpty ? 'Prestataire' : parts.join(' ');

    // Métier
    final svc = data['service'];
    String? metier;
    if (svc is Map) {
      metier = svc['nomservice']?.toString().trim();
      if (metier != null && metier.isEmpty) metier = null;
    }

    // Photo publique
    final photoProfil = utilisateur['photoProfil']?.toString();
    final String? photoUrl = (photoProfil != null &&
            photoProfil.isNotEmpty &&
            photoProfil.startsWith('http'))
        ? photoProfil
        : null;

    return ProviderPhotoCard(
      name: name,
      metier: metier,
      photoUrl: photoUrl,
      note: _note(data),
      tarifLabel: _tarifLabel(data),
      location: _location(data),
      verified: data['verifier'] == true,
      isFavorited: isFavorited,
      onTap: onTap,
      onFavoriteTap: onFavoriteTap,
      width: width,
    );
  }
}
