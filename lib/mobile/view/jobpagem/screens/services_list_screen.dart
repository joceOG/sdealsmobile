import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../jobpageblocm/jobPageBlocM.dart';
import '../jobpageblocm/jobPageEventM.dart';
import '../jobpageblocm/jobPageStateM.dart';
import 'detailPageScreenM.dart';

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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Tous les Services',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: BlocBuilder<JobPageBlocM, JobPageStateM>(
          builder: (context, state) {
            if (state.isLoading2) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2E7D32),
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
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error2,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<JobPageBlocM>().add(LoadServiceDataJobM());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Réessayer'),
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
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun service disponible',
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

            return ListView.builder(
              padding: const EdgeInsets.all(16),
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
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF2E7D32).withOpacity(0.05),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image du service
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
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
                                  color: const Color(0xFF2E7D32),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF2E7D32).withOpacity(0.1),
                                child: Icon(
                                  _getServiceIcon(service.nomservice),
                                  size: 40,
                                  color: const Color(0xFF2E7D32),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            child: Icon(
                              _getServiceIcon(service.nomservice),
                              size: 40,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Informations du service
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du service
                      Text(
                        service.nomservice,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Catégorie
                      if (service.categorie?.nomcategorie != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            service.categorie!.nomcategorie,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Prix
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'À partir de ${service.prixmoyen} FCFA/h',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
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
