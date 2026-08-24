/// STAB-12B — Affichage sûr de textes / noms / médias partiels.
///
/// Évite les interpolations Dart du type `'$prenom $nom'` quand [prenom] est
/// `null` (ce qui produit littéralement « null alice »).

/// Nettoie une partie de texte affichable.
/// Retourne `null` si absente, vide, espaces seuls, ou littéraux « null » / « undefined ».
String? cleanDisplayPart(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  final lower = s.toLowerCase();
  if (lower == 'null' || lower == 'undefined') return null;
  return s;
}

/// Joint prénom + nom sans jamais exposer « null ».
///
/// Exemples :
/// - Alice + Dupont → « Alice Dupont »
/// - null + alice → « alice »
/// - Alice + null → « Alice »
/// - null + null → [fallback]
String joinPersonName({
  dynamic prenom,
  dynamic nom,
  String fallback = 'Utilisateur',
}) {
  final parts = <String>[
    if (cleanDisplayPart(prenom) != null) cleanDisplayPart(prenom)!,
    if (cleanDisplayPart(nom) != null) cleanDisplayPart(nom)!,
  ];
  if (parts.isEmpty) return fallback;
  return parts.join(' ');
}

/// Découpe saisie « Prénom Nom… » (legacy champ unique) → champs API.
/// - 1 mot → [nom] uniquement (mononyme)
/// - 2+ mots → prénom = 1er mot, nom = reste
({String nom, String? prenom}) splitPersonNameInput(String input) {
  final parts =
      input.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return (nom: '', prenom: null);
  if (parts.length == 1) return (nom: parts.first, prenom: null);
  return (nom: parts.sublist(1).join(' '), prenom: parts.first);
}

/// Nom depuis une map utilisateur (API).
String personNameFromMap(
  Map<String, dynamic>? user, {
  String fallback = 'Utilisateur',
}) {
  if (user == null) return fallback;
  return joinPersonName(
    prenom: user['prenom'],
    nom: user['nom'],
    fallback: fallback,
  );
}

/// Texte optionnel pour UI (métier, ville, description…).
String displayOrFallback(dynamic value, String fallback) {
  return cleanDisplayPart(value) ?? fallback;
}

/// URL image affichable, ou `null` → placeholder (jamais charger « null »).
String? safeImageUrl(dynamic value) {
  final cleaned = cleanDisplayPart(value);
  if (cleaned == null) return null;
  if (cleaned.startsWith('https://') || cleaned.startsWith('http://')) {
    return cleaned;
  }
  if (cleaned.startsWith('//')) return 'https:$cleaned';
  // Asset local éventuel
  if (cleaned.startsWith('assets/')) return cleaned;
  return null;
}

/// Note absente → `null` (UI : « Pas encore noté »), pas de faux 0.0 forcé.
String? formatOptionalRating(dynamic note, {dynamic reviewCount}) {
  if (note == null) return null;
  final n = note is num
      ? note.toDouble()
      : double.tryParse(note.toString().replaceAll(',', '.').trim());
  if (n == null || n <= 0) return null;
  final reviews = reviewCount is num
      ? reviewCount.toInt()
      : int.tryParse(reviewCount?.toString() ?? '');
  if (reviews != null && reviews > 0) {
    return '${n.toStringAsFixed(1)} ($reviews avis)';
  }
  return n.toStringAsFixed(1);
}

/// Prix absent / ≤0 → `null` (UI : « Sur devis » / « Prix non renseigné »).
String? formatOptionalPrice(
  dynamic price, {
  String suffix = 'FCFA',
  String? perUnit,
}) {
  if (price == null) return null;
  final n = price is num
      ? price.toDouble()
      : double.tryParse(price.toString().replaceAll(',', '.').trim());
  if (n == null || n <= 0) return null;
  final base = '${n.toStringAsFixed(0)} $suffix';
  if (perUnit != null && perUnit.isNotEmpty) return '$base$perUnit';
  return base;
}

/// Vrai si une chaîne d'UI contient encore le littéral « null » (tests).
bool containsLiteralNull(String? text) {
  if (text == null || text.isEmpty) return false;
  return RegExp(r'(^|\s)null(\s|$)', caseSensitive: false).hasMatch(text);
}
