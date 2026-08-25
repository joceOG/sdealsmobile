import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/groupe.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/screens/freelancePageScreen.dart';

class _HubApi extends ApiClient {
  _HubApi({
    this.categories = const [],
    this.freelances = const [],
  });

  final List<Categorie> categories;
  final List<Map<String, dynamic>> freelances;
  int servicesCalls = 0;

  @override
  Future<List<Categorie>> fetchCategorie(String nomGroupe) async => categories;

  @override
  Future<List<Service>> fetchServices(String nomGroupe) async {
    servicesCalls++;
    return [];
  }

  @override
  Future<Map<String, dynamic>> fetchFreelances({
    int page = 1,
    int limit = 50,
    String sortBy = 'rating',
    String sortOrder = 'desc',
  }) async =>
      {
        'freelances': freelances,
        'pagination': null,
      };
}

Categorie _cat(String id, String name, {String image = ''}) => Categorie(
      idcategorie: id,
      nomcategorie: name,
      imagecategorie: image,
      groupe: Groupe(idgroupe: 'g1', nomgroupe: 'Freelance'),
    );

Map<String, dynamic> _freelance({
  String id = 'f1',
  String name = 'Awa Koné',
  String job = 'UI Designer',
  double rating = 0,
  double hourlyRate = 0,
  List<String> skills = const ['Figma', 'UI'],
  String? availabilityStatus,
  String imagePath = '',
}) {
  return {
    '_id': id,
    'name': name,
    'job': job,
    'category': 'Design',
    'rating': rating,
    'hourlyRate': hourlyRate,
    'skills': skills,
    if (availabilityStatus != null) 'availabilityStatus': availabilityStatus,
    'imagePath': imagePath,
  };
}

Future<void> _pumpHub(
  WidgetTester tester, {
  required ApiClient api,
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        home: FreelancePageScreen(apiClient: api),
      ),
    ),
  );
  // Chargement catégories + freelances (éviter pumpAndSettle : AppImage
  // garde un CircularProgressIndicator en boucle en tests HTTP).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:3000/api');
  });

  group('STAB-13B Phase 2 — Hub Freelance talent-first', () {
    testWidgets('hub sans Services populaires ni Offres rapides', (tester) async {
      final api = _HubApi(
        categories: [_cat('c1', 'Design')],
        freelances: [_freelance()],
      );
      await _pumpHub(tester, api: api);

      expect(find.text('Services populaires'), findsNothing);
      expect(find.text('Offres rapides'), findsNothing);
      expect(find.text('Freelance'), findsOneWidget);
      expect(find.text('Quelle compétence recherchez-vous ?'), findsOneWidget);
      expect(find.text('Freelances recommandés'), findsOneWidget);
      expect(api.servicesCalls, 0);
    });

    testWidgets('catégories réelles avec imagecategorie backend', (tester) async {
      final api = _HubApi(
        categories: [
          _cat('c1', 'Design',
              image: 'https://res.cloudinary.com/demo/image/upload/design.jpg'),
          _cat('c2', 'Développement'),
        ],
        freelances: [_freelance()],
      );
      await _pumpHub(tester, api: api);

      expect(find.text('Design'), findsWidgets);
      expect(find.text('Développement'), findsOneWidget);
      // Image dashboard/backend affichée quand URL valide
      expect(find.byType(AppImage), findsWidgets);
    });

    testWidgets('catégorie sans image → icône fallback DS', (tester) async {
      final api = _HubApi(
        categories: [_cat('c1', 'Design', image: '')],
        freelances: [_freelance()],
      );
      await _pumpHub(tester, api: api);

      expect(find.text('Design'), findsWidgets);
      expect(find.byType(AppImage), findsNothing);
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    });

    testWidgets('freelance réel affiché', (tester) async {
      final api = _HubApi(
        categories: [_cat('c1', 'Design')],
        freelances: [_freelance(name: 'Awa Koné', job: 'UI Designer')],
      );
      await _pumpHub(tester, api: api);

      expect(find.text('Awa Koné'), findsOneWidget);
      expect(find.text('UI Designer'), findsOneWidget);
      expect(find.text('Voir le profil'), findsOneWidget);
    });

    testWidgets('sans note → pas de faux 0', (tester) async {
      final api = _HubApi(
        categories: [_cat('c1', 'Design')],
        freelances: [_freelance(rating: 0)],
      );
      await _pumpHub(tester, api: api);

      expect(find.textContaining('0.0'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('sans tarif → pas de faux prix', (tester) async {
      final api = _HubApi(
        categories: [_cat('c1', 'Design')],
        freelances: [_freelance(hourlyRate: 0)],
      );
      await _pumpHub(tester, api: api);

      expect(find.textContaining('FCFA'), findsNothing);
      expect(find.textContaining('Sur devis'), findsNothing);
      expect(find.textContaining('FCFA/h'), findsNothing);
    });

    testWidgets('note et tarif réels affichés seulement si renseignés',
        (tester) async {
      final api = _HubApi(
        categories: [_cat('c1', 'Design')],
        freelances: [
          _freelance(rating: 4.8, hourlyRate: 15000, name: 'Yao'),
        ],
      );
      await _pumpHub(tester, api: api);

      expect(find.text('Yao'), findsOneWidget);
      expect(find.textContaining('4.8'), findsOneWidget);
      expect(find.textContaining('FCFA'), findsOneWidget);
    });

    testWidgets('zéro freelance → empty propre', (tester) async {
      final api = _HubApi(
        categories: [_cat('c1', 'Design')],
        freelances: const [],
      );
      await _pumpHub(tester, api: api);

      expect(find.text('Aucun freelance disponible'), findsOneWidget);
      expect(
        find.text('De nouveaux talents apparaîtront bientôt.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('compétences populaires depuis données réelles', (tester) async {
      final api = _HubApi(
        categories: [_cat('c1', 'Design')],
        freelances: [
          _freelance(skills: ['Figma', 'UI']),
          _freelance(id: 'f2', name: 'Bé', skills: ['Figma', 'React']),
        ],
      );
      await _pumpHub(tester, api: api);

      expect(find.text('Compétences populaires'), findsOneWidget);
      expect(find.text('Figma'), findsWidgets);
    });

    testWidgets('imagecategorie Cloudinary → AppImage (source dashboard/backend)',
        (tester) async {
      const url =
          'https://res.cloudinary.com/demo/image/upload/cat-design.jpg';
      final api = _HubApi(
        categories: [_cat('c1', 'Design', image: url)],
        freelances: [_freelance(imagePath: '')],
      );
      await _pumpHub(tester, api: api);

      final appImage = tester.widget<AppImage>(find.byType(AppImage).first);
      expect(appImage.imageUrl, url);
    });

    for (final size in [
      const Size(320, 568),
      const Size(360, 640),
      const Size(390, 844),
      const Size(412, 915),
    ]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
            '${size.width.toInt()}×${size.height.toInt()} scale $scale sans overflow',
            (tester) async {
          final api = _HubApi(
            categories: [
              _cat('c1', 'Design graphique'),
              _cat('c2', 'Développement web'),
              _cat('c3', 'Marketing digital'),
              _cat('c4', 'Rédaction'),
            ],
            freelances: [
              _freelance(name: 'Awa', job: 'Designer UX/UI'),
              _freelance(id: 'f2', name: 'Koffi', job: 'Dev Flutter'),
            ],
          );
          await _pumpHub(tester, api: api, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          // Scroll pour forcer layout bas de page
          await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
