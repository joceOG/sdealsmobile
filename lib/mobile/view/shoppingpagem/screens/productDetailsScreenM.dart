import 'package:flutter/material.dart';
import 'package:sdealsmobile/mobile/view/common/utils/app_snackbar.dart';
import '../../common/widgets/empty_state_widget.dart';
import '../../common/widgets/app_image.dart';
import '../shoppingpageblocm/shoppingPageStateM.dart' as bloc_model;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import '../shoppingpageblocm/shoppingPageBlocM.dart';
import '../shoppingpageblocm/shoppingPageEventM.dart';
import '../utils/cart_navigation.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';

// Type alias pour simplifier l'import
typedef Product = bloc_model.Product;

class ProductDetails extends StatefulWidget {
  final Product product;

  const ProductDetails({super.key, required this.product});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  int _quantity = 1;
  String? _selectedVariation;

  /// Formate un prix brut en "3 000 FCFA" avec espace fine insécable.
  /// Accepte "3000", "3000 FCFA", "3 000 FCFA" — normalise toujours.
  String _formatPrice(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return raw;
    final value = int.tryParse(digits);
    if (value == null) return raw;
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m.group(1)}\u202F',
    );
    return '$formatted FCFA';
  }

  /// Compose la description du produit sans double point ni ligne vide.
  String _buildDescription() {
    final parts = <String>[];
    if (widget.product.brand.isNotEmpty) {
      parts.add('Article de qualité ${widget.product.brand}');
    }
    if (widget.product.size.isNotEmpty) {
      parts.add(widget.product.size);
    }
    if (parts.isEmpty) return 'Aucune description disponible.';
    return '${parts.join('. ')}.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      body: CustomScrollView(
        slivers: [
          // Header avec image du produit
          _buildHeroHeader(context),

          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(SDSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations principales du produit
                  _buildProductInfo(),
                  SizedBox(height: SDSpacing.sm),

                  // Prix et disponibilité
                  _buildPricingSection(),
                  SizedBox(height: SDSpacing.sm),

                  // Évaluation
                  _buildRatingSection(),
                  SizedBox(height: SDSpacing.sm),

                  // Sélecteur de quantité
                  _buildQuantitySelector(),
                  SizedBox(height: SDSpacing.sm),

                  // Description (si disponible)
                  _buildDescriptionSection(),
                  SizedBox(height: SDSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
      // Barre CTA fixe safe-bottom (comme provider_profile_screen)
      bottomNavigationBar: _buildBottomCtaBar(context),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300.0,
      floating: false,
      pinned: true,
      // En expanded : icônes en blanc (sur fond image sombre).
      // En collapsed : AppBar blanche → foregroundColor neutral900.
      backgroundColor: SDColors.white,
      foregroundColor: SDColors.neutral900,
      iconTheme: const IconThemeData(color: SDColors.neutral900),
      actionsIconTheme: const IconThemeData(color: SDColors.neutral900),
      // Le titre n'est placé que dans FlexibleSpaceBar pour bénéficier de
      // l'animation de collapse. La couleur neutral900 + ombre blanche
      // garantit la lisibilité sur l'image (expanded) ET sur fond blanc (collapsed).
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Text(
          widget.product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SDTypography.titleSmall.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(blurRadius: 8, color: Colors.white, offset: Offset(0, 0)),
              Shadow(blurRadius: 14, color: Colors.white, offset: Offset(0, 0)),
            ],
          ),
        ),
        background: _buildProductImage(),
        collapseMode: CollapseMode.parallax,
      ),
      actions: [
        // Bouton favoris
        BlocBuilder<ShoppingPageBlocM, bloc_model.ShoppingPageStateM>(
          builder: (context, state) {
            final isFavorite =
                state.favoriteProductIds?.contains(widget.product.id) ?? false;
            return IconButton(
              style: SDAppBarIconStyles.onLightSurface,
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? SDColors.error500 : SDColors.neutral900,
              ),
              onPressed: () {
                context
                    .read<ShoppingPageBlocM>()
                    .add(ToggleFavoriteEvent(widget.product.id));
                if (isFavorite) {
                  AppSnackBar.info(context, '${widget.product.name} retiré des favoris!');
                } else {
                  AppSnackBar.success(context, '${widget.product.name} ajouté aux favoris!');
                }
              },
            );
          },
        ),
        // Bouton partage
        IconButton(
          style: SDAppBarIconStyles.onLightSurface,
          icon: Icon(Icons.share, color: SDColors.neutral900),
          onPressed: () {
            // TODO: Implémenter le partage
            AppSnackBar.info(context, 'Fonctionnalité de partage à venir');
          },
        ),
      ],
    );
  }

  Widget _buildProductImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SDColors.neutral700,
            SDColors.neutral900,
          ],
        ),
      ),
      child: widget.product.image.startsWith('http') ||
              widget.product.image.startsWith('https')
          ? Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  imageUrl: widget.product.image,
                  fit: BoxFit.cover,
                  placeholderAsset: 'assets/products/default.png',
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        SDColors.neutral900.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  widget.product.image.isNotEmpty
                      ? widget.product.image
                      : 'assets/products/default.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultImage();
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        SDColors.neutral900.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      color: SDColors.neutral200,
      child: Center(
        child: Icon(
          Icons.shopping_bag,
          size: 100,
          color: SDColors.neutral400,
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.name,
              style: SDTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: SDColors.neutral900,
              ),
            ),
            SizedBox(height: SDSpacing.xs),
            Row(
              children: [
                Text(
                  'Marque: ',
                  style: SDTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.product.brand,
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.info600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: SDSpacing.xxxs),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: SDColors.neutral600),
                SizedBox(width: SDSpacing.xxxs),
                Text(
                  widget.product.size,
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatPrice(widget.product.price),
                  style: SDTypography.displaySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: SDColors.primary700,
                    fontSize: 22,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: SDSpacing.xs, vertical: SDSpacing.xxxs),
                  decoration: BoxDecoration(
                    color: SDColors.primary50,
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                    border: Border.all(color: SDColors.primary200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: SDColors.primary700),
                      SizedBox(width: SDSpacing.xxxs),
                      Text(
                        'Disponible',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: SDSpacing.xs),
            Row(
              children: [
                Icon(Icons.local_shipping, size: 16, color: SDColors.neutral600),
                SizedBox(width: SDSpacing.xxxs),
                Text(
                  'Livraison disponible',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    final rating = widget.product.rating;
    final hasRating = rating > 0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.sm),
        child: hasRating
            ? Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < rating.floor()
                          ? Icons.star
                          : Icons.star_border,
                      color: SDColors.warning500,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: SDSpacing.xs),
                  Text(
                    '${rating.toStringAsFixed(1)} / 5',
                    style: SDTypography.titleSmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                children: [
                  const Icon(Icons.star_border_rounded,
                      color: SDColors.neutral400, size: 20),
                  SizedBox(width: SDSpacing.xs),
                  Text(
                    'Pas encore noté',
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quantité',
              style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: SDColors.neutral300),
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, color: SDColors.neutral900),
                    onPressed: _quantity > 1
                        ? () {
                            setState(() {
                              _quantity--;
                            });
                          }
                        : null,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm),
                    child: Text(
                      '$_quantity',
                      style: SDTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: SDColors.neutral900),
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: SDTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SDSpacing.xs),
            Text(
              _buildDescription(),
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Remplace le toast orange par un auth gate propre (bottom sheet).
  void _showGuestCartGate(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SDColors.neutral200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: SDColors.primary50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: SDColors.primary600,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Connectez-vous pour continuer',
              textAlign: TextAlign.center,
              style: SDTypography.titleLarge.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous devez être connecté pour ajouter un article à votre panier.',
              textAlign: TextAlign.center,
              style: SDTypography.bodyMedium
                  .copyWith(color: SDColors.neutral600, height: 1.5),
            ),
            const SizedBox(height: 28),
            SDButton(
              text: 'Se connecter',
              fullWidth: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamed('/login');
              },
            ),
            const SizedBox(height: 12),
            SDButton(
              text: 'Créer un compte',
              type: SDButtonType.outlined,
              fullWidth: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamed('/register');
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                  foregroundColor: SDColors.neutral600),
              child: Text(
                'Annuler',
                style: SDTypography.labelLarge
                    .copyWith(color: SDColors.neutral600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barre CTA fixe — même architecture safe-bottom que provider_profile_screen.
  Widget _buildBottomCtaBar(BuildContext context) {
    return Builder(
      builder: (context) {
        final double sysBottom = SDResponsive.systemBottomInset(context);
        return Container(
          padding: EdgeInsets.fromLTRB(
            SDSpacing.sm,
            SDSpacing.sm,
            SDSpacing.sm,
            SDSpacing.sm + sysBottom,
          ),
          decoration: BoxDecoration(
            color: SDColors.white,
            boxShadow: [
              BoxShadow(
                color: SDColors.neutral900.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Bouton secondaire : Acheter maintenant
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter l'achat direct
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Fonctionnalité achat direct à venir',
                              style: SDTypography.bodyMedium)),
                    );
                  },
                  icon: Icon(Icons.flash_on, color: SDColors.primary700),
                  label: Text(
                    'Acheter',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelMedium.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SDColors.primary700,
                    side: BorderSide(color: SDColors.primary700, width: 1.5),
                    minimumSize: const Size(0, 48),
                    padding: EdgeInsets.symmetric(
                      horizontal: SDSpacing.xs,
                      vertical: SDSpacing.xs,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              SizedBox(width: SDSpacing.sm),
              // Bouton principal : Ajouter au panier
              Expanded(
                flex: 2,
                child: _buildAddToCartButton(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return BlocConsumer<ShoppingPageBlocM, bloc_model.ShoppingPageStateM>(
            listenWhen: (prev, curr) =>
                prev.isAddingToCart &&
                !curr.isAddingToCart &&
                (curr.cartError != prev.cartError ||
                    curr.cart != prev.cart),
            listener: (context, state) {
              if ((state.cartError ?? '').isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.cartError!),
                    backgroundColor: SDColors.error500,
                  ),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: SDColors.white),
                      SizedBox(width: SDSpacing.xs),
                      Expanded(
                        child: Text(
                          '${widget.product.name} ajouté au panier!',
                          style: SDTypography.bodyMedium
                              .copyWith(color: SDColors.white),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: SDColors.primary700,
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'Voir',
                    textColor: SDColors.white,
                    onPressed: () => openShoppingCart(context),
                  ),
                ),
              );
            },
            builder: (context, state) {
              final isAdding = state.isAddingToCart;
              return ElevatedButton.icon(
                onPressed: isAdding
                    ? null
                    : () {
                        final authState = context.read<AuthCubit>().state;
                        if (authState is AuthAuthenticated) {
                          final vendeurId = widget.product.vendeurId;
                          if (!isLikelyMongoObjectId(vendeurId)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Produit incomplet : vendeur manquant. Impossible d\'ajouter au panier.',
                                ),
                                backgroundColor: SDColors.warning500,
                              ),
                            );
                            return;
                          }

                          context.read<ShoppingPageBlocM>().add(
                                AddToCartEvent(
                                  userId:
                                      authState.utilisateur.idutilisateur,
                                  articleId: widget.product.id,
                                  vendeurId: vendeurId!,
                                  quantite: _quantity,
                                ),
                              );
                        } else {
                          _showGuestCartGate(context);
                        }
                      },
                icon: isAdding
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(SDColors.white),
                        ),
                      )
                    : Icon(Icons.shopping_cart, color: SDColors.white),
                label: Text(
                  isAdding ? 'Ajout...' : 'Ajouter au panier',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SDColors.primary700,
                  foregroundColor: SDColors.white,
                  minimumSize: const Size(0, 48),
                  padding: EdgeInsets.symmetric(
                    horizontal: SDSpacing.xs,
                    vertical: SDSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            },
          );
  }
}
