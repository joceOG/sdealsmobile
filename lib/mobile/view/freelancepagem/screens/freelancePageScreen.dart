import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageStateM.dart';
import 'package:sdealsmobile/mobile/view/freelance_registration/screens/freelance_registration_screen.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';
import '../freelancepageblocm/freelancePageBlocM.dart';
import '../freelancepageblocm/freelancePageEventM.dart';
import '../models/freelance_model.dart';
import 'freelance_details_screen.dart';

// Design System
import '../../../../design_system/colors.dart';
import '../../../../design_system/typography.dart';
import '../../../../design_system/spacing.dart';

// Widget wrapper qui fournit le BLoC à toute la page
class FreelancePageScreen extends StatelessWidget {
  final List<dynamic> categories;

  const FreelancePageScreen({Key? key, this.categories = const []})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FreelancePageBlocM()
        // Toujours charger les catégories depuis l'API pour l'instant
        // Les catégories passées en paramètre pourront être utilisées à l'avenir
        ..add(LoadCategorieDataM())
        ..add(LoadFreelancersEvent())
        ..add(LoadServicesEvent()),
      child: _FreelancePageScreenContent(),
    );
  }
}

// Contenu réel de la page
class _FreelancePageScreenContent extends StatefulWidget {
  const _FreelancePageScreenContent({Key? key}) : super(key: key);

  @override
  State<_FreelancePageScreenContent> createState() =>
      _FreelancePageScreenContentState();
}

