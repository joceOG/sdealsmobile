/// Destination FCM en mémoire uniquement. Jamais de jeton ni de payload brut.
class PendingLaunchDestination {
  static String? _value;

  static void hold(String route) {
    if (FcmRoutePolicy.isAllowedPath(route) &&
        route != '/homepage' &&
        route != '/login') {
      _value = route;
    } else {
      _value = null;
    }
  }

  static String? peek() => _value;

  static String? consume() {
    final value = _value;
    _value = null;
    if (value == null || !FcmRoutePolicy.isAllowedPath(value)) return null;
    return value;
  }

  static void clear() {
    _value = null;
  }
}

class FcmNavigationDecision {
  const FcmNavigationDecision({
    required this.route,
    this.resumeAfterAuth,
  });

  final String route;
  final String? resumeAfterAuth;
}

/// Que faire d'une destination en attente quand la restauration de session
/// se termine après l'ouverture de l'interface.
enum PostRestoreAction { none, openPending, openLogin }

class SplashNavDecision {
  const SplashNavDecision({
    required this.route,
    this.hold,
    this.extra,
  });

  final String route;
  final String? hold;
  final Object? extra;
}

/// Destinations FCM fermées. Une route de payload n'est jamais reprise telle quelle
/// si elle n'est pas dans l'allowlist.
class FcmRoutePolicy {
  static final _id = RegExp(r'^[A-Za-z0-9_-]{1,80}$');
  static final _chat = RegExp(r'^/chat/[A-Za-z0-9_-]{1,80}$');
  static final _mission = RegExp(r'^/mission-details/[A-Za-z0-9_-]{1,80}$');

  static bool isAllowedPath(String path) {
    return path == '/homepage' ||
        _chat.hasMatch(path) ||
        _mission.hasMatch(path);
  }

  static bool isProtected(String path) {
    return path.startsWith('/chat/') || path.startsWith('/mission-details/');
  }

  /// Retourne une route allowlistée, ou null s'il n'y a pas de destination métier.
  static String? mapToAllowedRoute(Map<String, dynamic> data) {
    final explicit = data['route']?.toString() ?? '';
    if (explicit.isNotEmpty && isAllowedPath(explicit)) {
      return explicit;
    }
    final conversationId = data['conversationId']?.toString() ?? '';
    if (_id.hasMatch(conversationId)) {
      return '/chat/$conversationId';
    }
    final missionId =
        data['prestationId']?.toString() ?? data['missionId']?.toString() ?? '';
    if (_id.hasMatch(missionId)) {
      return '/mission-details/$missionId';
    }
    return null;
  }

  static FcmNavigationDecision decide(
    Map<String, dynamic> data, {
    required bool loggedIn,
  }) {
    final target = mapToAllowedRoute(data);
    if (target == null) {
      return const FcmNavigationDecision(route: '/homepage');
    }
    if (isProtected(target) && !loggedIn) {
      return FcmNavigationDecision(route: '/login', resumeAfterAuth: target);
    }
    return FcmNavigationDecision(route: target);
  }

  static SplashNavDecision resolveSplash({
    required String? pendingRoute,
    required bool onboardingCompleted,
    required bool loggedIn,
    required bool openProviderHome,
    Object? providerExtra,

    /// La restauration de session n'est pas terminée : on ne sait pas si
    /// l'utilisateur est connecté. Ni « invité » (→ /login), ni accès pro.
    bool sessionPending = false,
  }) {
    final hold = pendingRoute != null &&
            isAllowedPath(pendingRoute) &&
            pendingRoute != '/homepage'
        ? pendingRoute
        : null;
    if (!onboardingCompleted) {
      return SplashNavDecision(route: '/onboarding', hold: hold);
    }
    if (sessionPending && !loggedIn) {
      // Interface neutre ; la destination reste en attente et sera ouverte
      // (ou menée au login) dès que la session est fixée.
      return SplashNavDecision(route: '/homepage', hold: hold);
    }
    if (hold != null && isProtected(hold) && !loggedIn) {
      return SplashNavDecision(route: '/login', hold: hold);
    }
    if (hold != null) {
      return SplashNavDecision(route: hold);
    }
    if (openProviderHome) {
      return SplashNavDecision(route: '/providermain', extra: providerExtra);
    }
    return const SplashNavDecision(route: '/homepage');
  }

  /// Décision quand la restauration passe de « en cours » à un état final.
  /// [pending] = destination conservée (allowlistée) ; [settled] = la
  /// restauration n'est plus « en cours » ; [authenticated] = session appliquée.
  static PostRestoreAction afterSessionRestore({
    required bool settled,
    required bool authenticated,
    required String? pending,
  }) {
    if (!settled || pending == null || !isAllowedPath(pending)) {
      return PostRestoreAction.none;
    }
    if (authenticated) return PostRestoreAction.openPending;
    if (isProtected(pending)) return PostRestoreAction.openLogin;
    return PostRestoreAction.none;
  }
}
