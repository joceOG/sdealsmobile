import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/design_system/design_system.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageEventM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageStateM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/category_services_screen.dart';

/// Grille complète des catégories Métiers.
///
/// Données : BLoC [JobPageBlocM] → [LoadCategorieDataJobM] → API fetchCategorie("Métiers").
/// Image   : [Categorie.imagecategorie] via [normalizeMediaUrl] — même chemin que le hub.
/// Fallback: pictogramme contextuel sur fond neutre si URL absente ou inaccessible.
class CategoriesListScreen extends StatelessWidget {
  const CategoriesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Réutilise le BLoC ancêtre s'il existe (appelé depuis jobPageScreenM),
    // sinon crée un BLoC autonome (navigation directe).
    final hasAncestorBloc =
        context.findAncestorWidgetOfExactType<BlocProvider<JobPageBlocM>>() != null;

    if (hasAncestorBloc) {
      return const _Body();
    }
    return BlocProvider(
      create: (_) => JobPageBlocM()..add(LoadCategorieDataJobM()),
      child: const _Body(),
    );
  }
}

// ── Scaffold + BlocBuilder ────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: AppBar(
        backgroundColor: SDColors.white,
        foregroundColor: SDColors.neutral900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Catégories',
          style: SDTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: SDColors.neutral900,
          ),
        ),
      ),
      body: BlocBuilder<JobPageBlocM, JobPageStateM>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          if (state.error.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_outlined,
                        size: 48, color: SDColors.neutral400),
                    const SizedBox(height: 12),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.bodySmall
                          .copyWith(color: SDColors.neutral600),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<JobPageBlocM>()
                          .add(LoadCategorieDataJobM()),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Réessayer'),
                      style: FilledButton.styleFrom(
                          backgroundColor: SDColors.primary600),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.listItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.category_outlined,
                      size: 48, color: SDColors.neutral300),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune catégorie disponible',
                    style: SDTypography.bodyMedium
                        .copyWith(color: SDColors.neutral500),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              // 2 colonnes, ratio hauteur/largeur : image (≈60 %) + texte (≈40 %)
              crossAxisCount: 2,
              childAspectRatio: 0.82,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: state.listItems.length,
            itemBuilder: (context, i) {
              final cat = state.listItems[i];
              return _CategoryCard(
                categorie: cat,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryServicesScreen(
                      categorieId: cat.idcategorie,
                      nomcategorie: cat.nomcategorie,
                      imagecategorie: cat.imagecategorie,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Carte catégorie ───────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final Categorie categorie;
  final VoidCallback onTap;

  const _CategoryCard({required this.categorie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Même mécanisme que les chips du hub jobPageScreenM.
    final imgUrl = normalizeMediaUrl(categorie.imagecategorie);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      // clipBehavior arrondit automatiquement l'image ET le texte
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Zone image ── Expanded → prend tout l'espace libre
            Expanded(
              child: imgUrl != null
                  ? AppImage(
                      imageUrl: imgUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: SDColors.primary50,
                      alignment: Alignment.center,
                      child: Icon(
                        _icon(categorie.nomcategorie),
                        size: 40,
                        color: SDColors.primary600,
                      ),
                    ),
            ),

            // ── Nom de la catégorie ── hauteur naturelle, jamais de débordement
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Text(
                categorie.nomcategorie,
                style: SDTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SDColors.neutral900,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pictogramme contextuel utilisé uniquement quand aucune image n'est disponible.
  static IconData _icon(String name) {
    final n = name.toLowerCase();
    if (n.contains('plomb')) return Icons.plumbing;
    if (n.contains('électr') || n.contains('electr')) {
      return Icons.electrical_services;
    }
    if (n.contains('coiff')) return Icons.content_cut;
    if (n.contains('photo')) return Icons.camera_alt;
    if (n.contains('ménag') || n.contains('menag') || n.contains('nettoy')) {
      return Icons.cleaning_services;
    }
    if (n.contains('menuis') || n.contains('bois')) return Icons.handyman;
    if (n.contains('peint')) return Icons.format_paint;
    if (n.contains('jardin')) return Icons.local_florist;
    if (n.contains('cuisin')) return Icons.restaurant;
    if (n.contains('macon') || n.contains('maçon')) return Icons.foundation;
    if (n.contains('clim') || n.contains('climatisation')) return Icons.ac_unit;
    if (n.contains('info') || n.contains('tech')) return Icons.computer;
    if (n.contains('transport') || n.contains('livraison')) return Icons.local_shipping;
    if (n.contains('médic') || n.contains('soin') || n.contains('santé')) {
      return Icons.local_hospital;
    }
    return Icons.category_outlined; // Fallback neutre — plus générique que la mallette
  }
}
