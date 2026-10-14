import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/design_system/client_foundations.dart';
import 'package:sdealsmobile/mobile/view/locationpagem/locationpageblocm/locationPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/locationpagem/locationpageblocm/locationPageStateM.dart';
import 'package:sdealsmobile/mobile/view/locationpagem/screens/locationPageScreenM.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:9/api\n');
  });

  tearDown(LocationPageBlocM.debugReset);

  Future<void> pumpPicker(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = LocationPageBlocM();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<LocationPageBlocM>.value(
        value: bloc,
        child: const MaterialApp(home: LocationPageScreenM()),
      ),
    );
    await tester.pump();
  }

  testWidgets('recherche et carte accessibles sans GPS au chargement',
      (tester) async {
    await pumpPicker(tester);

    expect(find.text('Ma localisation'), findsOneWidget);
    expect(find.text('Où recherchez-vous ?'), findsOneWidget);
    expect(find.text('Choisissez une commune ou un quartier.'), findsOneWidget);
    expect(find.text('Rechercher une commune'), findsOneWidget);
    expect(find.text('Utiliser ma position actuelle'), findsOneWidget);
    expect(find.text('Choisir sur la carte'), findsOneWidget);
    expect(find.text('Confirmer la localisation'), findsOneWidget);
    expect(find.textContaining(SDClientLocationPolicy.fallbackCity), findsOneWidget);
    expect(find.text('Angré'), findsNothing);
    expect(find.text('Riviera'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refus GPS laisse la recherche et la carte accessibles',
      (tester) async {
    LocationPageBlocM.debugGps = () async => null;
    await pumpPicker(tester);

    await tester.tap(find.text('Utiliser ma position actuelle'));
    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining('Autorisation refusée'),
      findsOneWidget,
    );
    expect(find.text('Rechercher une commune'), findsOneWidget);
    expect(find.text('Choisir sur la carte'), findsOneWidget);
    expect(find.text('Confirmer la localisation'), findsOneWidget);
    expect(find.text('Où recherchez-vous ?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la recherche affiche des lieux réels, pas une liste inventée',
      (tester) async {
    LocationPageBlocM.debugSearch = (query) async {
      if (!query.toLowerCase().contains('cocody')) return const [];
      return const [
        LocationSuggestion(
          title: 'Cocody',
          subtitle: "Abidjan, Côte d'Ivoire",
          latitude: 5.36,
          longitude: -3.98,
        ),
      ];
    };
    await pumpPicker(tester);

    await tester.enterText(find.byType(TextField), 'Cocody');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Résultats de recherche'), findsOneWidget);
    expect(find.text('Cocody'), findsWidgets);
    expect(find.text("Abidjan, Côte d'Ivoire"), findsWidgets);
    expect(find.text('Angré'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
