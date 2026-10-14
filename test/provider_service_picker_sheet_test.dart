import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/groupe.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/widgets/provider_service_picker_sheet.dart';

Service _svc(String id, String name) => Service(
      idservice: id,
      nomservice: name,
      imageservice: '',
      prixmoyen: '0',
      categorie: Categorie(
        idcategorie: 'c2',
        nomcategorie: 'Bâtiment & Construction',
        imagecategorie: '',
        groupe: Groupe(idgroupe: 'm', nomgroupe: 'Métiers'),
      ),
    );

Future<void> _openSheet(
  WidgetTester tester, {
  String? initialSelectedId,
  List<Service> seed = const [],
  Future<List<Service>> Function()? loadServices,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final services = seed.isNotEmpty
      ? seed
      : [
          _svc('s1', 'Électricien'),
          _svc('s2', 'Plombier'),
          _svc('s3', 'Maçon'),
        ];

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () {
              ProviderServicePickerSheet.show(
                context,
                categoryId: 'c2',
                categoryLabel: 'Bâtiment & Construction',
                initialSelectedId: initialSelectedId,
                seedServices: services,
                loadServices: loadServices ?? () async => services,
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('affiche titre, catégorie et confirm désactivé sans sélection',
      (tester) async {
    await _openSheet(tester);

    expect(find.text('Choisir un service'), findsOneWidget);
    expect(find.text('Catégorie'), findsOneWidget);
    expect(find.text('Bâtiment & Construction'), findsOneWidget);
    expect(find.text('Rechercher un service'), findsOneWidget);

    final confirm = tester.widget<SDButton>(
      find.widgetWithText(SDButton, 'Confirmer le service'),
    );
    expect(confirm.onPressed, isNull);
  });

  testWidgets('filtre la liste via la recherche', (tester) async {
    await _openSheet(tester);

    await tester.enterText(find.byType(TextField), 'plom');
    await tester.pump();

    expect(find.text('Plombier'), findsOneWidget);
    expect(find.text('Électricien'), findsNothing);
    expect(
      find.text('Aucun service ne correspond à votre recherche.'),
      findsNothing,
    );
  });

  testWidgets('confirmation renvoie l’identifiant du service', (tester) async {
    String? result;
    final services = [_svc('s1', 'Électricien'), _svc('s2', 'Plombier')];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await ProviderServicePickerSheet.show(
                  context,
                  categoryId: 'c2',
                  categoryLabel: 'Bâtiment & Construction',
                  initialSelectedId: null,
                  seedServices: services,
                  loadServices: () async => services,
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

    await tester.tap(find.text('Électricien'));
    await tester.pump();
    await tester.tap(find.text('Confirmer le service'));
    await tester.pumpAndSettle();

    expect(result, 's1');
  });

  testWidgets('fermer annule la sélection temporaire', (tester) async {
    String? result;
    final services = [_svc('s1', 'Électricien'), _svc('s2', 'Plombier')];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await ProviderServicePickerSheet.show(
                  context,
                  categoryId: 'c2',
                  categoryLabel: 'Bâtiment',
                  initialSelectedId: 's1',
                  seedServices: services,
                  loadServices: () async => services,
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

    await tester.tap(find.text('Plombier'));
    await tester.pump();
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('erreur de chargement avec Réessayer', (tester) async {
    var calls = 0;
    final services = [_svc('s1', 'Électricien')];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                ProviderServicePickerSheet.show(
                  context,
                  categoryId: 'c2',
                  categoryLabel: 'Bâtiment',
                  initialSelectedId: null,
                  loadServices: () async {
                    calls++;
                    if (calls == 1) throw Exception('fail');
                    return services;
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

    expect(find.text('Impossible de charger les services.'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Électricien'), findsOneWidget);
  });
}
