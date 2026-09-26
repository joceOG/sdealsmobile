import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/protected_action_intent.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/auth_completion.dart';
import 'package:sdealsmobile/mobile/view/homepagem/homepageblocm/homePageBlocM.dart';
import 'package:sdealsmobile/mobile/view/homepagem/screens/homePageScreenM.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    final dir = await Directory.systemTemp.createTemp('phase10c4-hive');
    Hive.init(dir.path);
    ProtectedActionStore.instance.clear();
  });

  testWidgets('accueil invité sans CTA Se connecter ni trou dans les actions',
      (tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(create: (_) => AuthCubit()),
          BlocProvider<HomePageBlocM>(create: (_) => HomePageBlocM()),
        ],
        child: const MaterialApp(home: HomePageScreenM()),
      ),
    );
    await tester.pump();

    expect(find.text('Se connecter'), findsNothing);
    expect(find.text('Créer un compte'), findsNothing);
    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.textContaining('Bonjour, Invité'), findsNothing);
    expect(find.textContaining('👋'), findsNothing);

    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.byTooltip('Commandes'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Se connecter'), findsNothing);
  });

  testWidgets('profil invité conserve Se connecter et Créer un compte',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GuestAuthState(
            pageTitle: 'Profil',
            title: 'Connectez-vous à votre profil',
            description:
                'Gérez vos informations, favoris, demandes et votre activité Soutrali Deals.',
            icon: Icons.person_outline_rounded,
          ),
        ),
      ),
    );

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Connectez-vous à votre profil'), findsOneWidget);
  });

  testWidgets('action protégée propose encore l’authentification existante',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => const ProtectedAuthSheet(
                    explanation:
                        'Connectez-vous pour contacter ce professionnel',
                  ),
                );
              },
              child: const Text('appeler'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('appeler'));
    await tester.pumpAndSettle();
    expect(
      find.text('Connectez-vous pour contacter ce professionnel'),
      findsOneWidget,
    );
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text("S'inscrire"), findsOneWidget);
  });

  test('logout pointe vers l’accueil invité et efface l’intention', () {
    ProtectedActionStore.instance.set(
      const ProtectedActionIntent(
        type: ProtectedActionType.callProvider,
        originRoute: 'providerProfile',
        technicalId: 'id-test',
      ),
    );
    SessionExit.clearPending();
    expect(SessionExit.destination, '/homepage');
    expect(ProtectedActionStore.instance.hasPending, isFalse);
  });
}
