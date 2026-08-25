import 'package:flutter/material.dart';
import '../../../../data/models/prestataire.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../data/utils/media_url.dart';
import '../utils/navigation_helper.dart';
import '../../../../design_system/design_system.dart';

class ProviderPopup extends StatelessWidget {
  final dynamic provider; // Peut être Prestataire ou Map
  final VoidCallback onClose;

  const ProviderPopup({
    Key? key,
    required this.provider,
    required this.onClose,
  }) : super(key: key);

  // Helper pour extraire l'ID du prestataire
  String _getProviderId() {
    if (provider is Prestataire) {
      return (provider as Prestataire).idprestataire;
    } else if (provider is Map<String, dynamic>) {
      return provider['_id']?.toString() ?? provider['idprestataire']?.toString() ?? '';
    }
    return '';
  }

  // Helper pour extraire toutes les données du prestataire pour le cache
  Map<String, dynamic>? _getProviderDataForCache() {
    if (provider is Prestataire) {
      return (provider as Prestataire).toJson();
    } else if (provider is Map<String, dynamic>) {
      return provider;
    }
    return null;
  }

  // Helper pour extraire les données du prestataire de manière sécurisée
  Map<String, dynamic> _getProviderData() {
    if (provider is Prestataire) {
      final p = provider as Prestataire;
      return {
        'fullName': joinPersonName(
          prenom: p.utilisateur.prenom,
          nom: p.utilisateur.nom,
          fallback: 'Prestataire',
        ),
        'serviceName':
            cleanDisplayPart(p.service.nomservice) ?? 'Service',
        'categoryName':
            cleanDisplayPart(p.service.categorie?.nomcategorie) ?? '',
        'description': cleanDisplayPart(p.description) ?? 'Non renseigné',
        'note': cleanDisplayPart(p.note),
        'isVerified': p.verifier,
        'photoProfil': providerPhotoUrl(
          selfie: p.selfie,
          photoProfil: p.utilisateur.photoProfil,
        ),
        'price': formatOptionalPrice(
              p.prixprestataire,
              suffix: 'FCFA',
              perUnit: '/h',
            ) ??
            'Sur devis',
        'location':
            cleanDisplayPart(p.localisation) ?? 'Adresse non renseignée',
      };
    } else if (provider is Map<String, dynamic>) {
      final utilisateur = provider['utilisateur'] as Map<String, dynamic>?;
      final service = provider['service'] as Map<String, dynamic>?;
      return {
        'fullName': utilisateur != null
            ? personNameFromMap(utilisateur, fallback: 'Prestataire')
            : 'Prestataire',
        'serviceName':
            cleanDisplayPart(service?['nomservice']) ?? 'Service',
        'categoryName':
            cleanDisplayPart(service?['categorie']?['nomcategorie']) ?? '',
        'description':
            cleanDisplayPart(provider['description']) ?? 'Non renseigné',
        'note': cleanDisplayPart(provider['note']),
        'isVerified': provider['verifier'] == true,
        'photoProfil': providerPhotoUrl(
          selfie: provider['selfie']?.toString(),
          photoProfil: utilisateur?['photoProfil']?.toString(),
          utilisateurMap: utilisateur,
          prestataireMap: provider,
        ),
        'price': formatOptionalPrice(
              provider['prixprestataire'],
              suffix: 'FCFA',
              perUnit: '/h',
            ) ??
            'Sur devis',
        'location':
            cleanDisplayPart(provider['localisation']) ?? 'Adresse non renseignée',
      };
    }
    // Fallback par défaut
    return {
      'fullName': 'Prestataire',
      'serviceName': 'Service',
      'categoryName': '',
      'description': 'Non renseigné',
      'note': null,
      'isVerified': false,
      'photoProfil': null,
      'price': 'Sur devis',
      'location': 'Adresse non renseignée',
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = _getProviderData();
    
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap:
                  () {}, // Empêcher la fermeture quand on clique sur le popup
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SDColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SDEntityCard(
                            width: null,
                            type: SDEntityCardType.provider,
                            title: data['fullName']?.toString() ?? 'Prestataire',
                            subtitle: data['serviceName']?.toString() ?? 'Service',
                            fallbackIcon: Icons.handyman_rounded,
                            imageUrl: normalizeMediaUrl(
                              data['photoProfil']?.toString(),
                            ),
                            ratingText: data['note'] != null
                                ? '${data['note']}/5'
                                : 'Pas encore noté',
                            metaText: data['isVerified'] == true
                                ? '${data['location'] ?? ''} • ✓ Identité vérifiée'
                                : (data['location']?.toString() ?? ''),
                            statusText: 'Disponible maintenant',
                            priceText: data['price']?.toString(),
                            ctaLabel: 'Voir profil',
                            onTap: () {
                              final providerId = _getProviderId();
                              if (providerId.isNotEmpty) {
                                NavigationHelper.navigateToProviderProfile(
                                  context,
                                  providerId: providerId,
                                  providerData: _getProviderDataForCache(),
                                );
                              }
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Description du service',
                        style: SDTypography.titleSmall.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['description']?.toString() ?? '',
                      style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fonction de contact à implémenter')),
                              );
                            },
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Contacter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SDColors.primary600,
                              foregroundColor: SDColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              onClose();
                              final providerId = _getProviderId();
                              if (providerId.isNotEmpty) {
                                NavigationHelper.navigateToProviderProfile(
                                  context,
                                  providerId: providerId,
                                  providerData: _getProviderDataForCache(),
                                );
                              }
                            },
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Text('Détails'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SDColors.info600,
                              foregroundColor: SDColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}





