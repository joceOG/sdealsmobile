import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/errors/api_exception.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/design_system/widgets/sd_button.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/auth_form_widgets.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/auth_phone_otp_form.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/phone_verification_invite_sheet.dart';
import 'package:sdealsmobile/mobile/view/loginpagem/screens/forgotPasswordScreenM.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeForgotApi extends ApiClient {
  int calls = 0;
  String? lastEmail;
  Object? errorToThrow;

  @override
  Future<void> forgotPassword({required String email}) async {
    calls++;
    lastEmail = email;
    if (errorToThrow != null) throw errorToThrow!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('invitation : contenus, icône sans coche, actions',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PhoneVerificationInviteSheet()),
      ),
    );
    await tester.pump();

    expect(find.text('Vérifier votre téléphone'), findsOneWidget);
    expect(
      find.text(
        'Confirmez que ce numéro vous appartient à l’aide d’un code de vérification.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Vous pouvez aussi le faire plus tard depuis votre profil.'),
      findsOneWidget,
    );
    expect(find.text('Vérifier maintenant'), findsOneWidget);
    expect(find.text('Plus tard'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.verified), findsNothing);
    expect(find.text('Profil'), findsNothing);
  });

  testWidgets('OTP : numéro réel, collage, validation bloquée si incomplet',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final code = TextEditingController();
    var verifyCount = 0;
    var resendCount = 0;
    var changeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: AuthPhoneOtpForm(
                  e164Phone: '+2250700112242',
                  codeController: code,
                  onVerify: () => verifyCount++,
                  onResend: () => resendCount++,
                  onChangeNumber: () => changeCount++,
                  canResend: true,
                  onCodeChanged: (_) => setState(() {}),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Vérifier mon numéro'), findsWidgets);
    expect(find.text('Numéro à vérifier'), findsOneWidget);
    expect(find.text(maskPhoneForDisplay('+2250700112242')), findsOneWidget);
    expect(find.text('+225 07 •• •• •• 42'), findsNothing);
    expect(find.text('Modifier le numéro'), findsOneWidget);
    expect(find.text('Renvoyer le code'), findsOneWidget);

    final verifyBtn = tester.widget<SDButton>(find.byType(SDButton));
    expect(verifyBtn.onPressed, isNull);

    await tester.enterText(find.byType(TextFormField), '12 34 56');
    await tester.pump();
    expect(code.text, '123456');

    await tester.tap(find.widgetWithText(SDButton, 'Vérifier mon numéro'));
    await tester.pump();
    expect(verifyCount, 1);

    await tester.tap(find.text('Renvoyer le code'));
    await tester.pump();
    expect(resendCount, 1);

    await tester.tap(find.text('Modifier le numéro'));
    await tester.pump();
    expect(changeCount, 1);
  });

  testWidgets('mot de passe oublié : e-mail, lien, erreur conservée',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeForgotApi()..errorToThrow = ApiException.network();

    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordScreenM(
          initialEmail: 'awa@example.com',
          apiClient: api,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('SOUTRALI DEALS'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text('Retrouvez l’accès à votre compte.'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Envoyer le lien'), findsOneWidget);
    expect(find.text('Retour à la connexion'), findsOneWidget);
    expect(find.text('Identifiant du compte'), findsNothing);
    expect(find.text('Numéro de téléphone'), findsNothing);

    await tester.tap(find.widgetWithText(SDButton, 'Envoyer le lien'));
    await tester.pump();
    await tester.pump();

    expect(api.calls, 1);
    expect(api.lastEmail, 'awa@example.com');
    expect(
      find.text('Impossible de se connecter. Vérifiez votre connexion internet.'),
      findsOneWidget,
    );
    expect(find.text('awa@example.com'), findsOneWidget);

    api.errorToThrow = null;
    await tester.tap(find.widgetWithText(SDButton, 'Envoyer le lien'));
    await tester.pump();
    expect(api.calls, 2);
  });
}
