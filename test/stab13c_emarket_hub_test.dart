import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/models/article.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/groupe.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';

class _ShopHubApi extends ApiClient {
  _ShopHubApi({
    this.categories = const [],
    this.articles = const [],
    this.vendeurs = const [],
  });

  final List<Categorie> categories;
  final List<Article> articles;
  final List<Map<String, dynamic>> vendeurs;

  @override
  Future<List<Categorie>> fetchCategorie(String nomGroupe) async => categories;

  @override
  Future<List<Article>> fetchArticle() async => articles;

  @override
  Future<List<Map<String, dynamic>>> fetchVendeurs() async => vendeurs;
}

Categorie _cat(String id, String name) => Categorie(
      idcategorie: id,
      nomcategorie: name,
      imagecategorie: '',
      groupe: Groupe(idgroupe: 'g1', nomgroupe: 'E-marché'),
    );

Article _article({
  String id = 'a1',
  String name = 'Article FULL',
  String price = '3000',
  String photo = '',
}) =>
    Article(
      id: id,
      nomArticle: name,
      prixArticle: price,
      quantiteArticle: 1,
      photoArticle: photo,
      vendeurId: 'v1',
    );

Future<void> _pumpHub(
  WidgetTester tester, {
  required _ShopHubApi api,
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
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit()),
          BlocProvider(create: (_) => ShoppingPageBlocM(apiClient: api)),
        ],
        child: const MaterialApp(home: ShoppingPageScreenM()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:3000/api');
  });

  group('STAB-13C Phase 2 — É-marché product-first', () {
    testWidgets('aucune bannière fake -20%, aucun Bons plans, aucun faux km',
        (tester) async {
      final api = _ShopHubApi(
        categories: [_cat('c1', 'Mode')],
        articles: [_article()],
      );
      await _pumpHub(tester, api: api);

      expect(find.textContaining('-20%'), findsNothing);
      expect(find.textContaining('électronique'), findsNothing);
      expect(find.text('Bon plan'), findsNothing);
      expect(find.text('Bons plans'), findsNothing);
      expect(find.text('Près de vous'), findsNothing);
      expect(find.textContaining(' km'), findsNothing);
      expect(find.text('Produits populaires'), findsNothing);
    });

    testWidgets('architecture : É-marché + recherche + catégories avant produits',
        (tester) async {
      final api = _ShopHubApi(
        categories: [_cat('c1', 'Électronique')],
        articles: [_article(name: 'Oiseau')],
      );
      await _pumpHub(tester, api: api);

      expect(find.text('É-marché'), findsOneWidget);
      expect(find.text('Que recherchez-vous ?'), findsOneWidget);
      expect(find.text('Catégories'), findsOneWidget);
      expect(find.text('Produits à découvrir'), findsOneWidget);
      expect(find.text('Électronique'), findsWidgets);

      final catY = tester.getTopLeft(find.text('Catégories')).dy;
      final prodY = tester.getTopLeft(find.text('Produits à découvrir')).dy;
      expect(catY < prodY, isTrue);
    });

    testWidgets('produit réel + prix formaté', (tester) async {
      final api = _ShopHubApi(
        categories: [_cat('c1', 'Mode')],
        articles: [_article(name: 'Oiseau', price: '3000')],
      );
      await _pumpHub(tester, api: api);

      expect(find.text('Oiseau'), findsOneWidget);
      expect(find.textContaining('FCFA'), findsWidgets);
      // Espace fine \u202F entre milliers
      expect(find.text('3\u202F000 FCFA'), findsOneWidget);
    });

    testWidgets('produit sans rating → aucun faux 0', (tester) async {
      final api = _ShopHubApi(
        categories: [_cat('c1', 'Mode')],
        articles: [_article()],
      );
      await _pumpHub(tester, api: api);

      expect(find.textContaining('0.0'), findsNothing);
      expect(find.text('Non spécifié'), findsNothing);
    });

    testWidgets('titre long sans overflow critique', (tester) async {
      final api = _ShopHubApi(
        categories: [_cat('c1', 'Mode')],
        articles: [
          _article(
            name:
                'Super article premium ultra long pour tester le wrap sur deux lignes maximum',
          ),
        ],
      );
      await _pumpHub(tester, api: api, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
    });

    testWidgets('image absente → placeholder icône', (tester) async {
      final api = _ShopHubApi(
        categories: [_cat('c1', 'Mode')],
        articles: [_article(photo: '')],
      );
      await _pumpHub(tester, api: api);
      expect(find.byIcon(Icons.image_outlined), findsWidgets);
    });

    testWidgets('vendeurs vides → section Boutiques absente', (tester) async {
      final api = _ShopHubApi(
        categories: [_cat('c1', 'Mode')],
        articles: [_article()],
        vendeurs: const [],
      );
      await _pumpHub(tester, api: api);

      expect(find.text('Boutiques'), findsNothing);
      expect(find.text('Aucune boutique'), findsNothing);
      expect(find.textContaining('apparaîtront bientôt'), findsNothing);
    });

    testWidgets('vendeurs présents → section Boutiques visible', (tester) async {
      final api = _ShopHubApi(
        categories: [_cat('c1', 'Mode')],
        articles: [_article()],
        vendeurs: [
          {
            '_id': 'v1',
            'shopName': 'Boutique Alpha',
            'shopDescription': '',
            'rating': 0,
          },
        ],
      );
      await _pumpHub(tester, api: api);

      expect(find.text('Boutiques'), findsOneWidget);
      expect(find.text('Boutique Alpha'), findsOneWidget);
      expect(find.textContaining('0.0'), findsNothing);
    });

    testWidgets('panier toujours accessible', (tester) async {
      final api = _ShopHubApi(
        categories: [_cat('c1', 'Mode')],
        articles: [_article()],
      );
      await _pumpHub(tester, api: api);
      expect(find.byTooltip('Panier'), findsOneWidget);
    });

    testWidgets('320×568 textScale 1.3 sans overflow', (tester) async {
      final api = _ShopHubApi(
        categories: [
          _cat('c1', 'Mode & Fashion'),
          _cat('c2', 'Électronique'),
          _cat('c3', 'Maison'),
          _cat('c4', 'Sport'),
        ],
        articles: [
          _article(name: 'Produit A', price: '15000'),
          _article(id: 'a2', name: 'Produit B', price: '2500'),
        ],
      );
      await _pumpHub(
        tester,
        api: api,
        size: const Size(320, 568),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });
}
