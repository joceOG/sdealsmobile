import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../jobpageblocm/jobPageBlocM.dart';
import '../jobpageblocm/jobPageEventM.dart';
import '../jobpageblocm/jobPageStateM.dart';
import 'detailPageScreenM.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  @override
  void initState() {
    super.initState();
    // Les catégories sont chargées automatiquement dans le BlocProvider
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JobPageBlocM()..add(LoadCategorieDataJobM()),
      child: Scaffold(
        backgroundColor: SDColors.white,
        appBar: SDWhiteAppBar.appBar(
          title: 'Toutes les Catégories',
        ),
        body: BlocBuilder<JobPageBlocM, JobPageStateM>(
          builder: (context, state) {
            if (state.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(SDSpacing.md),
                      decoration: BoxDecoration(
                        color: SDColors.primary700.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusXLarge),
                      ),
                      child: CircularProgressIndicator(
                        color: SDColors.primary700,
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: SDSpacing.md),
                    Text(
                      'Chargement des catégories...',
                      style: SDTypography.titleSmall.copyWith(
                        color: SDColors.primary700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state.error.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(SDSpacing.md),
                      decoration: BoxDecoration(
                        color: SDColors.error50,
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusXLarge),
                        border: Border.all(
                          color: SDColors.error200,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: SDColors.error500,
                      ),
                    ),
                    SizedBox(height: SDSpacing.md),
                    Text(
                      'Erreur de chargement',
                      style: SDTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: SDColors.error600,
                      ),
                    ),
                    SizedBox(height: SDSpacing.xs),
                    Text(
                      state.error,
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.error600,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: SDSpacing.md),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<JobPageBlocM>()
                            .add(LoadCategorieDataJobM());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SDColors.primary700,
                        foregroundColor: SDColors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: SDSpacing.md,
                          vertical: SDSpacing.xs,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Réessayer',
                        style: SDTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: SDColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state.listItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: SDColors.neutral300,
                    ),
                    SizedBox(height: SDSpacing.sm),
                    Text(
                      'Aucune catégorie disponible',
                      style: SDTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: SDColors.neutral700,
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: EdgeInsets.all(SDSpacing.md),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85, // Ajusté pour la nouvelle hauteur
                crossAxisSpacing: SDSpacing.md,
                mainAxisSpacing: SDSpacing.md,
              ),
              itemCount: state.listItems.length,
              itemBuilder: (context, index) {
                final category = state.listItems[index];
                return _buildCategoryCard(category);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(dynamic category) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusXLarge),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusXLarge),
        onTap: () {
          // Navigation vers les services de cette catégorie
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailPage(
                title: category.nomcategorie,
                image: category.imagecategorie.isNotEmpty
                    ? category.imagecategorie
                    : 'assets/categories/Image1.png',
              ),
            ),
          );
        },
        child: Container(
          height: 180, // Hauteur fixe pour éviter le débordement
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusXLarge),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SDColors.primary700.withOpacity(0.08),
                SDColors.primary500.withOpacity(0.12),
                SDColors.primary300.withOpacity(0.08),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(SDSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Évite le débordement
              children: [
                // Icône de la catégorie avec effet de brillance
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: SDColors.primary700.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: SDColors.primary700.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(category.nomcategorie),
                    size: 35,
                    color: SDColors.primary700,
                  ),
                ),
                SizedBox(height: SDSpacing.sm),
                // Nom de la catégorie avec style amélioré
                Flexible(
                  child: Text(
                    category.nomcategorie,
                    style: SDTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SDColors.neutral900,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: SDSpacing.xs),
                // Badge "Voir services" avec design amélioré
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: SDSpacing.xs, vertical: SDSpacing.xxxs),
                  decoration: BoxDecoration(
                    color: SDColors.primary700,
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: SDColors.primary700.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Voir services',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('plombier') || name.contains('plomberie')) {
      return Icons.plumbing;
    } else if (name.contains('électricien') || name.contains('électricité')) {
      return Icons.electrical_services;
    } else if (name.contains('coiffeur') || name.contains('coiffure')) {
      return Icons.content_cut;
    } else if (name.contains('photographe') || name.contains('photo')) {
      return Icons.camera_alt;
    } else if (name.contains('nettoyage') || name.contains('ménage')) {
      return Icons.cleaning_services;
    } else if (name.contains('menuiserie') || name.contains('bois')) {
      return Icons.build;
    } else if (name.contains('peintre') || name.contains('peinture')) {
      return Icons.format_paint;
    } else if (name.contains('jardinier') || name.contains('jardin')) {
      return Icons.local_florist;
    } else if (name.contains('cuisinier') || name.contains('cuisine')) {
      return Icons.restaurant;
    } else {
      return Icons.work;
    }
  }
}
