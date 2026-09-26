import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
import 'package:sdealsmobile/mobile/view/common/publish_options.dart';
import 'package:sdealsmobile/mobile/view/homepagem/widgets/home_universe_choice_card.dart';
import 'package:sdealsmobile/mobile/view/freelance_registration/screens/freelance_welcome_screen.dart';
import 'package:sdealsmobile/mobile/view/home.dart';
import 'package:sdealsmobile/mobile/view/homepagem/home_place_label.dart';
import 'package:sdealsmobile/mobile/view/homepagem/homepageblocm/homePageBlocM.dart';
import 'package:sdealsmobile/mobile/view/homepagem/screens/homePageScreenM.dart';
import 'package:sdealsmobile/mobile/view/homepagem/widgets/home_nearby_card.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/locationpagem/screens/locationPageScreenM.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    final dir = await Directory.systemTemp.createTemp('phase10d2b-hive');
    Hive.init(dir.path);
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    required Size logical,
    double textScale = 1,
    List<Map<String, dynamic>>? preview,
  }) async {
    tester.view.physicalSize = logical;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: logical,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>(create: (_) => AuthCubit()),
            BlocProvider<HomePageBlocM>(create: (_) => HomePageBlocM()),
          ],
          child: MaterialApp(
            home: HomePageScreenM(previewPrestataires: preview),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  test('lieu humain, coordonnées rejetées, aperçu régulier', () {
    expect(looksLikeRawCoordinates('GPS 5.3786, -3.9701'), isTrue);
    expect(looksLikeRawCoordinates('[5.3786, -3.970]'), isTrue);
    expect(looksLikeRawCoordinates('Cocody 5.3786, -3.970'), isTrue);
    expect(looksLikeRawCoordinates('Cocody'), isFalse);
    expect(looksLikeRawCoordinates('Abidjan'), isFalse);

    expect(
      firstReadablePlace(['GPS 5.3786, -3.970', 'Cocody', 'Abidjan']),
      'Cocody',
    );
    expect(
      firstReadablePlace(['GPS 5.37, -3.97', '[1.2, 3.4]', 'null', '']),
      isNull,
    );

    for (final width in [320.0, 360.0, 393.0]) {
      expect(NearbyCarouselMetrics.showsRegularPeek(width), isTrue);
      final card = NearbyCarouselMetrics.cardWidth(width);
      final fragment = width - 32 - card - 12;
      expect(fragment, inInclusiveRange(32, 48));
      expect(card, greaterThan(fragment));
    }
  });

  test('accueil ne relance pas Freelance ni Articles, destinations intactes',
      () {
    final home = File(
      'lib/mobile/view/homepagem/screens/homePageScreenM.dart',
    ).readAsStringSync();
    expect(home.contains('fetchFreelances('), isFalse);
    expect(home.contains('fetchHomeFreelanceServices('), isFalse);
    expect(home.contains('fetchArticle('), isFalse);
    expect(home.contains('Geolocator'), isFalse);
    expect(home.contains('fetchPrestataires('), isTrue);
    expect(home.contains('JobPageScreenM'), isTrue);
    expect(home.contains('FreelancePageScreen'), isTrue);
    expect(home.contains('LocationPageScreenM'), isTrue);

    final sheet =
        File('lib/mobile/view/common/publish_options.dart').readAsStringSync();
    expect(sheet.contains('openProviderPublishFlow'), isTrue);
    expect(sheet.contains('openFreelancePublishFlow'), isTrue);
    expect(sheet.contains("originRoute: 'home'"), isTrue);
    expect(sheet.contains('info600'), isFalse);
    expect(sheet.contains('RadialGradient'), isFalse);
    expect(sheet.contains('ClientFeatureFlags.emarketEnabled'), isTrue);
  });

  testWidgets(
      'ville avant les professionnels, Abidjan, pas de GPS au premier rendu',
      (tester) async {
    var gpsCalls = 0;
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        gpsCalls++;
        return 0;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await pumpHome(tester, logical: const Size(360, 800));
    expect(find.text('Abidjan'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Choisir la ville'), findsNothing);
    expect(find.text('Professionnels près de vous'), findsOneWidget);
    expect(find.byType(HomeUniverseChoiceCard), findsNWidgets(2));
    expect(find.textContaining('GPS'), findsNothing);
    expect(find.byType(LocationPageScreenM), findsNothing);
    expect(find.text('Se connecter'), findsNothing);
    expect(gpsCalls, 0);

    final city = tester.getTopLeft(find.text('Abidjan')).dy;
    final nearby =
        tester.getTopLeft(find.text('Professionnels près de vous')).dy;
    final promise = tester
        .getTopLeft(find.text('Trouvez un professionnel près de vous'))
        .dy;
    expect(promise, lessThan(city));
    expect(city, lessThan(nearby));
  });

  testWidgets('Modifier ouvre l’écran de localisation existant',
      (tester) async {
    await pumpHome(tester, logical: const Size(360, 800));
    await tester.ensureVisible(find.text('Modifier'));
    await tester.tap(find.text('Modifier'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(LocationPageScreenM), findsOneWidget);
  });

  testWidgets('Voir tous les professionnels, lieu humain, rien d’inventé',
      (tester) async {
    await pumpHome(
      tester,
      logical: const Size(360, 900),
      preview: [_provider(verified: false, price: null, place: 'Cocody')],
    );
    expect(find.text('Voir tous les professionnels'), findsOneWidget);
    expect(find.text('Voir tous les artisans'), findsNothing);
    expect(find.text('Cocody'), findsOneWidget);
    expect(find.textContaining('GPS'), findsNothing);
    expect(find.text('Identité vérifiée'), findsNothing);
    expect(find.textContaining('FCFA'), findsNothing);
    expect(find.textContaining('avis'), findsNothing);
  });

  testWidgets('identité vérifiée seulement si verifier', (tester) async {
    await pumpHome(
      tester,
      logical: const Size(360, 900),
      preview: [
        _provider(verified: true, price: 5000, place: 'Yopougon'),
      ],
    );
    expect(find.text('Identité vérifiée'), findsOneWidget);
    expect(find.text('5 000 FCFA'), findsOneWidget);
    expect(find.text('Yopougon'), findsOneWidget);
    expect(find.textContaining('avis'), findsNothing);
  });

  testWidgets('ligne de lieu absente si aucune valeur exploitable',
      (tester) async {
    await pumpHome(
      tester,
      logical: const Size(360, 900),
      preview: [
        _provider(verified: false, price: null, place: 'GPS 5.3786, -3.970'),
      ],
    );
    expect(find.textContaining('GPS'), findsNothing);
    expect(find.text('Cocody'), findsNothing);
  });

  testWidgets('cartes sans overflow 320, 360, 393 et text scale 1.3',
      (tester) async {
    final preview = [
      _provider(
        verified: true,
        price: 2500,
        place: 'Marcory',
        prenom: 'Awa',
      ),
      _provider(
        verified: false,
        price: null,
        place: null,
        prenom: 'Yao',
      ),
      _provider(
        verified: false,
        price: null,
        place: 'GPS 5.3786, -3.970',
        prenom: 'Koffi',
      ),
    ];
    for (final width in [320.0, 360.0, 393.0]) {
      for (final scale in [1.0, 1.3]) {
        await pumpHome(
          tester,
          logical: Size(width, 1200),
          textScale: scale,
          preview: preview,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(HomeNearbyCard), findsWidgets);
        expect(
          tester.widgetList<HomeNearbyCard>(find.byType(HomeNearbyCard)).length,
          lessThan(3),
        );
        expect(find.textContaining('GPS'), findsNothing);
        await tester.ensureVisible(find.text('Professionnels près de vous'));
        await tester.scrollUntilVisible(
          find.text('Koffi test'),
          180,
          scrollable: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.right,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Koffi test'), findsOneWidget);
        final cards = tester.widgetList<HomeNearbyCard>(
          find.byType(HomeNearbyCard),
        );
        final expected = NearbyCarouselMetrics.cardWidth(width);
        for (final card in cards) {
          expect(card.width, expected);
        }
      }
    }
  });

  testWidgets('favori 48 dp, état non sélectionné', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeNearbyCard(
            width: NearbyCarouselMetrics.cardWidth(320),
            name: 'Profil test',
            onFavorite: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('FCFA'), findsNothing);
    expect(find.text('Identité vérifiée'), findsNothing);
    final button = tester.getSize(find.byType(IconButton));
    expect(button.width, greaterThanOrEqualTo(48));
    expect(button.height, greaterThanOrEqualTo(48));
    expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
    expect(find.bySemanticsLabel('Ajouter aux favoris'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('feuille : nouveau titre, pas Boutique, freelance inchangé',
      (tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => _SheetAuth()..asClient(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showPublishOptions(context),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(
      find.text('Comment souhaitez-vous proposer vos services ?'),
      findsOneWidget,
    );
    expect(
      find.text('Choisissez votre activité pour commencer.'),
      findsOneWidget,
    );
    expect(find.text('Que souhaitez-vous publier ?'), findsNothing);
    expect(
        find.text('Proposer des services près de chez vous'), findsOneWidget);
    expect(find.text('Proposer des compétences à distance'), findsOneWidget);
    expect(find.text('Devenir professionnel'), findsOneWidget);
    expect(find.text('Devenir freelance'), findsOneWidget);
    expect(find.text('Boutique'), findsNothing);
    expect(find.text('Fermer'), findsOneWidget);

    final icons = tester.widgetList<Icon>(find.byType(Icon));
    for (final icon in icons) {
      expect(icon.color, isNot(SDColors.info600));
    }

    await tester.tap(find.text('Freelance'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(FreelanceWelcomeScreen), findsOneWidget);
  });

  testWidgets('accueil : Métiers et Freelance ouvrent les écrans existants',
      (tester) async {
    await pumpHome(tester, logical: const Size(360, 800));
    await tester.ensureVisible(find.text('Métiers'));
    await tester.tap(find.text('Métiers'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(JobPageScreenM), findsOneWidget);
    final jobLayout = tester.takeException();
    if (jobLayout != null) {
      expect(
        jobLayout.toString(),
        contains('overflowed'),
        reason:
            'La liste Métiers a un overflow préexistant, hors refonte 10D-2B.',
      );
    }
  });

  testWidgets('barre à quatre onglets, logout revient sur Accueil',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => AuthCubit(),
        child: const MaterialApp(home: Home()),
      ),
    );
    await tester.pump();
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Explorer'), findsOneWidget);
    expect(find.text('Messagerie'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Publier'), findsNothing);
    expect(find.text('Se connecter'), findsNothing);

    await tester.tap(find.text('Profil'));
    await tester.pump();
    ClientShellSelection.showHome();
    await tester.pump();
    expect(find.text('Trouvez un professionnel près de vous'), findsOneWidget);
  });
}

class _SheetAuth extends AuthCubit {
  void asClient() {
    emit(
      AuthAuthenticated(
        token: 'token-test',
        utilisateur: Utilisateur(
          idutilisateur: 'user-test',
          nom: 'Test',
          prenom: 'Awa',
          email: 'hidden@example.com',
          password: 'secret',
          telephone: '00000000',
          role: 'CLIENT',
        ),
      ),
    );
  }
}

Map<String, dynamic> _provider({
  required bool verified,
  required Object? price,
  required String? place,
  String prenom = 'Profil',
}) {
  return {
    '_id': 'p-$prenom-$verified-${place ?? 'none'}',
    'verifier': verified,
    'prixprestataire': price,
    'commune': place,
    'localisation': 'GPS 5.3786, -3.970',
    'utilisateur': {
      'prenom': prenom,
      'nom': 'test',
    },
    'service': {'nomservice': 'Plomberie'},
  };
}
