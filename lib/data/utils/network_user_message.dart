/// Messages d'erreur lisibles pour l'utilisateur (réseau / API).
String userFacingNetworkMessage(Object error) {
  final s = error.toString().toLowerCase();
  if (s.contains('socket') ||
      s.contains('failed host') ||
      s.contains('network') ||
      s.contains('connection') ||
      s.contains('timed out') ||
      s.contains('timeout') ||
      s.contains('connection refused') ||
      s.contains('clientexception') ||
      s.contains('handshake')) {
    return 'Pas de connexion. Vérifiez votre réseau puis réessayez.';
  }
  if (s.contains('503') || s.contains('502') || s.contains('504')) {
    return 'Le serveur redémarre. Réessayez dans quelques secondes.';
  }
  return 'Impossible de charger les données. Réessayez.';
}
