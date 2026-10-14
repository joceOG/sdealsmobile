/// STAB-12B — Affichage sûr de textes / noms / médias partiels.
///
/// Évite les interpolations Dart du type `'$prenom $nom'` quand [prenom] est
/// `null` (ce qui produit littéralement « null alice »).

/// Nettoie une partie de texte affichable.
/// Retourne `null` si absente, vide, espaces seuls, ou littéraux « null » / « undefined ».
String? cleanDisplayPart(dynamic value) {
  if (value == null) return null;
  if (value is Map || value is Iterable) return null;
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
  if (value is bool) return null;
  final cleaned = cleanDisplayPart(value);
  if (cleaned == null) return null;
  final lower = cleaned.toLowerCase();
  if (lower == 'true' || lower == 'false') return null;
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

/// Tarif carte Explorateur / Métiers.
///
/// [marker] tient sur la pastille. [sheet] est le libellé de la mini-fiche.
/// `prixprestataire` n’a pas d’unité. `/h` seulement si le montant vient de
/// `tarifHoraireMin`.
class ProviderPriceCopy {
  const ProviderPriceCopy({required this.marker, required this.sheet});

  final String marker;
  final String sheet;
}

ProviderPriceCopy providerPriceCopy({
  required num? prixprestataire,
  num? tarifHoraireMin,
}) {
  final base = prixprestataire?.toDouble() ?? 0;
  if (base > 0) {
    final grouped = _groupThousands(base.round());
    return ProviderPriceCopy(marker: '$grouped F', sheet: '$grouped FCFA');
  }
  final hourly = tarifHoraireMin?.toDouble() ?? 0;
  if (hourly > 0) {
    final grouped = _groupThousands(hourly.round());
    return ProviderPriceCopy(
      marker: '$grouped F/h',
      sheet: 'À partir de $grouped FCFA/h',
    );
  }
  return const ProviderPriceCopy(marker: 'Devis', sheet: 'Sur devis');
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
  final grouped = _groupThousands(n.round());
  final base = '$grouped $suffix';
  if (perUnit != null && perUnit.isNotEmpty) return '$base$perUnit';
  return base;
}

String _groupThousands(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u00A0');
    buf.write(s[i]);
  }
  final out = buf.toString();
  return value < 0 ? '-$out' : out;
}

/// Titre lisible d'une prestation (évite `.toString()` sur l'objet Service).
String prestationServiceTitle(Map<String, dynamic> mission) {
  final titre = cleanDisplayPart(mission['titre']);
  if (titre != null) return titre;
  final service = mission['service'];
  if (service is Map) {
    final fromService = cleanDisplayPart(
      service['nomservice'] ?? service['nom'] ?? service['name'],
    );
    if (fromService != null) return fromService;
  }
  final typeService = cleanDisplayPart(mission['typeService']);
  if (typeService != null) return typeService;
  return 'Mission';
}

/// Lieu court (ville ou adresse) pour cartes liste.
String prestationLocationLabel(Map<String, dynamic> mission) {
  final ville = cleanDisplayPart(mission['ville']);
  if (ville != null) return ville;
  final adresse = cleanDisplayPart(mission['adresse']);
  if (adresse != null) return adresse;
  final loc = mission['localisation'];
  if (loc is Map) {
    final fromMap = cleanDisplayPart(
      loc['commune'] ?? loc['ville'] ?? loc['adresse'],
    );
    if (fromMap != null) return fromMap;
  }
  final lieu = cleanDisplayPart(mission['lieu']);
  if (lieu != null) return lieu;
  return 'Lieu à préciser';
}

/// Nom du client sur une prestation.
String prestationClientName(
  Map<String, dynamic> mission, {
  String fallback = 'Client',
}) {
  final u = mission['utilisateur'];
  if (u is Map) {
    return personNameFromMap(Map<String, dynamic>.from(u), fallback: fallback);
  }
  return fallback;
}

/// Libellé métier prestataire depuis le document API.
String prestataireMetierLabel(Map<String, dynamic>? doc) {
  if (doc == null) return 'Prestataire';
  final service = doc['service'];
  if (service is Map) {
    final name = cleanDisplayPart(
      service['nomservice'] ?? service['nom'] ?? service['name'],
    );
    if (name != null) return name;
  }
  dynamic raw = doc['metier'];
  if (raw == null) {
    final spec = doc['specialite'];
    if (spec is List && spec.isNotEmpty) {
      raw = spec.first;
    } else if (spec != null) {
      raw = spec;
    }
  }
  var s = raw?.toString().trim() ?? '';
  if (s.startsWith('[') && s.endsWith(']')) {
    s = s.substring(1, s.length - 1).trim();
  }
  if ((s.startsWith('"') && s.endsWith('"')) ||
      (s.startsWith("'") && s.endsWith("'"))) {
    s = s.substring(1, s.length - 1).trim();
  }
  return cleanDisplayPart(s) ?? 'Prestataire';
}

/// Vrai si une chaîne d'UI contient encore le littéral « null » (tests).
bool containsLiteralNull(String? text) {
  if (text == null || text.isEmpty) return false;
  return RegExp(r'(^|\s)null(\s|$)', caseSensitive: false).hasMatch(text);
}
