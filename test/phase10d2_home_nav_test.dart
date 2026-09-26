import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
import 'package:sdealsmobile/mobile/view/common/publish_options.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/client_universe_pictograms.dart';
import 'package:sdealsmobile/mobile/view/home.dart';
import 'package:sdealsmobile/mobile/view/homepagem/homepageblocm/homePageBlocM.dart';
import 'package:sdealsmobile/mobile/view/homepagem/screens/homePageScreenM.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/profilpageblocm/profilPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/profilPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';

class _TestAuthCubit extends AuthCubit {
  void asClient({String prenom = 'Awa'}) {
    emit(
      AuthAuthenticated(
        token: 'token-test',
        utilisateur: Utilisateur(
          idutilisateur: 'user-test',
          nom: 'Kouassi',
          prenom: prenom,
          email: 'hidden@example.com',
          password: 'secret',
          telephone: '00000000',
          role: 'CLIENT',
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    final dir = await Directory.systemTemp.createTemp('phase10d2-hive');
    Hive.init(dir.path);
    ProtectedActionStore.instance.clear();
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    required Size logical,
    double textScale = 1,
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
          child: const MaterialApp(home: HomePageScreenM()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('accueil 320 à 393, scale 1.0 et 1.3, sans overflow',
      (tester) async {
    for (final width in [320.0, 360.0, 393.0]) {
      for (final scale in [1.0, 1.3]) {
        await pumpHome(tester, logical: Size(width, 800), textScale: scale);
        expect(tester.takeException(), isNull);
        expect(
            find.text('Trouvez un professionnel près de vous'), findsOneWidget);
        expect(find.text('Métiers'), findsOneWidget);
        expect(find.text('Freelance'), findsOneWidget);
        expect(find.text('Artisans et services près de vous'), findsOneWidget);
        expect(
          find.text('Compétences à distance ou au projet'),
          findsOneWidget,
        );
        expect(find.text('Explorer les univers'), findsNothing);
        expect(find.text('É-marché'), findsNothing);
        expect(find.text('Se connecter'), findsNothing);
        expect(find.byTooltip('Commandes'), findsNothing);
        expect(find.byType(Image), findsNothing);
      }
    }
  });

  testWidgets('recherche ouvre l’écran existant', (tester) async {
    await pumpHome(tester, logical: const Size(360, 800));
    await tester.tap(find.text('Quel service recherchez-vous ?'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(SearchPageScreenM), findsOneWidget);
  });

  testWidgets('état proche vide propose Explorer, pas une erreur réseau',
      (tester) async {
    await pumpHome(tester, logical: const Size(360, 800));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Professionnels près de vous'), findsOneWidget);
    expect(find.text('Aucun professionnel à afficher'), findsOneWidget);
    expect(find.text('Ouvrir Explorer'), findsOneWidget);
    expect(find.textContaining('hors connexion'), findsNothing);
  });

  testWidgets('barre : quatre destinations, Profil index 3, logout vers 0',
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
    expect(find.byIcon(Icons.add_rounded), findsNothing);

    await tester.tap(find.text('Messagerie'));
    await tester.pump();
    await tester.pump();
    ClientShellSelection.showHome();
    await tester.pump();
    expect(find.text('Trouvez un professionnel près de vous'), findsOneWidget);
    await tester.tap(find.text('Profil'));
    await tester.pump();
    expect(find.text('Se connecter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profil invité inchangé, sans Devenir professionnel',
      (tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => AuthCubit(),
        child: BlocProvider(
          create: (_) => ProfilPageBlocM(),
          child: const MaterialApp(home: ProfilPageScreenM()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Devenir professionnel'), findsNothing);
  });

  testWidgets('profil connecté : commandes et devenir pro une seule fois',
      (tester) async {
    final auth = _TestAuthCubit()..asClient();
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
        child: BlocProvider(
          create: (_) => ProfilPageBlocM(),
          child: const MaterialApp(home: ProfilPageScreenM()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Mes commandes'), findsOneWidget);
    expect(find.text('Modifier le profil'), findsOneWidget);
    expect(find.byType(ClientUniversePictogram), findsOneWidget);
    expect(find.text('Devenir professionnel'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(find.text('Supprimer le compte'), findsNothing);
    expect(find.text('Boutique'), findsNothing);
  });

  testWidgets('sheet publier : Métiers et Freelance, pas Boutique',
      (tester) async {
    final auth = _TestAuthCubit()..asClient();
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
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
    expect(find.text('Métiers'), findsOneWidget);
    expect(find.text('Freelance'), findsOneWidget);
    expect(find.text('Boutique'), findsNothing);
    expect(find.text('Comment souhaitez-vous proposer vos services ?'),
        findsOneWidget);
    expect(find.text('Que souhaitez-vous publier ?'), findsNothing);
  });
}
