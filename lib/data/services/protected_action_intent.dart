import 'fcm_route_policy.dart';

enum ProtectedActionType {
  callProvider,
  requestService,
  startConversation,
  addFavorite,
  contactSeller,
  publish,
}

/// Intention protégée : type, identifiant technique, route d'origine.
/// Jamais de numéro, email, jeton ou contenu de formulaire.
class ProtectedActionIntent {
  const ProtectedActionIntent({
    required this.type,
    required this.originRoute,
    this.technicalId,
  });

  final ProtectedActionType type;
  final String originRoute;
  final String? technicalId;
}

class ProtectedActionStore {
  ProtectedActionStore._();
  static final ProtectedActionStore instance = ProtectedActionStore._();

  static const allowedOrigins = {
    'providerProfile',
    'jobList',
    'freelanceDetails',
    'vendorDetails',
    'chat',
    'home',
    'detailPage',
  };

  ProtectedActionIntent? _pending;

  bool get hasPending => _pending != null;

  ProtectedActionIntent? peek() => _pending;

  void set(ProtectedActionIntent intent) {
    if (!allowedOrigins.contains(intent.originRoute)) {
      throw ArgumentError('originRoute non autorisée');
    }
    _pending = intent;
  }

  /// Consomme l'intention une seule fois.
  ProtectedActionIntent? consume() {
    final value = _pending;
    _pending = null;
    return value;
  }

  void clear() {
    _pending = null;
  }
}

class SessionExit {
  static const String destination = '/homepage';

  static void clearPending() {
    ProtectedActionStore.instance.clear();
    PendingLaunchDestination.clear();
  }
}
