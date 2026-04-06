import 'package:flutter/material.dart';
import 'package:sdealsmobile/mobile/view/common/utils/app_snackbar.dart';
import '../../common/widgets/empty_state_widget.dart';
import '../../common/widgets/app_image.dart';
import '../shoppingpageblocm/shoppingPageStateM.dart' as bloc_model;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import '../shoppingpageblocm/shoppingPageBlocM.dart';
import '../shoppingpageblocm/shoppingPageEventM.dart';
import 'panierProductScreenM.dart';
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
                  SizedBox(height: SDSpacing.md),

                  // Boutons d'action
                  _buildActionButtons(context),
                  SizedBox(height: SDSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300.0,
      floating: false,
      pinned: true,
      backgroundColor: SDColors.primary600,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.product.name,
          style: SDTypography.titleMedium.copyWith(
            color: SDColors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 2, color: SDColors.neutral900.withOpacity(0.54))],
          ),
        ),
        background: _buildProductImage(),
      ),
      actions: [
        // Bouton favoris
        BlocBuilder<ShoppingPageBlocM, bloc_model.ShoppingPageStateM>(
          builder: (context, state) {
            final isFavorite =
                state.favoriteProductIds?.contains(widget.product.id) ?? false;
            return IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? SDColors.error500 : SDColors.white,
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
          icon: Icon(Icons.share, color: SDColors.white),
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
            SDColors.primary600,
            SDColors.primary800,
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
              style: SDTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
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
                  widget.product.price,
                  style: SDTypography.displaySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: SDColors.success500,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: SDSpacing.xs, vertical: SDSpacing.xxxs),
                  decoration: BoxDecoration(
                    color: SDColors.success100,
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                    border: Border.all(color: SDColors.success200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: SDColors.success700),
                      SizedBox(width: SDSpacing.xxxs),
                      Text(
                        'Disponible',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.success700,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.sm),
        child: Row(
          children: [
            ...List.generate(
              5,
              (index) => Icon(
                index < widget.product.rating.floor()
                    ? Icons.star
                    : Icons.star_border,
                color: SDColors.warning500,
                size: 24,
              ),
            ),
            SizedBox(width: SDSpacing.xs),
            Text(
              '${widget.product.rating.toStringAsFixed(1)} / 5.0',
              style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
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
              'Article de qualité ${widget.product.brand}. ${widget.product.size}.',
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Bouton principal : Ajouter au panier
        SizedBox(
          width: double.infinity,
          child: BlocBuilder<ShoppingPageBlocM, bloc_model.ShoppingPageStateM>(
            builder: (context, state) {
              final isAdding = state.isAddingToCart;
              return ElevatedButton.icon(
                onPressed: isAdding
                    ? null
                    : () {
                        final authState = context.read<AuthCubit>().state;
                        if (authState is AuthAuthenticated) {
                          final vendeurId = widget.product.vendeurId ?? 'unknown';

                          context.read<ShoppingPageBlocM>().add(
                                AddToCartEvent(
                                  userId: authState.utilisateur.idutilisateur,
                                  articleId: widget.product.id,
                                  vendeurId: vendeurId,
                                  quantite: _quantity,
                                ),
                              );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: SDColors.white),
                                  SizedBox(width: SDSpacing.xs),
                                  Expanded(
                                    child: Text(
                                        '${widget.product.name} ajouté au panier!',
                                        style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
                                  ),
                                ],
                              ),
                              backgroundColor: SDColors.success500,
                              duration: Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'Voir',
                                textColor: SDColors.white,
                                onPressed: () {
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
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Veuillez vous connecter pour ajouter au panier',
                                  style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
                              backgroundColor: SDColors.warning500,
                            ),
                          );
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
                  isAdding ? 'Ajout en cours...' : 'Ajouter au panier',
                  style: SDTypography.labelMedium.copyWith(color: SDColors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SDColors.success500,
                  foregroundColor: SDColors.white,
                  padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: SDSpacing.xs),
        // Bouton secondaire : Acheter maintenant
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Implémenter l'achat direct
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Fonctionnalité achat direct à venir',
                        style: SDTypography.bodyMedium)),
              );
            },
            icon: Icon(Icons.flash_on, color: SDColors.success500),
            label: Text(
              'Acheter maintenant',
              style: SDTypography.labelMedium.copyWith(color: SDColors.success500),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: SDColors.success500,
              side: BorderSide(color: SDColors.success500, width: 2),
              padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
