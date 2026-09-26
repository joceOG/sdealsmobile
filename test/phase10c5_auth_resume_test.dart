import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    ProtectedActionStore.instance.clear();
  });

  group('décision', () {
    test('login direct sans intention → accueil', () {
      expect(
        decideAuthExit(hasPending: false, hasFcmDestination: false),
        AuthExit.goHome,
      );
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
    });

    test('intention protégée → pas de redirection accueil', () {
      expect(
        decideAuthExit(hasPending: true, hasFcmDestination: false),
        AuthExit.returnToCaller,
      );
      expect(
        shouldRedirectAuthedAuthRouteToHome(
          loggedIn: true,
          location: '/login',
          hasPending: true,
          hasFcmDestination: false,
          routeExtra: AuthEntryMode.protectedAction,
        ),
        isFalse,
      );
      expect(
        shouldRedirectAuthedAuthRouteToHome(
          loggedIn: true,
          location: '/register',
          hasPending: true,
          hasFcmDestination: false,
          routeExtra: AuthEntryMode.protectedAction,
        ),
        isFalse,
      );
    });
  });

  group('store', () {
    test('non consommée avant succès, une fois après, vide ensuite', () {
      ProtectedActionStore.instance.set(
        const ProtectedActionIntent(
          type: ProtectedActionType.callProvider,
          originRoute: 'providerProfile',
          technicalId: 'tech-1',
        ),
      );
      expect(ProtectedActionStore.instance.hasPending, isTrue);
      expect(ProtectedActionStore.instance.peek()?.technicalId, 'tech-1');

      final first = ProtectedActionStore.instance.consume();
      expect(first?.type, ProtectedActionType.callProvider);
      expect(ProtectedActionStore.instance.hasPending, isFalse);
      expect(ProtectedActionStore.instance.consume(), isNull);
    });

    test('annulation et logout effacent sans consommer comme succès', () {
      ProtectedActionStore.instance.set(
        const ProtectedActionIntent(
          type: ProtectedActionType.requestService,
          originRoute: 'providerProfile',
        ),
      );
      ProtectedActionStore.instance.clear();
      expect(ProtectedActionStore.instance.peek(), isNull);

      ProtectedActionStore.instance.set(
        const ProtectedActionIntent(
          type: ProtectedActionType.callProvider,
          originRoute: 'providerProfile',
        ),
      );
      SessionExit.clearPending();
      expect(ProtectedActionStore.instance.hasPending, isFalse);
    });
  });

  testWidgets('login depuis Appeler reprend la fiche une fois, sans accueil',
      (tester) async {
    var dials = 0;
    final router = _router(
      onResume: (type) {
        expect(type, ProtectedActionType.callProvider);
        dials++;
      },
    );
    await tester.pumpWidget(_app(router));
    await tester.tap(find.text('Appeler'));
    await tester.pumpAndSettle();
    expect(ProtectedActionStore.instance.hasPending, isTrue);

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('auth'), findsOneWidget);
    expect(ProtectedActionStore.instance.hasPending, isTrue);

    await tester.tap(find.text('succès'));
    await tester.pumpAndSettle();

    expect(dials, 1);
    expect(find.text('fiche'), findsOneWidget);
    expect(find.text('accueil'), findsNothing);
    expect(ProtectedActionStore.instance.hasPending, isFalse);
  });

  testWidgets('login depuis Demander reprend la sheet une fois',
      (tester) async {
    var sheets = 0;
    final router = _router(
      actionLabel: 'Demander',
      type: ProtectedActionType.requestService,
      onResume: (type) {
        expect(type, ProtectedActionType.requestService);
        sheets++;
      },
    );
    await tester.pumpWidget(_app(router));
    await tester.tap(find.text('Demander'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(ProtectedActionStore.instance.hasPending, isTrue);

    await tester.tap(find.text('succès'));
    await tester.pumpAndSettle();

    expect(sheets, 1);
    expect(find.text('fiche'), findsOneWidget);
    expect(find.text('accueil'), findsNothing);
  });

  testWidgets('login annulé ne lance aucune action', (tester) async {
    var actions = 0;
    final router = _router(onResume: (_) => actions++);
    await tester.pumpWidget(_app(router));
    await tester.tap(find.text('Appeler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    final back = find.byType(BackButton);
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back);
    } else {
      final dynamic state = tester.state(find.byType(Navigator).first);
      state.pop();
    }
    await tester.pumpAndSettle();

    expect(actions, 0);
    expect(ProtectedActionStore.instance.hasPending, isFalse);
    expect(find.text('fiche'), findsOneWidget);
  });

  testWidgets('inscription directe sans intention → accueil', (tester) async {
    var homeSelected = 0;
    void onHome() => homeSelected++;
    ClientShellSelection.bind(onHome);
    addTearDown(() => ClientShellSelection.unbind(onHome));

    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/homepage',
          builder: (_, __) => const Text('accueil'),
        ),
        GoRoute(
          path: '/register',
          builder: (context, _) => TextButton(
            onPressed: () => AuthCompletion.goAfterSuccess(context),
            child: const Text('succès'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('succès'));
    await tester.pumpAndSettle();

    expect(find.text('accueil'), findsOneWidget);
    expect(homeSelected, 1);
  });

  testWidgets('inscription depuis Appeler demande le composeur une fois',
      (tester) async {
    var dials = 0;
    final router = _router(onResume: (_) => dials++);
    await tester.pumpWidget(_app(router));
    await tester.tap(find.text('Appeler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('S\'inscrire'));
    await tester.pumpAndSettle();
    expect(ProtectedActionStore.instance.hasPending, isTrue);

    await tester.tap(find.text('succès'));
    await tester.pumpAndSettle();

    expect(dials, 1);
    expect(find.text('fiche'), findsOneWidget);
    expect(find.text('accueil'), findsNothing);
  });

  testWidgets('inscription depuis Demander demande la sheet une fois',
      (tester) async {
    var sheets = 0;
    final router = _router(
      actionLabel: 'Demander',
      type: ProtectedActionType.requestService,
      onResume: (_) => sheets++,
    );
    await tester.pumpWidget(_app(router));
    await tester.tap(find.text('Demander'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('S\'inscrire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('succès'));
    await tester.pumpAndSettle();

    expect(sheets, 1);
    expect(find.text('fiche'), findsOneWidget);
  });

  testWidgets('inscription annulée ne lance aucune action', (tester) async {
    var actions = 0;
    final router = _router(onResume: (_) => actions++);
    await tester.pumpWidget(_app(router));
    await tester.tap(find.text('Appeler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('S\'inscrire'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('auth'))).pop();
    await tester.pumpAndSettle();

    expect(actions, 0);
    expect(ProtectedActionStore.instance.hasPending, isFalse);
  });

  testWidgets('logout depuis Profil ramène l’index Accueil', (tester) async {
    final host = _ShellHost();
    await tester.pumpWidget(MaterialApp(home: host));
    await tester.tap(find.text('Profil'));
    await tester.pump();
    expect(find.text('onglet-profil'), findsOneWidget);

    ClientShellSelection.showHome();
    await tester.pump();

    expect(find.text('onglet-accueil'), findsOneWidget);
    expect(find.text('onglet-profil'), findsNothing);
    expect(find.text('Se connecter'), findsNothing);
  });
}

GoRouter _router({
  String actionLabel = 'Appeler',
  ProtectedActionType type = ProtectedActionType.callProvider,
  required void Function(ProtectedActionType type) onResume,
}) {
  return GoRouter(
    initialLocation: '/homepage',
    routes: [
      GoRoute(
        path: '/homepage',
        builder: (context, _) => Column(
          children: [
            const Text('fiche'),
            TextButton(
              onPressed: () async {
                final ready = await ensureAuthenticatedForAction(
                  context: context,
                  type: type,
                  originRoute: 'providerProfile',
                  explanation: type == ProtectedActionType.callProvider
                      ? 'Connectez-vous pour contacter ce professionnel'
                      : 'Connectez-vous pour demander un service',
                );
                if (!ready) return;
                expect(ProtectedActionStore.instance.peek(), isNull);
                onResume(type);
              },
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/login',
        builder: _authPage,
      ),
      GoRoute(
        path: '/register',
        builder: _authPage,
      ),
    ],
  );
}

Widget _authPage(BuildContext context, GoRouterState state) {
  return Column(
    children: [
      const Text('auth'),
      TextButton(
        onPressed: () {
          context.read<AuthCubit>().setAuthenticated(
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
          AuthCompletion.goAfterSuccess(context);
        },
        child: const Text('succès'),
      ),
      const BackButton(),
    ],
  );
}

Widget _app(GoRouter router) {
  return BlocProvider(
    create: (_) => AuthCubit(),
    child: MaterialApp.router(routerConfig: router),
  );
}

class _ShellHost extends StatefulWidget {
  @override
  State<_ShellHost> createState() => _ShellHostState();
}

class _ShellHostState extends State<_ShellHost> {
  int index = 3;
  late final VoidCallback _showHome = () {
    if (!mounted || index == 0) return;
    setState(() => index = 0);
  };

  @override
  void initState() {
    super.initState();
    ClientShellSelection.bind(_showHome);
  }

  @override
  void dispose() {
    ClientShellSelection.unbind(_showHome);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(index == 0 ? 'onglet-accueil' : 'onglet-profil'),
        TextButton(
          onPressed: () => setState(() => index = 3),
          child: const Text('Profil'),
        ),
      ],
    );
  }
}
