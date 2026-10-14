import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/logout_confirm_dialog.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/profilpageblocm/profilPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/profilPageScreenM.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuthCubit extends AuthCubit {
  int logoutCalls = 0;
  Completer<void>? hold;

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

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (hold != null) await hold!.future;
    emit(AuthInitial());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpProfile(WidgetTester tester, _TestAuthCubit auth) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
  }

  Future<void> openLogout(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Se déconnecter'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Se déconnecter'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('présentation : icône, textes, boutons', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LogoutConfirmDialog(
          onLogout: () async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Se déconnecter ?'), findsOneWidget);
    expect(
      find.text('Vous devrez vous reconnecter pour accéder à votre compte.'),
      findsOneWidget,
    );
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Se déconnecter'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(find.text('Êtes-vous sûr de vouloir vous déconnecter ?'), findsNothing);
  });

  testWidgets('Annuler ne modifie pas la session', (tester) async {
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);
    await pumpProfile(tester, auth);
    await openLogout(tester);

    expect(find.text('Se déconnecter ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pump();

    expect(find.text('Se déconnecter ?'), findsNothing);
    expect(auth.state, isA<AuthAuthenticated>());
    expect(auth.logoutCalls, 0);
    expect(find.text('Modifier mon profil'), findsOneWidget);
  });

  testWidgets('retour Android ferme sans déconnexion', (tester) async {
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);
    await pumpProfile(tester, auth);
    await openLogout(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Se déconnecter ?'), findsNothing);
    expect(auth.state, isA<AuthAuthenticated>());
    expect(auth.logoutCalls, 0);
  });

  testWidgets('confirmation unique, chargement, puis état invité',
      (tester) async {
    final auth = _TestAuthCubit()..asClient();
    auth.hold = Completer<void>();
    addTearDown(auth.close);
    await pumpProfile(tester, auth);
    await openLogout(tester);

    final confirm = find.widgetWithText(ElevatedButton, 'Se déconnecter');
    await tester.tap(confirm);
    await tester.tap(confirm);
    await tester.pump();

    expect(auth.logoutCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    auth.hold!.complete();
    await tester.pump();
    await tester.pump();

    expect(auth.state, isA<AuthInitial>());
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Modifier mon profil'), findsNothing);
    expect(find.text('Déconnexion réussie'), findsNothing);
  });
}
