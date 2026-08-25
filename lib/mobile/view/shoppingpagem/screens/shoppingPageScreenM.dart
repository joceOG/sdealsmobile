import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import '../shoppingpageblocm/shoppingPageBlocM.dart';
import '../shoppingpageblocm/shoppingPageEventM.dart';
import '../shoppingpageblocm/shoppingPageStateM.dart' as bloc_model;
import 'productDetailsScreenM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';
import 'panierProductScreenM.dart';
import 'package:sdealsmobile/data/models/vendeur.dart';
import '../utils/cart_navigation.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../../common/widgets/app_image.dart';
import '../../common/widgets/skeleton_loader.dart';

// Design System
import '../../../../design_system/colors.dart';
import '../../../../design_system/typography.dart';
import '../../../../design_system/spacing.dart';
import '../../../../design_system/widgets/sd_app_bar_icon_button.dart';
import '../../../../design_system/widgets/sd_feedback_states.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';

// Utilisation du modèle Product du BLoC
typedef Product = bloc_model.Product;

/// Aperçu catégories sur le hub (comme Freelance).
const int _kShopCategoryPreviewCount = 8;

/// Icônes É-marché — mapping strict (spécifique → générique). Sans image réseau.
IconData _shopCategoryIcon(String rawName) {
  final name = rawName
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('à', 'a')
      .replaceAll('ù', 'u')
      .replaceAll('ô', 'o')
      .replaceAll('î', 'i')
      .replaceAll('ç', 'c');

  if (name.contains('telephone') ||
      name.contains('smartphone') ||
      name.contains('phone')) {
    return Icons.smartphone_outlined;
  }
  if (name.contains('ordinateur') ||
      name.contains('laptop') ||
      name.contains('informatique')) {
    return Icons.laptop_mac_outlined;
  }
  if (name.contains('tv') ||
      name.contains('television') ||
      name.contains('ecran') ||
      name.contains('electronique') ||
      name.contains('high-tech') ||
      name.contains('hightech') ||
      name.contains('tech')) {
    return Icons.devices_other_outlined;
  }
  if (name.contains('beaute') ||
      name.contains('cosmetique') ||
      name.contains('maquillage') ||
      name.contains('parfum')) {
    return Icons.spa_outlined;
  }
  if (name.contains('sante') ||
      name.contains('pharmacie') ||
      name.contains('medic')) {
    return Icons.medical_services_outlined;
  }
  if (name.contains('chaussure') || name.contains('sneaker')) {
    return Icons.checkroom_outlined;
  }
  if (name.contains('mode') ||
      name.contains('vetement') ||
      name.contains('fashion') ||
      name.contains('habillement') ||
      name.contains('accessoire')) {
    return Icons.checkroom_outlined;
  }
  if (name.contains('bijou') || name.contains('montre')) {
    return Icons.watch_outlined;
  }
  if (name.contains('bebe') ||
      name.contains('enfant') ||
      name.contains('jouet') ||
      name.contains('puericulture')) {
    return Icons.child_care_outlined;
  }
  if (name.contains('sport') ||
      name.contains('fitness') ||
      name.contains('gym')) {
    return Icons.fitness_center_outlined;
  }
  if (name.contains('jeu') ||
      name.contains('gaming') ||
      name.contains('console')) {
    return Icons.sports_esports_outlined;
  }
  if (name.contains('livre') ||
      name.contains('papeterie') ||
      name.contains('education')) {
    return Icons.menu_book_outlined;
  }
  if (name.contains('aliment') ||
      name.contains('epicerie') ||
      name.contains('boisson') ||
      name.contains('food') ||
      name.contains('agro')) {
    return Icons.restaurant_outlined;
  }
  if (name.contains('electromenager')) {
    return Icons.kitchen_outlined;
  }
  if (name.contains('maison') ||
      name.contains('cuisine') ||
      name.contains('deco') ||
      name.contains('meuble') ||
      name.contains('jardin')) {
    return Icons.chair_outlined;
  }
  if (name.contains('immobilier') ||
      name.contains('appartement') ||
      name.contains('terrain')) {
    return Icons.home_work_outlined;
  }
  if (name.contains('auto') ||
      name.contains('moto') ||
      name.contains('vehicule') ||
      name.contains('voiture')) {
    return Icons.directions_car_outlined;
  }
  if (name.contains('bricolage') ||
      name.contains('outil') ||
      name.contains('quincaillerie')) {
    return Icons.handyman_outlined;
  }
  if (name.contains('animal') || name.contains('animau') || name.contains('pet')) {
    return Icons.pets_outlined;
  }
  if (name.contains('voyage') || name.contains('bagage') || name.contains('valise')) {
    return Icons.luggage_outlined;
  }
  if (name.contains('bureau') || name.contains('entreprise')) {
    return Icons.business_center_outlined;
  }
  return Icons.shopping_bag_outlined;
}

