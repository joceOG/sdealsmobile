import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/professional_capabilities.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/orderpagem/screens/service_requests_list_screen.dart';
import 'package:sdealsmobile/mobile/view/orderpagem/servicerequestcubit/service_request_cubit.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/profilpageblocm/profilPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/edit_profile_screen.dart';
import 'package:sdealsmobile/mobile/view/profilpagem/screens/profilPageScreenM.dart';

class _TestAuthCubit extends AuthCubit {
  void asClient({UserProfessionalCapabilities? professional}) {
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
        professional: professional,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
    ServiceRequestCubit.debugFetchMine = () async => <Map<String, dynamic>>[];
  });

  tearDown(ServiceRequestCubit.debugReset);

  Future<void> pumpProfile(
    WidgetTester tester,
    _TestAuthCubit auth,
  ) async {
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

  testWidgets('zéro profil : Devenir professionnel, pas d’espace',
      (tester) async {
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);
    await pumpProfile(tester, auth);
    expect(find.text('Devenir professionnel'), findsOneWidget);
    expect(find.text('Espace Métiers'), findsNothing);
    expect(find.text('Ajouter une autre activité'), findsNothing);
    expect(find.text('Mes demandes de services'), findsOneWidget);
    expect(find.text('Mes achats E-marché'), findsNothing);
    expect(find.text('Historique'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Notifications'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un profil Métiers pending + ajout d’une autre activité',
      (tester) async {
    final auth = _TestAuthCubit()
      ..asClient(
        professional: const UserProfessionalCapabilities(
          prestataire: ProfessionalProfileSnapshot(
            exists: true,
            id: 'p1',
            status: 'pending',
            canOperate: false,
          ),
        ),
      );
    addTearDown(auth.close);
    await pumpProfile(tester, auth);
    expect(find.text('Espace Métiers'), findsOneWidget);
    expect(find.text('En attente'), findsWidgets);
    expect(find.text('Ajouter une autre activité'), findsOneWidget);
    expect(find.text('Devenir professionnel'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trois profils : pas d’ajout', (tester) async {
    final auth = _TestAuthCubit()
      ..asClient(
        professional: const UserProfessionalCapabilities(
          prestataire: ProfessionalProfileSnapshot(
            exists: true,
            id: 'p1',
            status: 'active',
            canOperate: true,
          ),
          freelance: ProfessionalProfileSnapshot(
            exists: true,
            id: 'f1',
            status: 'active',
            canOperate: false,
          ),
          vendeur: ProfessionalProfileSnapshot(
            exists: true,
            id: 'v1',
            status: 'suspended',
            canOperate: false,
          ),
        ),
      );
    addTearDown(auth.close);
    await pumpProfile(tester, auth);
    expect(find.text('Espace Métiers'), findsOneWidget);
    expect(find.text('Espace Freelance'), findsOneWidget);
    expect(find.text('Espace E-marché'), findsOneWidget);
    expect(find.text('Devenir professionnel'), findsNothing);
    expect(find.text('Ajouter une autre activité'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demandes ouvrent Services, achats restent un onglet honnête',
      (tester) async {
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
        child: const MaterialApp(home: ServiceRequestsListScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Mes demandes'), findsOneWidget);
    expect(find.text('Le suivi de vos achats sera bientôt disponible.'),
        findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
        child: const MaterialApp(
          home: ServiceRequestsListScreen(initialAchats: true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Vos achats E-marché'), findsOneWidget);
    expect(find.text('Le suivi de vos achats sera bientôt disponible.'),
        findsOneWidget);
    expect(find.text('Aucune commande pour le moment.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('édition : titre, sections et validations conservées',
      (tester) async {
    final auth = _TestAuthCubit()..asClient();
    addTearDown(auth.close);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
        child: MaterialApp(
          home: EditProfileScreen(
            initialUserData: {
              'nom': 'Kouassi',
              'prenom': 'Awa',
              'telephone': '0700000000',
              'email': 'awa@example.com',
              'genre': 'Femme',
              'datedenaissance': '01/01/1990',
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Modifier mon profil'), findsOneWidget);
    expect(find.text('Identité'), findsOneWidget);
    expect(find.text('Coordonnées'), findsOneWidget);
    expect(find.text('Enregistrer les modifications'), findsOneWidget);
    expect(find.text('Changer la photo'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
