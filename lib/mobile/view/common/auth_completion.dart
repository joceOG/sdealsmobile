import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/fcm_service.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/data/utils/phone_dialer.dart';
export 'package:sdealsmobile/data/utils/phone_dialer.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

/// Origine du parcours login/register. Aucune donnée personnelle.
enum AuthEntryMode { direct, protectedAction }

bool isProtectedAuthEntry(Object? extra) =>
    extra == AuthEntryMode.protectedAction;

/// Sortie après succès : retour à l'appelant, destination FCM, ou accueil.
enum AuthExit { returnToCaller, goFcm, goHome }

/// Index de l'onglet Accueil du shell existant. Pas un nouveau shell.
class ClientShellSelection {
  static final List<VoidCallback> _listeners = [];

  static void bind(VoidCallback listener) {
    if (_listeners.contains(listener)) return;
    _listeners.add(listener);
  }

  static void unbind(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void showHome() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }
}

/// Décision unique, partagée par le redirect et le succès d'auth.
/// Une fiche ouverte par Navigator.push laisse `router.location` sur
/// `/homepage` : ne pas s'en servir pour juger qu'aucune auth n'est ouverte.
AuthExit decideAuthExit({
  required bool hasPending,
  required bool hasFcmDestination,
}) {
  if (hasPending) return AuthExit.returnToCaller;
  if (hasFcmDestination) return AuthExit.goFcm;
  return AuthExit.goHome;
}

/// Redirect : ne pas remplacer la pile par l'accueil tant qu'une intention
/// ou une destination FCM attend le résultat du `push`.
bool shouldRedirectAuthedAuthRouteToHome({
  required bool loggedIn,
  required String location,
  required bool hasPending,
  required bool hasFcmDestination,
  Object? routeExtra,
}) {
  if (!loggedIn) return false;
  final loc = location.split('?').first;
  if (loc != '/login' && loc != '/register') return false;
  if (hasPending || hasFcmDestination) return false;
  // Indépendant du store : le marqueur vit sur la route jusqu'à son pop.
  if (isProtectedAuthEntry(routeExtra)) return false;
  return true;
}

/// Vrai seulement s'il reste une page GoRouter sous la route courante.
bool canPopDeclarativeRoute(BuildContext context) {
  final matches =
      GoRouter.of(context).routerDelegate.currentConfiguration.matches;
  return matches.length > 1;
}

bool routeIsProtectedAuth(BuildContext context) {
  try {
    return isProtectedAuthEntry(GoRouterState.of(context).extra);
  } catch (_) {
    return false;
  }
}

/// Après authentification : reprend l'appelant si une intention existe,
/// sinon une destination FCM allowlistée, sinon l'accueil.
class AuthCompletion {
  static void goAfterSuccess(BuildContext context) {
    if (ProtectedActionStore.instance.hasPending ||
        routeIsProtectedAuth(context)) {
      // Navigator.canPop est vrai dès qu'une fiche impérative existe, mais
      // GoRouter crash si on retire sa dernière page déclarative.
      if (canPopDeclarativeRoute(context)) {
        Navigator.of(context).pop(true);
      }
      return;
    }
    // Ne pas consommer l'intention ici : l'appelant le fait une seule fois,
    // puis exécute l'action. Ne jamais go('/homepage') tant qu'elle existe.
    final exit = decideAuthExit(
      hasPending: false,
      hasFcmDestination: FcmService.instance.peekPendingDestination() != null,
    );
    if (exit == AuthExit.goFcm) {
      final destination = FcmService.instance.consumePendingDestination();
      if (destination != null) {
        GoRouter.of(context).go(destination);
        return;
      }
    }
    ClientShellSelection.showHome();
    GoRouter.of(context).go('/homepage');
  }
}

/// Logout : session déjà vidée par l'appelant. Réaffiche l'accueil invité
/// du shell existant, sans recréer l'application ni doubler la navigation.
void exitToGuestHome(BuildContext context) {
  ClientShellSelection.showHome();
  final router = GoRouter.of(context);
  final nav = Navigator.of(context, rootNavigator: true);
  if (nav.canPop()) {
    nav.popUntil((route) => route.isFirst);
  }
  final loc = router.location.split('?').first;
  if (loc != '/homepage') {
    router.go('/homepage');
  }
}

Future<bool> ensureAuthenticatedForAction({
  required BuildContext context,
  required ProtectedActionType type,
  required String originRoute,
  required String explanation,
  String? technicalId,
}) async {
  final auth = context.read<AuthCubit>().state;
  if (auth is AuthAuthenticated) return true;

  ProtectedActionStore.instance.set(
    ProtectedActionIntent(
      type: type,
      originRoute: originRoute,
      technicalId: technicalId,
    ),
  );

  final choice = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProtectedAuthSheet(explanation: explanation),
  );
  if (!context.mounted) {
    ProtectedActionStore.instance.clear();
    return false;
  }
  if (choice != 'login' && choice != 'register') {
    ProtectedActionStore.instance.clear();
    return false;
  }

  final ok = await context.push<bool>(
    choice == 'register' ? '/register' : '/login',
    extra: AuthEntryMode.protectedAction,
  );
  if (ok != true) {
    ProtectedActionStore.instance.clear();
    return false;
  }
  ProtectedActionStore.instance.consume();
  if (!context.mounted) return false;
  return context.read<AuthCubit>().state is AuthAuthenticated;
}

Future<bool> pushAuthForPendingAction({
  required BuildContext context,
  required ProtectedActionType type,
  required String originRoute,
  required String route,
  String? technicalId,
}) async {
  final auth = context.read<AuthCubit>().state;
  if (auth is AuthAuthenticated) return true;
  ProtectedActionStore.instance.set(
    ProtectedActionIntent(
      type: type,
      originRoute: originRoute,
      technicalId: technicalId,
    ),
  );
  final ok = await context.push<bool>(
    route,
    extra: AuthEntryMode.protectedAction,
  );
  if (ok != true) {
    ProtectedActionStore.instance.clear();
    return false;
  }
  ProtectedActionStore.instance.consume();
  if (!context.mounted) return false;
  return context.read<AuthCubit>().state is AuthAuthenticated;
}

class ProtectedAuthSheet extends StatelessWidget {
  const ProtectedAuthSheet({super.key, required this.explanation});

  final String explanation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              explanation,
              style: SDTypography.titleMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connexion ou inscription, puis retour sur la même fiche.',
              style:
                  SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'login'),
              child: const Text('Se connecter'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, 'register'),
              child: const Text('S\'inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showDialerFeedback(
    BuildContext context, PhoneDialResult result) async {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  switch (result.outcome) {
    case PhoneDialOutcome.opened:
    case PhoneDialOutcome.alreadyOpening:
      return;
    case PhoneDialOutcome.invalidNumber:
      messenger.showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non disponible')),
      );
    case PhoneDialOutcome.launchFailed:
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir le composeur. Réessayez.'),
        ),
      );
  }
}
