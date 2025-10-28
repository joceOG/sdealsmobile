import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../jobpageblocm/jobPageBlocM.dart';
import '../jobpageblocm/jobPageEventM.dart';
import '../jobpageblocm/jobPageStateM.dart';
import 'detailPageScreenM.dart';

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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Toutes les Catégories',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2E7D32),
                  const Color(0xFF4CAF50),
                ],
              ),
            ),
          ),
        ),
        body: BlocBuilder<JobPageBlocM, JobPageStateM>(
          builder: (context, state) {
            if (state.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Chargement des catégories...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<JobPageBlocM>()
                            .add(LoadCategorieDataJobM());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Réessayer',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
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
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune catégorie disponible',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85, // Ajusté pour la nouvelle hauteur
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2E7D32).withOpacity(0.08),
                const Color(0xFF4CAF50).withOpacity(0.12),
                const Color(0xFF66BB6A).withOpacity(0.08),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Évite le débordement
              children: [
                // Icône de la catégorie avec effet de brillance
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(category.nomcategorie),
                    size: 35,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 16),
                // Nom de la catégorie avec style amélioré
                Flexible(
                  child: Text(
                    category.nomcategorie,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                // Badge "Voir services" avec design amélioré
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Voir services',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
