import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/skeleton_loader.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageEventM.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    SharedPreferences.setMockInitialValues({});
    SearchPageBlocM.debugSearch = (_) async => _payload();
  });

  tearDown(SearchPageBlocM.debugReset);

  Future<void> pumpSearch(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    bool reduceMotion = false,
    bool tickersEnabled = true,
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
        home: const SearchPageScreenM(),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  SearchPageBlocM blocOf(WidgetTester tester) {
    return tester.element(find.byType(TextField).first).read<SearchPageBlocM>();
  }

  String? shownAsset(WidgetTester tester) {
    final found = find.byType(SDIllustration);
    if (found.evaluate().isEmpty) return null;
    return tester.widget<SDIllustration>(found).asset;
  }

  testWidgets('aucune recherche n’affiche pas SD-ILL-006', (tester) async {
    await pumpSearch(tester);

    expect(find.text('Plombier'), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);
    expect(find.text('Aucun résultat'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une recherche à zéro affiche SD-ILL-006', (tester) async {
    await pumpSearch(tester);
    blocOf(tester).add(const PerformGlobalSearch('zzzz'));
    await tester.pump();
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.searchEmpty);
    expect(find.text('Aucun résultat'), findsOneWidget);
    expect(find.textContaining('zzzz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le chargement ne montre pas SD-ILL-006', (tester) async {
    final gate = Completer<Map<String, dynamic>>();
    SearchPageBlocM.debugSearch = (_) => gate.future;
    await pumpSearch(tester);
    blocOf(tester).add(const PerformGlobalSearch('zzzz'));
    await tester.pump();

    expect(find.byType(SkeletonList), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);
    expect(find.text('Aucun résultat'), findsNothing);

    gate.complete(_payload());
    await tester.pump();
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.searchEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une recherche avec résultat n’affiche pas SD-ILL-006',
      (tester) async {
    SearchPageBlocM.debugSearch = (_) async => _payload(
          services: [
            {'nomservice': 'Plomberie'},
          ],
        );
    await pumpSearch(tester);
    blocOf(tester).add(const PerformGlobalSearch('plomb'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Plomberie'), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une nouvelle recherche retire SD-ILL-006 puis affiche la liste',
      (tester) async {
    final first = Completer<Map<String, dynamic>>();
    final second = Completer<Map<String, dynamic>>();
    SearchPageBlocM.debugSearch = (_) => first.future;
    await pumpSearch(tester);
    final bloc = blocOf(tester);
    bloc.add(const PerformGlobalSearch('aaaa'));
    await tester.pump();
    expect(find.byType(SDIllustration), findsNothing);

    first.complete(_payload());
    await tester.pump();
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.searchEmpty);

    SearchPageBlocM.debugSearch = (_) => second.future;
    bloc.add(const PerformGlobalSearch('bbbb'));
    await tester.pump();
    expect(find.byType(SkeletonList), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);

    second.complete(_payload(services: [
      {'nomservice': 'Menuiserie'},
    ]));
    await tester.pump();
    await tester.pump();

    expect(find.text('Menuiserie'), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('effacer la recherche revient à l’état initial', (tester) async {
    await pumpSearch(tester);
    final bloc = blocOf(tester);
    bloc.add(const PerformGlobalSearch('zzzz'));
    await tester.pump();
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.searchEmpty);

    bloc.add(ClearSearch());
    await tester.pump();
    await tester.pump();

    expect(find.byType(SDIllustration), findsNothing);
    expect(find.text('Aucun résultat'), findsNothing);
    expect(find.text('Plombier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une erreur de recherche ne montre pas SD-ILL-006',
      (tester) async {
    SearchPageBlocM.debugSearch = (_) async => throw Exception('réseau');
    await pumpSearch(tester);
    blocOf(tester).add(const PerformGlobalSearch('zzzz'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SDIllustration), findsNothing);
    expect(find.text('Aucun résultat'), findsNothing);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'un changement de filtre ne montre pas SD-ILL-006 pendant le chargement',
      (tester) async {
    await pumpSearch(tester);
    final bloc = blocOf(tester);
    bloc.add(const PerformGlobalSearch('zzzz'));
    await tester.pump();
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.searchEmpty);

    final gate = Completer<Map<String, dynamic>>();
    SearchPageBlocM.debugSearch = (_) => gate.future;
    bloc.add(
        const UpdateFilters(minPrice: 1000, maxPrice: 5000, city: 'Cocody'));
    bloc.add(const PerformGlobalSearch('zzzz'));
    await tester.pump();

    expect(find.byType(SkeletonList), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);

    gate.complete(_payload());
    await tester.pump();
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.searchEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('petit et grand écran sans overflow', (tester) async {
    for (final size in const [Size(320, 568), Size(1024, 1366)]) {
      await pumpSearch(tester, size: size);
      blocOf(tester).add(const PerformGlobalSearch('zzzz'));
      await tester.pump();
      await tester.pump();
      expect(shownAsset(tester), SDIllustrations.searchEmpty);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Reduce Motion fige SD-ILL-006', (tester) async {
    await pumpSearch(tester, reduceMotion: true);
    blocOf(tester).add(const PerformGlobalSearch('zzzz'));
    await tester.pump();
    await tester.pump();

    final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
    expect(lottie.animate, isFalse);
    expect(shownAsset(tester), SDIllustrations.searchEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrière-plan puis retour conserve l’état vide', (tester) async {
    await pumpSearch(tester);
    blocOf(tester).add(const PerformGlobalSearch('zzzz'));
    await tester.pump();
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.searchEmpty);

    await pumpSearch(tester, tickersEnabled: false);
    await pumpSearch(tester);
    blocOf(tester).add(const PerformGlobalSearch('zzzz'));
    await tester.pump();
    await tester.pump();
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

    expect(shownAsset(tester), SDIllustrations.searchEmpty);
    expect(find.byType(SDIllustration), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _payload({List<Map<String, dynamic>>? services}) {
  final items = services ?? const <Map<String, dynamic>>[];
  return {
    'results': {
      'services': items,
      'articles': <Map<String, dynamic>>[],
      'freelances': <Map<String, dynamic>>[],
      'prestataires': <Map<String, dynamic>>[],
      'vendeurs': <Map<String, dynamic>>[],
    },
    'counts': {
      'services': items.length,
      'articles': 0,
      'freelances': 0,
      'prestataires': 0,
      'vendeurs': 0,
    },
  };
}
