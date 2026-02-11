import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../shoppingpageblocm/shoppingPageBlocM.dart';
import '../shoppingpageblocm/shoppingPageEventM.dart';
import '../shoppingpageblocm/shoppingPageStateM.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'confirmationCommandeScreenM.dart';
import 'delivery_address_screen.dart';
import 'package:sdealsmobile/mobile/view/common/utils/app_snackbar.dart';
import '../../common/widgets/empty_state_widget.dart';
import '../../common/widgets/app_image.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';

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
        title: Text(
          "Votre panier",
          style: SDTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: SDColors.white),
        ),
        backgroundColor: SDColors.primary600,
        actions: [
          // Bouton vider le panier
          BlocBuilder<ShoppingPageBlocM, ShoppingPageStateM>(
            builder: (context, state) {
              if (state.cart != null && state.cart!.isNotEmpty) {
                return IconButton(
                  icon: Icon(Icons.delete_outline, color: SDColors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text('Vider le panier', style: SDTypography.titleMedium),
                        content: Text(
                            'Êtes-vous sûr de vouloir vider votre panier ?',
                            style: SDTypography.bodyMedium),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text('Annuler', style: SDTypography.labelMedium),
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
                            child: Text('Vider',
                                style: SDTypography.labelMedium.copyWith(color: SDColors.error500)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<ShoppingPageBlocM, ShoppingPageStateM>(
        listener: (context, state) {
          // Afficher les erreurs
          if (state.cartError != null && state.cartError!.isNotEmpty) {
            AppSnackBar.error(context, state.cartError!);
          }
        },
        builder: (context, state) {
          // Afficher le loader
          if (state.isCartLoading && state.cart == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: SDColors.primary600),
                  SizedBox(height: SDSpacing.sm),
                  Text('Chargement du panier...', style: SDTypography.bodyMedium),
                ],
              ),
            );
          }

          // Panier vide
          if (state.cart == null || state.cart!.isEmpty) {
            return EmptyStateWidget(
              imagePath: 'assets/panier_vide.png',
              title: 'Votre panier est vide',
              message: 'Ajoutez des produits pour commencer vos achats et profitez de nos offres !',
              action: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.shopping_bag, color: SDColors.white),
                label: Text('Continuer mes achats', style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SDColors.primary700,
                  foregroundColor: SDColors.white,
                  padding: EdgeInsets.symmetric(horizontal: SDSpacing.lg, vertical: SDSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                  ),
                ),
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
                padding: EdgeInsets.all(SDSpacing.xs),
                color: SDColors.success50,
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag, color: SDColors.success700),
                    SizedBox(width: SDSpacing.xs),
                    Text(
                      '${cart.totalItems} article${cart.totalItems > 1 ? 's' : ''} dans votre panier',
                      style: SDTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SDColors.success700,
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
                      padding: EdgeInsets.only(bottom: SDSpacing.sm),
                      itemCount: cart.articles.length,
                      itemBuilder: (context, index) {
                        final item = cart.articles[index];

                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: SDSpacing.xs,
                            vertical: SDSpacing.xxxs,
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(SDSpacing.xs),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image du produit
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                                  child: AppImage(
                                    imageUrl: item.imageArticle,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: SDSpacing.xs),

                                // Détails du produit
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nomArticle,
                                        style: SDTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: SDSpacing.xxxs),
                                      Text(
                                        "${item.prixUnitaire.toStringAsFixed(0)} FCFA",
                                        style: SDTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: SDColors.success700,
                                        ),
                                      ),
                                      SizedBox(height: SDSpacing.xs),

                                      // Contrôles de quantité
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: SDColors.neutral300),
                                              borderRadius:
                                                  BorderRadius.circular(SDSpacing.borderRadiusSmall),
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
                                                      ? SDColors.warning500
                                                      : SDColors.error500,
                                                  padding:
                                                      EdgeInsets.all(SDSpacing.xxxs),
                                                  constraints:
                                                      BoxConstraints(
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
                                                                title: Text(
                                                                    'Retirer l\'article',
                                                                    style: SDTypography.titleMedium),
                                                                content: Text(
                                                                    'Voulez-vous retirer cet article du panier ?',
                                                                    style: SDTypography.bodyMedium),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                            dialogContext),
                                                                    child: Text(
                                                                        'Annuler',
                                                                        style: SDTypography.labelMedium),
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
                                                                    child: Text(
                                                                        'Retirer',
                                                                        style: SDTypography.labelMedium.copyWith(
                                                                            color:
                                                                                SDColors.error500)),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }
                                                        },
                                                ),
                                                Container(
                                                  padding: EdgeInsets
                                                      .symmetric(
                                                      horizontal: SDSpacing.xs),
                                                  child: Text(
                                                    "${item.quantite}",
                                                    style: SDTypography.titleSmall.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.add,
                                                      size: 20),
                                                  color: SDColors.success500,
                                                  padding:
                                                      EdgeInsets.all(SDSpacing.xxxs),
                                                  constraints:
                                                      BoxConstraints(
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
                                          Spacer(),
                                          Text(
                                            "${item.prixTotal.toStringAsFixed(0)} FCFA",
                                            style: SDTypography.bodyMedium.copyWith(
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
                        color: SDColors.neutral900.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(color: SDColors.primary600),
                        ),
                      ),
                  ],
                ),
              ),

              // Résumé et bouton commander
              Container(
                padding: EdgeInsets.all(SDSpacing.sm),
                decoration: BoxDecoration(
                  color: SDColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: SDColors.neutral500.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Détails du montant
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Sous-total:",
                          style: SDTypography.bodyMedium,
                        ),
                        Text(
                          "${cart.montantArticles.toStringAsFixed(0)} FCFA",
                          style: SDTypography.bodyMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: SDSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Livraison:",
                              style: SDTypography.bodyMedium,
                            ),
                            if (cart.fraisLivraison == 0)
                              Container(
                                margin: EdgeInsets.only(left: SDSpacing.xs),
                                padding: EdgeInsets.symmetric(
                                  horizontal: SDSpacing.xs,
                                  vertical: SDSpacing.xxxs,
                                ),
                                decoration: BoxDecoration(
                                  color: SDColors.success100,
                                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                                ),
                                child: Text(
                                  "GRATUITE",
                                  style: SDTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: SDColors.success700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          cart.fraisLivraison == 0
                              ? "Gratuite"
                              : "${cart.fraisLivraison.toStringAsFixed(0)} FCFA",
                          style: SDTypography.bodyMedium.copyWith(
                            color: cart.fraisLivraison == 0
                                ? SDColors.success700
                                : SDColors.neutral900,
                            fontWeight: cart.fraisLivraison == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),

                    // Code promo si appliqué
                    if (cart.hasPromoCode) ...[
                      SizedBox(height: SDSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_offer,
                                  size: 16, color: SDColors.warning700),
                              SizedBox(width: SDSpacing.xxxs),
                              Text(
                                "Code promo:",
                                style: SDTypography.bodyMedium.copyWith(
                                    color: SDColors.warning700),
                              ),
                            ],
                          ),
                          Text(
                            cart.codePromo!.descriptionReduction,
                            style: SDTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: SDColors.warning700,
                            ),
                          ),
                        ],
                      ),
                    ],

                    Divider(height: SDSpacing.md, thickness: 2, color: SDColors.neutral300),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total:",
                          style: SDTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${cart.montantTotal.toStringAsFixed(0)} FCFA",
                          style: SDTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: SDColors.success500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SDSpacing.sm),

                    // 📍 Section Adresse de livraison
                    Container(
                      padding: EdgeInsets.all(SDSpacing.xs),
                      decoration: BoxDecoration(
                        color: cart.hasDeliveryAddress
                            ? SDColors.success50
                            : SDColors.warning50,
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        border: Border.all(
                          color: cart.hasDeliveryAddress
                              ? SDColors.success200
                              : SDColors.warning200,
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
                                    ? SDColors.success500
                                    : SDColors.warning500,
                              ),
                              SizedBox(width: SDSpacing.xs),
                              Expanded(
                                child: Text(
                                  cart.hasDeliveryAddress
                                      ? "Adresse de livraison"
                                      : "Aucune adresse de livraison",
                                  style: SDTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cart.hasDeliveryAddress
                                        ? SDColors.success700
                                        : SDColors.warning700,
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
                                  style: SDTypography.labelMedium.copyWith(
                                    color: cart.hasDeliveryAddress
                                        ? SDColors.success700
                                        : SDColors.warning700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (cart.hasDeliveryAddress &&
                              cart.adresseLivraison != null) ...[
                            SizedBox(height: SDSpacing.xs),
                            Text(
                              cart.adresseLivraison!.nom,
                              style: SDTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: SDSpacing.xxxs),
                            Text(
                              "${cart.adresseLivraison!.adresse}\n${cart.adresseLivraison!.ville}, ${cart.adresseLivraison!.pays}",
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.neutral700,
                              ),
                            ),
                            SizedBox(height: SDSpacing.xxxs),
                            Text(
                              cart.adresseLivraison!.telephone,
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.neutral700,
                              ),
                            ),
                          ] else ...[
                            SizedBox(height: SDSpacing.xxxs),
                            Text(
                              "Veuillez ajouter une adresse pour continuer",
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.warning700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: SDSpacing.sm),

                    // Bouton commander
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SDColors.success500,
                          padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          ),
                          elevation: 2,
                          disabledBackgroundColor: SDColors.neutral300,
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
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      SDColors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Passer commande",
                                    style: SDTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: SDColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: SDSpacing.xs),
                                  Icon(Icons.arrow_forward,
                                      color: SDColors.white),
                                ],
                              ),
                      ),
                    ),

                    // Message si panier non valide
                    if (!cart.canCheckout) ...[
                      SizedBox(height: SDSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: SDColors.warning700),
                          SizedBox(width: SDSpacing.xxxs),
                          Expanded(
                            child: Text(
                              !cart.hasDeliveryAddress
                                  ? "Ajoutez une adresse de livraison pour continuer"
                                  : cart.isEmpty
                                      ? "Votre panier est vide"
                                      : "Impossible de passer commande",
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.warning700,
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
