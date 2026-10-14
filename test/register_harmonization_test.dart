import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/phone_verification_config.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/design_system/widgets/sd_button.dart';
import 'package:sdealsmobile/design_system/widgets/sd_google_sign_in_button.dart';
import 'package:sdealsmobile/mobile/view/registerpagem/registerpageblocm/registerPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/registerpagem/screens/registerPageScreenM.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRegisterApi extends ApiClient {
  String? lastPhone;

  @override
  Future<PhoneVerificationConfig> fetchPhoneVerificationConfig({
    bool forceRefresh = false,
  }) async =>
      const PhoneVerificationConfig(
        mode: 'deferred',
        signupRequiresOtp: false,
        googleRequiresPhone: false,
      );

  @override
  Future<Map<String, dynamic>> registerUser({
    required String nom,
    String? prenom,
    required String phone,
    String? phoneCountry,
    required String password,
    String? email,
    String? phoneVerificationToken,
    String role = 'Client',
  }) async {
    lastPhone = phone;
    throw Exception('Erreur API inscription');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    SharedPreferences.setMockInitialValues({});
    RegisterPageScreenM.debugPhoneConfig = const PhoneVerificationConfig(
      mode: 'deferred',
      signupRequiresOtp: false,
      googleRequiresPhone: false,
    );
  });

  tearDown(RegisterPageScreenM.debugReset);

  Future<void> pumpRegister(
    WidgetTester tester, {
    ApiClient? api,
  }) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit()),
          BlocProvider(
            create: (_) => RegisterPageBlocM(apiClient: api ?? ApiClient()),
          ),
        ],
        child: const MaterialApp(home: RegisterPageScreenM()),
      ),
    );
    await tester.pump();
  }

  testWidgets('un seul formulaire : haut et bas ensemble', (tester) async {
    await pumpRegister(tester);

    expect(find.text('SOUTRALI DEALS'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(
      find.text('Vos échanges et vos demandes, au même endroit.'),
      findsOneWidget,
    );
    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Téléphone (facultatif)'), findsOneWidget);
    expect(find.text('Vous pourrez le vérifier plus tard.'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('6 caractères minimum'), findsOneWidget);
    expect(find.text('Confirmer le mot de passe'), findsOneWidget);
    expect(find.text('Créer mon compte'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(find.text('Vous avez déjà un compte ?'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);

    expect(find.text('Rejoignez Soutrali Deals'), findsNothing);
    expect(find.text('Genre'), findsNothing);
    expect(find.text('Date de naissance'), findsNothing);
    expect(find.text('Prestataire'), findsNothing);
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
      labels.indexOf('Créer mon compte') <
          labels.indexOf('Continuer avec Google'),
      isTrue,
    );
  });

  testWidgets('bouton gris tant que le consentement manque', (tester) async {
    await pumpRegister(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'Kouassi');
    await tester.enterText(fields.at(2), 'awa@example.com');
    await tester.enterText(fields.at(3), 'secret1');
    await tester.enterText(fields.at(4), 'secret1');
    await tester.pump();
    expect(tester.widget<SDButton>(find.byType(SDButton)).onPressed, isNull);

    await tester.ensureVisible(find.text('Créer mon compte'));
    await tester.tap(find.text('Créer mon compte'));
    await tester.pump();
    expect(
      find.text('Acceptez les conditions pour créer votre compte.'),
      findsOneWidget,
    );
  });

  testWidgets('mots de passe différents : erreur compréhensible',
      (tester) async {
    await pumpRegister(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'Kouassi');
    await tester.enterText(fields.at(2), 'awa@example.com');
    await tester.enterText(fields.at(3), 'secret1');
    await tester.enterText(fields.at(4), 'secret2');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<SDButton>(find.byType(SDButton)).onPressed, isNull);

    await tester.ensureVisible(find.text('Créer mon compte'));
    await tester.tap(find.text('Créer mon compte'));
    await tester.pump();
    expect(
      find.text('Les mots de passe ne correspondent pas.'),
      findsOneWidget,
    );
  });

  testWidgets('téléphone vide : bouton actif, aucun numéro fictif envoyé',
      (tester) async {
    final api = _FakeRegisterApi();
    await pumpRegister(tester, api: api);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'Kouassi');
    await tester.enterText(fields.at(2), 'awa@example.com');
    await tester.enterText(fields.at(3), 'secret1');
    await tester.enterText(fields.at(4), 'secret1');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(tester.widget<SDButton>(find.byType(SDButton)).onPressed, isNotNull);
    await tester.ensureVisible(find.text('Créer mon compte'));
    await tester.tap(find.text('Créer mon compte'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(api.lastPhone, '');
    expect(find.text('Erreur API inscription'), findsOneWidget);
    expect(find.text('Kouassi'), findsOneWidget);
    expect(find.text('awa@example.com'), findsOneWidget);
    expect(find.byType(SDGoogleSignInButton), findsOneWidget);
  });
}
