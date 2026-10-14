import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/delete_account_screen.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/language_settings_screen.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/profile_settings_hub_screen.dart';
import 'package:sdealsmobile/mobile/view/securitypagem/screens/securityPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/securitypagem/securitypageblocm/securityPageBlocM.dart';

class _TestAuthCubit extends AuthCubit {
  void asClient({bool phoneVerified = false}) {
    emit(
      AuthAuthenticated(
        token: 'token-test',
        utilisateur: Utilisateur(
          idutilisateur: 'user-test',
          nom: 'Kouassi',
          prenom: 'Awa',
          email: 'hidden@example.com',
          password: 'secret',
          telephone: '0700000000',
          role: 'CLIENT',
          telephoneVerified: phoneVerified,
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
  });

  Future<void> pumpSettings(WidgetTester tester, _TestAuthCubit auth) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
        child: const MaterialApp(home: ProfileSettingsHubScreen()),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpSecurity(
    WidgetTester tester,
    _TestAuthCubit auth, {
    bool phoneVerified = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    auth.asClient(phoneVerified: phoneVerified);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider(
            create: (_) => SecurityPageBlocM(apiClient: ApiClient()),
          ),
        ],
        child: const MaterialApp(home: SecurityPageScreenM()),
      ),
    );
    await tester.pump();
  }

  testWidgets('Paramètres : trois groupes, Français, pas d’anglais',
      (tester) async {
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);
    await pumpSettings(tester, auth);

    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Compte'), findsOneWidget);
    expect(find.text('Préférences'), findsOneWidget);
    expect(find.text('Aide et informations'), findsOneWidget);
    expect(find.text('Informations personnelles'), findsOneWidget);
    expect(find.text('Sécurité du compte'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Langue de l’application'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('English'), findsNothing);
    expect(find.text('Aide et support'), findsOneWidget);
    expect(find.text('Conditions d’utilisation'), findsOneWidget);
    expect(find.text('Politique de confidentialité'), findsOneWidget);
    expect(find.text('À propos de Soutrali'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Supprimer mon compte'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Supprimer mon compte'), findsOneWidget);
    expect(find.text('Langue & Devise'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Supprimer mon compte ouvre le flux dédié', (tester) async {
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);
    await pumpSettings(tester, auth);

    await tester.scrollUntilVisible(
      find.text('Supprimer mon compte'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(DeleteAccountScreen), findsOneWidget);
    expect(find.textContaining('n’est pas une simple déconnexion'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('langue : Français sans choix non confirmé', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LanguageSettingsScreen()),
    );
    await tester.pump();
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('English'), findsNothing);
    expect(find.text('Euro (€)'), findsNothing);
    expect(find.text('Dollar US (\$)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sécurité : parcours existants et statut téléphone API',
      (tester) async {
    final auth = _TestAuthCubit();
    addTearDown(auth.close);
    await pumpSecurity(tester, auth);

    expect(find.text('Sécurité du compte'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Numéro de téléphone'), findsOneWidget);
    expect(find.text('Consulter mon statut de vérification'), findsOneWidget);
    expect(find.text('Un problème d’accès ?'), findsOneWidget);
    expect(find.text('Numéro vérifié'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('téléphone vérifié : statut API affiché', (tester) async {
    final auth = _TestAuthCubit();
    addTearDown(auth.close);
    await pumpSecurity(tester, auth, phoneVerified: true);

    expect(find.text('Numéro vérifié'), findsOneWidget);
    expect(find.text('Consulter mon statut de vérification'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
