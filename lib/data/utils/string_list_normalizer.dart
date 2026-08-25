import 'dart:convert';

/// STAB-13B1 — Normalisation de listes de libellés métier (spécialités, zones…).
///
/// Tolère les données legacy Mongo / multipart mal encodées, ex. :
/// - `'["Bâtiment & Construction"]'`
/// - `['["Bâtiment & Construction"]']`
///
/// Responsabilité **data**, pas design system.
List<String> normalizeStringList(dynamic value) {
  if (value == null) return const [];

  final out = <String>[];
  final seen = <String>{};

  void addClean(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    final lower = t.toLowerCase();
    if (lower == 'null' || lower == 'undefined') return;
    if (seen.add(t)) out.add(t);
  }

  void walk(dynamic node, {int depth = 0}) {
    if (node == null || depth > 6) return;

    if (node is List) {
      for (final e in node) {
        walk(e, depth: depth + 1);
      }
      return;
    }

    // Booléens STAB-11b (présence KYC) — jamais des libellés.
    if (node is bool) return;

    if (node is! String) {
      addClean(node.toString());
      return;
    }

    final s = node.trim();
    if (s.isEmpty) return;

    // JSON uniquement si la string ressemble à un array/objet JSON.
    if ((s.startsWith('[') && s.endsWith(']')) ||
        (s.startsWith('{') && s.endsWith('}'))) {
      try {
        final parsed = jsonDecode(s);
        walk(parsed, depth: depth + 1);
        return;
      } catch (_) {
        // Phrase normale contenant des crochets → garder tel quel.
      }
    }

    addClean(s);
  }

  walk(value);
  return out;
}

/// Comme [normalizeStringList], mais `null` si la liste résultante est vide
/// (compat champs optionnels du modèle Prestataire).
List<String>? normalizeStringListOrNull(dynamic value) {
  final list = normalizeStringList(value);
  return list.isEmpty ? null : list;
}
