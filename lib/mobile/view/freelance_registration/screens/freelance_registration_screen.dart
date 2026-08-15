import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageBlocM.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageEventM.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageStateM.dart';
import 'package:sdealsmobile/mobile/view/freelance_registration/screens/freelance_form_screen.dart';
import '../../../../design_system/design_system.dart';

class FreelanceRegistrationScreen extends StatelessWidget {
  const FreelanceRegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FreelancePageBlocM()
        ..add(LoadCategorieDataM())
        ..add(LoadFreelancersEvent()),
      child: _FreelanceRegistrationContent(),
    );
  }
}

class _FreelanceRegistrationContent extends StatefulWidget {
  @override
  State<_FreelanceRegistrationContent> createState() => _FreelanceRegistrationContentState();
}

class _FreelanceRegistrationContentState extends State<_FreelanceRegistrationContent> {
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedServices = {};
  int _estimatedHoursPerWeek = 20; // Valeur par défaut
  
  // Icônes pour chaque catégorie
  final Map<String, IconData> categoryIcons = {
    'Développement': Icons.code,
    'Design': Icons.brush,
    'Rédaction': Icons.edit_note,
    'Marketing': Icons.trending_up,
    'Traduction': Icons.translate,
    'Photo': Icons.camera_alt,
    'Audio': Icons.headphones,
    'Vidéo': Icons.videocam,
    'Conseil': Icons.lightbulb,
    'Autre': Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(
        title: 'Devenir Freelance',
      ),
      body: BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state.error != null) {
            return Center(child: Text('Erreur: ${state.error}'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(),
                _buildCategoriesSection(state.listItems ?? []),
                _buildPopularServicesSection(state),
                _buildRevenueSimulator(),
                _buildCallToActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      color: SDColors.primary700,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rejoignez notre communauté de freelances et vendez vos compétences',
            style: SDTypography.displaySmall,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('1,250+', 'freelances actifs'),
              _buildStatCard('180,000 FCFA', 'revenus moyens/mois'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: SDTypography.titleLarge.copyWith(color: SDColors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: SDTypography.bodySmall.copyWith(color: SDColors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(List<dynamic> categories) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez votre domaine',
            style: SDTypography.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sélectionnez une ou plusieurs catégories qui correspondent à vos compétences',
            style: SDTypography.bodyMedium,
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategories.contains(category.nomcategorie);
              final icon = categoryIcons[category.nomcategorie] ?? Icons.category;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCategories.remove(category.nomcategorie);
                    } else {
                      _selectedCategories.add(category.nomcategorie);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? SDColors.primary100 : SDColors.neutral100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? SDColors.primary700 : SDColors.neutral300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? SDColors.primary700 : SDColors.neutral700,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.nomcategorie,
                        style: SDTypography.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? SDColors.primary700 : SDColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '15 services • ~5,000 FCFA/h',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServicesSection(FreelancePageStateM state) {
    // Pour simuler des services populaires par catégorie
    final List<Map<String, dynamic>> mockServices = [
      {'nom': 'Création de logo', 'categorie': 'Design', 'demande': 'Élevée', 'tarif': '15,000 FCFA'},
      {'nom': 'Développement mobile', 'categorie': 'Développement', 'demande': 'Très élevée', 'tarif': '25,000 FCFA'},
      {'nom': 'Rédaction web SEO', 'categorie': 'Rédaction', 'demande': 'Élevée', 'tarif': '10,000 FCFA'},
      {'nom': 'Montage vidéo', 'categorie': 'Vidéo', 'demande': 'Moyenne', 'tarif': '20,000 FCFA'},
      {'nom': 'Traduction Français-Anglais', 'categorie': 'Traduction', 'demande': 'Élevée', 'tarif': '8,000 FCFA'},
      {'nom': 'Gestion réseaux sociaux', 'categorie': 'Marketing', 'demande': 'Très élevée', 'tarif': '30,000 FCFA'},
    ];
    
    // Filtrer les services pertinents pour les catégories sélectionnées
    List<Map<String, dynamic>> relevantServices = _selectedCategories.isEmpty
        ? mockServices
        : mockServices.where((service) => _selectedCategories.contains(service['categorie'])).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services populaires',
            style: SDTypography.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategories.isEmpty
                ? 'Sélectionnez une catégorie pour voir les services les plus demandés'
                : 'Les services les plus demandés dans ${_selectedCategories.join(", ")}',
            style: SDTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: relevantServices.length,
            itemBuilder: (context, index) {
              final service = relevantServices[index];
              final isSelected = _selectedServices.contains(service['nom']);
              
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedServices.add(service['nom']);
                    } else {
                      _selectedServices.remove(service['nom']);
                    }
                  });
                },
                title: Text(service['nom']),
                subtitle: Text('${service['categorie']} • Demande: ${service['demande']}'),
                secondary: Text(
                  service['tarif'],
                  style: SDTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: SDColors.primary600,
                  ),
                ),
                activeColor: SDColors.primary700,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSimulator() {
    // Calculer les revenus estimés
    final int minRevenue = _selectedServices.length * 15000;
    final int maxRevenue = _selectedServices.length * 30000;
    
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.primary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate, color: SDColors.secondary700),
              const SizedBox(width: 8),
              const Text(
                'Simulateur de revenus',
                style: SDTypography.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Avec ${_selectedServices.length} service${_selectedServices.length > 1 ? 's' : ''} sélectionné${_selectedServices.length > 1 ? 's' : ''} dans ${_selectedCategories.length} catégorie${_selectedCategories.length > 1 ? 's' : ''}:',
            style: SDTypography.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Revenus estimés: ${minRevenue.toString()} - ${maxRevenue.toString()} FCFA/mois',
            style: SDTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: SDColors.secondary500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Basé sur $_estimatedHoursPerWeek heures de travail/semaine',
            style: SDTypography.bodySmall.copyWith(
              color: SDColors.neutral700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Temps de travail hebdomadaire estimé:',
            style: SDTypography.bodySmall.copyWith(
              color: SDColors.neutral700,
            ),
          ),
          Slider(
            value: _estimatedHoursPerWeek.toDouble(),
            min: 5,
            max: 40,
            divisions: 7,
            label: '$_estimatedHoursPerWeek h',
            activeColor: SDColors.secondary500,
            onChanged: (value) {
              setState(() {
                _estimatedHoursPerWeek = value.toInt();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCallToActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              // Rediriger vers le formulaire d'inscription
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FreelanceFormScreen(
                    preSelectedCategories: _selectedCategories,
                    preSelectedServices: _selectedServices,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SDColors.primary700,
              foregroundColor: SDColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Commencer mon inscription freelance',
              style: SDTypography.titleMedium,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              // Afficher plus d'informations sur les conditions
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Conditions pour devenir freelance'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('• Être âgé d\'au moins 18 ans'),
                        const SizedBox(height: 8),
                        const Text('• Avoir une pièce d\'identité valide'),
                        const SizedBox(height: 8),
                        const Text('• Disposer d\'un compte bancaire mobile'),
                        const SizedBox(height: 8),
                        const Text('• Avoir des compétences vérifiables'),
                        const SizedBox(height: 8),
                        const Text('• Respecter la charte de qualité Soutrali'),
                        const SizedBox(height: 16),
                        const Text(
                          'Les freelances sur Soutrali sont soumis à une commission de 10% sur les transactions réalisées via la plateforme.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: SDColors.primary700,
              side: const BorderSide(color: SDColors.primary700),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'En savoir plus sur les conditions',
              style: SDTypography.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
