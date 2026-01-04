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
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Header avec image du produit
          _buildHeroHeader(context),

          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations principales du produit
                  _buildProductInfo(),
                  const SizedBox(height: 16),

                  // Prix et disponibilité
                  _buildPricingSection(),
                  const SizedBox(height: 16),

                  // Évaluation
                  _buildRatingSection(),
                  const SizedBox(height: 16),

                  // Sélecteur de quantité
                  _buildQuantitySelector(),
                  const SizedBox(height: 16),

                  // Description (si disponible)
                  _buildDescriptionSection(),
                  const SizedBox(height: 24),

                  // Boutons d'action
                  _buildActionButtons(context),
                  const SizedBox(height: 32),
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
      backgroundColor: Colors.green,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.product.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
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
                color: isFavorite ? Colors.red : Colors.white,
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
          icon: const Icon(Icons.share, color: Colors.white),
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
            Colors.green.shade600,
            Colors.green.shade800,
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
                        Colors.black.withOpacity(0.3),
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
                        Colors.black.withOpacity(0.3),
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
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.shopping_bag,
          size: 100,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Marque: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.product.brand,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  widget.product.size,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.product.price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Disponible',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.local_shipping, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Livraison disponible',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ...List.generate(
              5,
              (index) => Icon(
                index < widget.product.rating.floor()
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.product.rating.toStringAsFixed(1)} / 5.0',
              style: const TextStyle(
                fontSize: 16,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quantité',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _quantity > 1
                        ? () {
                            setState(() {
                              _quantity--;
                            });
                          }
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Article de qualité ${widget.product.brand}. ${widget.product.size}.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
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
                                  const Icon(Icons.check_circle,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                        '${widget.product.name} ajouté au panier!'),
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
                            const SnackBar(
                              content: Text(
                                  'Veuillez vous connecter pour ajouter au panier'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                icon: isAdding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.shopping_cart),
                label: Text(
                  isAdding ? 'Ajout en cours...' : 'Ajouter au panier',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Bouton secondaire : Acheter maintenant
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Implémenter l'achat direct
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Fonctionnalité achat direct à venir')),
              );
            },
            icon: const Icon(Icons.flash_on),
            label: const Text(
              'Acheter maintenant',
              style: TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
