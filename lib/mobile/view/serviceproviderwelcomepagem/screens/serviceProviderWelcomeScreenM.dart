import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/mobile/view/serviceproviderregistrationpagem/screens/serviceProviderRegistrationScreenM.dart';

// ✅ Design System
import '../../../../design_system/design_system.dart';

class ServiceProviderWelcomeScreenM extends StatelessWidget {
  final List<dynamic> categories;

  const ServiceProviderWelcomeScreenM({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      appBar: SDWhiteAppBar.appBar(
        centerTitle: false,
        title: 'Devenir prestataire',
      ),
      // Bouton fixe en bas de l'écran
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(SDSpacing.sm, SDSpacing.xs, SDSpacing.sm, SDSpacing.md),
        decoration: BoxDecoration(
          color: SDColors.white,
          boxShadow: [
            BoxShadow(
              color: SDColors.neutral900.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SDButton(
          text: 'COMMENCER MON INSCRIPTION',
          fullWidth: true,
          onPressed: () {
            GoRouter.of(context).push('/serviceProviderRegistration');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _buildHeaderSection(context),

            // Avantages section
            _buildAdvantagesSection(),

            // Métiers section
            _buildCategoriesSection(context),

            // Espace supplémentaire en bas pour éviter que le bouton fixe ne cache du contenu
            SDSpacing.verticalLargeGap,
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: SDGradients.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(SDSpacing.borderRadiusXLarge),
          bottomRight: Radius.circular(SDSpacing.borderRadiusXLarge),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(SDSpacing.md, SDSpacing.md, SDSpacing.md, SDSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.handyman, color: SDColors.white, size: 28),
                SDSpacing.horizontalTinyGap,
                Text(
                  'Rejoignez-nous',
                  style: SDTypography.displaySmall.copyWith(
                    color: SDColors.white,
                  ),
                ),
              ],
            ),
            SDSpacing.verticalTinyGap,
            Text(
              'Développez votre activité avec Soutrali Deals',
              style: SDTypography.bodyLarge.copyWith(
                color: SDColors.white.withOpacity(0.9),
              ),
            ),
            SDSpacing.verticalMediumGap,
            Row(
              children: [
                Expanded(child: _buildStatItem('500+', 'prestataires actifs')),
                SDSpacing.horizontalSmallGap,
                Expanded(child: _buildStatItem('1000+', 'missions réalisées')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.sm),
      decoration: BoxDecoration(
        color: SDColors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        border: Border.all(color: SDColors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: SDTypography.titleLarge.copyWith(
              color: SDColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          SDSpacing.verticalTinyGap,
          Text(
            label,
            style: SDTypography.bodySmall.copyWith(
              color: SDColors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvantagesSection() {
    return Padding(
      padding: EdgeInsets.all(SDSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pourquoi nous rejoindre ?',
            style: SDTypography.titleLarge,
          ),
          SDSpacing.verticalMediumGap,

          // Grille d'avantages
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: SDSpacing.sm,
            crossAxisSpacing: SDSpacing.sm,
            childAspectRatio: 1.5,
            children: [
              _buildAdvantageCard('💰', 'Augmentez vos revenus',
                  'Tarifs attractifs et clients réguliers'),
              _buildAdvantageCard('📅', 'Gérez votre planning',
                  'Travaillez selon vos disponibilités'),
              _buildAdvantageCard('⭐', 'Construisez votre réputation',
                  'Système d\'avis et de notation'),
              _buildAdvantageCard('🎯', 'Clients qualifiés près de chez vous',
                  'Réduisez vos déplacements'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvantageCard(String emoji, String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6)),
        ],
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.06), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    // Utilisation des catégories dynamiques passées en paramètre
    final metierCategories = categories.isNotEmpty ? categories : [];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏗️ Dans quel domaine exercez-vous ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Découvrez les opportunités pour votre métier',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),

          // Liste des catégories professionnelles
          metierCategories.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Chargement des catégories de métiers...',
                      style:
                          TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: metierCategories.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final category = metierCategories[index];
                    // Services par défaut pour chaque catégorie
                    final defaultServices = [
                      'Installation',
                      'Réparation',
                      'Dépannage',
                      'Conseil'
                    ];

                    // Accéder directement à la propriété nomcategorie comme dans l'écran freelance
                    final categoryName = category.nomcategorie;

                    return _buildCategoryItem(
                      context,
                      categoryName,
                      _getCategoryIcon(categoryName),
                      defaultServices,
                    );
                  },
                ),
        ],
      ),
    );
  }

  // Méthode pour obtenir l'icône appropriée en fonction du nom de la catégorie
  IconData _getCategoryIcon(String categoryName) {
    final Map<String, IconData> iconMap = {
      'Plombier': Icons.plumbing,
      'Électricien': Icons.electrical_services,
      'Menuisier': Icons.carpenter,
      'Peintre': Icons.format_paint,
      'Jardinier': Icons.yard,
      'Maçon': Icons.architecture,
      'Serrurier': Icons.lock,
      'Chauffagiste': Icons.local_fire_department,
      'Décorateur': Icons.brush,
      'Informaticien': Icons.computer,
      'Photographe': Icons.camera_alt,
      'Coiffeur': Icons.content_cut,
      'Mécanicien': Icons.car_repair,
    };

    return iconMap[categoryName] ?? Icons.handyman; // Icône par défaut
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String title,
    IconData icon,
    List<String> services,
  ) {
    return Card(
      elevation: 0,
      color: Colors.green.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.green.shade700, size: 20),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Services proposés:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: services
                        .map((service) => Chip(
                              label: Text(service),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                  color: Colors.green.withOpacity(0.2)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tarifs moyens dans votre région:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildTarifItem(
                          'Prestation simple', '5.000 - 10.000 FCFA'),
                      const SizedBox(width: 10),
                      _buildTarifItem(
                          'Prestation complète', '15.000 - 30.000 FCFA'),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher un tarif avec son type
  Widget _buildTarifItem(String type, String price) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