class _FreelancePageScreenContentState
    extends State<_FreelancePageScreenContent> {
  // Controller pour la barre de recherche
  final TextEditingController _searchController = TextEditingController();

  // Couleurs pour les catégories dynamiques
  final List<Color> _categoryColors = [
    SDColors.info500,
    SDColors.info600,
    SDColors.secondary500,
    SDColors.primary600,
    SDColors.primary500,
    SDColors.error500,
    SDColors.success500,
    SDColors.warning500,
    SDColors.secondary400,
    SDColors.info500,
    SDColors.neutral700,
    SDColors.success600,
  ];

  // Icônes pour les catégories dynamiques
  final List<IconData> _categoryIcons = [
    Icons.computer,
    Icons.brush,
    Icons.edit_document,
    Icons.trending_up,
    Icons.videocam,
    Icons.translate,
    Icons.camera_alt,
    Icons.build,
    Icons.mic,
    Icons.school,
    Icons.support_agent,
    Icons.paid,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }



  // Construction des filtres de catégories
  Widget _buildCategoryFilters() {
    // Lire la catégorie sélectionnée depuis le BLoC
    final bloc = context.watch<FreelancePageBlocM>();
    final selectedCategory = bloc.state.selectedCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SDSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filtrer par catégorie',
              style: SDTypography.titleSmall.copyWith(
                color: SDColors.neutral900,
              ),
            ),
            // Bouton pour réinitialiser les filtres
            if (selectedCategory != null || bloc.state.searchQuery.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  bloc.add(ClearFiltersEvent());
                },
                icon: Icon(Icons.refresh, size: 16, color: SDColors.neutral500),
                label: Text('Réinitialiser', style: SDTypography.labelMedium.copyWith(color: SDColors.neutral500)),
                style: TextButton.styleFrom(foregroundColor: SDColors.neutral500),
              ),
          ],
        ),
        SizedBox(height: SDSpacing.xs),
        SizedBox(
          height: 40,
          child: BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
            builder: (context, state) {
              // Ajouter une catégorie "Tous" au début
              final allCategories = [
                {'id': 'all', 'name': 'Tous'},
                ...state.listItems
                        ?.map((cat) =>
                            {'id': cat.idcategorie, 'name': cat.nomcategorie})
                        .toList() ??
                    []
              ];

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allCategories.length,
                itemBuilder: (context, index) {
                  final category = allCategories[index];
                  final categoryName = category['name'] as String;
                  final isSelected = selectedCategory == categoryName;

                  // Obtenir une couleur et une icône stables pour cette catégorie
                  final colorIndex = index % _categoryColors.length;
                  final iconIndex = index % _categoryIcons.length;
                  final categoryColor = _categoryColors[colorIndex];
                  final categoryIcon =
                      index == 0 ? Icons.apps : _categoryIcons[iconIndex];

                  return GestureDetector(
                    onTap: () {
                      // Envoyer l'événement au BLoC pour le filtrage
                      bloc.add(FilterByCategoryEvent(
                          isSelected ? null : categoryName));
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.only(right: SDSpacing.xxs),
                      padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? categoryColor : SDColors.neutral200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? categoryColor : Colors.transparent,
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: categoryColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            categoryIcon,
                            size: 16,
                            color: isSelected ? SDColors.white : categoryColor,
                          ),
                          SizedBox(width: SDSpacing.xxxs),
                          Text(
                            categoryName,
                            style: SDTypography.labelSmall.copyWith(
                              color: isSelected ? SDColors.white : SDColors.neutral900,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }



  // Construction de la section des résultats filtrés
  Widget _buildFilterResultsSection(FreelancePageStateM state) {
    final filteredFreelancers = state.filteredFreelancers;

    if (state.searchQuery.isNotEmpty || state.selectedCategory != null) {
      // Afficher un message si aucun résultat
      if (filteredFreelancers.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SDSpacing.lg),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 64, color: SDColors.neutral400),
                SizedBox(height: SDSpacing.sm),
                Text(
                  'Aucun freelance trouvé pour "${state.searchQuery}"${state.selectedCategory != null ? ' dans ${state.selectedCategory}' : ''}',
                  textAlign: TextAlign.center,
                  style: SDTypography.bodyLarge.copyWith(color: SDColors.neutral500),
                ),
              ],
            ),
          ),
        );
      }

      // Afficher les résultats de recherche
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SDSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Résultats (${filteredFreelancers.length})',
                style: SDTypography.titleMedium.copyWith(
                  color: SDColors.neutral900,
                ),
              ),
              IconButton(
                icon: Icon(Icons.swap_vert, color: SDColors.neutral700),
                onPressed: () {
                  // Ici on pourrait ajouter une fonction de tri
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tri non implémenté', style: SDTypography.bodyMedium.copyWith(color: SDColors.white))),
                  );
                },
                tooltip: 'Trier les résultats',
              ),
            ],
          ),
          SizedBox(height: SDSpacing.sm),
          _buildFilteredFreelancersList(filteredFreelancers),
        ],
      );
    }

    // Si pas de filtre actif, ne rien afficher dans cette section
    return const SizedBox.shrink();
  }

  // Liste des freelancers filtrés avec animation
  Widget _buildFilteredFreelancersList(List<FreelanceModel> freelancers) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: ListView.builder(
        key: ValueKey<int>(freelancers.length), // Important pour l'animation
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: freelancers.length,
        itemBuilder: (context, index) {
          final freelancer = freelancers[index];
          // Animation pour chaque élément apparaissant avec un délai basé sur l'index
          return AnimatedBuilder(
            animation: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: ModalRoute.of(context)?.animation ??
                    const AlwaysStoppedAnimation(1),
                curve: Interval((index / 10).clamp(0, 1), 1,
                    curve: Curves.easeOut),
              ),
            ),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0,
                    (1 - (ModalRoute.of(context)?.animation?.value ?? 1)) * 50),
                child: Opacity(
                  opacity: (ModalRoute.of(context)?.animation?.value ?? 1),
                  child: child,
                ),
              );
            },
            child: _buildFreelancerCard(freelancer),
          );
        },
      ),
    );
  }

  // Carte de freelancer améliorée pour l'affichage dans les résultats
  Widget _buildFreelancerCard(FreelanceModel freelancer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigation vers le détail du freelancer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FreelanceDetailsScreen(freelance: freelancer),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                children: [
                  Hero(
                    tag: 'freelancer-${freelancer.id}',
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(freelancer.imagePath),
                    ),
                  ),
                  if (freelancer.isTopRated)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Top',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            freelancer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${freelancer.hourlyRate.toStringAsFixed(0)} €/h',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      freelancer.job,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    // Compétences
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: freelancer.skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              Text(skill, style: SDTypography.labelSmall),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: SDSpacing.xxs),
                    // Note et nombre de projets
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: SDColors.warning700),
                        SizedBox(width: SDSpacing.xxxs),
                        Text(
                          freelancer.rating.toString(),
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.warning700,
                          ),
                        ),
                        SizedBox(width: SDSpacing.sm),
                        Icon(Icons.check_circle_outline,
                            size: 16, color: SDColors.success700),
                        SizedBox(width: SDSpacing.xxxs),
                        Text(
                          '${freelancer.completedJobs} projets',
                          style: SDTypography.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => FreelancePageBlocM()
                    ..add(LoadCategorieDataM())
                    ..add(LoadFreelancersEvent()),
                  child: const FreelanceRegistrationScreen(),
                ),
              ),
            );
        },
        backgroundColor: SDColors.primary600,
        child: Icon(Icons.person_add, color: SDColors.white),
        tooltip: 'Devenir Freelance',
      ),
      body: BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
        builder: (context, state) {
          if (state.isLoading == true) {
            return Center(
                child: CircularProgressIndicator(color: SDColors.primary600));
          }

          return CustomScrollView(
            slivers: [
              // Banner promo sticky
              _buildPromoStickyBanner(context),

              // Chips SoutraPay + IA
              _buildToolChipsSliver(context),

              // Contenu principal
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: SDSpacing.lg),
                      // Hero Search Bar (Nouveau)
                      _buildHeroSearchBar(),

                      // Filtres par catégorie
                      _buildCategoryFilters(),

                      // Résultats filtrés - nouvelle section
                      _buildFilterResultsSection(state),

                      SizedBox(height: SDSpacing.xl),
                      // Liste horizontale de freelances
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Freelances populaires',
                            style: SDTypography.titleMedium.copyWith(
                              color: SDColors.neutral900,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Voir plus',
                              style: SDTypography.bodyMedium.copyWith(
                                color: SDColors.primary600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SDSpacing.sm),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.freelancers
                              .where((f) => f.isTopRated)
                              .take(5)
                              .length,
                          itemBuilder: (context, index) {
                            final topFreelancers = state.freelancers
                                .where((f) => f.isTopRated)
                                .toList();
                            if (index >= topFreelancers.length) {
                              return const SizedBox.shrink();
                            }
                            final freelancer = topFreelancers[index];
                            return _buildSimpleFreelanceCard(
                              freelancer.name,
                              freelancer.job,
                              freelancer.imagePath,
                              freelancer: freelancer,
                              isTop: true,
                              avatarSize: 48,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Section À la une
                      const Text(
                        'À la une',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFeaturedCard(state),
                      const SizedBox(height: 40),
                      // Nouveaux freelances
                      const Text(
                        'Nouveaux freelances',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.freelancers
                              .where((f) => f.isNew)
                              .take(5)
                              .length,
                          itemBuilder: (context, index) {
                            final newFreelancers = state.freelancers
                                .where((f) => f.isNew)
                                .toList();
                            if (index >= newFreelancers.length) {
                              return const SizedBox.shrink();
                            }
                            final freelancer = newFreelancers[index];
                            return _buildSimpleFreelanceCard(
                              freelancer.name,
                              freelancer.job,
                              freelancer.imagePath,
                              freelancer: freelancer,
                              avatarSize: 40,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // 🛠️ Services populaires
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '🛠️ Services populaires',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Navigation vers liste complète
                            },
                            icon: Icon(Icons.arrow_forward, size: 14, color: SDColors.primary600),
                            label: Text('Tout', style: SDTypography.labelSmall),
                            style: TextButton.styleFrom(
                              foregroundColor: SDColors.primary600,
                              padding: SDSpacing.chipPadding,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
                        builder: (context, state) {
                          if (state.isLoadingServices) {
                            return const SizedBox(
                              height: 150,
                              child: Center(
                                child: CircularProgressIndicator(color: Colors.green),
                              ),
                            );
                          }
                          if (state.servicesError.isNotEmpty) {
                            return SizedBox(
                              height: 150,
                              child: Center(
                                child: Text(
                                  'Erreur chargement services',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          }
                          if (state.services.isEmpty) {
                            return const SizedBox(
                              height: 150,
                              child: Center(
                                child: Text(
                                  'Aucun service disponible',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          }
                          
                          return SizedBox(
                            height: 150,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.services.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final service = state.services[index];
                                return _buildServiceCard(service);
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      
                      // 🔄 SECTION DYNAMIQUE (Skills, Top Talents, Stats)
                      BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
                        builder: (context, state) {
                          // Calculs des données dérivées
                          final skills = state.freelancers
                              .expand((f) => f.skills)
                              .where((s) => s.isNotEmpty)
                              .toSet()
                              .toList()
                            ..shuffle(); // Mélange pour la variété
                          final displaySkills = skills.take(12).toList();
                          
                          final topFreelancers = state.freelancers
                              .where((f) => f.rating >= 4.5 || f.isTopRated)
                              .take(5)
                              .toList();
                              
                          final totalFreelancers = state.freelancers.length;
                          final totalProjects = state.freelancers.isEmpty ? 0 : state.freelancers.fold(0, (sum, f) => sum + f.completedJobs);
                          final avgRating = state.freelancers.isEmpty 
                              ? 0.0 
                              : (state.freelancers.fold(0.0, (sum, f) => sum + f.rating) / state.freelancers.length);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1️⃣ SKILLS CLOUD (Compétences en vogue)
                              if (displaySkills.isNotEmpty) ...[
                                const Text(
                                  '🔥 Compétences en vogue',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: displaySkills
                                      .map((skill) => _buildSkillChip(skill))
                                      .toList(),
                                ),
                                const SizedBox(height: 40),
                              ],

                              // 2️⃣ TOP TALENTS (L'Élite Freelance)
                              if (topFreelancers.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      '🏆 L\'Élite Freelance',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text('Voir le classement',
                                          style: TextStyle(color: Colors.green)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 220,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: topFreelancers.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 16),
                                    itemBuilder: (context, index) =>
                                        _buildTopTalentCard(topFreelancers[index]),
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],

                              // 3️⃣ LIVE STATS (Impact en temps réel)
                              if (totalFreelancers > 0) ...[
                                const Text(
                                  '📈 Impact en temps réel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 24, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                    border: Border.all(
                                        color: Colors.green.withOpacity(0.1)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildLiveStatItem(
                                          'Experts',
                                          '${totalFreelancers}+',
                                          Icons.verified_user,
                                          Colors.blue),
                                      Container(
                                          height: 40,
                                          width: 1,
                                          color: Colors.grey.shade200),
                                      _buildLiveStatItem(
                                          'Missions',
                                          '${totalProjects}+',
                                          Icons.rocket_launch,
                                          Colors.orange),
                                      Container(
                                          height: 40,
                                          width: 1,
                                          color: Colors.grey.shade200),
                                      _buildLiveStatItem(
                                          'Satisfaction',
                                          avgRating.toStringAsFixed(1),
                                          Icons.star,
                                          Colors.green),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      // Call-to-action secondaire
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 12),
                            elevation: 3,
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.add_business,
                              color: Colors.white),
                          label: const Text(
                            'Publier une mission',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Pourquoi choisir un freelance ?
                      const Text(
                        'Pourquoi choisir un freelance ?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildWhyFreelance(),
                      const SizedBox(height: 40),
                      // Bannière promotionnelle
                      _buildPromoBanner(),
                      const SizedBox(height: 32),
                      // Bouton d'action
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            elevation: 4,
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.people, color: Colors.white),
                          label: const Text(
                            'Voir tous les freelances',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80), // Espace final pour scroll
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🎯 NOUVEAU : Hero Search Bar (Adapté de JobPage)
  Widget _buildHeroSearchBar() {
    return Container(
      padding: SDSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SDColors.primary600,
            SDColors.primary500,
          ],
        ),
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: SDColors.primary600.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👨‍💻 Talents Freelance',
            style: SDTypography.titleSmall.copyWith(
              color: SDColors.white,
            ),
          ),
          SizedBox(height: SDSpacing.xxs),
          Text(
            'Trouvez l\'expert idéal',
            style: SDTypography.displaySmall.copyWith(
              color: SDColors.white,
            ),
          ),
          SizedBox(height: SDSpacing.md),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: SDColors.white,
              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
              boxShadow: [
                BoxShadow(
                  color: SDColors.neutral900.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              readOnly: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchPageScreenM(initialIndex: 2),
                  ),
                );
              },
              decoration: InputDecoration(
                hintText: 'Rechercher (ex: Logo, Site Web...)',
                hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
                prefixIcon: Icon(Icons.search, color: SDColors.primary600),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: SDSpacing.sm, vertical: SDSpacing.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFreelanceCard(String name, String job, String imagePath,
      {bool isTop = false,
      double avatarSize = 40,
      FreelanceModel? freelancer}) {
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: GestureDetector(
        onTap: () {
          if (freelancer != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FreelanceDetailsScreen(freelance: freelancer),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.green.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Stack(
                children: [
                  CircleAvatar(
                    radius: avatarSize,
                    backgroundImage: AssetImage(imagePath),
                  ),
                  if (isTop)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Top',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                job,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(FreelancePageStateM state) {
    // Récupérer le premier freelance "featured" ou le mieux noté
    final featuredFreelancer = state.freelancers.isNotEmpty
        ? (state.freelancers.where((f) => f.isFeatured).isNotEmpty
            ? state.freelancers.firstWhere((f) => f.isFeatured)
            : state.freelancers.reduce((a, b) => a.rating > b.rating ? a : b))
        : null;

    if (featuredFreelancer == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FreelanceDetailsScreen(freelance: featuredFreelancer),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)], // Vert profond -> Vif
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Décoration de fond (Cercles abstraits)
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: 20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Avatar avec Glow Premium
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: featuredFreelancer.imagePath.startsWith('http')
                          ? NetworkImage(featuredFreelancer.imagePath)
                          : AssetImage(featuredFreelancer.imagePath.isNotEmpty
                                  ? featuredFreelancer.imagePath
                                  : 'assets/profile_picture.jpg')
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Infos et CTA
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('💎 ', style: TextStyle(fontSize: 10)),
                              Text(
                                'TALENT À LA UNE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          featuredFreelancer.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          featuredFreelancer.job,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        // Bouton CTA Glassmorphism
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Voir le profil',
                                style: TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 10, color: Color(0xFF1B5E20)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(String review, String name, String imagePath) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage(imagePath),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  review,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '- ' + name,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: 100,
      height: 90,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyFreelance() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✔️ Flexibilité et réactivité',
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral900,
              )),
          SizedBox(height: SDSpacing.xxs),
          Text('✔️ Tarifs compétitifs',
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral900,
              )),
          SizedBox(height: SDSpacing.xxs),
          Text('✔️ Accès à des talents variés',
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral900,
              )),
          SizedBox(height: SDSpacing.xxs),
          Text('✔️ Collaboration directe et rapide',
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral900,
              )),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43EA5E), Color(0xFF1CBF3F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.13),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.white, size: 36),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              "Rejoignez la communauté et boostez votre activité dès aujourd'hui !",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        String selectedCategory = 'Tous';
        String selectedLocation = 'Abidjan';
        double minRating = 3;
        bool availableNow = false;
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Text('Filtrer les freelances',
                    style: SDTypography.titleMedium.copyWith(
                      color: SDColors.neutral900,
                    )),
                SizedBox(height: SDSpacing.md),
                // Métier/catégorie
                Text('Catégorie',
                    style: SDTypography.titleSmall.copyWith(
                      color: SDColors.neutral900,
                    )),
                SizedBox(height: SDSpacing.xxs),
                DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: <String>[
                    'Tous',
                    'Développement',
                    'Design',
                    'Rédaction',
                    'Photo',
                    'Traduction',
                    'Marketing'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 16),
                // Localisation
                const Text('Localisation',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedLocation,
                  isExpanded: true,
                  items: <String>[
                    'Abidjan',
                    'Bouaké',
                    'Yamoussoukro',
                    'San Pedro',
                    'Autre'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedLocation = v!),
                ),
                const SizedBox(height: 16),
                // Note minimale
                const Text('Note minimale',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Slider(
                  value: minRating,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: minRating.toStringAsFixed(1),
                  activeColor: Colors.green,
                  onChanged: (v) => setModalState(() => minRating = v),
                ),
                const SizedBox(height: 16),
                // Disponibilité
                Row(
                  children: [
                    Checkbox(
                      value: availableNow,
                      activeColor: Colors.green,
                      onChanged: (v) => setModalState(() => availableNow = v!),
                    ),
                    const Text('Disponible maintenant'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // Ici tu peux appliquer les filtres à ta recherche
                    },
                    child: const Text('Appliquer les filtres',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  // ✅ NOUVEAU : Banner promo sticky pour freelances
  Widget _buildPromoStickyBanner(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PromoStickyDelegate(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.1),
                Colors.green.withOpacity(0.15),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              bottom:
                  BorderSide(color: Colors.green.withOpacity(0.3), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.verified_user, color: Colors.green, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🚀 Trouve le freelance parfait pour ton projet !',
                  style: TextStyle(
                    color: Colors.green.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: () {
                    // TODO: Masquer le banner définitivement pour cet utilisateur
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.green,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NOUVEAU : Chips horizontales SoutraPay + IA
  Widget _buildToolChipsSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Chip SoutraPay
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/wallet'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.1),
                      Colors.green.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.4), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet,
                        color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '💳 SoutraPay',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Chip IA Assistant
            InkWell(
              onTap: () {
                // TODO: Ouvrir assistant IA pour freelances
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade300, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy,
                        color: Colors.blue.shade700, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '🤖 IA Assistant',
                      style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🛠️ NOUVEAU : Card pour afficherun Service
  Widget _buildServiceCard(service) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigation vers détail service
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.green.withOpacity(0.05),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: service.imageservice.isNotEmpty
                    ? Image.network(
                        service.imageservice,
                        width: 110,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 110,
                          height: 150,
                          color: Colors.green.withOpacity(0.1),
                          child: const Icon(Icons.image, size: 40, color: Colors.green),
                        ),
                      )
                    : Container(
                        width: 110,
                        height: 150,
                        color: Colors.green.withOpacity(0.1),
                        child: const Icon(Icons.handyman, size: 40, color: Colors.green),
                      ),
              ),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        service.nomservice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (service.categorie?.nomcategorie != null)
                        Text(
                          service.categorie!.nomcategorie,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      Text(
                        '${service.prixmoyen} FCFA/h',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🏷️ Helper : Skill Chip
  Widget _buildSkillChip(String label) {
    return Chip(
      label: Text(label, style: SDTypography.labelSmall.copyWith(color: SDColors.primary600)),
      backgroundColor: SDColors.primary50,
      side: BorderSide(color: SDColors.primary200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  // 🏆 Helper : Top Talent Card
  Widget _buildTopTalentCard(FreelanceModel freelance) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FreelanceDetailsScreen(freelance: freelance)),
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.green.shade50,
                  backgroundImage: freelance.imagePath.startsWith('http') 
                      ? NetworkImage(freelance.imagePath) 
                      : AssetImage(freelance.imagePath.isEmpty ? 'assets/profile_picture.jpg' : freelance.imagePath) as ImageProvider,
                ),
                if (freelance.isTopRated)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, color: Colors.blue, size: 18),
                    ),
                  ),
              ],
            ),
            SizedBox(height: SDSpacing.xs),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SDSpacing.xxs),
              child: Text(
                freelance.name,
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.neutral900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              freelance.job,
              style: SDTypography.labelSmall.copyWith(color: SDColors.neutral600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    freelance.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📈 Helper : Live Stat Item
  Widget _buildLiveStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ✅ NOUVEAU : Delegate pour banner sticky
class _PromoStickyDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _PromoStickyDelegate({required this.child});

  @override
  double get minExtent => 45.0;

  @override
  double get maxExtent => 45.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_PromoStickyDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
