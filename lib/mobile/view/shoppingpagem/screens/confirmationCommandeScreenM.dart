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
// ✅ Design System
import '../../../../design_system/design_system.dart';

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
    // STAB-10: pas de réduction fictive côté client.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Les codes promo seront disponibles bientôt.',
          style: SDTypography.bodyMedium.copyWith(color: SDColors.white),
        ),
        backgroundColor: SDColors.neutral700,
      ),
    );
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
      appBar: SDWhiteAppBar.appBar(
        centerTitle: true,
        title: 'Passez votre commande',
      ),
      body: BlocConsumer<ShoppingPageBlocM, ShoppingPageStateM>(
        listener: (context, state) {
          if (state.cartError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.cartError!,
                    style: SDTypography.bodyMedium.copyWith(color: SDColors.white)),
                backgroundColor: SDColors.error500,
              ),
            );
          }
        },
        builder: (context, state) {
          final cart = state.cart;

          if (state.isCartLoading && cart == null) {
            return Center(child: CircularProgressIndicator(color: SDColors.primary600));
          }

          if (cart == null || cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 100, color: SDColors.neutral500),
                  SizedBox(height: SDSpacing.sm),
                  Text(
                    'Votre panier est vide',
                    style: SDTypography.titleMedium.copyWith(color: SDColors.neutral500),
                  ),
                  SizedBox(height: SDSpacing.sm),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SDColors.primary600,
                      foregroundColor: SDColors.white,
                    ),
                    child: Text('Retour au shopping',
                        style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
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
                  padding: EdgeInsets.all(SDSpacing.sm),
                  color: SDColors.neutral200,
                  child: Text(
                    "Si vous continuez, vous acceptez automatiquement notre",
                    style: SDTypography.bodySmall,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm),
                  child: Text(
                    "Termes et Conditions",
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.info600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: SDSpacing.sm),

                // RÉSUMÉ DE COMMANDE
                Container(
                  padding: EdgeInsets.all(SDSpacing.md),
                  color: SDColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Résumé de commande",
                        style: SDTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: SDSpacing.sm),
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
                          textColor: SDColors.success500,
                        ),
                      ],
                      Divider(color: SDColors.neutral300),
                      rowItem(
                        "Total",
                        "${cart.montantTotal.toStringAsFixed(0)} FCFA",
                        isBold: true,
                      ),
                      SizedBox(height: SDSpacing.sm),

                      // Champ de code promo
                      if (cart.codePromo == null ||
                          !cart.codePromo!.isValid) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _promoController,
                                style: SDTypography.bodyMedium,
                                decoration: InputDecoration(
                                  hintText: "Entrez votre code ici",
                                  hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                                  ),
                                  prefixIcon: Icon(Icons.card_giftcard, color: SDColors.primary600),
                                ),
                              ),
                            ),
                            SizedBox(width: SDSpacing.sm),
                            ElevatedButton(
                              onPressed:
                                  state.isCartLoading ? null : _applyPromoCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SDColors.success500,
                                foregroundColor: SDColors.white,
                              ),
                              child: state.isCartLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(SDColors.white)),
                                    )
                                  : Text("Appliquer",
                                      style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: EdgeInsets.all(SDSpacing.xs),
                          decoration: BoxDecoration(
                            color: SDColors.success50,
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                            border: Border.all(color: SDColors.success200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: SDColors.success500),
                              SizedBox(width: SDSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Code promo "${cart.codePromo!.code}" appliqué',
                                  style: SDTypography.bodyMedium.copyWith(
                                    color: SDColors.success500,
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

                SizedBox(height: SDSpacing.sm),

                // MESSAGE GRATUIT (remplace les options de paiement)
                Container(
                  padding: EdgeInsets.all(SDSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [SDColors.success100, SDColors.success50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    border: Border.all(color: SDColors.success200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: SDColors.success200.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(SDSpacing.xs),
                        decoration: BoxDecoration(
                          color: SDColors.success500,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle, color: SDColors.white, size: 24),
                      ),
                      SizedBox(width: SDSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Commande 100% GRATUITE',
                              style: SDTypography.titleSmall.copyWith(
                                color: SDColors.success700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: SDSpacing.xxxs),
                            Text(
                              'Aucun paiement requis • Service immédiat',
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.success600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SDSpacing.sm),

                // ADRESSE DE LIVRAISON
                sectionTitle("Adresse", isGreen: true),
                if (cart.adresseLivraison != null &&
                    cart.adresseLivraison!.isComplete) ...[
                  ListTile(
                    leading: Icon(Icons.location_on, color: SDColors.success500),
                    title: Text(cart.adresseLivraison!.nom, style: SDTypography.bodyMedium),
                    subtitle: Text(
                      "${cart.adresseLivraison!.adresse}\n${cart.adresseLivraison!.ville}, ${cart.adresseLivraison!.pays}\n${cart.adresseLivraison!.telephone}",
                      style: SDTypography.bodySmall,
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
                      child: Text(
                        "Modifier",
                        style: SDTypography.labelMedium.copyWith(
                          color: SDColors.success500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  ListTile(
                    leading:
                        Icon(Icons.add_location, color: SDColors.warning500),
                    title: Text("Aucune adresse de livraison", style: SDTypography.bodyMedium),
                    subtitle: Text("Veuillez ajouter une adresse", style: SDTypography.bodySmall),
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
                        backgroundColor: SDColors.success500,
                        foregroundColor: SDColors.white,
                      ),
                      child: Text("Ajouter",
                          style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
                    ),
                  ),
                ],

                SizedBox(height: SDSpacing.sm),

                // LIVRAISON
                sectionTitle("Livraison", isGreen: true),
                ListTile(
                  leading: Icon(Icons.local_shipping, color: SDColors.success500),
                  title: Text("Livraison standard", style: SDTypography.bodyMedium),
                  subtitle: Text("Livraison sous 2-5 jours ouvrés", style: SDTypography.bodySmall),
                ),

                SizedBox(height: SDSpacing.md),

                // BOUTON CONFIRMATION COMMANDE
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
                  child: ElevatedButton(
                    onPressed: cart.canCheckout && !state.isCartLoading
                        ? _confirmOrder
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SDColors.success500,
                      padding: EdgeInsets.symmetric(vertical: SDSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                      ),
                      disabledBackgroundColor: SDColors.neutral400,
                    ),
                    child: Center(
                      child: state.isCartLoading
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(SDColors.white),
                            )
                          : Text(
                              "Confirmer La Commande",
                              style: SDTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: SDColors.white,
                              ),
                            ),
                    ),
                  ),
                ),

                SizedBox(height: SDSpacing.md),
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
      padding: EdgeInsets.symmetric(vertical: SDSpacing.xxxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: SDTypography.bodyMedium.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: SDTypography.bodyMedium.copyWith(
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
      color: isGreen ? SDColors.success500 : SDColors.neutral200,
      padding: EdgeInsets.all(SDSpacing.sm),
      child: Text(
        title,
        style: SDTypography.titleSmall.copyWith(
          fontWeight: FontWeight.bold,
          color: isGreen ? SDColors.white : SDColors.neutral900,
        ),
      ),
    );
  }
}
