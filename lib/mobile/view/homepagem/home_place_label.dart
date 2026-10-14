/// Libellés de lieu pour l'accueil. Aucune donnée inventée, aucune coordonnée brute.
bool looksLikeRawCoordinates(String value) {
  final raw = value.trim();
  if (raw.isEmpty) return false;
  final lower = raw.toLowerCase();
  if (lower.startsWith('gps')) return true;
  if (raw.startsWith('[') || raw.startsWith('{')) return true;

  final pair = RegExp(r'-?\d{1,3}[.,]\d+\s*,\s*-?\d{1,3}[.,]\d+');
  if (pair.hasMatch(raw)) return true;
  return false;
}

bool _isBlankPlace(String value) {
  final lower = value.trim().toLowerCase();
  return lower.isEmpty ||
      lower == 'null' ||
      lower == 'n/a' ||
      lower == 'na' ||
      lower == 'undefined' ||
      lower == 'adresse non renseignée';
}

/// Premier lieu humain. Les coordonnées et les placeholders sont ignorés.
String? firstReadablePlace(Iterable<String?> candidates) {
  for (final candidate in candidates) {
    if (candidate == null) continue;
    final value = candidate.trim();
    if (_isBlankPlace(value) || looksLikeRawCoordinates(value)) continue;
    return value;
  }
  return null;
}

/// Deux cartes portrait entières + aperçu de la troisième.
class NearbyCarouselMetrics {
  /// Fragment visible de la 3ème carte (aperçu constant).
  static const double peek = 24;

  /// Espacement entre cartes.
  static const double gap = 12;

  /// Largeur d'une carte : 2 cartes + 1 gap + peek tiennent dans la viewport.
  static double cardWidth(double screenWidth) {
    final viewport = screenWidth - 16 * 2;
    final w = (viewport - gap - peek) / 2;
    if (w < 100) return viewport; // écran extrêmement étroit
    return w;
  }

  /// Vérifie que le fragment visible de la 3ème carte est raisonnable.
  static bool showsRegularPeek(double screenWidth) {
    final viewport = screenWidth - 32;
    final card = cardWidth(screenWidth);
    final visibleFragment = viewport - 2 * card - gap;
    return visibleFragment >= 16 && visibleFragment <= 36;
  }
}
