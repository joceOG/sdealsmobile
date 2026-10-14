import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageEventM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/detailPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    DetailPage.debugFetchPrestataires = (_) async => const [];
  });

  tearDown(DetailPage.debugReset);

  Future<void> pumpDetail(
    WidgetTester tester, {
    String? serviceId = 'svc-plomberie',
    Size size = const Size(390, 844),
    bool reduceMotion = false,
    bool tickersEnabled = true,
    Key? key,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
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
        home: DetailPage(
          key: key,
          title: 'Plomberie',
          image: 'assets/profil_vide.png',
          serviceId: serviceId,
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

  Map<String, dynamic> provider(String prenom) => {
        '_id': 'p-$prenom',
        'verifier': false,
        'localisation': 'Cocody',
        'prixprestataire': 5000,
        'utilisateur': {
          'nom': 'Kouassi',
          'prenom': prenom,
          'role': 'PRESTATAIRE',
        },
        'service': {'_id': 'svc-plomberie', 'nomservice': 'Plomberie'},
      };

  testWidgets('le chargement initial ne montre pas SD-ILL-007', (tester) async {
    final gate = Completer<List<Map<String, dynamic>>>();
    DetailPage.debugFetchPrestataires = (_) => gate.future;
    await pumpDetail(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(shownAsset(tester), isNull);
    expect(find.text('Aucun prestataire pour ce service pour le moment.'),
        findsNothing);

    gate.complete(const []);
    await tester.pump();
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.professionalsEmpty);
  });

  testWidgets('un service sans prestataire affiche SD-ILL-007', (tester) async {
    await pumpDetail(tester);
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.professionalsEmpty);
    expect(find.text('Aucun prestataire pour ce service pour le moment.'),
        findsOneWidget);
    expect(find.text('Aucun résultat'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un service avec prestataire n’affiche pas SD-ILL-007',
      (tester) async {
    DetailPage.debugFetchPrestataires = (_) async => [provider('Awa')];
    await pumpDetail(tester);
    await tester.pump();

    expect(find.textContaining('Awa'), findsWidgets);
    expect(shownAsset(tester), isNull);
  });

  testWidgets('une erreur API ne montre pas SD-ILL-007', (tester) async {
    DetailPage.debugFetchPrestataires = (_) async {
      throw Exception('réseau');
    };
    await pumpDetail(tester);
    await tester.pump();
    await tester.pump();

    expect(shownAsset(tester), isNull);
    // Erreur ≠ vide : message lisible + Réessayer, pas l'exception brute.
    expect(find.text('Impossible de charger les données. Réessayez.'),
        findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.text('Aucun prestataire pour ce service pour le moment.'),
        findsNothing);
    expect(find.text('Chargement des professionnels…'), findsNothing);
  });

  testWidgets('Réessayer après erreur recharge la liste', (tester) async {
    var calls = 0;
    DetailPage.debugFetchPrestataires = (_) async {
      calls++;
      if (calls == 1) throw Exception('réseau');
      return [provider('Awa')];
    };
    await pumpDetail(tester);
    await tester.pump();
    await tester.pump();
    expect(find.text('Réessayer'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump();

    expect(calls, 2);
    expect(find.textContaining('Awa'), findsWidgets);
    expect(find.text('Réessayer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vide chargé : pas de « Chargement… » à côté de l’état vide',
      (tester) async {
    await pumpDetail(tester);
    await tester.pump();

    expect(find.text('Aucun prestataire pour ce service pour le moment.'),
        findsOneWidget);
    expect(find.text('Chargement des professionnels…'), findsNothing);
    expect(find.text('Aucun prestataire disponible'), findsOneWidget);
  });

  testWidgets('sans service identifié, pas de SD-ILL-007', (tester) async {
    await pumpDetail(tester, serviceId: null);
    await tester.pump();

    expect(shownAsset(tester), isNull);
    expect(find.textContaining('pas identifié'), findsOneWidget);
    expect(find.text('Aucun prestataire pour ce service pour le moment.'),
        findsNothing);
    expect(find.text('Chargement des professionnels…'), findsNothing);
  });

  testWidgets('un filtre client vide ne montre pas SD-ILL-007', (tester) async {
    DetailPage.debugFetchPrestataires = (_) async => [provider('Awa')];
    await pumpDetail(tester);
    await tester.pump();
    expect(shownAsset(tester), isNull);

    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();

    expect(shownAsset(tester), isNull);
    expect(
      find.text(
        'Aucun résultat avec ces filtres. Modifiez la recherche ou les filtres.',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.textContaining('Awa'), findsWidgets);
    expect(shownAsset(tester), isNull);
  });

  testWidgets('changer de service retire SD-ILL-007 pendant le chargement',
      (tester) async {
    await pumpDetail(tester, key: const ValueKey('a'));
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.professionalsEmpty);

    final gate = Completer<List<Map<String, dynamic>>>();
    DetailPage.debugFetchPrestataires = (_) => gate.future;
    await pumpDetail(tester,
        key: const ValueKey('b'), serviceId: 'svc-menuiserie');
    expect(shownAsset(tester), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete([provider('Yao')]);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Yao'), findsWidgets);
    expect(shownAsset(tester), isNull);
  });

  testWidgets('petit et grand écran sans overflow', (tester) async {
    for (final size in const [Size(320, 568), Size(1024, 1366)]) {
      await pumpDetail(tester, size: size);
      await tester.pump();
      expect(shownAsset(tester), SDIllustrations.professionalsEmpty);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Reduce Motion fige SD-ILL-007', (tester) async {
    await pumpDetail(tester, reduceMotion: true);
    await tester.pump();

    final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
    expect(lottie.animate, isFalse);
    expect(shownAsset(tester), SDIllustrations.professionalsEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrière-plan puis retour conserve l’état vide', (tester) async {
    await pumpDetail(tester);
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.professionalsEmpty);

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

    expect(shownAsset(tester), SDIllustrations.professionalsEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Métiers : pas d’illustration avant la fin du chargement',
      (tester) async {
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => 0,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final gates = <Completer<List<Map<String, dynamic>>>>[];
    final bloc = JobPageBlocM(
      fetchCategories: (_) async => const [],
      fetchServices: (_) async => const [],
      fetchShortcuts: ({scope = 'metiers'}) async => const [],
      fetchPrestataires: ({
        forceRefresh = false,
        page = 1,
        limit = 20,
        serviceId,
        categorieId,
      }) {
        final gate = Completer<List<Map<String, dynamic>>>();
        gates.add(gate);
        return gate.future;
      },
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<JobPageBlocM>.value(
        value: bloc,
        child: const MaterialApp(home: JobPageScreenM()),
      ),
    );
    await tester.pump();
    expect(shownAsset(tester), isNull);

    await tester.pump();
    if (!bloc.state.isNearbyLoading && !bloc.state.isMatchingLoading) {
      bloc.add(const LoadProviderMatchingM(
        serviceType: 'Plomberie',
        location: '',
        serviceId: 'svc-plomberie',
      ));
      await tester.pump();
    }
    expect(
      bloc.state.isNearbyLoading || bloc.state.isMatchingLoading,
      isTrue,
    );
    expect(shownAsset(tester), isNull);

    gates.last.complete(const []);
    await tester.pump();
    await tester.pump();
    expect(find.text('Aucun professionnel pour ces filtres'), findsOneWidget);
    expect(shownAsset(tester), SDIllustrations.professionalsEmpty);

    bloc.add(const LoadNearbyProvidersM(
      latitude: 5.3,
      longitude: -4.0,
      radius: 5,
    ));
    await tester.pump();
    expect(bloc.state.isNearbyLoading, isTrue);
    expect(shownAsset(tester), isNull);

    gates.last.complete([
      {
        '_id': '507f1f77bcf86cd799439011',
        'verifier': true,
        'prixprestataire': 12000,
        'localisation': 'Port-Bouët',
        'utilisateur': {
          '_id': '507f1f77bcf86cd799439012',
          'nom': 'Residence',
          'prenom': 'Chapechape',
          'email': 'a@b.c',
          'telephone': '0700000000',
          'role': 'PRESTATAIRE',
        },
        'service': {
          '_id': '507f1f77bcf86cd799439013',
          'nomservice': 'Serrurier',
          'imageservice': '',
          'prixmoyen': '10000',
        },
      },
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Chapechape'), findsWidgets);
    expect(shownAsset(tester), isNull);
    expect(tester.takeException(), isNull);
  });
}
