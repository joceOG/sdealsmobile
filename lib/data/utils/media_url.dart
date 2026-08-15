/// Normalisation / sélection d'URLs média (Cloudinary, http, protocole-relatif).

String? normalizeMediaUrl(String? raw) {
  if (raw == null) return null;
  final v = raw.trim();
  if (v.isEmpty) return null;
  if (v.startsWith('https://') || v.startsWith('http://')) return v;
  if (v.startsWith('//')) return 'https:$v';
  return null;
}

/// Photo d'un prestataire : selfie (KYC) puis photoProfil utilisateur.
String? providerPhotoUrl({
  String? selfie,
  String? photoProfil,
  Map<String, dynamic>? utilisateurMap,
  Map<String, dynamic>? prestataireMap,
}) {
  final fromSelfie = normalizeMediaUrl(selfie) ??
      normalizeMediaUrl(prestataireMap?['selfie']?.toString());
  if (fromSelfie != null) return fromSelfie;

  final fromProfil = normalizeMediaUrl(photoProfil) ??
      normalizeMediaUrl(utilisateurMap?['photoProfil']?.toString()) ??
      normalizeMediaUrl(utilisateurMap?['selfie']?.toString()) ??
      normalizeMediaUrl(utilisateurMap?['avatar']?.toString()) ??
      normalizeMediaUrl(utilisateurMap?['photo']?.toString());
  return fromProfil;
}
