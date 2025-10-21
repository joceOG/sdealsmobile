import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../shoppingpageblocm/shoppingPageBlocM.dart';
import '../shoppingpageblocm/shoppingPageEventM.dart';
import '../shoppingpageblocm/shoppingPageStateM.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'confirmationCommandeScreenM.dart';
import 'delivery_address_screen.dart';

class PanierProductScreenM extends StatefulWidget {
  const PanierProductScreenM({super.key});

  @override
  _PanierProductScreenMState createState() => _PanierProductScreenMState();
}

class _PanierProductScreenMState extends State<PanierProductScreenM> {
  @override
  void initState() {
    super.initState();
    // Charger le panier au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        context.read<ShoppingPageBlocM>().add(
              LoadCartEvent(userId: authState.utilisateur.idutilisateur),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Votre panier",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        actions: [
          // Bouton vider le panier
          BlocBuilder<ShoppingPageBlocM, ShoppingPageStateM>(
            builder: (context, state) {
              if (state.cart != null && state.cart!.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Vider le panier'),
                        content: const Text(
                            'Êtes-vous sûr de vouloir vider votre panier ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              final authState = context.read<AuthCubit>().state;
                              if (authState is AuthAuthenticated) {
                                context.read<ShoppingPageBlocM>().add(
                                      ClearCartEvent(
                                          userId: authState
                                              .utilisateur.idutilisateur),
                                    );
                              }
                              Navigator.pop(dialogContext);
                            },
                            child: const Text('Vider',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<ShoppingPageBlocM, ShoppingPageStateM>(
        listener: (context, state) {
          // Afficher les erreurs
          if (state.cartError != null && state.cartError!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.cartError!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          // Afficher le loader
          if (state.isCartLoading && state.cart == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement du panier...'),
                ],
              ),
            );
          }

          // Panier vide
          if (state.cart == null || state.cart!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Votre panier est vide',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez des articles pour commencer',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Continuer mes achats',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final cart = state.cart!;
          final authState = context.read<AuthCubit>().state;
          final userId = (authState is AuthAuthenticated)
              ? authState.utilisateur.idutilisateur
              : '';

          return Column(
            children: [
              // Badge avec nombre d'articles
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.green[50],
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      '${cart.totalItems} article${cart.totalItems > 1 ? 's' : ''} dans votre panier',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des articles
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: cart.articles.length,
                      itemBuilder: (context, index) {
                        final item = cart.articles[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image du produit
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.imageArticle,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Détails du produit
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nomArticle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${item.prixUnitaire.toStringAsFixed(0)} FCFA",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Contrôles de quantité
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    item.quantite > 1
                                                        ? Icons.remove
                                                        : Icons.delete_outline,
                                                    size: 20,
                                                  ),
                                                  color: item.quantite > 1
                                                      ? Colors.orange
                                                      : Colors.red,
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 32,
                                                    minHeight: 32,
                                                  ),
                                                  onPressed: state.isCartLoading
                                                      ? null
                                                      : () {
                                                          if (item.quantite >
                                                              1) {
                                                            context
                                                                .read<
                                                                    ShoppingPageBlocM>()
                                                                .add(
                                                                  UpdateCartItemQuantityEvent(
                                                                    userId:
                                                                        userId,
                                                                    itemId:
                                                                        item.id,
                                                                    quantite:
                                                                        item.quantite -
                                                                            1,
                                                                  ),
                                                                );
                                                          } else {
                                                            // Confirmer la suppression
                                                            showDialog(
                                                              context: context,
                                                              builder:
                                                                  (dialogContext) =>
                                                                      AlertDialog(
                                                                title: const Text(
                                                                    'Retirer l\'article'),
                                                                content: const Text(
                                                                    'Voulez-vous retirer cet article du panier ?'),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                            dialogContext),
                                                                    child: const Text(
                                                                        'Annuler'),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      context
                                                                          .read<
                                                                              ShoppingPageBlocM>()
                                                                          .add(
                                                                            RemoveFromCartEvent(
                                                                              userId: userId,
                                                                              itemId: item.id,
                                                                            ),
                                                                          );
                                                                      Navigator.pop(
                                                                          dialogContext);
                                                                    },
                                                                    child: const Text(
                                                                        'Retirer',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.red)),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }
                                                        },
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12),
                                                  child: Text(
                                                    "${item.quantite}",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add,
                                                      size: 20),
                                                  color: Colors.green,
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 32,
                                                    minHeight: 32,
                                                  ),
                                                  onPressed: state.isCartLoading
                                                      ? null
                                                      : () {
                                                          context
                                                              .read<
                                                                  ShoppingPageBlocM>()
                                                              .add(
                                                                UpdateCartItemQuantityEvent(
                                                                  userId:
                                                                      userId,
                                                                  itemId:
                                                                      item.id,
                                                                  quantite:
                                                                      item.quantite +
                                                                          1,
                                                                ),
                                                              );
                                                        },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            "${item.prixTotal.toStringAsFixed(0)} FCFA",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
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
                      },
                    ),

                    // Overlay de chargement
                    if (state.isCartLoading)
                      Container(
                        color: Colors.black.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),

              // Résumé et bouton commander
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Détails du montant
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Sous-total:",
                          style: TextStyle(fontSize: 15),
                        ),
                        Text(
                          "${cart.montantArticles.toStringAsFixed(0)} FCFA",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Livraison:",
                              style: TextStyle(fontSize: 15),
                            ),
                            if (cart.fraisLivraison == 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "GRATUITE",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          cart.fraisLivraison == 0
                              ? "Gratuite"
                              : "${cart.fraisLivraison.toStringAsFixed(0)} FCFA",
                          style: TextStyle(
                            fontSize: 15,
                            color: cart.fraisLivraison == 0
                                ? Colors.green[700]
                                : Colors.black,
                            fontWeight: cart.fraisLivraison == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),

                    // Code promo si appliqué
                    if (cart.hasPromoCode) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_offer,
                                  size: 16, color: Colors.orange[700]),
                              const SizedBox(width: 4),
                              Text(
                                "Code promo:",
                                style: TextStyle(
                                    fontSize: 15, color: Colors.orange[700]),
                              ),
                            ],
                          ),
                          Text(
                            cart.codePromo!.descriptionReduction,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 24, thickness: 2),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total:",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${cart.montantTotal.toStringAsFixed(0)} FCFA",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 📍 Section Adresse de livraison
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cart.hasDeliveryAddress
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cart.hasDeliveryAddress
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                cart.hasDeliveryAddress
                                    ? Icons.location_on
                                    : Icons.add_location,
                                color: cart.hasDeliveryAddress
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cart.hasDeliveryAddress
                                      ? "Adresse de livraison"
                                      : "Aucune adresse de livraison",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: cart.hasDeliveryAddress
                                        ? Colors.green.shade900
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BlocProvider.value(
                                        value:
                                            context.read<ShoppingPageBlocM>(),
                                        child: DeliveryAddressScreen(
                                          currentAddress: cart.adresseLivraison,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  cart.hasDeliveryAddress
                                      ? "Modifier"
                                      : "Ajouter",
                                  style: TextStyle(
                                    color: cart.hasDeliveryAddress
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (cart.hasDeliveryAddress &&
                              cart.adresseLivraison != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              cart.adresseLivraison!.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${cart.adresseLivraison!.adresse}\n${cart.adresseLivraison!.ville}, ${cart.adresseLivraison!.pays}",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cart.adresseLivraison!.telephone,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            Text(
                              "Veuillez ajouter une adresse pour continuer",
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bouton commander
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        onPressed: cart.canCheckout && !state.isCartLoading
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<ShoppingPageBlocM>(),
                                      child: const ConfirmationCommandeScreen(),
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: state.isCartLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Passer commande",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward,
                                      color: Colors.white),
                                ],
                              ),
                      ),
                    ),

                    // Message si panier non valide
                    if (!cart.canCheckout) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              !cart.hasDeliveryAddress
                                  ? "Ajoutez une adresse de livraison pour continuer"
                                  : cart.isEmpty
                                      ? "Votre panier est vide"
                                      : "Impossible de passer commande",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
