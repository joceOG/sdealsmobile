import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/groupe.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/widgets/provider_category_picker_sheet.dart';

Categorie _cat(String id, String name) => Categorie(
      idcategorie: id,
      nomcategorie: name,
      imagecategorie: '',
      groupe: Groupe(idgroupe: 'metiers', nomgroupe: 'Métiers'),
    );

Future<void> _pumpSheet(
  WidgetTester tester, {
  String? initialSelectedId,
  List<Categorie> seed = const [],
  Future<List<Categorie>> Function()? loadCategories,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                await ProviderCategoryPickerSheet.show(
                  context,
                  initialSelectedId: initialSelectedId,
                  seedCategories: seed,
                  loadCategories: loadCategories ?? () async => seed,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final categories = [
    _cat('c1', 'Services à Domicile & de Sécurité'),
    _cat('c2', 'Bâtiment & Construction'),
    _cat('c3', 'Mécanique & Transport'),
  ];

  testWidgets('affiche titre, contexte Métiers et bouton confirm désactivé sans sélection',
      (tester) async {
    await _pumpSheet(tester, seed: categories);

    expect(find.text('Choisir une catégorie'), findsOneWidget);
    expect(find.text('Métiers'), findsOneWidget);
    expect(find.text('Confirmer la catégorie'), findsOneWidget);

    final confirm = tester.widget<SDButton>(
      find.widgetWithText(SDButton, 'Confirmer la catégorie'),
    );
    expect(confirm.onPressed, isNull);
  });

  testWidgets('sélection temporaire puis confirmation renvoie l’identifiant', (tester) async {
    String? result;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await ProviderCategoryPickerSheet.show(
                  context,
                  initialSelectedId: null,
                  seedCategories: categories,
                  loadCategories: () async => categories,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bâtiment & Construction'));
    await tester.pump();

    await tester.tap(find.text('Confirmer la catégorie'));
    await tester.pumpAndSettle();

    expect(result, 'c2');
  });

  testWidgets('fermer annule sans renvoyer une sélection', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await ProviderCategoryPickerSheet.show(
                  context,
                  initialSelectedId: 'c2',
                  seedCategories: categories,
                  loadCategories: () async => categories,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mécanique & Transport'));
    await tester.pump();

    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('à l’ouverture, reprend la catégorie initiale', (tester) async {
    await _pumpSheet(
      tester,
      initialSelectedId: 'c2',
      seed: categories,
    );

    final confirm = tester.widget<SDButton>(
      find.widgetWithText(SDButton, 'Confirmer la catégorie'),
    );
    expect(confirm.onPressed, isNotNull);
  });

  testWidgets('erreur de chargement avec Réessayer', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                ProviderCategoryPickerSheet.show(
                  context,
                  initialSelectedId: null,
                  loadCategories: () async {
                    calls++;
                    if (calls == 1) throw Exception('network');
                    return categories;
                  },
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Impossible de charger les catégories.'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Bâtiment & Construction'), findsOneWidget);
  });
}
