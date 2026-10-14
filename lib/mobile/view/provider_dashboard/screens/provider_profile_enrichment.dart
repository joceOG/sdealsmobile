import '../../../../data/utils/display_text.dart';

/// Enrichissement du profil (présentation publique) — distinct du dossier KYC.
class ProviderProfileEnrichment {
  static const String bioDescriptionSeparator = '\n\n';

  /// Deux champs UI, un seul `description` côté API : bio courte + corps séparés par [bioDescriptionSeparator].
  static ({String bio, String description}) splitDescription(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return (bio: '', description: '');
    final idx = t.indexOf(bioDescriptionSeparator);
    if (idx >= 0) {
      return (
        bio: t.substring(0, idx).trim(),
        description: t.substring(idx + bioDescriptionSeparator.length).trim(),
      );
    }
    if (t.length <= 80 && !t.contains('\n')) {
      return (bio: t, description: '');
    }
    return (bio: '', description: t);
  }

  static String joinDescription({required String bio, required String description}) {
    final b = bio.trim();
    final d = description.trim();
    if (b.isEmpty) return d;
    if (d.isEmpty) return b;
    return '$b$bioDescriptionSeparator$d';
  }

  static bool hasProfilePhotoUrl(String? profileImage, String? authPhoto) {
    return safeImageUrl(profileImage) != null || safeImageUrl(authPhoto) != null;
  }

  /// Libellés affichables des manques d'enrichissement (pas CNI / selfie / GPS).
  static List<String> missingLabels({
    required bool hasPhotoUrl,
    required String bio,
    required String description,
  }) {
    final items = <String>[];
    if (!hasPhotoUrl) items.add('photo');
    if (bio.trim().isEmpty && description.trim().isEmpty) {
      items.add('description');
    } else if (description.trim().isEmpty && bio.trim().length < 8) {
      items.add('description');
    }
    return items;
  }

  static String missingBannerText(List<String> keys) {
    if (keys.isEmpty) return '';
    final labels = keys.map(_labelForKey).join(' et ');
    return 'À compléter : $labels';
  }

  static String _labelForKey(String key) {
    switch (key) {
      case 'photo':
        return 'photo';
      case 'description':
        return 'description';
      default:
        return key;
    }
  }
}
