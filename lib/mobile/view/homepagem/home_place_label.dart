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

/// Une carte entière et un aperçu régulier de la suivante. Jamais un troisième fragment.
class NearbyCarouselMetrics {
  static const double peek = 40;

  static double cardWidth(double screenWidth) {
    final viewport = screenWidth - 16 * 2;
    final width = viewport - peek - 12;
    if (width < 160) return viewport;
    return width;
  }

  static bool showsRegularPeek(double screenWidth) {
    final viewport = screenWidth - 32;
    final card = cardWidth(screenWidth);
    final visibleFragment = viewport - card - 12;
    return visibleFragment >= 32 && visibleFragment <= 48;
  }
}
