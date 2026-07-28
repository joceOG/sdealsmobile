import 'package:flutter/material.dart';
import '../../../../data/models/prestataire.dart';
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
        'fullName': p.utilisateur.fullName,
        'serviceName': p.service.nomservice,
        'categoryName': p.service.categorie?.nomcategorie ?? '',
        'description': p.description,
        'note': p.note ?? '4.5',
        'isVerified': p.verifier,
        'photoProfil': p.utilisateur.photoProfil,
        'price': '${p.prixprestataire.toStringAsFixed(0)} FCFA/h',
        'location': p.localisation,
      };
    } else if (provider is Map<String, dynamic>) {
      final utilisateur = provider['utilisateur'] as Map<String, dynamic>?;
      final service = provider['service'] as Map<String, dynamic>?;
      return {
        'fullName': utilisateur != null 
          ? '${utilisateur['prenom'] ?? ''} ${utilisateur['nom'] ?? ''}'.trim()
          : 'Prestataire',
        'serviceName': service?['nomservice'] ?? 'Service',
        'categoryName': service?['categorie']?['nomcategorie'] ?? '',
        'description': provider['description'] ?? 'Service professionnel de qualité.',
        'note': provider['note']?.toString() ?? '4.5',
        'isVerified': provider['verifier'] == true,
        'photoProfil': utilisateur?['photoProfil'],
        'price': '${(provider['prixprestataire'] ?? 0).toString()} FCFA/h',
        'location': provider['localisation'] ?? 'Localisation',
      };
    }
    // Fallback par défaut
    return {
      'fullName': 'Prestataire',
      'serviceName': 'Service',
      'categoryName': '',
      'description': 'Service professionnel de qualité.',
      'note': '4.5',
      'isVerified': false,
      'photoProfil': null,
      'price': '0 FCFA/h',
      'location': 'Localisation',
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
                            type: SDEntityCardType.provider,
                            title: data['fullName']?.toString() ?? 'Prestataire',
                            subtitle: data['serviceName']?.toString() ?? 'Service',
                            fallbackIcon: Icons.handyman_rounded,
                            imageUrl: (data['photoProfil']?.toString().startsWith('http') ?? false)
                                ? data['photoProfil']?.toString()
                                : null,
                            ratingText: '${data['note'] ?? 'N/A'}/5',
                            metaText: data['isVerified'] == true
                                ? '${data['location'] ?? ''} • Vérifié'
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





