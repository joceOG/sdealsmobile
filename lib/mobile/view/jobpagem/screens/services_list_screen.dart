import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../jobpageblocm/jobPageBlocM.dart';
import '../jobpageblocm/jobPageEventM.dart';
import '../jobpageblocm/jobPageStateM.dart';
import 'detailPageScreenM.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  @override
  void initState() {
    super.initState();
    // Les services sont chargés automatiquement dans le BlocProvider
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JobPageBlocM()..add(LoadServiceDataJobM()),
      child: Scaffold(
        backgroundColor: SDColors.white,
        appBar: SDWhiteAppBar.appBar(
          title: 'Tous les Services',
        ),
        body: BlocBuilder<JobPageBlocM, JobPageStateM>(
          builder: (context, state) {
            if (state.isLoading2) {
              return Center(
                child: CircularProgressIndicator(
                  color: SDColors.primary700,
                ),
              );
            }

            if (state.error2.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: SDColors.error200,
                    ),
                    SizedBox(height: SDSpacing.sm),
                    Text(
                      'Erreur de chargement',
                      style: SDTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: SDColors.neutral700,
                      ),
                    ),
                    SizedBox(height: SDSpacing.xs),
                    Text(
                      state.error2,
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: SDSpacing.md),
                    ElevatedButton(
                      onPressed: () {
                        context.read<JobPageBlocM>().add(LoadServiceDataJobM());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SDColors.primary700,
                        foregroundColor: SDColors.white,
                      ),
                      child: Text('Réessayer', style: SDTypography.labelMedium),
                    ),
                  ],
                ),
              );
            }

            if (state.listItems2.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.build_outlined,
                      size: 64,
                      color: SDColors.neutral300,
                    ),
                    SizedBox(height: SDSpacing.sm),
                    Text(
                      'Aucun service disponible',
                      style: SDTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: SDColors.neutral700,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(SDSpacing.sm),
              itemCount: state.listItems2.length,
              itemBuilder: (context, index) {
                final service = state.listItems2[index];
                return _buildServiceCard(service);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceCard(dynamic service) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
      ),
      margin: EdgeInsets.only(bottom: SDSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
        onTap: () {
          // Navigation vers les détails du service
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailPage(
                title: service.nomservice,
                image: service.imageservice.isNotEmpty
                    ? service.imageservice
                    : 'assets/categories/Image1.png',
                serviceId: service.idservice.isNotEmpty
                    ? service.idservice
                    : null,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
            color: SDColors.primary700.withOpacity(0.05),
          ),
          child: Padding(
            padding: EdgeInsets.all(SDSpacing.sm),
            child: Row(
              children: [
                // Image du service
                ClipRRect(
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: SDColors.primary700.withOpacity(0.1),
                    child: service.imageservice.isNotEmpty
                        ? Image.network(
                            service.imageservice,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: SDColors.primary700,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: SDColors.primary700.withOpacity(0.1),
                                child: Icon(
                                  _getServiceIcon(service.nomservice),
                                  size: 40,
                                  color: SDColors.primary700,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: SDColors.primary700.withOpacity(0.1),
                            child: Icon(
                              _getServiceIcon(service.nomservice),
                              size: 40,
                              color: SDColors.primary700,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: SDSpacing.sm),
                // Informations du service
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du service
                      Text(
                        service.nomservice,
                        style: SDTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: SDColors.neutral900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: SDSpacing.xs),
                      // Catégorie
                      if (service.categorie?.nomcategorie != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: SDSpacing.xs, vertical: SDSpacing.xxxs),
                          decoration: BoxDecoration(
                            color: SDColors.primary700.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          ),
                          child: Text(
                            service.categorie!.nomcategorie,
                            style: SDTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: SDColors.primary700,
                            ),
                          ),
                        ),
                      SizedBox(height: SDSpacing.xs),
                      // Prix
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: SDColors.primary700,
                          ),
                          SizedBox(width: SDSpacing.xxxs),
                          Expanded(
                            child: Text(
                              'À partir de ${service.prixmoyen} FCFA/h',
                              style: SDTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: SDColors.primary700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bouton d'action
                Container(
                  padding: EdgeInsets.all(SDSpacing.xs),
                  decoration: BoxDecoration(
                    color: SDColors.primary700,
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: SDColors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String serviceName) {
    final name = serviceName.toLowerCase();
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
