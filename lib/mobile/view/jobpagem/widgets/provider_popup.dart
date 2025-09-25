import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProviderPopup extends StatelessWidget {
  final dynamic provider;
  final VoidCallback onClose;

  const ProviderPopup({
    Key? key,
    required this.provider,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                              child: provider.utilisateur?.photo != null
                                  ? Image.network(
                                      provider.utilisateur!.photo!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.green.shade100,
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.green,
                                            size: 30,
                                          ),
                                        );
                                      },
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
                                  provider.utilisateur?.fullName ??
                                      'Prestataire',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  provider.service?.nomservice ?? 'Service',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      provider.note?.toString() ?? '4.5',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (provider.verifier == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
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
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
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
                            provider.description ??
                                'Service professionnel de qualité. Contactez-moi pour plus d\'informations.',
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
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'À ${_calculateDistance()} km',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.access_time,
                                color: Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Disponible maintenant',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
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
                                // Naviguer vers l'écran de détail
                                context.push('/provider-detail',
                                    extra: provider);
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
