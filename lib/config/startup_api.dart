/// Résolution de l’URL d’API au démarrage.
///
/// `API_URL` vient de `--dart-define` (compilation). Le fichier `.env` n’est
/// pas un asset. S’il est absent, la release utilise l’URL publique déjà
/// configurée pour ce service — pas une adresse inventée. Une valeur
/// fournie en release qui n’est pas HTTPS, ou qui vise localhost / le LAN,
/// reste refusée.
const String publicApiUrl = 'https://soutralideals-backend.onrender.com/api';

const String publicLegalBaseUrl = 'https://soutralideals-web-app.onrender.com';

String resolveStartupApiUrl({
  required String fromEnvironment,
  required bool releaseMode,
}) {
  var value = fromEnvironment.trim();
  if (value.isEmpty ||
      (!releaseMode &&
          (value.contains('example.com') || value.contains('votre-api')))) {
    value = publicApiUrl;
  }
  if (value.isEmpty) {
    throw StateError('API_URL non configuré');
  }
  if (releaseMode && !value.startsWith('https://')) {
    throw StateError('API_URL release doit être HTTPS');
  }
  if (releaseMode &&
      (value.contains('localhost') ||
          value.contains('127.0.0.1') ||
          value.contains('192.168.'))) {
    throw StateError('API_URL release refuse localhost / LAN');
  }
  return value;
}
