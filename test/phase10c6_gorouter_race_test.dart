import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';

void main() {
  late AuthCubit cubit;
  late _Refresh refresh;
  late StreamSubscription<AuthState> authSub;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    ProtectedActionStore.instance.clear();
    cubit = AuthCubit();
    refresh = _Refresh();
    authSub = cubit.stream.listen((_) => refresh.ping());
  });

  tearDown(() async {
    await authSub.cancel();
    await cubit.close();
    refresh.dispose();
  });

  test('connecté + login direct → accueil', () {
    expect(
      shouldRedirectAuthedAuthRouteToHome(
        loggedIn: true,
        location: '/login',
        hasPending: false,
        hasFcmDestination: false,
        routeExtra: null,
      ),
      isTrue,
    );
    expect(
      shouldRedirectAuthedAuthRouteToHome(
        loggedIn: true,
        location: '/login',
        hasPending: false,
        hasFcmDestination: false,
        routeExtra: AuthEntryMode.direct,
      ),
      isTrue,
    );
  });

  testWidgets('login seule page : succès ne vide pas la pile', (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      initialExtra: AuthEntryMode.protectedAction,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => TextButton(
            onPressed: () => AuthCompletion.goAfterSuccess(context),
            child: const Text('terminer'),
          ),
        ),
        GoRoute(
          path: '/homepage',
          builder: (_, __) => const Text('accueil'),
        ),
      ],
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    ProtectedActionStore.instance.set(
      const ProtectedActionIntent(
        type: ProtectedActionType.requestService,
        originRoute: 'providerProfile',
      ),
    );
    await tester.tap(find.text('terminer'));
    await tester.pumpAndSettle();
    expect(find.text('terminer'), findsOneWidget);
    expect(find.text('accueil'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('login et register protégés, même après consume', () {
    for (final location in const ['/login', '/register']) {
      expect(
        shouldRedirectAuthedAuthRouteToHome(
          loggedIn: true,
          location: location,
          hasPending: false,
          hasFcmDestination: false,
          routeExtra: AuthEntryMode.protectedAction,
        ),
        isFalse,
        reason: location,
      );
    }
  });

  testWidgets('refresh AuthCubit et refreshRoles ne remplacent pas la fiche',
      (tester) async {
    final hops = <String>[];
    final router = _router(cubit, refresh, homeHops: hops);
    await tester.pumpWidget(_app(cubit, router));
    await tester.tap(find.text('ouvrir-protégé'));
    await tester.pumpAndSettle();
    expect(find.text('login-protected'), findsOneWidget);

    ProtectedActionStore.instance.set(
      const ProtectedActionIntent(
        type: ProtectedActionType.callProvider,
        originRoute: 'providerProfile',
      ),
    );
    _authenticate(cubit);
    await tester.pumpAndSettle();
    ProtectedActionStore.instance.consume();
    expect(ProtectedActionStore.instance.consume(), isNull);
    _authenticate(cubit);
    await tester.pumpAndSettle();

    expect(hops, isEmpty);
    expect(find.text('login-protected'), findsOneWidget);
  });

  testWidgets('route protégée retirée : login direct redevient l’accueil',
      (tester) async {
    final router = _router(cubit, refresh);
    await tester.pumpWidget(_app(cubit, router));
    _authenticate(cubit);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ouvrir-direct'));
    await tester.pumpAndSettle();
    expect(find.text('login-direct'), findsNothing);
  });

  testWidgets('feuille vers login et inscription conserve le marqueur',
      (tester) async {
    final router = _router(cubit, refresh);
    await tester.pumpWidget(_app(cubit, router));
    await tester.tap(find.text('Appeler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('login-protected'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appeler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('S\'inscrire'));
    await tester.pumpAndSettle();
    expect(find.text('register-protected'), findsOneWidget);
  });

  testWidgets('login vers inscription conserve le marqueur', (tester) async {
    final router = _router(cubit, refresh);
    await tester.pumpWidget(_app(cubit, router));
    await tester.tap(find.text('Appeler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    expect(find.text('register-protected'), findsOneWidget);
  });

  testWidgets('authentification directe ne reçoit pas le marqueur',
      (tester) async {
    final router = _router(cubit, refresh);
    await tester.pumpWidget(_app(cubit, router));
    await tester.tap(find.text('ouvrir-direct'));
    await tester.pumpAndSettle();
    expect(find.text('login-direct'), findsOneWidget);
    expect(find.text('login-protected'), findsNothing);
  });

  testWidgets('annulation n’exécute rien et garde la fiche', (tester) async {
    var calls = 0;
    final router = _router(cubit, refresh, onResume: () => calls++);
    await tester.pumpWidget(_app(cubit, router));
    await tester.tap(find.text('Demander'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(ProtectedActionStore.instance.hasPending, isFalse);
    expect(find.text('fiche'), findsOneWidget);
  });
}

void _authenticate(AuthCubit cubit) {
  cubit.setAuthenticated(
    token: 'test-token',
    utilisateur: Utilisateur(
      idutilisateur: 'id-test',
      nom: 'Testeur',
      email: 'test@example.com',
      password: '',
      telephone: '',
      role: 'CLIENT',
    ),
  );
}

GoRouter _router(
  AuthCubit cubit,
  Listenable refresh, {
  VoidCallback? onResume,
  List<String>? homeHops,
}) {
  return GoRouter(
    initialLocation: '/homepage',
    refreshListenable: refresh,
    redirect: (context, state) {
      final home = shouldRedirectAuthedAuthRouteToHome(
        loggedIn: cubit.state is AuthAuthenticated,
        location: state.matchedLocation,
        hasPending: ProtectedActionStore.instance.hasPending,
        hasFcmDestination: false,
        routeExtra: state.extra,
      );
      if (home) {
        homeHops?.add(state.matchedLocation);
        return '/homepage';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/homepage',
        builder: (context, _) => Column(
          children: [
            const Text('fiche'),
            TextButton(
              onPressed: () => context.push(
                '/login',
                extra: AuthEntryMode.protectedAction,
              ),
              child: const Text('ouvrir-protégé'),
            ),
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('ouvrir-direct'),
            ),
            TextButton(
              onPressed: () async {
                final ready = await ensureAuthenticatedForAction(
                  context: context,
                  type: ProtectedActionType.callProvider,
                  originRoute: 'providerProfile',
                  explanation: 'Connectez-vous pour contacter ce professionnel',
                );
                if (ready) onResume?.call();
              },
              child: const Text('Appeler'),
            ),
            TextButton(
              onPressed: () async {
                final ready = await ensureAuthenticatedForAction(
                  context: context,
                  type: ProtectedActionType.requestService,
                  originRoute: 'providerProfile',
                  explanation: 'Connectez-vous pour demander un service',
                );
                if (ready) onResume?.call();
              },
              child: const Text('Demander'),
            ),
          ],
        ),
      ),
      GoRoute(path: '/login', builder: _loginPage),
      GoRoute(path: '/register', builder: _registerPage),
    ],
  );
}

Widget _loginPage(BuildContext context, GoRouterState state) {
  final label =
      isProtectedAuthEntry(state.extra) ? 'login-protected' : 'login-direct';
  return Column(
    children: [
      Text(label),
      TextButton(
        onPressed: () async {
          final protected = isProtectedAuthEntry(state.extra);
          final ok = await context.push<bool>(
            '/register',
            extra: protected ? AuthEntryMode.protectedAction : null,
          );
          if (ok == true && protected && context.mounted) {
            context.pop(true);
          }
        },
        child: const Text('Créer un compte'),
      ),
    ],
  );
}

Widget _registerPage(BuildContext context, GoRouterState state) {
  final label = isProtectedAuthEntry(state.extra)
      ? 'register-protected'
      : 'register-direct';
  return Column(
    children: [
      Text(label),
      TextButton(
        onPressed: () => AuthCompletion.goAfterSuccess(context),
        child: const Text('succès-register'),
      ),
    ],
  );
}

Widget _app(AuthCubit cubit, GoRouter router) {
  return BlocProvider.value(
    value: cubit,
    child: MaterialApp.router(routerConfig: router),
  );
}

class _Refresh extends ChangeNotifier {
  void ping() => notifyListeners();
}
