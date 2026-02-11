import 'package:flutter/material.dart';
import 'package:sdealsmobile/data/models/vendeur.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';

class VendorDetailsScreenM extends StatelessWidget {
  final Vendeur vendeur;

  const VendorDetailsScreenM({super.key, required this.vendeur});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLargeScreen = screenSize.width > 600;

    return Scaffold(
      backgroundColor: SDColors.neutral50,
      body: CustomScrollView(
        slivers: [
          // ✅ HERO HEADER avec image boutique
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: SDColors.primary600,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                vendeur.shopName.isNotEmpty ? vendeur.shopName : 'Boutique',
                style: SDTypography.titleMedium.copyWith(
                  color: SDColors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 2, color: SDColors.neutral900.withOpacity(0.54))],
                ),
              ),
              background: Container(
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
                child: vendeur.shopLogo != null && vendeur.shopLogo!.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            vendeur.shopLogo!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultHeader();
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
                      )
                    : _buildDefaultHeader(),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.favorite_border, color: SDColors.white),
                onPressed: () {
                  // TODO: Ajouter aux favoris
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ajouté aux favoris !',
                        style: SDTypography.bodyMedium)),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.share, color: SDColors.white),
                onPressed: () {
                  // TODO: Partager vendeur
                },
              ),
            ],
          ),

          // ✅ CONTENU PRINCIPAL
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(SDSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏪 SECTION INFO BOUTIQUE
                  _buildShopInfoSection(context, isLargeScreen),
                  SizedBox(height: SDSpacing.md),

                  // 👤 SECTION PROPRIÉTAIRE
                  _buildOwnerSection(context),
                  SizedBox(height: SDSpacing.md),

                  // 📊 SECTION STATISTIQUES
                  _buildStatsSection(context),
                  SizedBox(height: SDSpacing.md),

                  // 📍 SECTION LOCALISATION & LIVRAISON
                  _buildLocationSection(context),
                  SizedBox(height: SDSpacing.md),

                  // 💳 SECTION PAIEMENTS & POLITIQUES
                  _buildPaymentSection(context),
                  SizedBox(height: SDSpacing.lg),

                  // 🎯 BOUTONS D'ACTION
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SDColors.primary400, SDColors.primary700],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront,
          size: 80,
          color: SDColors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildShopInfoSection(BuildContext context, bool isLargeScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge)),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: SDColors.success100,
                  backgroundImage:
                      vendeur.shopLogo != null && vendeur.shopLogo!.isNotEmpty
                          ? NetworkImage(vendeur.shopLogo!)
                          : null,
                  child: vendeur.shopLogo == null || vendeur.shopLogo!.isEmpty
                      ? Icon(Icons.storefront, color: SDColors.success600)
                      : null,
                ),
                SizedBox(width: SDSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendeur.shopName,
                        style: SDTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: SDSpacing.xxxs),
                      Row(
                        children: [
                          Icon(Icons.business,
                              size: 16, color: SDColors.neutral600),
                          SizedBox(width: SDSpacing.xxxs),
                          Text(
                            vendeur.businessType,
                            style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge de statut
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: SDSpacing.xs, vertical: SDSpacing.xxxs),
                  decoration: BoxDecoration(
                    color: vendeur.accountStatus == 'Active'
                        ? SDColors.success100
                        : SDColors.warning100,
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                    border: Border.all(
                      color: vendeur.accountStatus == 'Active'
                          ? SDColors.success200
                          : SDColors.warning200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vendeur.accountStatus == 'Active'
                            ? Icons.verified
                            : Icons.hourglass_empty,
                        size: 16,
                        color: vendeur.accountStatus == 'Active'
                            ? SDColors.success700
                            : SDColors.warning700,
                      ),
                      SizedBox(width: SDSpacing.xxxs),
                      Text(
                        vendeur.accountStatus == 'Active'
                            ? 'Actif'
                            : 'En attente',
                        style: SDTypography.labelSmall.copyWith(
                          color: vendeur.accountStatus == 'Active'
                              ? SDColors.success700
                              : SDColors.warning700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (vendeur.shopDescription.isNotEmpty) ...[
              SizedBox(height: SDSpacing.sm),
              Text(
                vendeur.shopDescription,
                style: SDTypography.titleSmall.copyWith(
                  color: SDColors.neutral700,
                  height: 1.5,
                ),
              ),
            ],
            if (vendeur.businessCategories.isNotEmpty) ...[
              SizedBox(height: SDSpacing.sm),
              Wrap(
                spacing: SDSpacing.xs,
                runSpacing: SDSpacing.xs,
                children: vendeur.businessCategories.map((category) {
                  return Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: SDSpacing.xs, vertical: SDSpacing.xxxs),
                    decoration: BoxDecoration(
                      color: SDColors.info50,
                      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                      border: Border.all(color: SDColors.info200),
                    ),
                    child: Text(
                      category,
                      style: SDTypography.labelSmall.copyWith(
                        color: SDColors.info700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerSection(BuildContext context) {
    if (vendeur.utilisateur == null) return SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge)),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Propriétaire',
              style: SDTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SDSpacing.sm),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: SDColors.neutral200,
                  backgroundImage: vendeur.utilisateur!.photoProfil != null &&
                          vendeur.utilisateur!.photoProfil!.isNotEmpty
                      ? NetworkImage(vendeur.utilisateur!.photoProfil!)
                      : null,
                  child: vendeur.utilisateur!.photoProfil == null ||
                          vendeur.utilisateur!.photoProfil!.isEmpty
                      ? Icon(Icons.person, color: SDColors.neutral600)
                      : null,
                ),
                SizedBox(width: SDSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendeur.utilisateur!.fullName,
                        style: SDTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: SDSpacing.xxxs),
                      if (vendeur.utilisateur!.email != null)
                        Row(
                          children: [
                            Icon(Icons.email,
                                size: 16, color: SDColors.neutral600),
                            SizedBox(width: SDSpacing.xxxs),
                            Text(
                              vendeur.utilisateur!.email!,
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.neutral600,
                              ),
                            ),
                          ],
                        ),
                      if (vendeur.utilisateur!.telephone != null) ...[
                        SizedBox(height: SDSpacing.xxxs),
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: 16, color: SDColors.neutral600),
                            SizedBox(width: SDSpacing.xxxs),
                            Text(
                              vendeur.utilisateur!.telephone!,
                              style: SDTypography.bodySmall.copyWith(
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge)),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: SDTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SDSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.star,
                    'Note',
                    '${vendeur.rating.toStringAsFixed(1)}/5',
                    SDColors.warning500,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.shopping_bag,
                    'Ventes',
                    '${vendeur.completedOrders}',
                    SDColors.success500,
                  ),
                ),
              ],
            ),
            SizedBox(height: SDSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.schedule,
                    'Dernière activité',
                    _formatDate(vendeur.lastActive),
                    SDColors.info500,
                  ),
                ),
                if (vendeur.isTopRated)
                  Expanded(
                    child: _buildStatItem(
                      Icons.emoji_events,
                      'Top Vendeur',
                      '🏆',
                      SDColors.warning500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(SDSpacing.xs),
      margin: EdgeInsets.only(right: SDSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: SDSpacing.xs),
          Text(
            value,
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge)),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Localisation & Livraison',
              style: SDTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SDSpacing.sm),
            if (vendeur.businessAddress != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on, color: SDColors.error500),
                  SizedBox(width: SDSpacing.xs),
                  Expanded(
                    child: Text(
                      '${vendeur.businessAddress!.street}, ${vendeur.businessAddress!.city}, ${vendeur.businessAddress!.country}',
                      style: SDTypography.titleSmall,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SDSpacing.xs),
            ],
            if (vendeur.deliveryZones.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_shipping, color: SDColors.info500),
                  SizedBox(width: SDSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zones de livraison :',
                          style: SDTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: SDSpacing.xxxs),
                        Wrap(
                          spacing: SDSpacing.xxxs,
                          runSpacing: SDSpacing.xxxs,
                          children: vendeur.deliveryZones.map((zone) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SDSpacing.xs, vertical: SDSpacing.xxxs),
                              decoration: BoxDecoration(
                                color: SDColors.success50,
                                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                                border:
                                    Border.all(color: SDColors.success200),
                              ),
                              child: Text(
                                zone,
                                style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.success700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge)),
      child: Padding(
        padding: EdgeInsets.all(SDSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paiements & Politiques',
              style: SDTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SDSpacing.sm),
            if (vendeur.paymentMethods.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.payment, color: SDColors.secondary500),
                  SizedBox(width: SDSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Méthodes de paiement :',
                          style: SDTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: SDSpacing.xxxs),
                        Wrap(
                          spacing: SDSpacing.xxxs,
                          runSpacing: SDSpacing.xxxs,
                          children: vendeur.paymentMethods.map((method) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SDSpacing.xs, vertical: SDSpacing.xxxs),
                              decoration: BoxDecoration(
                                color: SDColors.secondary50,
                                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                                border:
                                    Border.all(color: SDColors.secondary200),
                              ),
                              child: Text(
                                method,
                                style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.secondary700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: SDSpacing.xs),
            ],
            if (vendeur.returnPolicy.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.assignment_return, color: SDColors.warning500),
                  SizedBox(width: SDSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Politique de retour :',
                          style: SDTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: SDSpacing.xxxs),
                        Text(
                          vendeur.returnPolicy,
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Contacter le vendeur
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Fonctionnalité de contact à venir',
                        style: SDTypography.bodyMedium)),
              );
            },
            icon: Icon(Icons.phone, color: SDColors.white),
            label: Text('Contacter',
                style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: SDColors.success500,
              foregroundColor: SDColors.white,
              padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
              ),
            ),
          ),
        ),
        SizedBox(width: SDSpacing.xs),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Voir les produits du vendeur
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Produits du vendeur à venir',
                    style: SDTypography.bodyMedium)),
              );
            },
            icon: Icon(Icons.shopping_cart, color: SDColors.white),
            label: Text('Voir produits',
                style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: SDColors.info500,
              foregroundColor: SDColors.white,
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} an(s)';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} mois';
    } else {
      return '${difference.inDays} jour(s)';
    }
  }
}
