import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/mobile/data/models/commande_model.dart';
import '../../../../data/services/authCubit.dart';
import '../shoppingpageblocm/shoppingPageBlocM.dart';
import '../shoppingpageblocm/shoppingPageEventM.dart';
import '../shoppingpageblocm/shoppingPageStateM.dart';
import 'package:sdealsmobile/mobile/view/common/utils/app_snackbar.dart';
import 'delivery_address_screen.dart';

class ConfirmationCommandeScreen extends StatefulWidget {
  const ConfirmationCommandeScreen({super.key});

  @override
  State<ConfirmationCommandeScreen> createState() =>
      _ConfirmationCommandeScreenState();
}

class _ConfirmationCommandeScreenState
    extends State<ConfirmationCommandeScreen> {
  final TextEditingController _promoController = TextEditingController();
  String _selectedPaymentMethod = 'Cash à la livraison';

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromoCode() {
    if (_promoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un code promo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      // TODO: Pour appliquer un code promo, il faudrait d'abord le valider côté backend
      // Pour l'instant, on applique une réduction fictive de 10%
      context.read<ShoppingPageBlocM>().add(
            ApplyPromoCodeEvent(
              userId: authState.utilisateur.idutilisateur,
              code: _promoController.text.trim(),
              reduction: 10.0, // Exemple: 10% ou 10 FCFA selon le type
              typeReduction: 'POURCENTAGE',
            ),
          );
    }
  }

  void _confirmOrder() {
    final state = context.read<ShoppingPageBlocM>().state;
    final cart = state.cart;

    if (cart == null || cart.isEmpty) {
      AppSnackBar.warning(context, 'Votre panier est vide');
      return;
    }

    if (!cart.hasDeliveryAddress) {
      AppSnackBar.warning(context, 'Veuillez ajouter une adresse de livraison');
      return;
    }

    // TODO: Pour le moment, pas de paiement intégré
    // On va juste valider la commande
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ShoppingPageBlocM>().add(
            CheckoutEvent(
              userId: authState.utilisateur.idutilisateur,
              moyenPaiement: _selectedPaymentMethod,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Passez votre commande",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: BlocConsumer<ShoppingPageBlocM, ShoppingPageStateM>(
        listener: (context, state) {
          if (state.cartError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.cartError!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final cart = state.cart;

          if (state.isCartLoading && cart == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cart == null || cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      size: 100, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Votre panier est vide',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour au shopping'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message d'information
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.grey[200],
                  child: const Text(
                    "Si vous continuez, vous acceptez automatiquement notre",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "Termes et Conditions",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // RÉSUMÉ DE COMMANDE
                Container(
                  padding: const EdgeInsets.all(15),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Résumé de commande",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      rowItem(
                        "Total articles (${cart.totalItems})",
                        "${cart.montantArticles.toStringAsFixed(0)} FCFA",
                      ),
                      rowItem(
                        "Frais de livraison",
                        "${cart.fraisLivraison.toStringAsFixed(0)} FCFA",
                      ),
                      if (cart.codePromo != null &&
                          cart.codePromo!.isValid) ...[
                        rowItem(
                          "Réduction (${cart.codePromo!.code})",
                          cart.codePromo!.descriptionReduction,
                          textColor: Colors.green,
                        ),
                      ],
                      const Divider(),
                      rowItem(
                        "Total",
                        "${cart.montantTotal.toStringAsFixed(0)} FCFA",
                        isBold: true,
                      ),
                      const SizedBox(height: 10),

                      // Champ de code promo
                      if (cart.codePromo == null ||
                          !cart.codePromo!.isValid) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _promoController,
                                decoration: InputDecoration(
                                  hintText: "Entrez votre code ici",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  prefixIcon: const Icon(Icons.card_giftcard),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed:
                                  state.isCartLoading ? null : _applyPromoCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: state.isCartLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text("Appliquer",
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Code promo "${cart.codePromo!.code}" appliqué',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // MODE DE PAIEMENT
                sectionTitle("Mode de Paiement", isGreen: true),
                ListTile(
                  title: Text("Payer cash à la livraison"),
                  subtitle: Text(
                    "Réglez vos achats en espèces directement à la livraison. Nous n'acceptons que les Francs CFA.",
                  ),
                  leading: Radio<String>(
                    value: 'Cash à la livraison',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ),

                const SizedBox(height: 10),

                // ADRESSE DE LIVRAISON
                sectionTitle("Adresse", isGreen: true),
                if (cart.adresseLivraison != null &&
                    cart.adresseLivraison!.isComplete) ...[
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.green),
                    title: Text(cart.adresseLivraison!.nom),
                    subtitle: Text(
                      "${cart.adresseLivraison!.adresse}\n${cart.adresseLivraison!.ville}, ${cart.adresseLivraison!.pays}\n${cart.adresseLivraison!.telephone}",
                    ),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeliveryAddressScreen(
                              currentAddress: cart.adresseLivraison,
                              onAddressSaved: (address) {
                                // L'adresse sera automatiquement mise à jour via le BLoC
                              },
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Modifier",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  ListTile(
                    leading:
                        const Icon(Icons.add_location, color: Colors.orange),
                    title: const Text("Aucune adresse de livraison"),
                    subtitle: const Text("Veuillez ajouter une adresse"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DeliveryAddressScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Ajouter",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // LIVRAISON
                sectionTitle("Livraison", isGreen: true),
                const ListTile(
                  leading: Icon(Icons.local_shipping, color: Colors.green),
                  title: Text("Livraison standard"),
                  subtitle: Text("Livraison sous 2-5 jours ouvrés"),
                ),

                const SizedBox(height: 20),

                // BOUTON CONFIRMATION COMMANDE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: ElevatedButton(
                    onPressed: cart.canCheckout && !state.isCartLoading
                        ? _confirmOrder
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: Center(
                      child: state.isCartLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text(
                              "Confirmer La Commande",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget pour afficher les lignes du résumé de commande
  Widget rowItem(String title, String value,
      {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher les titres de section
  Widget sectionTitle(String title, {bool isGreen = false}) {
    return Container(
      width: double.infinity,
      color: isGreen ? Colors.green : Colors.grey[200],
      padding: const EdgeInsets.all(10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isGreen ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
