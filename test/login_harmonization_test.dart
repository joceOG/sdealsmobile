import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/design_system/widgets/sd_button.dart';
import 'package:sdealsmobile/design_system/widgets/sd_google_sign_in_button.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/screens/loginPageScreenM.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthCubit(),
        child: const MaterialApp(home: LoginPageScreenM()),
      ),
    );
    await tester.pump();
  }

  testWidgets('composition : formulaire prioritaire, Google en alternative',
      (tester) async {
    await pumpLogin(tester);

    expect(find.text('SOUTRALI DEALS'), findsOneWidget);
    expect(find.text('Connexion'), findsOneWidget);
    expect(
      find.text('Retrouvez votre compte Soutrali Deals.'),
      findsOneWidget,
    );
    expect(find.text('Téléphone'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Numéro de téléphone'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('ou'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(find.text('Pas encore de compte ?'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);

    expect(find.text('Bienvenue !'), findsNothing);
    expect(find.text('Connectez-vous pour continuer'), findsNothing);
    expect(find.text('6 caractères minimum'), findsNothing);
    expect(find.text('Accueil'), findsNothing);

    expect(
      find.byWidgetPredicate((w) {
        if (w is! Image) return false;
        final image = w.image;
        return image is AssetImage && image.assetName.contains('logo1');
      }),
      findsNothing,
    );

    final labels = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    expect(
      labels.indexOf('Se connecter') < labels.indexOf('Continuer avec Google'),
      isTrue,
    );
  });

  testWidgets('modes téléphone / e-mail : valeurs conservées', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextField).first, '0700000000');
    await tester.tap(find.text('E-mail'));
    await tester.pump();

    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Numéro de téléphone'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'awa@example.com');
    await tester.tap(find.text('Téléphone'));
    await tester.pump();

    expect(find.text('0700000000'), findsOneWidget);
    await tester.tap(find.text('E-mail'));
    await tester.pump();
    expect(find.text('awa@example.com'), findsOneWidget);
  });

  testWidgets('bouton principal désactivé tant que la saisie est incomplète',
      (tester) async {
    await pumpLogin(tester);
    final button = tester.widget<SDButton>(find.byType(SDButton));
    expect(button.onPressed, isNull);
    expect(button.isLoading, isFalse);
  });

  testWidgets('affichage du mot de passe et Google présents', (tester) async {
    await pumpLogin(tester);
    expect(find.byTooltip('Afficher'), findsOneWidget);
    await tester.tap(find.byTooltip('Afficher'));
    await tester.pump();
    expect(find.byTooltip('Masquer'), findsOneWidget);
    expect(find.byType(SDGoogleSignInButton), findsOneWidget);
  });

  testWidgets('mot de passe oublié ouvre l’écran e-mail existant',
      (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();
    expect(find.text('Mot de passe oublié ?'), findsWidgets);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Envoyer le lien'), findsOneWidget);
    expect(find.text('Retour à la connexion'), findsOneWidget);
    expect(find.text('Identifiant du compte'), findsNothing);
  });
}
