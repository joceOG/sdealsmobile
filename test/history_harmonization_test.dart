import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/services/local_storage_service.dart';
import 'package:sdealsmobile/mobile/view/historypagem/historypageblocm/historyPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/historypagem/screens/historyPageScreenM.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          telephone: '0700000000',
          role: 'CLIENT',
        ),
      ),
    );
  }
}

Map<String, dynamic> _historyJson({
  required String id,
  required String titre,
  required String objetType,
  required String objetId,
  required DateTime at,
  String? categorie,
}) {
  final iso = at.toUtc().toIso8601String();
  return {
    '_id': id,
    'utilisateur': 'user-test',
    'objetType': objetType,
    'objetId': objetId,
    'titre': titre,
    if (categorie != null) 'categorie': categorie,
    'statut': 'ACTIVE',
    'dureeConsultation': 0,
    'nombreVues': 1,
    'sessionId': 'sdealsmobile',
    'dateConsultation': iso,
    'dateDerniereConsultation': iso,
    'createdAt': iso,
    'updatedAt': iso,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    SharedPreferences.setMockInitialValues({});
    HistoryPageBlocM.debugReset();
    HistoryPageBlocM.debugGet = (_) async => http.Response(
          jsonEncode({'history': [], 'pagination': {}}),
          200,
        );
  });

  tearDown(HistoryPageBlocM.debugReset);

  Future<void> pumpHistory(
    WidgetTester tester,
    _TestAuthCubit auth, {
    bool signedIn = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (signedIn) auth.asClient();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider(create: (_) => HistoryPageBlocM()),
        ],
        child: const MaterialApp(home: HistoryPageScreenM()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  test('recherches : horodatage, scope, pas de date inventée', () async {
    SharedPreferences.setMockInitialValues({
      'search_history': ['Ancienne requête'],
    });
    final storage = LocalStorageService();
    await storage.addToHistory('  plombier  ', scope: 'metiers');
    await storage.addToHistory('');
    await storage.addToHistory('Plombier', scope: 'metiers');
    final entries = await storage.getSearchHistoryEntries();

    expect(entries.first.query.toLowerCase(), 'plombier');
    expect(entries.first.scope, 'metiers');
    expect(entries.first.at, isNotNull);
    expect(entries.where((e) => e.query.toLowerCase() == 'plombier').length, 1);

    final legacy = entries.firstWhere((e) => e.query == 'Ancienne requête');
    expect(legacy.at, isNull);
    expect(legacy.scope, isNull);
  });

  testWidgets('invité : bannière, pas de fiches illustratives', (tester) async {
    final auth = _TestAuthCubit();
    await pumpHistory(tester, auth, signedIn: false);
    expect(find.text('Votre historique'), findsOneWidget);
    expect(find.text('Kouamé Yao'), findsNothing);
    expect(find.text('Profils'), findsNothing);
  });

  testWidgets('Profils / Recherches, sous-titre, vide réel', (tester) async {
    final auth = _TestAuthCubit();
    await pumpHistory(tester, auth);
    expect(find.text('Historique'), findsWidgets);
    expect(
      find.text('Retrouvez vos dernières visites et recherches.'),
      findsOneWidget,
    );
    expect(find.text('Profils'), findsOneWidget);
    expect(find.text('Recherches'), findsOneWidget);
    expect(find.text('Aucune consultation'), findsOneWidget);
    expect(find.text('Kouamé Yao'), findsNothing);
    expect(find.text('Aminata Koné'), findsNothing);

    await tester.tap(find.text('Recherches'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Aucune recherche récente'), findsOneWidget);
    expect(find.text('Plombier'), findsNothing);
  });

  testWidgets('profils enregistrés regroupés par date, pas de maquette',
      (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10);
    final yesterday = today.subtract(const Duration(days: 1));
    HistoryPageBlocM.debugGet = (_) async => http.Response(
          jsonEncode({
            'history': [
              _historyJson(
                id: 'h1',
                titre: 'Bamba Seydou',
                objetType: 'PRESTATAIRE',
                objetId: 'p1',
                at: today,
                categorie: 'Plombier',
              ),
              _historyJson(
                id: 'h2',
                titre: 'Traoré Aïcha',
                objetType: 'FREELANCE',
                objetId: 'f1',
                at: yesterday,
                categorie: 'Graphiste',
              ),
            ],
          }),
          200,
        );

    final auth = _TestAuthCubit();
    await pumpHistory(tester, auth);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('Hier'), findsOneWidget);
    expect(find.text('Bamba Seydou'), findsOneWidget);
    expect(find.text('Traoré Aïcha'), findsOneWidget);
    expect(find.text('Plombier'), findsOneWidget);
    expect(find.text('Graphiste'), findsOneWidget);
    expect(find.text('Métiers'), findsWidgets);
    expect(find.text('Freelance'), findsOneWidget);
    expect(
      find.text('Ouvrez un profil pour le consulter à nouveau.'),
      findsOneWidget,
    );
    expect(find.text('Kouamé Yao'), findsNothing);
  });

  testWidgets('recherches stockées : groupes et chip d’univers réel',
      (tester) async {
    final localNow = DateTime.now();
    final today = DateTime(localNow.year, localNow.month, localNow.day, 15);
    final yesterday = today.subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      'search_history': [
        jsonEncode({
          'q': 'Réparation de robinet',
          'at': today.toUtc().toIso8601String(),
          'scope': 'metiers',
        }),
        jsonEncode({
          'q': 'Développement web',
          'at': yesterday.toUtc().toIso8601String(),
          'scope': 'freelance',
        }),
        'Requête sans date',
      ],
    });

    final auth = _TestAuthCubit();
    await pumpHistory(tester, auth);
    await tester.tap(find.text('Recherches'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('Réparation de robinet'), findsOneWidget);
    expect(find.text('Développement web'), findsOneWidget);
    expect(find.text('Requête sans date'), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('Hier'), findsOneWidget);
    expect(find.text('Récentes'), findsOneWidget);
    expect(find.text('Métiers'), findsOneWidget);
    expect(find.text('Freelance'), findsOneWidget);
    expect(
      find.text('Touchez une recherche pour la relancer.'),
      findsOneWidget,
    );
    expect(find.text('Création de logo'), findsNothing);
  });

  testWidgets('erreur de chargement : réessayer, pas de faux profils',
      (tester) async {
    HistoryPageBlocM.debugGet = (_) async => http.Response('{}', 500);
    final auth = _TestAuthCubit();
    await pumpHistory(tester, auth);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Kouamé Yao'), findsNothing);
    expect(find.text('Aucune consultation'), findsNothing);
  });
}
