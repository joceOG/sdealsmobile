import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import '../shoppingpageblocm/shoppingPageBlocM.dart';
import '../shoppingpageblocm/shoppingPageEventM.dart';
import '../shoppingpageblocm/shoppingPageStateM.dart' as bloc_model;
import 'productDetailsScreenM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';
import 'panierProductScreenM.dart';
import '../../seller_registration/screens/seller_registration_screen.dart';
import 'package:sdealsmobile/data/models/vendeur.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/product_card_m.dart';
import '../../common/widgets/app_image.dart';
import '../../common/widgets/skeleton_loader.dart';

// Design System
import '../../../../design_system/colors.dart';
import '../../../../design_system/typography.dart';
import '../../../../design_system/spacing.dart';

// Utilisation du modèle Product du BLoC
typedef Product = bloc_model.Product;

class ShoppingPageScreenM extends StatefulWidget {
  // Retiré la dépendance aux catégories passées depuis HomePage
  const ShoppingPageScreenM({Key? key}) : super(key: key);

  @override
  State<ShoppingPageScreenM> createState() => _ShoppingPageScreenMState();
}

class _ShoppingPageScreenMState extends State<ShoppingPageScreenM> {
  @override
  void initState() {
    super.initState();
    // Charger les catégories spécifiquement pour E-marché
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShoppingPageBlocM>().add(LoadCategorieDataM());
      // Charger aussi les produits
      context.read<ShoppingPageBlocM>().add(LoadProductsEvent());

      // 🛒 NOUVEAU : Charger le panier de l'utilisateur
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        context.read<ShoppingPageBlocM>().add(
              LoadCartEvent(userId: authState.utilisateur.idutilisateur),
            );
      }
    });
  }

  bool hasSoutraPayBalance = true; // Solde disponible sur SoutraPay
  bool isCompareDialogOpen = false; // Dialog de comparaison ouvert ou fermé
  // Note: selectedFilter sera maintenant géré par le BLoC

  // Méthode pour attribuer une icône selon le nom de la catégorie
  IconData _getCategoryIcon(String name) {
    // Attribution d'une icône selon le nom de la catégorie
    IconData icon = Icons.category; // Icône par défaut

    name = name.toLowerCase();

    if (name.contains('auto') || name.contains('moto')) {
      return Icons.directions_car;
    } else if (name.contains('immobilier') || name.contains('maison')) {
      return Icons.house;
    } else if (name.contains('électronique') || name.contains('electronique')) {
      return Icons.devices;
    } else if (name.contains('tech')) {
      return Icons.electrical_services;
    } else if (name.contains('mode') ||
        name.contains('vêtement') ||
        name.contains('vetement')) {
      return Icons.style;
    } else if (name.contains('meuble')) {
      return Icons.chair;
    } else if (name.contains('sport')) {
      return Icons.sports_soccer;
    } else if (name.contains('jeu')) {
      return Icons.videogame_asset;
    } else if (name.contains('santé') || name.contains('sante')) {
      return Icons.health_and_safety;
    }

    return icon;
  }

  // Liste de produits fictifs (remplacer par nos données API)
  List<Product> get products => [
        Product(
            id: '1',
            name: 'Nike Air Max',
            image: 'assets/products/1.png',
            size: 'Pointures 42-43',
            price: '25.000 Fcfa',
            brand: 'Nike'),
        Product(
            id: '2',
            name: 'Adidas Superstar',
            image: 'assets/products/2.png',
            size: 'Pointures 42-43',
            price: '30.000 Fcfa',
            brand: 'Adidas',
            isFavorite: true),
        Product(
            id: '3',
            name: 'Puma Suede',
            image: 'assets/products/3.png',
            size: 'Pointures 40-44',
            price: '22.000 Fcfa',
            brand: 'Puma'),
        Product(
            id: '4',
            name: 'Reebok Classic',
            image: 'assets/products/4.png',
            size: 'Pointures 41-45',
            price: '28.000 Fcfa',
            brand: 'Reebok',
            isFavorite: true),
        Product(
            id: '5',
            name: 'Fila Disruptor',
            image: 'assets/products/5.png',
            size: 'Pointures 39-43',
            price: '20.000 Fcfa',
            brand: 'Fila'),
        Product(
            id: '6',
            name: 'Converse Chuck Taylor',
            image: 'assets/products/6.png',
            size: 'Pointures 38-42',
            price: '27.000 Fcfa',
            brand: 'Converse'),
        Product(
            id: '7',
            name: 'Vans Old Skool',
            image: 'assets/products/7.png',
            size: 'Pointures 40-44',
            price: '24.000 Fcfa',
            brand: 'Vans'),
        Product(
            id: '8',
            name: 'New Balance 574',
            image: 'assets/products/8.png',
            size: 'Pointures 41-45',
            price: '29.000 Fcfa',
            brand: 'New Balance'),
        Product(
            id: '9',
            name: 'Asics Gel Lyte',
            image: 'assets/products/9.png',
            size: 'Pointures 40-43',
            price: '23.000 Fcfa',
            brand: 'Asics'),
        Product(
            id: '10',
            name: 'Air Jordan 4',
            image: 'assets/products/10.png',
            size: 'Pointures 42-46',
            price: '35.000 Fcfa',
            brand: 'Jordan',
            rating: 4.9),
      ];

  // Conversion des catégories de l'API en format utilisable
  List<Map<String, dynamic>> _getCategories() {
    // Récupérer les catégories depuis le BLoC
    final state = context.read<ShoppingPageBlocM>().state;
    final categories = state.listItems;

    if (categories == null || categories.isEmpty) {
      print('Aucune catégorie dans le BLoC de ShoppingPageScreenM');
      return [
        {'name': 'Aucune catégorie', 'icon': Icons.error_outline},
      ];
    }

    try {
      // Déboguer les catégories récupérées du BLoC
      print('Catégories récupérées du BLoC: ${categories?.length ?? 0}');
      if (categories != null) {
        for (var cat in categories) {
          print('Catégorie: ${cat.nomcategorie}, Groupe: ${cat.groupe}');
        }
      }

      // Transformation des catégories récupérées - correction de l'opérateur null-aware inutile
      return categories.map<Map<String, dynamic>>((category) {
        // Attribution d'une icône selon le nom de la catégorie
        IconData icon = Icons.category;
        String name = "Catégorie";

        if (category != null) {
          // Utiliser titre ou nom selon ce qui est disponible
          name = category.nomcategorie ?? "Catégorie";

          // Attribuer une icône selon le nom
          if (name.toLowerCase().contains('auto') ||
              name.toLowerCase().contains('moto')) {
            icon = Icons.directions_car;
          } else if (name.toLowerCase().contains('immobilier') ||
              name.toLowerCase().contains('maison')) {
            icon = Icons.house;
          } else if (name.toLowerCase().contains('électronique')) {
            icon = Icons.devices;
          } else if (name.toLowerCase().contains('tech')) {
            icon = Icons.electrical_services;
          } else if (name.toLowerCase().contains('mode') ||
              name.toLowerCase().contains('vêtement')) {
            icon = Icons.style;
          } else if (name.toLowerCase().contains('meuble')) {
            icon = Icons.chair;
          } else if (name.toLowerCase().contains('sport')) {
            icon = Icons.sports_soccer;
          } else if (name.toLowerCase().contains('jeu')) {
            icon = Icons.videogame_asset;
          } else if (name.toLowerCase().contains('santé')) {
            icon = Icons.health_and_safety;
          }
        }

        return {
          'name': name,
          'icon': icon,
          'id': category?.idcategorie ?? '',
          'groupe': category?.groupe ?? '',
        };
      }).toList();
    } catch (e) {
      print('Erreur lors de la conversion des catégories: $e');
      return [
        {'name': 'Erreur de chargement', 'icon': Icons.error},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      // FloatingActionButton "Vendre sur Soutrali" (vert uniforme)
      // FloatingActionButton "Vendre" discret (icône seule)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final authState = context.read<AuthCubit>().state;
          if (authState is AuthAuthenticated) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SellerRegistrationScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Veuillez vous connecter pour continuer',
                      style: SDTypography.bodyMedium.copyWith(color: SDColors.white))),
            );
            context.push('/login');
          }
        },
        backgroundColor: SDColors.primary600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.storefront, color: SDColors.white),
      ),
      body: BlocProvider(
        create: (_) => ShoppingPageBlocM()
          ..add(LoadCategorieDataM())
          ..add(LoadProductsEvent()),
        child: CustomScrollView(
          slivers: [
            // AppBar slim moderne
            _buildModernSliverAppBar(),

            // Banner promo sticky SUPPRIMÉE pour plus de clarté
            // _buildPromoStickyBanner(context),

            // Chips E-commerce spécialisées
            _buildEcommerceChipsSliver(context),

            // Contenu principal
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: SDSpacing.sm),
                    // Titre des catégories avec style
                    Padding(
                      padding: EdgeInsets.only(left: SDSpacing.xxxs, bottom: SDSpacing.xs),
                      child: Text(
                        'Catégories populaires',
                        style: SDTypography.titleMedium.copyWith(
                          color: SDColors.neutral900,
                        ),
                      ),
                    ),

                    // Liste horizontale de catégories avec design amélioré - utilisation de BlocBuilder
                    SizedBox(
                      height: 120,
                      child: BlocBuilder<ShoppingPageBlocM,
                          bloc_model.ShoppingPageStateM>(
                        builder: (context, state) {
                          // Afficher message de chargement ou d'erreur si nécessaire
                          if (state?.isLoading == true) {
                            return SizedBox(
                              height: 100, // Hauteur approximative des catégories
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 5,
                                padding: EdgeInsets.symmetric(horizontal: SDSpacing.xxxs),
                                itemBuilder: (context, index) => Padding(
                                  padding: EdgeInsets.symmetric(horizontal: SDSpacing.xxs),
                                  child: SkeletonWidget.rounded(
                                    width: 100,
                                    height: 100,
                                    borderRadius: 12,
                                  ),
                                ),
                              ),
                            );
                          }

                          if (state?.error?.isNotEmpty == true) {
                            return Center(
                                child: Text('Erreur: ${state!.error}',
                                    style: SDTypography.bodyMedium.copyWith(color: SDColors.error500)));
                          }

                          final categories = state?.listItems;
                          if (categories == null || categories.isEmpty) {
                            return const Center(
                                child: Text('Aucune catégorie disponible'));
                          }

                          // Générer des couleurs et icônes pour les catégories
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: SDSpacing.xxxs),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final name = category.nomcategorie ?? "Catégorie";

                              // Attribution d'une icône selon le nom
                              IconData icon = _getCategoryIcon(name);

                              return Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: SDSpacing.xxs),
                                child: _buildCategoryCard(name, icon),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: SDSpacing.sm),

                    // 3. Filtres avancés
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: SDSpacing.xxs),
                      child: Text(
                        'Filtres avancés',
                        style: SDTypography.titleSmall.copyWith(
                          color: SDColors.neutral900,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('Prix', Icons.monetization_on),
                          _buildFilterChip('Marque', Icons.branding_watermark),
                          _buildFilterChip('État', Icons.inventory_2),
                          _buildFilterChip('Livraison', Icons.local_shipping),
                          _buildFilterChip('Localisation', Icons.location_on),
                        ],
                      ),
                    ),
                    SizedBox(height: SDSpacing.sm),

                    SizedBox(height: SDSpacing.sm),

                    // Titre de la section produits
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Articles populaires',
                          style: SDTypography.titleMedium.copyWith(
                            color: SDColors.neutral900,
                          ),
                        ),
                        BlocBuilder<ShoppingPageBlocM,
                            bloc_model.ShoppingPageStateM>(
                          builder: (context, state) {
                            return TextButton.icon(
                              onPressed: () {
                                // Ouvrir le dialog de comparaison uniquement si des produits sont sélectionnés
                                if ((state.productsToCompare?.isNotEmpty ??
                                    false)) {
                                  setState(() {
                                    isCompareDialogOpen = true;
                                  });
                                  _showCompareDialog(
                                      context, state.productsToCompare!);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Sélectionnez des produits à comparer (max. 4)',
                                          style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.compare_arrows, size: 18, color: SDColors.primary600),
                              label: Text(
                                'Comparer ${state.productsToCompare?.length ?? 0}/4',
                                style: SDTypography.labelMedium.copyWith(color: SDColors.primary600),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: SDColors.primary600,
                                padding: EdgeInsets.zero,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: SDSpacing.xxs),
                    // Grille de produits scrollable avec BlocBuilder
                    BlocBuilder<ShoppingPageBlocM,
                        bloc_model.ShoppingPageStateM>(
                        builder: (context, state) {
                          if (state.isLoading ?? false) {
                            return SkeletonGrid(
                              itemCount: 6,
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              itemTemplate: const SkeletonWidget.rounded(
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 12,
                              ),
                            );
                          }

                          // Affichage de débogage pour comprendre l'erreur
                          print('Débogage BlocBuilder ShoppingPage');
                          print('state.error: ${state.error}');
                          print('state.products: ${state.products?.length}');
                          print(
                              'state.filteredProducts: ${state.filteredProducts?.length}');
                          print('state.isLoading: ${state.isLoading}');

                          // Ignorer l'erreur si nous avons des produits à afficher
                          if (state.error != null &&
                              (state.products == null ||
                                  state.products!.isEmpty)) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        size: 50, color: SDColors.error500),
                                    SizedBox(height: SDSpacing.sm),
                                    Text(
                                      'Erreur: ${state.error}',
                                      style: SDTypography.bodyMedium.copyWith(color: SDColors.error500),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: SDSpacing.sm),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Recharger les produits
                                        context
                                            .read<ShoppingPageBlocM>()
                                            .add(LoadProductsEvent());
                                      },
                                      child: Text('Recharger', style: SDTypography.labelMedium),
                                    ),
                                  ],
                                ),
                              );
                          }

                          // ✅ AFFICHAGE CONDITIONNEL : Vendeurs ou Produits
                          if (state.showVendeurs ?? false) {
                            // 👥 AFFICHAGE DES VENDEURS
                            final displayVendeurs =
                                state.filteredVendeurs ?? [];

                            if (state.error?.isNotEmpty == true) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        size: 64, color: SDColors.error200),
                                    SizedBox(height: SDSpacing.sm),
                                    Text(
                                      'Erreur de chargement',
                                      style: SDTypography.titleMedium.copyWith(
                                          color: SDColors.error600),
                                    ),
                                    SizedBox(height: SDSpacing.xxs),
                                    Text(
                                      state.error!,
                                      style: SDTypography.bodyMedium.copyWith(
                                          color: SDColors.neutral600),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: SDSpacing.sm),
                                    ElevatedButton.icon(
                                      onPressed: () => context
                                          .read<ShoppingPageBlocM>()
                                          .add(LoadVendeursEvent()),
                                      icon: Icon(Icons.refresh, color: SDColors.white),
                                      label: Text('Réessayer', style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return _buildVendeursGrid(context, displayVendeurs);
                          } else {
                            // 🛍️ AFFICHAGE DES PRODUITS (logique existante)

                            // S'assurer que nous avons une liste valide même si elle est vide
                            final displayProducts =
                                state.filteredProducts ?? state.products ?? [];

                            if (displayProducts.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_bag_outlined,
                                        size: 64, color: SDColors.neutral400),
                                    SizedBox(height: SDSpacing.sm),
                                    Text(
                                      'Aucun produit trouvé',
                                      style: SDTypography.titleMedium.copyWith(
                                          color: SDColors.neutral500),
                                    ),
                                    SizedBox(height: SDSpacing.xxs),
                                    Text(
                                      'Essayez de modifier vos critères de recherche',
                                      style: SDTypography.bodyMedium.copyWith(
                                          color: SDColors.neutral500),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayProducts.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 2 produits par ligne
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio:
                                    0.72, // Ajuste la hauteur des cartes
                              ),
                              itemBuilder: (context, index) {
                                final product = displayProducts[index];
                                // ✅ PREMIUM : Utilisation de la nouvelle carte produit
                                return ProductCardM(product: product);
                              },
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget pour une carte de catégorie avec design e-commerce moderne
  Widget _buildCategoryCard(String categoryName, IconData icon) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge pour l'icône avec effet de gradient
          Container(
            padding: EdgeInsets.all(SDSpacing.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SDColors.primary300,
                  SDColors.primary600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: SDColors.white,
            ),
          ),
          SizedBox(height: SDSpacing.xs),
          // Texte de la catégorie avec style amélioré
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SDSpacing.xxxs),
            child: Text(
              categoryName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.neutral900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour un filtre
  Widget _buildFilterChip(String label, IconData icon) {
    return BlocBuilder<ShoppingPageBlocM, bloc_model.ShoppingPageStateM>(
      builder: (context, state) {
        bool isSelected = state.selectedFilter == label;

        return Container(
          margin: EdgeInsets.only(right: SDSpacing.xxs),
          child: FilterChip(
            avatar: Icon(icon,
                size: 16, color: isSelected ? SDColors.white : SDColors.primary600),
            label: Text(label, style: SDTypography.labelSmall),
            labelStyle: SDTypography.labelSmall.copyWith(
              color: isSelected ? SDColors.white : SDColors.neutral900,
            ),
            selected: isSelected,
            onSelected: (selected) {
              // Utiliser le BLoC pour changer le filtre sélectionné
              context
                  .read<ShoppingPageBlocM>()
                  .add(ApplyFilterEvent(selected ? label : ''));
            },
            backgroundColor: SDColors.neutral200,
            selectedColor: SDColors.primary600,
          ),
        );
      },
    );
  }

  /// Affiche un dialog de comparaison entre plusieurs produits
  void _showCompareDialog(
      BuildContext context, List<Product> productsToCompare) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comparer les produits'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: productsToCompare
                  .map((product) => Container(
                        margin: const EdgeInsets.all(8),
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            product.image.startsWith('http') ||
                                    product.image.startsWith('https')
                                    ? AppImage(
                                        imageUrl: product.image,
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.contain,
                                        placeholderAsset: 'assets/products/default.png',
                                      )
                                : Image.asset(
                                    product.image.isNotEmpty
                                        ? product.image
                                        : 'assets/products/default.png',
                                    height: 80),
                            const SizedBox(height: 8),
                            Text(product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(product.price),
                            Text('Taille: ${product.size}'),
                            Text('Marque: ${product.brand}'),
                            const SizedBox(height: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () {
                                // Suppression du produit de la comparaison
                                context
                                    .read<ShoppingPageBlocM>()
                                    .add(RemoveFromCompareEvent(product.id));
                                if (productsToCompare.length <= 1) {
                                  Navigator.of(context)
                                      .pop(); // Fermer le dialog si c'est le dernier produit
                                }
                              },
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Fermer'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Vider la liste'),
            onPressed: () {
              context.read<ShoppingPageBlocM>().add(ClearCompareListEvent());
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    ).then((_) => setState(() => isCompareDialogOpen = false));
  }

  /// Widget pour une carte produit minimaliste
  Widget _buildProductCard(BuildContext context, Product product) {
    return BlocBuilder<ShoppingPageBlocM, bloc_model.ShoppingPageStateM>(
      builder: (context, state) {
        // Vérifier si le produit est dans les favoris
        final bool isFavorite =
            state.favoriteProductIds?.contains(product.id) ?? false;
        // Vérifier si le produit est dans la liste de comparaison
        final bool isInCompare =
            state.productsToCompare?.any((p) => p.id == product.id) ?? false;

        return InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<ShoppingPageBlocM>(),
              child: ProductDetails(product: product),
            ),
          )),
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge de la marque
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      child: product.image.startsWith('http') ||
                              product.image.startsWith('https')
                          ? Image.network(
                              product.image,
                              fit: BoxFit.contain,
                              height: 120,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                print('Erreur de chargement image: $error');
                                return Container(
                                  height: 120,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported,
                                        size: 40, color: Colors.grey),
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 120,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              product.image.isNotEmpty
                                  ? product.image
                                  : 'assets/products/default.png',
                              fit: BoxFit.contain,
                              height: 120,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                print('Erreur de chargement image: $error');
                                return Container(
                                  height: 120,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported,
                                        size: 40, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: SDColors.primary600,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(SDSpacing.borderRadiusMedium),
                            bottomRight: Radius.circular(SDSpacing.borderRadiusSmall),
                          ),
                        ),
                        child: Text(
                          product.brand,
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.white,
                          ),
                        ),
                      ),
                    ),
                    // Bouton favoris avec BLoC
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? SDColors.error500 : SDColors.neutral400,
                        ),
                        onPressed: () {
                          // Utiliser le BLoC pour ajouter/retirer des favoris
                          context
                              .read<ShoppingPageBlocM>()
                              .add(ToggleFavoriteEvent(product.id));

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFavorite
                                    ? '${product.name} retiré des favoris!'
                                    : '${product.name} ajouté aux favoris!',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                    // Indicateur de comparaison
                    if (isInCompare)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.8),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.compare_arrows,
                              color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: SDSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du produit
                      Text(
                        product.name,
                        style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: SDSpacing.xxxs),
                      // Taille du produit
                      Text(
                      product.size,
                      style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral500),
                    ),
                    SizedBox(height: SDSpacing.xxxs),
                    // Évaluation
                    Row(
                      children: [
                        ...List.generate(
                          5,
                            (index) => Icon(
                              index < product.rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: SDColors.warning500,
                              size: 14,
                            ),
                          ),
                          SizedBox(width: SDSpacing.xxxs),
                          Text(
                            product.rating.toString(),
                            style: SDTypography.bodySmall.copyWith(
                                color: SDColors.neutral500),
                          ),
                        ],
                      ),
                      SizedBox(height: SDSpacing.xxxs),
                      // Prix
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product.price,
                            style: SDTypography.titleSmall.copyWith(
                              color: SDColors.primary600,
                            ),
                          ),
                          // Rangée de boutons
                          Row(
                            children: [
                              // Bouton comparer
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  onTap: () {
                                    // Ajouter/retirer de la liste de comparaison via le BLoC
                                    if (isInCompare) {
                                      context.read<ShoppingPageBlocM>().add(
                                          RemoveFromCompareEvent(product.id));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${product.name} retiré de la comparaison'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    } else {
                                      context
                                          .read<ShoppingPageBlocM>()
                                          .add(AddToCompareEvent(product));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${product.name} ajouté à la comparaison'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                          child: Container(
                            padding: EdgeInsets.all(SDSpacing.xxxs),
                            decoration: BoxDecoration(
                              color: isInCompare
                                  ? SDColors.info500
                                  : SDColors.neutral400,
                              borderRadius: BorderRadius.circular(SDSpacing.xxxs),
                            ),
                            child: Icon(Icons.compare_arrows,
                                color: SDColors.white, size: 16),
                          ),
                                ),
                              ),
                              // 🛒 Bouton ajouter au panier CONNECTÉ AU BLOC
                              InkWell(
                                onTap: () {
                                  // Récupérer l'utilisateur connecté
                                  final authState =
                                      context.read<AuthCubit>().state;
                                  if (authState is AuthAuthenticated) {
                                    // TODO: Récupérer le vendeurId depuis l'article
                                    // Pour l'instant, on utilise un vendeurId fictif
                                    final vendeurId =
                                        product.vendeurId ?? 'unknown';

                                    // Dispatch l'événement au BLoC
                                    context.read<ShoppingPageBlocM>().add(
                                          AddToCartEvent(
                                            userId: authState
                                                .utilisateur.idutilisateur,
                                            articleId: product.id,
                                            vendeurId: vendeurId,
                                            quantite: 1,
                                          ),
                                        );

                                    // Animation + Feedback
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.white),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                  '${product.name} ajouté au panier!'),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 2),
                                        action: SnackBarAction(
                                          label: 'Voir',
                                          textColor: Colors.white,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    BlocProvider.value(
                                                  value: context.read<
                                                      ShoppingPageBlocM>(),
                                                  child:
                                                      const PanierProductScreenM(),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Rediriger vers la connexion
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Veuillez vous connecter pour ajouter au panier'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    context.push('/login');
                                  }
                                },
                                child: BlocBuilder<ShoppingPageBlocM,
                                    bloc_model.ShoppingPageStateM>(
                                  builder: (context, state) {
                                    final isAdding = state.isAddingToCart;
                                    return Container(
                                      padding: EdgeInsets.all(SDSpacing.xxxs),
                                      decoration: BoxDecoration(
                                        color: isAdding
                                            ? SDColors.neutral400
                                            : SDColors.primary600,
                                        borderRadius: BorderRadius.circular(SDSpacing.xxxs),
                                      ),
                                      child: isAdding
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : Icon(Icons.add_shopping_cart,
                                              color: SDColors.white, size: 16),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Affiche le ModalBottomSheet Premium avec filtres avancés
  void _showAdvancedFilterDialog(BuildContext context) {
    // Déléguer l'affichage au FilterBottomSheet moderne
    FilterBottomSheet.show(context);
  }


  // ✅ PREMIUM : AppBar avec Glassmorphism +  Search Intégré
  Widget _buildModernSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 150, // Hauteur réduite (180 -> 150)
      floating: true,
      pinned: true,
      snap: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SDColors.primary600,
                SDColors.primary700,
                SDColors.primary800,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: SDSpacing.sm),
                  // Top row: Actions uniquement (Alignées à droite)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Badge Marketplace supprimé pour éviter doublon avec tabs

                      // Actions
                      Row(
                        children: [
                          // Panier avec badge
                          BlocBuilder<ShoppingPageBlocM,
                              bloc_model.ShoppingPageStateM>(
                            builder: (context, state) {
                              final cartCount = state.cart?.totalItems ?? 0;
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BlocProvider.value(
                                        value:
                                            context.read<ShoppingPageBlocM>(),
                                        child: const PanierProductScreenM(),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(SDSpacing.xxs),
                                  decoration: BoxDecoration(
                                    color: SDColors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: SDColors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      Icon(Icons.shopping_cart,
                                          color: SDColors.white, size: 20),
                                      if (cartCount > 0)
                                        Positioned(
                                          top: -4,
                                          right: -4,
                                          child: Container(
                                            padding: EdgeInsets.all(SDSpacing.xxxs),
                                            constraints: BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: SDColors.error500,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: SDColors.error500
                                                      .withOpacity(0.5),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                cartCount > 99
                                                    ? '99+'
                                                    : cartCount.toString(),
                                                style: SDTypography.labelSmall.copyWith(
                                                  color: SDColors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(width: SDSpacing.xxs),
                          // Notifications
                          Container(
                            padding: EdgeInsets.all(SDSpacing.xxs),
                            decoration: BoxDecoration(
                              color: SDColors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: SDColors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(Icons.notifications_outlined,
                                color: SDColors.white, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: SDSpacing.sm),
                  // Barre de recherche avec Glassmorphism
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: SDColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: SDColors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: SDColors.neutral900.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      readOnly: true,
                      style: TextStyle(color: SDColors.white),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit...',
                        hintStyle: SDTypography.bodyMedium.copyWith(
                          color: SDColors.white.withOpacity(0.7),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: SDColors.white.withOpacity(0.9),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.filter_alt,
                            color: SDColors.white.withOpacity(0.9),
                          ),
                          onPressed: () =>
                              _showAdvancedFilterDialog(context),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 15),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchPageScreenM(initialIndex: 3),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: SDSpacing.sm),
                ],
              ),
            ),
          ),
        ),
        titlePadding: EdgeInsets.zero,
        expandedTitleScale: 1,
      ),
    );
  }

  // ✅ NOUVEAU : Banner promo sticky pour marketplace
  Widget _buildPromoStickyBanner(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PromoStickyDelegate(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SDColors.primary600.withOpacity(0.1),
                SDColors.primary600.withOpacity(0.15),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              bottom:
                  BorderSide(color: SDColors.primary600.withOpacity(0.3), width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xs),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(SDSpacing.xxxs),
                decoration: BoxDecoration(
                  color: SDColors.primary600.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                ),
                child: Icon(Icons.local_offer, color: SDColors.primary600, size: 16),
              ),
              SizedBox(width: SDSpacing.xs),
              Expanded(
                child: Text(
                  '🛒 Découvre nos meilleures offres et promotions !',
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.primary600.withOpacity(0.9),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(SDSpacing.xxxs),
                decoration: BoxDecoration(
                  color: SDColors.primary600.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                ),
                child: InkWell(
                  onTap: () {
                    // TODO: Masquer le banner définitivement pour cet utilisateur
                  },
                  child: Icon(
                    Icons.close,
                    color: SDColors.primary600,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NOUVEAU : Chips E-commerce spécialisées avec navigation Produits/Vendeurs
  Widget _buildEcommerceChipsSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(SDSpacing.sm, SDSpacing.sm, SDSpacing.sm, SDSpacing.xxs),
        child: BlocBuilder<ShoppingPageBlocM, bloc_model.ShoppingPageStateM>(
          builder: (context, state) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // ✅ NOUVEAU : Chip Navigation Produits
                  _buildNavigationChip(
                    context,
                    'Produits',
                    Icons.shopping_bag_outlined,
                    !(state.showVendeurs ?? false),
                    () => context
                        .read<ShoppingPageBlocM>()
                        .add(const ToggleViewEvent(showVendeurs: false)),
                  ),
                  SizedBox(width: SDSpacing.xxs),

                  // ✅ NOUVEAU : Chip Navigation Vendeurs
                  _buildNavigationChip(
                    context,
                    'Vendeurs',
                    Icons.storefront_outlined,
                    state.showVendeurs ?? false,
                    () => context
                        .read<ShoppingPageBlocM>()
                        .add(const ToggleViewEvent(showVendeurs: true)),
                  ),

                  SizedBox(width: SDSpacing.sm),

                // Chip SoutraPay (gardé en jaune pour différenciation e-commerce)
                InkWell(
                  onTap: () => context.go('/wallet'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xxxs),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [SDColors.warning100, SDColors.warning200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: SDColors.warning500, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: SDColors.warning500.withOpacity(0.15),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet,
                            color: SDColors.warning700, size: 16),
                        SizedBox(width: SDSpacing.xxxs),
                        Text(
                          '💳 SoutraPay',
                          style: SDTypography.labelSmall.copyWith(
                              color: SDColors.warning700),
                        ),
                        // Badge conditionnel si solde disponible
                        if (hasSoutraPayBalance)
                          Container(
                            margin: EdgeInsets.only(left: SDSpacing.xxxs),
                            padding: EdgeInsets.all(SDSpacing.xxxs),
                            decoration: BoxDecoration(
                              color: SDColors.error500,
                              shape: BoxShape.circle,
                            ),
                            child: Text('!',
                                style: SDTypography.labelSmall.copyWith(
                                    color: SDColors.white)),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: SDSpacing.xxs),
                // 🛒 Chip Panier avec badge connecté au BLoC
                BlocBuilder<ShoppingPageBlocM, bloc_model.ShoppingPageStateM>(
                  builder: (context, state) {
                    final cartCount = state.cart?.totalItems ?? 0;
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BlocProvider.value(
                                      value: context.read<ShoppingPageBlocM>(),
                                      child: const PanierProductScreenM(),
                                    )));
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SDSpacing.sm, vertical: SDSpacing.xxxs),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              SDColors.primary600.withOpacity(0.1),
                              SDColors.primary600.withOpacity(0.15)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: SDColors.primary600.withOpacity(0.4), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: SDColors.primary600.withOpacity(0.15),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              children: [
                                Icon(Icons.shopping_cart,
                                    color: SDColors.primary600, size: 16),
                                if (cartCount > 0)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: EdgeInsets.all(SDSpacing.xxxs),
                                      constraints: BoxConstraints(
                                        minWidth: 12,
                                        minHeight: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SDColors.error500,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          cartCount > 9
                                              ? '9+'
                                              : cartCount.toString(),
                                          style: SDTypography.labelSmall.copyWith(
                                            color: SDColors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(width: SDSpacing.xxxs),
                            Text(
                              '🛒 Panier',
                              style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.primary600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                  ],
                ),
              );
            },
          ),
      ),
    );
  }

  // ✅ PREMIUM : Pills animées pour la navigation
  Widget _buildNavigationChip(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 - (value * 0.02), // Micro scale effect
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(25),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: SDSpacing.md, vertical: SDSpacing.xs),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          SDColors.primary500,
                          SDColors.primary600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          SDColors.neutral50,
                          SDColors.neutral100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? SDColors.primary300
                      : SDColors.neutral300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? SDColors.primary600 : SDColors.neutral500)
                        .withOpacity(isSelected ? 0.3 : 0.1),
                    blurRadius: isSelected ? 8 : 4,
                    offset: Offset(0, isSelected ? 4 : 2),
                    spreadRadius: isSelected ? 1 : 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()
                      ..scale(isSelected ? 1.1 : 1.0),
                    child: Icon(
                      icon,
                      color: isSelected ? SDColors.white : SDColors.neutral700,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: SDSpacing.xxs),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: SDTypography.bodyMedium.copyWith(
                      color: isSelected ? SDColors.white : SDColors.neutral800,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: isSelected ? 0.5 : 0,
                    ),
                    child: Text(label),
                  ),
                  if (isSelected) ...[
                    SizedBox(width: SDSpacing.xxxs),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 1.0 : 0.0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ NOUVEAU : Widget pour afficher la grille des vendeurs
  Widget _buildVendeursGrid(BuildContext context, List<Vendeur> vendeurs) {
    if (vendeurs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 64, color: SDColors.neutral400),
            SizedBox(height: SDSpacing.sm),
            Text(
              'Aucun vendeur trouvé',
              style: SDTypography.titleMedium.copyWith(color: SDColors.neutral500),
            ),
            SizedBox(height: SDSpacing.xxs),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vendeurs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1, // Une carte vendeur par ligne (plus d'infos)
        mainAxisSpacing: 12,
        crossAxisSpacing: 16,
        childAspectRatio: 3.5, // Cartes plus larges et moins hautes
      ),
      itemBuilder: (context, index) {
        final vendeur = vendeurs[index];
        return _buildVendeurCard(context, vendeur);
      },
    );
  }

  // ✅ NOUVEAU : Widget pour une carte vendeur
  Widget _buildVendeurCard(BuildContext context, Vendeur vendeur) {
    final bool isFavorite =
        false; // TODO: Implémenter avec state.favoriteVendeurIds

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          print('Vendeur sélectionné: ${vendeur.shopName}');
          print('Vendeur ID: ${vendeur.id}');
          print('Vendeur object: $vendeur');
          // ✅ Navigation vers la page détail vendeur (mobile router)
          try {
            context.push('/vendeurDetails', extra: vendeur);
          } catch (e) {
            print('Erreur lors de la navigation: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Erreur: Impossible d\'ouvrir la page détail')),
            );
          }
        },
        child: Padding(
          padding: SDSpacing.cardPadding,
          child: Row(
            children: [
              // Logo/Avatar du vendeur
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                  color: SDColors.neutral100,
                ),
                child: _buildVendeurAvatar(vendeur),
              ),
              SizedBox(width: SDSpacing.sm),

              // Informations du vendeur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Nom de la boutique
                    _buildSafeText(
                      vendeur.shopName,
                      style: SDTypography.titleSmall.copyWith(
                        color: SDColors.neutral900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SDSpacing.xxxs),

                    // Propriétaire
                    if (vendeur.utilisateur != null)
                      _buildSafeText(
                        'Par ${vendeur.utilisateur!.fullName}',
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: SDSpacing.xxxs),

                    // Rating et badges
                    Row(
                      children: [
                        Icon(Icons.star, color: SDColors.warning500, size: 16),
                        SizedBox(width: SDSpacing.xxxs),
                        Text(
                          vendeur.rating.toStringAsFixed(1),
                          style: SDTypography.bodyMedium.copyWith(
                              color: SDColors.warning500),
                        ),
                        SizedBox(width: SDSpacing.xxs),
                        _buildSafeText(
                          '${vendeur.completedOrders} ventes',
                          style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral600),
                        ),
                        SizedBox(width: SDSpacing.xxs),

                        // Badges
                        if (vendeur.isTopRated)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: SDSpacing.xxxs, vertical: SDSpacing.xxxs),
                            decoration: BoxDecoration(
                              color: SDColors.warning100,
                              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                            ),
                            child: Text(
                              '👑',
                              style: SDTypography.labelSmall,
                            ),
                          ),
                        if (vendeur.isFeatured)
                          Container(
                            margin: EdgeInsets.only(left: SDSpacing.xxxs),
                            padding: EdgeInsets.symmetric(
                                horizontal: SDSpacing.xxxs, vertical: SDSpacing.xxxs),
                            decoration: BoxDecoration(
                              color: SDColors.info100,
                              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                            ),
                            child: Text(
                              '⭐',
                              style: SDTypography.labelSmall,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: SDSpacing.xxxs),

                    // Localisation et livraison
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: SDColors.neutral500),
                        SizedBox(width: SDSpacing.xxxs),
                        Expanded(
                          child: _buildSafeText(
                            vendeur.businessAddress?.city ??
                                (vendeur.deliveryZones.isNotEmpty
                                    ? vendeur.deliveryZones.first
                                    : 'Non spécifié'),
                            style: SDTypography.bodySmall.copyWith(
                                color: SDColors.neutral600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (vendeur.shippingMethods.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(left: SDSpacing.xxs),
                            padding: EdgeInsets.symmetric(
                                horizontal: SDSpacing.xxxs, vertical: SDSpacing.xxxs),
                            decoration: BoxDecoration(
                              color: SDColors.success50,
                              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                              border: Border.all(color: SDColors.success200),
                            ),
                            child: _buildSafeText(
                              '🚚 ${vendeur.shippingMethods.first}',
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.success700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions (favoris, etc.)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      context.read<ShoppingPageBlocM>().add(
                            ToggleVendeurFavoriteEvent(vendeurId: vendeur.id),
                          );
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? SDColors.error500 : SDColors.neutral400,
                      size: 20,
                    ),
                  ),

                  // Indicateur de statut
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: SDSpacing.xxxs, vertical: SDSpacing.xxxs),
                    decoration: BoxDecoration(
                      color: vendeur.accountStatus == 'Active'
                          ? SDColors.success50
                          : SDColors.warning50,
                      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                    ),
                    child: _buildSafeText(
                      vendeur.accountStatus == 'Active'
                          ? 'Actif'
                          : 'En attente',
                      style: SDTypography.labelSmall.copyWith(
                        color: vendeur.accountStatus == 'Active'
                            ? SDColors.success700
                            : SDColors.warning700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NOUVEAU : Widget sécurisé pour avatar vendeur
  Widget _buildVendeurAvatar(Vendeur vendeur) {
    try {
      if (vendeur.shopLogo != null && vendeur.shopLogo!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AppImage(
            imageUrl: vendeur.shopLogo!,
            fit: BoxFit.cover,
          ),
        );
      } else {
        return Icon(Icons.storefront, color: Colors.grey.shade400, size: 30);
      }
    } catch (e) {
      print('Erreur construction avatar vendeur: $e');
      return Icon(Icons.error_outline, color: Colors.red.shade400, size: 30);
    }
  }

  // ✅ NOUVEAU : Texte sécurisé pour éviter les crashes Unicode
  Widget _buildSafeText(
    String text, {
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    try {
      // Nettoyer le texte des caractères problématiques
      String cleanText = text
          .replaceAll('�', '')
          .replaceAll('Ã´', 'ô')
          .replaceAll('Ã©', 'é')
          .replaceAll('Ã¨', 'è')
          .replaceAll('Ã ', 'à')
          .replaceAll('Ã»', 'û')
          .replaceAll('Ã§', 'ç')
          .trim();

      if (cleanText.isEmpty) {
        cleanText = 'Non spécifié';
      }

      return Text(
        cleanText,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    } catch (e) {
      print('Erreur affichage texte: $e');
      return Text(
        'Erreur affichage',
        style:
            style?.copyWith(color: Colors.red) ?? TextStyle(color: Colors.red),
        maxLines: maxLines,
        overflow: overflow,
      );
    }
  }
}

// ✅ NOUVEAU : Delegate pour banner sticky
class _PromoStickyDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _PromoStickyDelegate({required this.child});

  @override
  double get minExtent => 45.0;

  @override
  double get maxExtent => 45.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_PromoStickyDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}


