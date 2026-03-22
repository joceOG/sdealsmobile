import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../jobpageblocm/jobPageBlocM.dart';
import '../jobpageblocm/jobPageEventM.dart';
import '../jobpageblocm/jobPageStateM.dart';
import 'detailPageScreenM.dart';
import '../utils/navigation_helper.dart';
import '../../common/widgets/app_image.dart';
import '../../common/widgets/skeleton_loader.dart';
// ✅ Design System
import '../../../../design_system/design_system.dart';

class ProvidersListScreen extends StatefulWidget {
  const ProvidersListScreen({super.key});

  @override
  State<ProvidersListScreen> createState() => _ProvidersListScreenState();
}

class _ProvidersListScreenState extends State<ProvidersListScreen> {
  @override
  void initState() {
    super.initState();
    // Les prestataires sont chargés automatiquement dans le BlocProvider
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JobPageBlocM()
        ..add(LoadProviderMatchingM(
          serviceType: '',
          location: '',
        )),
      child: Scaffold(
        backgroundColor: SDColors.white,
        appBar: SDWhiteAppBar.appBar(
          title: 'Tous les Prestataires',
        ),
        body: BlocBuilder<JobPageBlocM, JobPageStateM>(
          builder: (context, state) {
            if (state.isMatchingLoading) {
               return SkeletonGrid(
                itemCount: 6,
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                itemTemplate: const SkeletonWidget.rounded(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 16,
                ),
              );
            }

            if (state.matchError.isNotEmpty) {
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
                      state.matchError,
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: SDSpacing.md),
                    ElevatedButton(
                      onPressed: () {
                        context.read<JobPageBlocM>().add(LoadProviderMatchingM(
                              serviceType: '',
                              location: '',
                            ));
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

            if (state.matchedProviders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: SDColors.neutral300,
                    ),
                    SizedBox(height: SDSpacing.sm),
                    Text(
                      'Aucun prestataire disponible',
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
              itemCount: state.matchedProviders.length,
              itemBuilder: (context, index) {
                final provider = state.matchedProviders[index];
                return _buildProviderCard(provider);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProviderCard(dynamic provider) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusXLarge),
      ),
      margin: EdgeInsets.only(bottom: SDSpacing.sm, left: SDSpacing.sm, right: SDSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusXLarge),
        onTap: () {
          // ✅ Navigation vers le profil complet du prestataire
          NavigationHelper.navigateToProviderProfile(
            context,
            providerId: provider.idprestataire,
            providerData: provider.toJson(),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SDSpacing.borderRadiusXLarge),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SDColors.primary700.withOpacity(0.05),
                SDColors.primary500.withOpacity(0.08),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(SDSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec photo et nom
                Row(
                  children: [
                    // Photo du prestataire
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          child: Container(
                            width: 70,
                            height: 70,
                            color: SDColors.primary700.withOpacity(0.1),
                            child: provider.utilisateur?.photoProfil != null &&
                                    provider
                                        .utilisateur!.photoProfil!.isNotEmpty
                                ? AppImage(
                                    imageUrl: provider.utilisateur!.photoProfil!,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 35,
                                    color: SDColors.primary700,
                                  ),
                          ),
                        ),
                        // Badge vérifié
                        if (provider.verifier == true)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(SDSpacing.xxxs),
                              decoration: BoxDecoration(
                                color: SDColors.primary700,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified,
                                color: SDColors.white,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: SDSpacing.sm),
                    // Nom et service
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.utilisateur?.fullName ?? 'Prestataire',
                            style: SDTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: SDColors.neutral900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: SDSpacing.xxxs),
                          Text(
                            provider.service?.nomservice ?? 'Service',
                            style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Bouton d'action
                    Container(
                      padding: EdgeInsets.all(SDSpacing.xs),
                      decoration: BoxDecoration(
                        color: SDColors.primary700,
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: SDColors.primary700.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: SDColors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SDSpacing.sm),
                // Localisation
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: SDColors.primary700,
                    ),
                    SizedBox(width: SDSpacing.xxxs),
                    Expanded(
                      child: Text(
                        provider.localisation ?? 'Localisation non disponible',
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SDSpacing.xs),
                // Note et expérience
                Row(
                  children: [
                    // Note
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: SDSpacing.xs, vertical: SDSpacing.xxxs),
                      decoration: BoxDecoration(
                        color: SDColors.warning50,
                        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: SDColors.warning600,
                          ),
                          SizedBox(width: SDSpacing.xxxs),
                          Text(
                            '${provider.note ?? 'N/A'}/5',
                            style: SDTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: SDColors.warning700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: SDSpacing.xs),
                    // Expérience
                    if (provider.anneeExperience != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SDSpacing.xs, vertical: SDSpacing.xxxs),
                        decoration: BoxDecoration(
                          color: SDColors.primary700.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.work,
                              size: 14,
                              color: SDColors.primary700,
                            ),
                            SizedBox(width: SDSpacing.xxxs),
                            Text(
                              '${provider.anneeExperience} ans',
                              style: SDTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: SDColors.primary700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