/// Prix hub : "3 000 FCFA" (espace fine).
String _formatShopPrice(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return raw.trim().isEmpty ? 'Prix non renseigné' : raw;
  final value = int.tryParse(digits);
  if (value == null || value <= 0) return 'Prix non renseigné';
  final formatted = value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m.group(1)}\u202F',
  );
  return '$formatted FCFA';
}

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ShoppingPageBlocM>().add(LoadCategorieDataM());
      context.read<ShoppingPageBlocM>().add(LoadProductsEvent());
      context.read<ShoppingPageBlocM>().add(LoadVendeursEvent());

      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        context.read<ShoppingPageBlocM>().add(
              LoadCartEvent(userId: authState.utilisateur.idutilisateur),
            );
      }
    });
  }

  List<Product> _displayProducts(bloc_model.ShoppingPageStateM state) {
    return state.filteredProducts ?? state.products ?? [];
  }

  void _openSearchShop(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SearchPageScreenM(initialIndex: 4),
      ),
    );
  }

  /// Même gabarit que Freelance / Métiers (`_buildSectionHeaderRow`).
  Widget _buildSectionHeaderRow({
    required IconData leadingIcon,
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
    int titleMaxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(leadingIcon, color: SDColors.primary600, size: 22),
        SizedBox(width: SDSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: SDTypography.titleMedium.copyWith(
              color: SDColors.neutral900,
            ),
            maxLines: titleMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.arrow_forward, size: 14),
          label: Text(actionLabel, style: SDTypography.labelSmall),
          style: TextButton.styleFrom(
            foregroundColor: SDColors.primary600,
            padding: SDSpacing.chipPadding,
            minimumSize: const Size(0, 32),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitleOnly({
    required IconData leadingIcon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(leadingIcon, color: SDColors.primary600, size: 22),
        SizedBox(width: SDSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: SDTypography.titleMedium.copyWith(
              color: SDColors.neutral900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<Categorie> _categoriesList(bloc_model.ShoppingPageStateM state) {
    final raw = state.listItems;
    if (raw == null) return [];
    return List<Categorie>.from(raw);
  }

  Widget _buildMarketplaceHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'É-marché',
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SDTypography.displayMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        BlocBuilder<ShoppingPageBlocM, bloc_model.ShoppingPageStateM>(
          builder: (context, state) {
            final cartCount = state.cart?.totalItems ?? 0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => openShoppingCart(context),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  color: SDColors.neutral900,
                  tooltip: 'Panier',
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: SDColors.primary600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        cartCount > 99 ? '99+' : '$cartCount',
                        textAlign: TextAlign.center,
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is AuthAuthenticated) {
              final u = authState.utilisateur;
              final url = u.photoProfil;
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: SDColors.primary50,
                  backgroundImage: (url != null &&
                          url.isNotEmpty &&
                          (url.startsWith('http://') ||
                              url.startsWith('https://')))
                      ? NetworkImage(url)
                      : null,
                  child: (url == null ||
                          url.isEmpty ||
                          (!url.startsWith('http://') &&
                              !url.startsWith('https://')))
                      ? Icon(Icons.person, color: SDColors.primary600, size: 20)
                      : null,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        Container(
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: SDColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: SDColors.neutral200),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, color: SDColors.neutral900),
            tooltip: 'Fermer',
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  /// Barre recherche — même style que Métiers / Freelance.
  Widget _buildSearchField(BuildContext context) {
    void openSearch() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SearchPageScreenM(initialIndex: 4),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SDSpacing.sm,
        vertical: SDSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SDColors.primary100, width: 1),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: SDColors.primary600, size: 20),
          SizedBox(width: SDSpacing.xs),
          Expanded(
            child: GestureDetector(
              onTap: openSearch,
              behavior: HitTestBehavior.opaque,
              child: Text(
                'Que recherchez-vous ?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral400,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showAdvancedFilterDialog(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SDColors.primary600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: SDColors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  // STAB-13C : bannière -20% hardcodée retirée (pas de promo certifiée).

  Widget _buildCategoryPreviewGrid(
      BuildContext context, bloc_model.ShoppingPageStateM state) {
    final all = _categoriesList(state);
    final preview = all.take(_kShopCategoryPreviewCount).toList();

    if (state.isLoading == true && preview.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: SDColors.primary600),
        ),
      );
    }
    if (preview.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: SDSpacing.md),
        child: Text(
          'Catégories en cours de chargement…',
          style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.68,
      ),
      itemCount: preview.length,
      itemBuilder: (context, index) {
        final cat = preview[index];
        return _ShopCategoryCell(
          categorie: cat,
          onTap: () {
            context.read<ShoppingPageBlocM>().add(
                  SearchProductsEvent(cat.nomcategorie),
                );
            _openSearchShop(context);
          },
        );
      },
    );
  }

  Widget _buildSeeAllCategoriesButton(
      BuildContext context, bloc_model.ShoppingPageStateM state) {
    final all = _categoriesList(state);
    if (all.length <= _kShopCategoryPreviewCount) {
      return const SizedBox.shrink();
    }
    return OutlinedButton(
      onPressed: () async {
        final selected = await Navigator.of(context).push<Categorie>(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<ShoppingPageBlocM>(),
              child: _ShopAllCategoriesPage(categories: all),
            ),
          ),
        );
        if (!mounted || selected == null) return;
        context.read<ShoppingPageBlocM>().add(
              SearchProductsEvent(selected.nomcategorie),
            );
        _openSearchShop(context);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: SDColors.primary600,
        side: BorderSide(color: SDColors.primary600.withOpacity(0.35)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: SDSpacing.lg,
          vertical: SDSpacing.sm,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Voir toutes les catégories',
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.primary600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward, size: 14, color: SDColors.primary600),
        ],
      ),
    );
  }

  Widget _buildPopularProductsRow(
      BuildContext context, bloc_model.ShoppingPageStateM state) {
    final list = _displayProducts(state).take(10).toList();
    if (state.isLoading == true && list.isEmpty) {
      return SizedBox(
        height: 248,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
          padding: EdgeInsets.zero,
          itemBuilder: (_, __) => SkeletonWidget.rounded(
            width: 148,
            height: 240,
            borderRadius: 16,
          ),
        ),
      );
    }
    if (list.isEmpty) {
      return Text(
        'Aucun produit pour le moment.',
        style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
      );
    }
    return SizedBox(
      height: 268,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
        itemBuilder: (context, i) {
          return _CompactShopProductCard(product: list[i]);
        },
      ),
    );
  }

  /// STAB-13C : Boutiques uniquement si données présentes (pas d’empty géant).
  Widget _buildShopsSection(
      BuildContext context, bloc_model.ShoppingPageStateM state) {
    final shops = state.filteredVendeurs ?? state.vendeurs ?? [];

    if (state.isVendeursLoading && shops.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitleOnly(
            leadingIcon: Icons.storefront_outlined,
            title: 'Boutiques',
          ),
          SizedBox(height: SDSpacing.sm),
          const SDLoadingInline(message: 'Chargement des boutiques…'),
        ],
      );
    }

    // Vide ou erreur sans données → section absente sur la Home.
    if (shops.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitleOnly(
          leadingIcon: Icons.storefront_outlined,
          title: 'Boutiques',
        ),
        SizedBox(height: SDSpacing.sm),
        ...shops.take(4).map((v) => _ShopRecommendTile(vendeur: v)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: BlocBuilder<ShoppingPageBlocM, bloc_model.ShoppingPageStateM>(
          builder: (context, state) {
            if ((state.isLoading == true) &&
                (state.products == null || state.products!.isEmpty) &&
                (state.error == null || state.error!.isEmpty)) {
              return Center(
                child: CircularProgressIndicator(color: SDColors.primary600),
              );
            }
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.error != null && state.error!.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: SDSpacing.cardPadding,
                            decoration: BoxDecoration(
                              color: SDColors.error50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: SDColors.error200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: SDColors.error600),
                                SizedBox(width: SDSpacing.sm),
                                Expanded(
                                  child: Text(
                                    state.error!,
                                    style: SDTypography.bodySmall.copyWith(
                                      color: SDColors.error600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context
                                        .read<ShoppingPageBlocM>()
                                        .add(LoadProductsEvent());
                                  },
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: SDSpacing.md),
                        ],
                        _buildMarketplaceHeader(context),
                        SizedBox(height: SDSpacing.md),
                        _buildSearchField(context),
                        SizedBox(height: SDSpacing.xl),
                        _buildSectionTitleOnly(
                          leadingIcon: Icons.grid_view_rounded,
                          title: 'Catégories',
                        ),
                        SizedBox(height: SDSpacing.sm),
                        _buildCategoryPreviewGrid(context, state),
                        SizedBox(height: SDSpacing.md),
                        Center(
                          child: _buildSeeAllCategoriesButton(context, state),
                        ),
                        SizedBox(height: SDSpacing.xl),
                        _buildSectionHeaderRow(
                          leadingIcon: Icons.local_mall_outlined,
                          title: 'Produits à découvrir',
                          actionLabel: 'Tout voir',
                          onAction: () => _openSearchShop(context),
                        ),
                        SizedBox(height: SDSpacing.sm),
                        _buildPopularProductsRow(context, state),
                        SizedBox(height: SDSpacing.xl),
                        _buildShopsSection(context, state),
                        SizedBox(height: SDSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
    ).then((_) {});
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
                                  final authState =
                                      context.read<AuthCubit>().state;
                                  if (authState is AuthAuthenticated) {
                                    final vendeurId = product.vendeurId;
                                    if (!isLikelyMongoObjectId(vendeurId)) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Produit incomplet : vendeur manquant. Impossible d\'ajouter au panier.',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    context.read<ShoppingPageBlocM>().add(
                                          AddToCartEvent(
                                            userId: authState
                                                .utilisateur.idutilisateur,
                                            articleId: product.id,
                                            vendeurId: vendeurId!,
                                            quantite: 1,
                                          ),
                                        );
                                  } else {
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
      backgroundColor: SDColors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: SDColors.neutral900,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: SDColors.white,
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
                                onTap: () => openShoppingCart(context),
                                child: Container(
                                  padding: EdgeInsets.all(SDSpacing.xxs),
                                  decoration: BoxDecoration(
                                    color: SDColors.neutral100,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: SDColors.neutral200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      Icon(Icons.shopping_cart_outlined,
                                          color: SDColors.neutral900, size: 20),
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
                              color: SDColors.neutral100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: SDColors.neutral200,
                                width: 1,
                              ),
                            ),
                            child: Icon(Icons.notifications_outlined,
                                color: SDColors.neutral900, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: SDSpacing.sm),
                  // Barre de recherche
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: SDColors.neutral50,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: SDColors.neutral200,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      readOnly: true,
                      style: TextStyle(color: SDColors.neutral900),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit...',
                        hintStyle: SDTypography.bodyMedium.copyWith(
                          color: SDColors.neutral500,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: SDColors.neutral500,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.filter_alt_outlined,
                            color: SDColors.neutral700,
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: SDColors.neutral200),
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
              // STAB-10: chip SoutraPay masqué (pas de PSP réel).
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
                        // Badge optionnel (solde SoutraPay — à brancher sur le wallet)
                        if (true)
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
                      onTap: () => openShoppingCart(context),
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

/// Carte produit hub É-marché (STAB-13C) — données réelles uniquement.
class _CompactShopProductCard extends StatelessWidget {
  final Product product;

  const _CompactShopProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    // Note uniquement si > 0 (pas de mapping promo/rating backend dans ce patch ;
    // le BLoC laisse rating à 0 tant que le contrat métier n’est pas certifié).
    final ratingLabel = formatOptionalRating(product.rating);
    final priceLabel = _formatShopPrice(product.price);
    final imageUrl = normalizeMediaUrl(product.image);
    final title = displayOrFallback(product.name, 'Produit');

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<ShoppingPageBlocM>(),
            child: ProductDetails(product: product),
          ),
        ),
      ),
      child: Container(
        width: 152,
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SDColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: SDColors.neutral900.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                decoration: BoxDecoration(
                  color: SDColors.neutral50,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl != null
                    ? AppImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        borderRadius: 12,
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 36,
                          color: SDColors.neutral400,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: SDSpacing.xxxs),
                  Text(
                    priceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelMedium.copyWith(
                      color: SDColors.primary600,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (ratingLabel != null) ...[
                    SizedBox(height: SDSpacing.xxxs),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: SDColors.warning500,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          ratingLabel,
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopRecommendTile extends StatelessWidget {
  final Vendeur vendeur;

  const _ShopRecommendTile({required this.vendeur});

  @override
  Widget build(BuildContext context) {
    final ratingLabel = formatOptionalRating(vendeur.rating);
    final logo = safeImageUrl(vendeur.shopLogo);
    final name = displayOrFallback(vendeur.shopName, 'Boutique');

    return Padding(
      padding: EdgeInsets.only(bottom: SDSpacing.xs),
      child: InkWell(
        onTap: () {
          try {
            context.push('/vendeurDetails', extra: vendeur);
          } catch (_) {}
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 40,
                height: 40,
                child: logo != null
                    ? AppImage(
                        imageUrl: logo,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: SDColors.primary50,
                        child: Icon(Icons.storefront_outlined,
                            color: SDColors.primary600, size: 22),
                      ),
              ),
            ),
            SizedBox(width: SDSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SDColors.neutral900,
                    ),
                  ),
                  if (ratingLabel != null)
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 12, color: SDColors.warning500),
                        Text(
                          ratingLabel,
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.neutral600,
                            fontSize: 10,
                          ),
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
  }
}

class _ShopCategoryCell extends StatelessWidget {
  final Categorie categorie;
  final VoidCallback onTap;

  const _ShopCategoryCell({
    required this.categorie,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // STAB-13C : icônes pro uniquement (pas imagecategorie produit/incohérente).
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final iconH =
              (constraints.maxHeight * 0.52).clamp(34.0, 52.0).toDouble();
          final iconSize = (iconH * 0.55).clamp(20.0, 30.0).toDouble();
          return Column(
            children: [
              Container(
                height: iconH,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: SDColors.primary50.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SDColors.primary100),
                ),
                child: Center(
                  child: Icon(
                    _shopCategoryIcon(categorie.nomcategorie),
                    color: SDColors.primary600,
                    size: iconSize,
                  ),
                ),
              ),
              SizedBox(height: SDSpacing.xxxs),
              Expanded(
                child: Text(
                  categorie.nomcategorie,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.neutral800,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShopAllCategoriesPage extends StatelessWidget {
  final List<Categorie> categories;

  const _ShopAllCategoriesPage({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDAppBarIconThemed(
        style: SDAppBarIconStyles.onLightSurface,
        bar: AppBar(
        elevation: 0,
        backgroundColor: SDColors.white,
        surfaceTintColor: SDColors.white,
        foregroundColor: SDColors.neutral900,
        title: Text(
          'Toutes les catégories',
          style: SDTypography.titleLarge.copyWith(color: SDColors.neutral900),
        ),
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(SDSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _ShopCategoryCell(
            categorie: cat,
            onTap: () => Navigator.of(context).pop<Categorie>(cat),
          );
        },
      ),
    );
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


