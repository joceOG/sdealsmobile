/// Normalisation / sélection d'URLs média (Cloudinary, http, protocole-relatif).

String? normalizeMediaUrl(String? raw) {
  if (raw == null) return null;
  final v = raw.trim();
  if (v.isEmpty) return null;
  final lower = v.toLowerCase();
  if (lower == 'null' ||
      lower == 'undefined' ||
      lower == 'true' ||
      lower == 'false') {
    return null;
  }
  if (v.startsWith('https://') || v.startsWith('http://')) return v;
  if (v.startsWith('//')) return 'https:$v';
  return null;
}

/// Champ KYC liste publique (STAB-11b) : URL réelle **ou** booléen de présence.
///
/// En catalogue public le backend remplace les URLs KYC par `true`/`false`.
/// Ne jamais caster en `String?` ni traiter `true` comme une URL image.
String? kycFieldAsPublicUrl(dynamic value) {
  if (value is bool) return null;
  if (value is! String) return null;
  return normalizeMediaUrl(value);
}

/// Photo d'affichage catalogue : [photoProfil] publique d'abord, puis selfie
/// **uniquement** s'il s'agit encore d'une URL http (viewer autorisé).
///
/// Ne ré-expose pas le KYC redacté (`selfie: true`).
String? providerPhotoUrl({
  String? selfie,
  String? photoProfil,
  Map<String, dynamic>? utilisateurMap,
  Map<String, dynamic>? prestataireMap,
}) {
  final fromProfil = normalizeMediaUrl(photoProfil) ??
      normalizeMediaUrl(utilisateurMap?['photoProfil']?.toString()) ??
      normalizeMediaUrl(utilisateurMap?['avatar']?.toString()) ??
      normalizeMediaUrl(utilisateurMap?['photo']?.toString());
  if (fromProfil != null) return fromProfil;

  // Selfie seulement si URL réelle (pas le booléen STAB-11b).
  return kycFieldAsPublicUrl(selfie) ??
      kycFieldAsPublicUrl(prestataireMap?['selfie']) ??
      kycFieldAsPublicUrl(utilisateurMap?['selfie']);
}
