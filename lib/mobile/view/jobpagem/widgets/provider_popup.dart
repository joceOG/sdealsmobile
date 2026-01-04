import 'package:flutter/material.dart';
import '../../../../data/models/prestataire.dart';
import '../screens/detailPageScreenM.dart';
import '../utils/navigation_helper.dart';
import '../../common/widgets/app_image.dart';

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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête avec photo et nom
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Photo du prestataire
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: data['photoProfil'] != null
                                  ? AppImage(
                                      imageUrl: data['photoProfil'],
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.green.shade100,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.green,
                                        size: 30,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Informations du prestataire
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['fullName'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['serviceName'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      flex: 2,
                                      child: Text(
                                        data['note'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (data['isVerified'] == true)
                                      Flexible(
                                        flex: 3,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Vérifié',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Prix comme dans l'exemple immobilier
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    data['price'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Bouton fermer
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close),
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),

                    // Description du service
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description du service',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['description'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Informations supplémentaires
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.green,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                flex: 2,
                                child: Text(
                                  'À ${_calculateDistance()} km',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time,
                                color: Colors.blue,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                flex: 3,
                                child: Text(
                                  'Disponible maintenant',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Boutons d'action
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Bouton Contacter
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Implémenter la fonction de contact
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Fonction de contact à implémenter'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('Contacter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Bouton Voir détails
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                onClose(); // Fermer le popup
                                // ✅ Naviguer vers le profil complet du prestataire
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
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  String _calculateDistance() {
    // Simulation de distance (à remplacer par le vrai calcul)
    return (2.5 + (provider.hashCode % 10) * 0.5).toStringAsFixed(1);
  }
}





