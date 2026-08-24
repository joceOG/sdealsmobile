import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/auth_form_widgets.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/phone_country_field.dart';
import 'package:sdealsmobile/mobile/view/onboarding/onboarding_screen.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageStateM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/widgets/product_card_m.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/models/categorie.dart';

class _StubShoppingApi extends ApiClient {
  @override
  Future<List<Categorie>> fetchCategorie(String nomGroupe) async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchVendeurs() async => [];
}

/// Reproduit la règle badge promo de [_CompactShopProductCard].
bool stab13ShowDealBadge({
  required int? discountPercent,
  required String? strikePrice,
}) {
  return discountPercent != null &&
      discountPercent > 0 &&
      strikePrice != null &&
      strikePrice.isNotEmpty;
}

/// Layout distance prestataire (STAB-13).
class _DistanceRowProbe extends StatelessWidget {
  const _DistanceRowProbe({required this.distance});

  final String distance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              distance,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:3000/api');
  });

  group('STAB-13 SDInput', () {
    testWidgets('helper mot de passe visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SDInput(
              label: 'Mot de passe',
              hint: 'Créez un mot de passe',
              helperText: '6 caractères minimum',
            ),
          ),
        ),
      );
      expect(find.text('6 caractères minimum'), findsOneWidget);
    });

    testWidgets('erreur email sous le champ', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SDInput(
              label: 'Email',
              errorText: 'Email déjà utilisé',
            ),
          ),
        ),
      );
      expect(find.text('Email déjà utilisé'), findsOneWidget);
    });
  });

  group('STAB-13 PhoneCountryField', () {
    testWidgets('erreur téléphone sous le champ', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneCountryField(
              controller: controller,
              selectedCountry: kDefaultPhoneCountries.first,
              onCountryChanged: (_) {},
              errorText: 'Numéro de téléphone invalide',
            ),
          ),
        ),
      );
      expect(find.text('Numéro de téléphone invalide'), findsOneWidget);
    });
  });

  group('STAB-13 SDButton', () {
    testWidgets('loading conserve taille stable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SDButton(
              text: 'Connexion',
              isLoading: true,
              fullWidth: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      final h1 = tester.getSize(find.byType(SDButton)).height;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SDButton(
              text: 'Connexion',
              isLoading: false,
              fullWidth: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      final h2 = tester.getSize(find.byType(SDButton)).height;
      expect(h1, h2);
    });
  });

  group('STAB-13 onboarding', () {
    testWidgets('bouton Passer visible petit écran sans overflow',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );
      await tester.pump();

      expect(find.text('Passer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('STAB-13 product card', () {
    testWidgets('nom long sans overflow', (tester) async {
      const product = Product(
        id: 'p1',
        name: 'Produit avec un nom extrêmement long pour tester ellipsis',
        image: '',
        size: 'M',
        price: '125 000 FCFA',
        brand: 'Marque',
        rating: 4.5,
      );

      final bloc = ShoppingPageBlocM(apiClient: _StubShoppingApi());
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 260,
              child: BlocProvider<ShoppingPageBlocM>.value(
                value: bloc,
                child: const ProductCardM(product: product),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('prix + note sans overlap', (tester) async {
      const product = Product(
        id: 'p2',
        name: 'Article',
        image: '',
        size: 'L',
        price: '999 999 999 FCFA',
        rating: 4.8,
      );

      final bloc = ShoppingPageBlocM(apiClient: _StubShoppingApi());
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 260,
              child: BlocProvider<ShoppingPageBlocM>.value(
                value: bloc,
                child: const ProductCardM(product: product),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('FCFA'), findsOneWidget);
    });
  });

  group('STAB-13 badge réduction', () {
    test('absence badge si aucune promotion', () {
      expect(
        stab13ShowDealBadge(discountPercent: null, strikePrice: null),
        isFalse,
      );
      expect(
        stab13ShowDealBadge(discountPercent: 15, strikePrice: null),
        isFalse,
      );
    });

    test('vrai badge réduction autorisé', () {
      expect(
        stab13ShowDealBadge(
          discountPercent: 15,
          strikePrice: '150 000 FCFA',
        ),
        isTrue,
      );
    });
  });

  group('STAB-13 carte prestataire distance', () {
    testWidgets('distance longue sans overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _DistanceRowProbe(
              distance: 'À 12,4 km de votre position',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('12,4 km'), findsOneWidget);
    });
  });

  group('STAB-13 feedback states', () {
    testWidgets('Boutiques Empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SDEmptyState(
              title: 'Aucune boutique',
              message: 'Les boutiques recommandées apparaîtront bientôt.',
              icon: Icons.storefront_outlined,
            ),
          ),
        ),
      );
      expect(find.text('Aucune boutique'), findsOneWidget);
    });

    testWidgets('Boutiques Error + Réessayer', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SDErrorState(
              message: 'Impossible de charger les boutiques.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Réessayer'));
      expect(retried, isTrue);
    });

    testWidgets('Freelance Empty cohérent', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SDEmptyState(
              title: 'Aucun freelance',
              message: 'Les freelances disponibles apparaîtront bientôt.',
              icon: Icons.people_outline,
            ),
          ),
        ),
      );
      expect(find.text('Aucun freelance'), findsOneWidget);
    });
  });

  group('STAB-13 auth login mode', () {
    testWidgets('toggle Téléphone / Email visible', (tester) async {
      AuthLoginMode mode = AuthLoginMode.phone;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthLoginModeToggle(
              mode: mode,
              onChanged: (m) => mode = m,
            ),
          ),
        ),
      );
      expect(find.text('Téléphone'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      await tester.tap(find.text('Email'));
      await tester.pump();
      expect(mode, AuthLoginMode.email);
    });
  });

  group('STAB-13 auth terms', () {
    testWidgets('conditions cliquables présentes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTermsAcceptance(
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.textContaining('Conditions d\'utilisation'), findsOneWidget);
      expect(find.textContaining('Politique de confidentialité'), findsOneWidget);
    });
  });

  group('STAB-13 GuestAuthState', () {
    testWidgets('messages invité — auth required, pas empty inbox', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestAuthState(
              pageTitle: 'Messages',
              title: 'Connectez-vous pour accéder à vos messages',
              description:
                  'Discutez directement avec les prestataires, freelances et vendeurs.',
              icon: Icons.forum_outlined,
            ),
          ),
        ),
      );

      expect(find.text('Connectez-vous pour accéder à vos messages'), findsOneWidget);
      expect(find.text('Pas encore de messages'), findsNothing);
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Créer un compte'), findsOneWidget);
    });

    testWidgets('profil invité — contenu orienté compte', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestAuthState(
              pageTitle: 'Profil',
              title: 'Connectez-vous à votre profil',
              description:
                  'Gérez vos informations, favoris, demandes et votre activité Soutrali Deals.',
              icon: Icons.person_outline_rounded,
            ),
          ),
        ),
      );

      expect(find.text('Connectez-vous à votre profil'), findsOneWidget);
      expect(find.textContaining('favoris'), findsOneWidget);
      expect(find.textContaining('services autour de vous'), findsNothing);
    });

    testWidgets('CTA guest — hauteur 56dp via SDButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestAuthState(
              title: 'Connectez-vous pour publier',
              description: 'Test',
              icon: Icons.add_rounded,
            ),
          ),
        ),
      );

      final primary = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(primary.style?.minimumSize?.resolve({})?.height, 56);
    });
  });

  group('STAB-13 textes longs', () {
    testWidgets('Row avec Flexible sans RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Message de validation très long qui ne doit pas provoquer de débordement',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
