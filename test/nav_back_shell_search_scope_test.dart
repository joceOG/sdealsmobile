import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/professional_capabilities.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageBlocM.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageEventM.dart';
import 'package:sdealsmobile/mobile/view/home.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuthCubit extends AuthCubit {
  Utilisateur _user(String role) => Utilisateur(
        idutilisateur: 'user-test',
        nom: 'Kouassi',
        prenom: 'Awa',
        email: 'hidden@example.com',
        password: 'secret',
        telephone: '00000000',
        role: role,
      );

  void asClient() {
    emit(AuthAuthenticated(
      token: 'token-test',
      utilisateur: _user('CLIENT'),
      roles: const ['CLIENT', 'PRESTATAIRE'],
      activeRole: 'CLIENT',
      professional: const UserProfessionalCapabilities(
        capabilities: ['Prestataire'],
      ),
    ));
  }

  void asProvider() {
    emit(AuthAuthenticated(
      token: 'token-test',
      utilisateur: _user('PRESTATAIRE'),
      roles: const ['CLIENT', 'PRESTATAIRE'],
      activeRole: 'PRESTATAIRE',
      professional: const UserProfessionalCapabilities(
        capabilities: ['Prestataire'],
      ),
    ));
  }
}

/// Bouton retour Android tel que l'embedding l'envoie au framework.
Future<void> _androidBack(WidgetTester tester) async {
  final message = const JSONMethodCodec()
      .encodeMethodCall(const MethodCall('popRoute'));
  await tester.binding.defaultBinaryMessenger
      .handlePlatformMessage('flutter/navigation', message, (_) {});
  await tester.pump();
}

class _GateFreelanceApi extends ApiClient {
  _GateFreelanceApi(this.categoryGate);

  final Completer<Map<String, dynamic>> categoryGate;

  @override
  Future<List<Categorie>> fetchCategorie(
    String nomGroupe, {
    bool skipCache = false,
    bool settleLateResponse = false,
  }) async =>
      [];

  @override
  Future<List<Service>> fetchServices(String nomGroupe) async => [];

  @override
  Future<Map<String, dynamic>> fetchFreelances({
    int page = 1,
    int limit = 50,
    String sortBy = 'rating',
    String sortOrder = 'desc',
    String? category,
  }) {
    if (category != null) return categoryGate.future;
    return Future.value({
      'freelances': [_freelance('f1', 'Ada'), _freelance('f2', 'Bob')],
      'pagination': null,
    });
  }
}

