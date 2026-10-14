import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/orderpagem/screens/service_requests_list_screen.dart';
import 'package:sdealsmobile/mobile/view/orderpagem/servicerequestcubit/service_request_cubit.dart';

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
    ServiceRequestCubit.debugFetchMine = () async => <Map<String, dynamic>>[];
  });

  tearDown(ServiceRequestCubit.debugReset);

  Future<void> pumpOrders(
    WidgetTester tester, {
    required AuthCubit auth,
    Size size = const Size(390, 844),
    bool reduceMotion = false,
    bool tickersEnabled = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
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
          home: const ServiceRequestsListScreen(),
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

  Map<String, dynamic> order({String status = 'EN_COURS'}) => {
        '_id': 'order-1',
        'status': status,
        'service': {'nom': 'Coiffure'},
      };

  Future<void> reload(WidgetTester tester) async {
    final cubit =
        tester.element(find.text('Mes demandes')).read<ServiceRequestCubit>();
    await cubit.fetchMine(token: 'token-test', utilisateurId: 'user-test');
    await tester.pump();
    await tester.pump();
  }

  testWidgets('connecté sans commande affiche SD-ILL-005', (tester) async {
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);

    await pumpOrders(tester, auth: auth);
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.ordersEmptyConnected);
    expect(find.text('Aucune commande pour le moment.'), findsOneWidget);
    expect(find.byType(SDIllustration), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le chargement ne montre pas SD-ILL-005', (tester) async {
    final gate = Completer<List<Map<String, dynamic>>>();
    ServiceRequestCubit.debugFetchMine = () => gate.future;
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);

    await pumpOrders(tester, auth: auth);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);
    expect(find.text('Aucune commande pour le moment.'), findsNothing);

    gate.complete(<Map<String, dynamic>>[]);
    await tester.pump();
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.ordersEmptyConnected);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une erreur de chargement ne montre pas SD-ILL-005',
      (tester) async {
    ServiceRequestCubit.debugFetchMine = () async => throw Exception('réseau');
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);

    await pumpOrders(tester, auth: auth);
    await tester.pump();

    expect(find.byType(SDIllustration), findsNothing);
    expect(find.text('Aucune commande pour le moment.'), findsNothing);
    expect(find.textContaining('réseau'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une commande n’affiche pas SD-ILL-005', (tester) async {
    ServiceRequestCubit.debugFetchMine = () async => [order()];
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);

    await pumpOrders(tester, auth: auth);
    await tester.pump();

    expect(find.text('Coiffure'), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la première commande retire SD-ILL-005', (tester) async {
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);

    await pumpOrders(tester, auth: auth);
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.ordersEmptyConnected);

    ServiceRequestCubit.debugFetchMine = () async => [order()];
    await reload(tester);

    expect(find.byType(SDIllustration), findsNothing);
    expect(find.text('Coiffure'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une liste revenue à zéro affiche SD-ILL-005', (tester) async {
    ServiceRequestCubit.debugFetchMine = () async => [order()];
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);

    await pumpOrders(tester, auth: auth);
    await tester.pump();
    expect(find.text('Coiffure'), findsOneWidget);

    ServiceRequestCubit.debugFetchMine = () async => <Map<String, dynamic>>[];
    await reload(tester);

    expect(shownAsset(tester), SDIllustrations.ordersEmptyConnected);
    expect(find.text('Coiffure'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un filtre vide ne montre pas SD-ILL-005', (tester) async {
    ServiceRequestCubit.debugFetchMine =
        () async => [order(status: 'TERMINEE')];
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);

    await pumpOrders(tester, auth: auth);
    await tester.pump();
    expect(find.text('Coiffure'), findsOneWidget);

    await tester.tap(find.text('En attente'));
    await tester.pump();

    expect(find.byType(SDIllustration), findsNothing);
    expect(find.text('Aucune commande pour le moment.'), findsOneWidget);
    expect(find.text('Coiffure'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invité puis connexion', (tester) async {
    final auth = _TestAuthCubit()..asGuest();
    addTearDown(auth.close);

    await pumpOrders(tester, auth: auth);
    expect(find.text('Vos commandes'), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);

    auth.asClient();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Vos commandes'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(shownAsset(tester), SDIllustrations.ordersEmptyConnected);
    expect(find.text('Vos commandes'), findsNothing);

    auth.asGuest();
    await tester.pump();

    expect(find.text('Vos commandes'), findsOneWidget);
    expect(find.byType(SDIllustration), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('petit et grand écran sans overflow', (tester) async {
    for (final size in const [Size(320, 568), Size(1024, 1366)]) {
      final auth = _TestAuthCubit()..asClient();
      addTearDown(auth.close);
      await pumpOrders(tester, auth: auth, size: size);
      await tester.pump();
      expect(shownAsset(tester), SDIllustrations.ordersEmptyConnected);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Reduce Motion fige SD-ILL-005', (tester) async {
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);

    await pumpOrders(tester, auth: auth, reduceMotion: true);
    await tester.pump();

    final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
    expect(lottie.animate, isFalse);
    expect(shownAsset(tester), SDIllustrations.ordersEmptyConnected);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onglet masqué puis arrière-plan ne casse pas l’état vide',
      (tester) async {
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);

    await pumpOrders(tester, auth: auth);
    await tester.pump();
    expect(shownAsset(tester), SDIllustrations.ordersEmptyConnected);

    await pumpOrders(tester, auth: auth, tickersEnabled: false);
    await pumpOrders(tester, auth: auth);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(shownAsset(tester), SDIllustrations.ordersEmptyConnected);
    expect(find.byType(SDIllustration), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
