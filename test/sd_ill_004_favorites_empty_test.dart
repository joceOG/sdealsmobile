import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/favorispagem/favorispageblocm/favoritePageBlocM.dart';
import 'package:sdealsmobile/mobile/view/favorispagem/favorispageblocm/favoritePageEventM.dart';
import 'package:sdealsmobile/mobile/view/favorispagem/screens/favorite_page_screen_m.dart';

class _TestAuthCubit extends AuthCubit {
  void asClient() {
    emit(
      AuthAuthenticated(
        token: 'token-test',
        utilisateur: Utilisateur(
          idutilisateur: 'user-test',
          nom: 'Kouassi',
          prenom: 'Awa',
          email: 'hidden@example.com',
          password: 'secret',
          telephone: '00000000',
          role: 'CLIENT',
        ),
      ),
    );
  }

  void asGuest() => emit(AuthInitial());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    FavoritePageBlocM.debugGet = (_) async => http.Response(
          jsonEncode({'favorites': <Object>[]}),
          200,
        );
  });

  tearDown(FavoritePageBlocM.debugReset);

  Future<void> pumpFavorites(
    WidgetTester tester, {
    required AuthCubit auth,
    required FavoritePageBlocM bloc,
    Size size = const Size(390, 844),
    bool reduceMotion = false,
    bool tickersEnabled = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<FavoritePageBlocM>.value(value: bloc),
        ],
        child: MaterialApp(
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return TickerMode(
              enabled: tickersEnabled,
              child: MediaQuery(
                data: media.copyWith(disableAnimations: reduceMotion),
                child: child!,
              ),
            );
          },
          home: const FavoritePageScreenM(),
        ),
      ),
    );
    await tester.pump();
  }

  String? shownAsset(WidgetTester tester) {
    final found = find.byType(SDIllustration);
    if (found.evaluate().isEmpty) return null;
    return tester.widget<SDIllustration>(found).asset;
  }

  Map<String, dynamic> favoriteJson() => {
        '_id': 'fav-1',
        'utilisateur': {
          '_id': 'user-test',
          'nom': 'Kouassi',
          'prenom': 'Awa',
          'email': 'hidden@example.com',
          'password': 'secret',
          'telephone': '00000000',
        },
        'objetType': 'PRESTATAIRE',
        'objetId': 'p1',
        'titre': 'Awa Kouassi',
        'categorie': 'Plombier',
        'localisation': {'ville': 'Cocody', 'pays': "Côte d'Ivoire"},
        'statut': 'ACTIF',
        'dateAjout': '2026-01-01T00:00:00.000Z',
        'dateDerniereConsultation': '2026-01-01T00:00:00.000Z',
      };

  void respondWith(List<Map<String, dynamic>> favorites) {
    FavoritePageBlocM.debugGet = (_) async => http.Response(
          jsonEncode({'favorites': favorites}),
          200,
        );
  }

  testWidgets('connecté sans favori affiche SD-ILL-004', (tester) async {
    final auth = _TestAuthCubit()..asClient();
    final bloc = FavoritePageBlocM();
    addTearDown(auth.close);
    addTearDown(bloc.close);

    await pumpFavorites(tester, auth: auth, bloc: bloc);
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.favoritesEmptyConnected);
    expect(find.text('Aucun favori pour le moment'), findsOneWidget);
    expect(
      find.text(
        'Enregistrez les profils qui vous plaisent pour les retrouver ici.',
      ),
      findsOneWidget,
    );
    expect(find.text('Explorer'), findsOneWidget);
    expect(find.text('Rechercher un favori'), findsOneWidget);
    expect(find.text('Tous'), findsOneWidget);
    expect(find.text('Métiers'), findsOneWidget);
    expect(find.text('Freelance'), findsOneWidget);
    expect(find.text('Vente & Achat'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le chargement ne montre pas SD-ILL-004', (tester) async {
    final gate = Completer<http.Response>();
    FavoritePageBlocM.debugGet = (_) => gate.future;
    final auth = _TestAuthCubit()..asClient();
    final bloc = FavoritePageBlocM();
    addTearDown(auth.close);
    addTearDown(bloc.close);

    await pumpFavorites(tester, auth: auth, bloc: bloc);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);
    expect(find.text('Aucun favori pour le moment'), findsNothing);

    gate.complete(
      http.Response(jsonEncode({'favorites': <Object>[]}), 200),
    );
    await tester.pump();
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.favoritesEmptyConnected);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une erreur de chargement ne montre pas SD-ILL-004',
      (tester) async {
    FavoritePageBlocM.debugGet = (_) async => http.Response('{}', 500);
    final auth = _TestAuthCubit()..asClient();
    final bloc = FavoritePageBlocM();
    addTearDown(auth.close);
    addTearDown(bloc.close);

    await pumpFavorites(tester, auth: auth, bloc: bloc);
    await tester.pump();

    expect(find.byType(SDIllustration), findsNothing);
    expect(find.text('Aucun favori pour le moment'), findsNothing);
    expect(find.text('Erreur lors du chargement des favoris'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un favori n’affiche pas SD-ILL-004', (tester) async {
    respondWith([favoriteJson()]);
    final auth = _TestAuthCubit()..asClient();
    final bloc = FavoritePageBlocM();
    addTearDown(auth.close);
    addTearDown(bloc.close);

    await pumpFavorites(tester, auth: auth, bloc: bloc);
    await tester.pump();

    expect(find.text('Awa Kouassi'), findsOneWidget);
    expect(find.text('Plombier'), findsOneWidget);
    expect(find.text('Cocody'), findsOneWidget);
    expect(find.text('Métiers'), findsWidgets);
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
    expect(find.text('Rechercher un favori'), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le premier favori retire SD-ILL-004', (tester) async {
    final auth = _TestAuthCubit()..asClient();
    final bloc = FavoritePageBlocM();
    addTearDown(auth.close);
    addTearDown(bloc.close);

    await pumpFavorites(tester, auth: auth, bloc: bloc);
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.favoritesEmptyConnected);

    respondWith([favoriteJson()]);
    bloc.add(const LoadFavoritesM());
    await tester.pump();
    await tester.pump();

    expect(find.byType(SDIllustration), findsNothing);
    expect(find.text('Awa Kouassi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supprimer le dernier favori affiche SD-ILL-004', (tester) async {
    respondWith([favoriteJson()]);
    final auth = _TestAuthCubit()..asClient();
    final bloc = FavoritePageBlocM();
    addTearDown(auth.close);
    addTearDown(bloc.close);

    await pumpFavorites(tester, auth: auth, bloc: bloc);
    await tester.pump();
    expect(find.text('Awa Kouassi'), findsOneWidget);

    respondWith([]);
    bloc.add(const LoadFavoritesM());
    await tester.pump();
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.favoritesEmptyConnected);
    expect(find.text('Awa Kouassi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invité ne voit pas SD-ILL-004', (tester) async {
    final auth = _TestAuthCubit()..asGuest();
    final bloc = FavoritePageBlocM();
    addTearDown(auth.close);
    addTearDown(bloc.close);

    await pumpFavorites(tester, auth: auth, bloc: bloc);
    await tester.pump();

    expect(find.text('Vos coups de cœur'), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);
    expect(find.text('Aucun favori pour le moment'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('petit et grand écran sans overflow', (tester) async {
    for (final size in const [Size(320, 568), Size(1024, 1366)]) {
      final auth = _TestAuthCubit()..asClient();
      final bloc = FavoritePageBlocM();
      addTearDown(auth.close);
      addTearDown(bloc.close);

      await pumpFavorites(tester, auth: auth, bloc: bloc, size: size);
      await tester.pump();

      expect(shownAsset(tester), SDIllustrations.favoritesEmptyConnected);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Reduce Motion fige SD-ILL-004', (tester) async {
    final auth = _TestAuthCubit()..asClient();
    final bloc = FavoritePageBlocM();
    addTearDown(auth.close);
    addTearDown(bloc.close);

    await pumpFavorites(
      tester,
      auth: auth,
      bloc: bloc,
      reduceMotion: true,
    );
    await tester.pump();

    final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
    expect(lottie.animate, isFalse);
    expect(shownAsset(tester), SDIllustrations.favoritesEmptyConnected);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onglet masqué puis arrière-plan ne casse pas l’état vide',
      (tester) async {
    final auth = _TestAuthCubit()..asClient();
    final bloc = FavoritePageBlocM();
    addTearDown(auth.close);
    addTearDown(bloc.close);

    await pumpFavorites(tester, auth: auth, bloc: bloc);
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.favoritesEmptyConnected);

    await pumpFavorites(
      tester,
      auth: auth,
      bloc: bloc,
      tickersEnabled: false,
    );
    await pumpFavorites(tester, auth: auth, bloc: bloc);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.favoritesEmptyConnected);
    expect(find.byType(SDIllustration), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