Map<String, dynamic> _freelance(String id, String name) => {
      '_id': id,
      'name': name,
      'job': 'Design',
      'category': 'Design',
      'rating': 4.5,
      'completedJobs': 3,
      'availabilityStatus': 'Disponible',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    SharedPreferences.setMockInitialValues({});
    final dir = await Directory.systemTemp.createTemp('nav-back-hive');
    Hive.init(dir.path);
    ProtectedActionStore.instance.clear();
  });

  group('Retour Android — shell client', () {
    testWidgets(
        'Profil / Messagerie → Accueil sans quitter ; Accueil → sortie',
        (tester) async {
      final systemPops = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') {
            systemPops.add(call.method);
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(),
          child: const MaterialApp(home: Home()),
        ),
      );
      await tester.pump();
      final homeState = tester.state(find.byType(Home));

      await tester.tap(find.text('Profil'));
      await tester.pump();
      expect(find.text('Se connecter'), findsOneWidget);

      await _androidBack(tester);
      expect(
          find.text('Trouvez un professionnel près de vous'), findsOneWidget);
      expect(find.text('Se connecter'), findsNothing);
      expect(systemPops, isEmpty, reason: 'Profil ne doit pas quitter l’app');
      // Même shell, pas de nouvelle route ni recréation des onglets.
      expect(tester.state(find.byType(Home)), same(homeState));

      await tester.tap(find.text('Messagerie'));
      await tester.pump();
      await tester.pump();
      await _androidBack(tester);
      expect(
          find.text('Trouvez un professionnel près de vous'), findsOneWidget);
      expect(systemPops, isEmpty);

      // Racine Accueil : sortie normale (rendue au système).
      await _androidBack(tester);
      expect(systemPops, ['SystemNavigator.pop']);
      expect(tester.takeException(), isNull);
    });
  });

  group('Bascule de rôle — go, pas push', () {
    GoRouter buildRouter() => GoRouter(
          initialLocation: '/homepage',
          routes: [
            GoRoute(path: '/homepage', builder: (_, __) => const Home()),
            GoRoute(
              path: '/providermain',
              builder: (_, __) => const Scaffold(body: Text('ESPACE PRO')),
            ),
          ],
        );

    testWidgets('rôle PRESTATAIRE : la pile est remplacée par /providermain',
        (tester) async {
      final auth = _TestAuthCubit()..asProvider();
      addTearDown(auth.close);
      final router = buildRouter();
      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: auth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('ESPACE PRO'), findsOneWidget);
      // Une seule page : retour Android ne revient pas sur un Home figé.
      expect(router.routerDelegate.currentConfiguration.matches.length, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'une fiche ouverte au-dessus de Home n’est pas écrasée par la redirection',
        (tester) async {
      final auth = _TestAuthCubit()..asClient();
      addTearDown(auth.close);
      final router = buildRouter();
      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: auth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      final nav = tester.state<NavigatorState>(find.byType(Navigator).last);
      unawaited(nav.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('FICHE REPRISE')),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('FICHE REPRISE'), findsOneWidget);

      auth.asProvider();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('FICHE REPRISE'), findsOneWidget);
      expect(find.text('ESPACE PRO'), findsNothing);

      nav.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('ESPACE PRO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Recherche — périmètre', () {
    Future<void> pumpSearch(WidgetTester tester, Widget screen) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('Freelance sans termes fournis : aucune suggestion Métiers',
        (tester) async {
      await pumpSearch(
        tester,
        const SearchPageScreenM(initialIndex: 2, scope: 'freelance'),
      );
      expect(find.text('Plombier'), findsNothing);
      expect(find.text('Électricien'), findsNothing);
      expect(find.text('Maçon'), findsNothing);
      expect(find.text('À découvrir'), findsNothing);
      expect(find.text('Rechercher une compétence freelance'), findsOneWidget);
    });

    testWidgets('Freelance : seulement les termes réels passés par le hub',
        (tester) async {
      await pumpSearch(
        tester,
        const SearchPageScreenM(
          initialIndex: 2,
          scope: 'freelance',
          discoveryTerms: ['Graphisme', 'Rédaction web'],
        ),
      );
      expect(find.text('Graphisme'), findsOneWidget);
      expect(find.text('Rédaction web'), findsOneWidget);
      expect(find.text('Plombier'), findsNothing);
    });

    testWidgets('Métiers : pas de terme Freelance', (tester) async {
      await pumpSearch(tester, const SearchPageScreenM(scope: 'metiers'));
      expect(find.text('Plombier'), findsOneWidget);
      expect(find.text('Développeur web'), findsNothing);
    });

    testWidgets('clavier ouvert : pas de second inset clavier dans la liste',
        (tester) async {
      await pumpSearch(tester, const SearchPageScreenM(scope: 'freelance'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      final list = tester.widget<ListView>(find.byType(ListView).first);
      final padding = list.padding!.resolve(TextDirection.ltr);
      expect(padding.bottom, lessThan(300));
      expect(tester.takeException(), isNull);
    });
  });

  group('Freelance — retour sur le hub pendant un filtre', () {
    test('ClearFilters éteint le chargement et ignore la réponse tardive',
        () async {
      final gate = Completer<Map<String, dynamic>>();
      final bloc = FreelancePageBlocM(apiClient: _GateFreelanceApi(gate));
      addTearDown(bloc.close);

      final loaded = bloc.stream.firstWhere(
        (s) => s.freelancersLoaded && !s.isLoadingFreelancers,
      );
      bloc.add(LoadFreelancersEvent());
      await loaded.timeout(const Duration(seconds: 3));

      final filtering = bloc.stream.firstWhere((s) => s.isLoadingFreelancers);
      bloc.add(const FilterByCategoryEvent('Design'));
      await filtering.timeout(const Duration(seconds: 3));

      final cleared = bloc.stream.firstWhere(
        (s) => s.selectedCategory == null && !s.isLoadingFreelancers,
      );
      bloc.add(ClearFiltersEvent());
      final state = await cleared.timeout(const Duration(seconds: 3));
      expect(state.freelancers.length, 2);
      expect(state.filteredFreelancers.length, 2);

      // Réponse du filtre abandonné : ne doit plus rien écraser.
      gate.complete({
        'freelances': [_freelance('f3', 'Chloé')],
        'pagination': null,
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.filteredFreelancers.length, 2);
      expect(bloc.state.isLoadingFreelancers, isFalse);
      expect(bloc.state.selectedCategory, isNull);
    });
  });
}
