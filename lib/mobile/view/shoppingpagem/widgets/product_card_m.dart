import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../shoppingpageblocm/shoppingPageBlocM.dart';
import '../shoppingpageblocm/shoppingPageStateM.dart' as bloc_model;
import '../screens/productDetailsScreenM.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import '../shoppingpageblocm/shoppingPageEventM.dart';
import '../utils/cart_navigation.dart';
import '../../common/widgets/app_image.dart';
import '../../../../design_system/colors.dart';
import '../../../../design_system/typography.dart';
import '../../../../design_system/spacing.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';

class ProductCardM extends StatelessWidget {
  final bloc_model.Product product;

  const ProductCardM({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShoppingPageBlocM, bloc_model.ShoppingPageStateM>(
      builder: (context, state) {
        final bool isFavorite =
            state.favoriteProductIds?.contains(product.id) ?? false;
        final priceLabel = formatOptionalPrice(product.price) ?? product.price;
        final ratingLabel = formatOptionalRating(product.rating);
        final showBrand = product.brand.isNotEmpty &&
            product.brand.toUpperCase() != 'NON SPÉCIFIÉ';

        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<ShoppingPageBlocM>(),
              child: ProductDetails(product: product),
            ),
          )),
          child: Container(
            decoration: BoxDecoration(
              color: SDColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: SDColors.overlayLight,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image + Badge Promo + Favoris
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      // Image Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: SDColors.neutral50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Hero(
                          tag: 'product_image_${product.id}',
                          child: product.image.startsWith('http')
                              ? AppImage(
                                  imageUrl: product.image,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.contain,
                                  placeholderAsset: 'assets/products/default.png',
                                )
                              : Image.asset(
                                  product.image.isNotEmpty
                                      ? product.image
                                      : 'assets/products/default.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image_not_supported),
                                ),
                        ),
                      ),

                    // Badge de la marque (seulement si disponible et valide)
                    if (showBrand)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 100),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            color: SDColors.primary600,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            product.brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 5,
                        right: 5,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              // TODO: Implémenter ToggleFavoriteEvent
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0), // Zone tactile agrandie
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite
                                    ? SDColors.error500
                                    : SDColors.neutral400,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // ✅ BOUTON ADD TO CART FLOTTANT
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () {
                            final authState = context.read<AuthCubit>().state;

                            if (authState is AuthAuthenticated) {
                              final vendeurId = product.vendeurId;
                              if (!isLikelyMongoObjectId(vendeurId)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Produit incomplet : vendeur manquant.',
                                      style: TextStyle(color: SDColors.white),
                                    ),
                                    backgroundColor: SDColors.warning500,
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
                                      'Connectez-vous pour ajouter au panier',
                                      style:
                                          TextStyle(color: SDColors.white)),
                                  backgroundColor: SDColors.warning500,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: SDColors.primary500,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: SDColors.primary500.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              color: SDColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Infos Produit
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showBrand)
                              Text(
                                product.brand.toUpperCase(),
                                style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.neutral500,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (showBrand) const SizedBox(height: 4),
                            // Nom
                            Text(
                              product.name,
                              style: SDTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        // Prix et Rating
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                priceLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SDTypography.titleMedium.copyWith(
                                  color: SDColors.primary600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (ratingLabel != null) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: SDColors.warning100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star,
                                        size: 10, color: SDColors.warning500),
                                    const SizedBox(width: 2),
                                    Text(
                                      ratingLabel,
                                      style: SDTypography.labelSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: SDColors.warning500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
