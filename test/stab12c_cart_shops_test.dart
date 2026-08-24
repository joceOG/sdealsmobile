import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdealsmobile/data/errors/api_exception.dart';
import 'package:sdealsmobile/data/models/article.dart';
import 'package:sdealsmobile/data/models/cart_model.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/models/freelance_model.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageEventM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageStateM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/utils/cart_navigation.dart';

class _FakeShoppingApi extends ApiClient {
  _FakeShoppingApi({
    this.vendeursResult,
    this.vendeursError,
    this.addCartResult,
    this.addCartError,
  });

  final List<Map<String, dynamic>>? vendeursResult;
  final Object? vendeursError;
  final Map<String, dynamic>? addCartResult;
  final Object? addCartError;

  int vendeursCalls = 0;
  int addCalls = 0;
  String? lastVendeurId;

  @override
  Future<List<Map<String, dynamic>>> fetchVendeurs() async {
    vendeursCalls++;
    if (vendeursError != null) throw vendeursError!;
    return List<Map<String, dynamic>>.from(vendeursResult ?? const []);
  }

  @override
  Future<Map<String, dynamic>> addToCart({
    required String userId,
    required String articleId,
    required String vendeurId,
    int quantite = 1,
    Map<String, String>? variantes,
  }) async {
    addCalls++;
    lastVendeurId = vendeurId;
    if (addCartError != null) throw addCartError!;
    return addCartResult ??
        {
          'cart': {
            '_id': 'c1',
            'utilisateur': userId,
            'articles': [
              {
                '_id': 'i1',
                'article': articleId,
                'vendeur': vendeurId,
                'nomArticle': 'Produit',
                'imageArticle': '',
                'quantite': quantite,
                'prixUnitaire': 1000,
                'prixTotal': 1000 * quantite,
              }
            ],
            'montantArticles': 1000 * quantite,
            'montantTotal': 1000 * quantite,
            'fraisLivraison': 0,
            'fraisService': 0,
          }
        };
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:3000/api');
  });

  group('STAB-12C Freelance / erreurs', () {
    test('profil partiel nested absent → parse OK', () {
      final f = FreelanceModel.fromBackend({
        '_id': '507f1f77bcf86cd799439011',
        'utilisateur': null,
        'name': null,
        'job': null,
      });
      expect(f.id, isNotEmpty);
      expect(f.name.toLowerCase(), isNot(contains('exception')));
    });

    test('message UI 500 propre — pas Exception:', () {
      const ex = ApiException(
        statusCode: 500,
        message: 'Impossible de charger ce profil. Réessayez.',
      );
      expect(ApiException.userFacing(ex), isNot(contains('Exception:')));
      expect(ex.message, contains('Impossible de charger'));
    });

    test('ObjectId invalide côté helper navigation panier', () {
      expect(isLikelyMongoObjectId('abc'), isFalse);
      expect(isLikelyMongoObjectId('unknown'), isFalse);
      expect(isLikelyMongoObjectId(null), isFalse);
      expect(isLikelyMongoObjectId('507f1f77bcf86cd799439011'), isTrue);
    });
  });

  group('STAB-12C Article / vendeurId', () {
    test('extrait vendeur ObjectId depuis ref', () {
      final a = Article.fromJson({
        '_id': 'a1',
        'nomArticle': 'Chaussures',
        'prixArticle': 5000,
        'quantiteArticle': 2,
        'photoArticle': 'https://example.com/a.jpg',
        'vendeur': '507f1f77bcf86cd799439011',
      });
      expect(a.vendeurId, '507f1f77bcf86cd799439011');
    });

    test('extrait vendeur depuis objet peuplé', () {
      final a = Article.fromJson({
        '_id': 'a1',
        'nomArticle': 'Chaussures',
        'prixArticle': 5000,
        'quantiteArticle': 2,
        'photoArticle': '',
        'vendeur': {'_id': '507f1f77bcf86cd799439011', 'shopName': 'Shop'},
      });
      expect(a.vendeurId, '507f1f77bcf86cd799439011');
    });

    test('article partiel ne plante pas', () {
      final a = Article.fromJson({
        'nomArticle': null,
        'prixArticle': null,
        'quantiteArticle': null,
        'photoArticle': null,
        'vendeur': null,
      });
      expect(a.nomArticle, '');
      expect(a.vendeurId, isNull);
    });
  });

  group('STAB-12C Boutiques', () {
    test('données → Loaded', () async {
      final api = _FakeShoppingApi(vendeursResult: [
        {
          '_id': 'v1',
          'shopName': 'Boutique A',
          'shopDescription': '',
          'businessType': 'Retail',
          'accountStatus': 'Active',
          'rating': 4,
          'completedOrders': 1,
          'shippingMethods': <String>[],
          'paymentMethods': <String>[],
          'deliveryZones': <String>[],
          'businessCategories': <String>[],
          'tags': <String>[],
        }
      ]);
      final bloc = ShoppingPageBlocM(apiClient: api);
      bloc.add(LoadVendeursEvent());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ShoppingPageStateM>(
            (s) =>
                s.isVendeursLoading == false &&
                (s.vendeurs?.length ?? 0) == 1 &&
                (s.vendeursError == null || s.vendeursError!.isEmpty),
          ),
        ),
      );
      await bloc.close();
    });

    test('zéro boutique → Empty (pas loading permanent)', () async {
      final bloc = ShoppingPageBlocM(
        apiClient: _FakeShoppingApi(vendeursResult: const []),
      );
      bloc.add(LoadVendeursEvent());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ShoppingPageStateM>(
            (s) =>
                s.isVendeursLoading == false &&
                (s.vendeurs?.isEmpty ?? false),
          ),
        ),
      );
      await bloc.close();
    });

    test('500 → Error + Retry', () async {
      final api = _FakeShoppingApi(
        vendeursError: const ApiException(
          statusCode: 500,
          message: 'Impossible de charger les boutiques. Réessayez.',
        ),
      );
      final bloc = ShoppingPageBlocM(apiClient: api);
      bloc.add(LoadVendeursEvent());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ShoppingPageStateM>(
            (s) =>
                s.isVendeursLoading == false &&
                (s.vendeursError ?? '').isNotEmpty &&
                !s.vendeursError!.contains('Exception:'),
          ),
        ),
      );
      expect(api.vendeursCalls, 1);
      bloc.add(LoadVendeursEvent());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ShoppingPageStateM>((s) => s.isVendeursLoading == false),
        ),
      );
      expect(api.vendeursCalls, 2);
      await bloc.close();
    });

    test('timeout → Error UI propre', () async {
      final bloc = ShoppingPageBlocM(
        apiClient: _FakeShoppingApi(vendeursError: ApiException.timeout()),
      );
      bloc.add(LoadVendeursEvent());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ShoppingPageStateM>(
            (s) =>
                s.isVendeursLoading == false &&
                (s.vendeursError ?? '').contains('trop de temps'),
          ),
        ),
      );
      await bloc.close();
    });
  });

  group('STAB-12C Panier', () {
    test('panier vide parse OK', () {
      final cart = Cart.fromJson({
        '_id': 'c1',
        'utilisateur': 'u1',
        'articles': [],
        'montantArticles': 0,
        'montantTotal': 0,
        'fraisLivraison': 0,
        'fraisService': 0,
      });
      expect(cart.articles, isEmpty);
      expect(cart.totalItems, 0);
    });

    test('ajout produit → cart visible + vendeurId transmis', () async {
      final api = _FakeShoppingApi();
      final bloc = ShoppingPageBlocM(apiClient: api);
      bloc.add(const AddToCartEvent(
        userId: '507f1f77bcf86cd799439011',
        articleId: '507f1f77bcf86cd799439012',
        vendeurId: '507f1f77bcf86cd799439013',
        quantite: 1,
      ));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ShoppingPageStateM>(
            (s) =>
                !s.isAddingToCart &&
                s.cart != null &&
                s.cart!.totalItems >= 1,
          ),
        ),
      );
      expect(api.lastVendeurId, '507f1f77bcf86cd799439013');
      expect(api.addCalls, 1);
      await bloc.close();
    });

    test('deux ajouts → 2 appels API (règle quantité serveur)', () async {
      final api = _FakeShoppingApi();
      final bloc = ShoppingPageBlocM(apiClient: api);
      const evt = AddToCartEvent(
        userId: '507f1f77bcf86cd799439011',
        articleId: '507f1f77bcf86cd799439012',
        vendeurId: '507f1f77bcf86cd799439013',
        quantite: 1,
      );
      bloc.add(evt);
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<ShoppingPageStateM>((s) => !s.isAddingToCart)),
      );
      bloc.add(evt);
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<ShoppingPageStateM>((s) => !s.isAddingToCart)),
      );
      expect(api.addCalls, 2);
      await bloc.close();
    });

    test('échec ajout → cartError sans Exception:', () async {
      final bloc = ShoppingPageBlocM(
        apiClient: _FakeShoppingApi(
          addCartError: const ApiException(
            statusCode: 400,
            message: 'Impossible d\'ajouter au panier. Réessayez.',
          ),
        ),
      );
      bloc.add(const AddToCartEvent(
        userId: '507f1f77bcf86cd799439011',
        articleId: '507f1f77bcf86cd799439012',
        vendeurId: '507f1f77bcf86cd799439013',
      ));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ShoppingPageStateM>(
            (s) =>
                !s.isAddingToCart &&
                (s.cartError ?? '').isNotEmpty &&
                !s.cartError!.contains('Exception:'),
          ),
        ),
      );
      await bloc.close();
    });
  });
}
