import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/alertpagem/alertpageblocm/alertPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/alertpagem/screens/alertPageScreenM.dart';

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
  });

  tearDown(AlertPageBlocM.debugReset);

  Map<String, dynamic> alertJson({
    required String id,
    required String titre,
    required String type,
    required String statut,
    required DateTime createdAt,
    String contenu = '',
    Map<String, dynamic>? donnees,
  }) {
    return {
      '_id': id,
      'titre': titre,
      'contenu': contenu,
      'type': type,
      'statut': statut,
      'priorite': 'NORMALE',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': createdAt.toIso8601String(),
      if (donnees != null) 'donnees': donnees,
    };
  }

  Future<void> pumpInbox(
    WidgetTester tester, {
    required List<Map<String, dynamic>> notifications,
    int statusCode = 200,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AlertPageBlocM.debugGet = (_) async => http.Response(
          jsonEncode({'notifications': notifications}),
          statusCode,
        );

    final auth = _TestAuthCubit()..asClient();
    final bloc = AlertPageBlocM();
    addTearDown(auth.close);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<AlertPageBlocM>.value(value: bloc),
        ],
        child: const MaterialApp(home: AlertPageScreenM()),
      ),
    );
    await tester.pump();
  }

  testWidgets('reçues : dates, contexte, non-lus et tout marquer',
      (tester) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    await pumpInbox(tester, notifications: [
      alertJson(
        id: 'n1',
        titre: 'Nouveau message',
        type: 'MESSAGE_RECU',
        statut: 'NON_LUE',
        createdAt: now,
        contenu: 'Aminata Koné vous a répondu.',
        donnees: {'service': 'Création de logo'},
      ),
      alertJson(
        id: 'n2',
        titre: 'Demande envoyée',
        type: 'NOUVELLE_MISSION',
        statut: 'LUE',
        createdAt: yesterday,
        contenu: 'Votre demande a bien été transmise.',
        donnees: {'service': 'Entretien du domicile'},
      ),
    ]);

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Vos messages et mises à jour'), findsOneWidget);
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('Hier'), findsOneWidget);
    expect(find.text('Nouveau message'), findsOneWidget);
    expect(find.text('Aminata Koné vous a répondu.'), findsOneWidget);
    expect(find.text('Création de logo'), findsOneWidget);
    expect(find.text('Non lues (1)'), findsOneWidget);
    expect(find.text('Tout marquer comme lu'), findsOneWidget);
    expect(find.text('Toutes (2)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('erreur : Réessayer sans faux compteurs', (tester) async {
    await pumpInbox(tester, notifications: const [], statusCode: 500);

    expect(
        find.text('Impossible de charger\nles notifications'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Non lues'), findsOneWidget);
    expect(find.text('Non lues (0)'), findsNothing);
    expect(find.text('Non lues (2)'), findsNothing);
    expect(find.text('Toutes (0)'), findsNothing);
    expect(find.text('Tout marquer comme lu'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('liste vide : pas de tout marquer', (tester) async {
    await pumpInbox(tester, notifications: const []);

    expect(find.text('Aucune notification'), findsOneWidget);
    expect(find.text('Tout marquer comme lu'), findsNothing);
    expect(find.text('Non lues'), findsOneWidget);
    expect(find.text('Non lues (0)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
