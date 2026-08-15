import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../jobpageblocm/jobPageBlocM.dart';
import '../jobpageblocm/jobPageEventM.dart';
import '../jobpageblocm/jobPageStateM.dart';
import '../utils/navigation_helper.dart';
import '../../common/widgets/skeleton_loader.dart';
import '../../../../data/utils/media_url.dart';
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
    final fullName = provider.utilisateur?.fullName ?? 'Prestataire';
    final serviceName = provider.service?.nomservice ?? 'Service';
    final note = provider.note?.toString() ?? 'N/A';
    final location = provider.localisation?.toString() ?? 'Localisation';
    final image = providerPhotoUrl(
      selfie: provider.selfie?.toString(),
      photoProfil: provider.utilisateur?.photoProfil?.toString(),
    );
    final isVerified = provider.verifier == true;
    final exp = provider.anneeExperience?.toString();
    final price = provider.prixprestataire != null
        ? '${provider.prixprestataire.toString()} FCFA /h'
        : null;

    return Padding(
      padding: EdgeInsets.only(bottom: SDSpacing.sm, left: SDSpacing.sm, right: SDSpacing.sm),
      child: SDEntityCard(
        type: SDEntityCardType.provider,
        title: fullName,
        subtitle: serviceName,
        fallbackIcon: Icons.handyman_rounded,
        imageUrl: image,
        ratingText: '$note/5',
        metaText: isVerified
            ? '$location • Vérifié${exp != null ? ' • $exp ans' : ''}'
            : '$location${exp != null ? ' • $exp ans' : ''}',
        statusText: 'Disponible',
        priceText: price,
        ctaLabel: 'Voir profil',
        onTap: () {
          NavigationHelper.navigateToProviderProfile(
            context,
            providerId: provider.idprestataire,
            providerData: provider.toJson(),
          );
        },
      ),
    );
  }
}
