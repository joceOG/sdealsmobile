/// Erreurs FCM transitoires : pas de token, l’app doit quand même démarrer.
bool isTransientFcmTokenError(Object error) {
  final text = error.toString();
  const markers = [
    'SERVICE_NOT_AVAILABLE',
    'FIS_AUTH_ERROR',
    'AUTHENTICATION_FAILED',
    'MISSING_INSTANCEID_SERVICE',
    'TOO_MANY_REGISTRATIONS',
    'NETWORK_ERROR',
    'TimeoutException',
  ];
  for (final m in markers) {
    if (text.contains(m)) return true;
  }
  return false;
}
