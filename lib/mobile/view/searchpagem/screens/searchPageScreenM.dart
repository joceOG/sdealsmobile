import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../jobpagem/screens/detailPageScreenM.dart';
import '../../jobpagem/screens/provider_profile_screen.dart';
import '../../shoppingpagem/screens/productDetailsScreenM.dart';
import '../../shoppingpagem/shoppingpageblocm/shoppingPageStateM.dart' as shop_model;
import '../../common/widgets/empty_state_widget.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageEventM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageStateM.dart';
import '../../common/widgets/app_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../common/widgets/skeleton_loader.dart';

class SearchPageScreenM extends StatelessWidget {
  final int initialIndex;
  
  const SearchPageScreenM({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchPageBlocM(),
      child: _SearchBody(initialIndex: initialIndex),
    );
  }
}

class _SearchBody extends StatefulWidget {
  final int initialIndex;
  const _SearchBody({this.initialIndex = 0});

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounce;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialIndex); // ✅ 5 Tabs
    
    // Listen to tab changes to dismiss keyboard
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        FocusScope.of(context).unfocus();
      }
    });

    // Charger l'historique au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchPageBlocM>().add(LoadHistory());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Pour l'historique (query vide) ou les suggestions (query texte)
      // on appelle toujours FetchSuggestions.
      context.read<SearchPageBlocM>().add(FetchSuggestions(query));
      setState(() => _showSuggestions = true);
    });
  }

  void _onSubmit(String query) {
    if (query.trim().isNotEmpty) {
      context.read<SearchPageBlocM>().add(PerformGlobalSearch(query));
      setState(() => _showSuggestions = false);
      FocusScope.of(context).unfocus();
    }
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _onSubmit(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background like Facebook/Telegram
      appBar: _buildAppBar(),
      body: BlocBuilder<SearchPageBlocM, SearchPageStateM>(
        builder: (context, state) {
          if (state.isLoading) {
            return SkeletonList(
              itemCount: 5,
              itemTemplate: const SkeletonWidget.rectangular(
                width: double.infinity,
                height: 80,
              ),
            );
          }

          if (state.error.isNotEmpty) {
            return Center(child: Text('Erreur: ${state.error}'));
          }

          // Case 1: Show Suggestions OR History Overlay
          if (_showSuggestions) {
            if (state.query.isEmpty && state.history.isNotEmpty) {
               return _buildHistoryList(state.history);
            } else if (state.suggestions.isNotEmpty) {
               return _buildSuggestionsList(state.suggestions);
            }
          }

          // Case 2: Show Results (if any data exists)
          bool hasResults = state.services.isNotEmpty || 
                           state.articles.isNotEmpty || 
                           state.freelances.isNotEmpty || 
                           state.prestataires.isNotEmpty || // ✅ Check Prestas
                           state.vendeurs.isNotEmpty;

          if (hasResults) {
            return Column(
              children: [
                _buildTabBar(state.counts),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllTab(state),       // Tout
                      _buildServicesTab(state),  // Services
                      _buildFreelancesTab(state),// Freelances
                      _buildPrestatairesTab(state), // ✅ Prestataires Tab
                      _buildShopTab(state),      // Boutique
                    ],
                  ),
                ),
              ],
            );
          }

          // Case 3: Empty State / Initial View
          return _buildEmptyState();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], // ✅ Standard Theme Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Back Button (if navigation allows, otherwise Menu)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(), // Or open drawer
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                
                // Search Bar
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onSubmitted: _onSubmit,
                      onTap: () {
                         // Montrer l'historique au focus si le champ est vide
                         if (_searchController.text.isEmpty) {
                            _onSearchChanged('');
                         }
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher services, produits...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32), size: 20), // ✅ Standard Green
                        suffixIcon: _searchController.text.isNotEmpty 
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                              child: const Icon(Icons.close, color: Colors.grey, size: 18),
                            )
                          : null,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                ),
                
                // 🎛️ BUTTON FILTRE
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showFilterModal(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                    ),
                    child: const Icon(Icons.tune, color: Color(0xFF2E7D32), size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎛️ MODAL DE FILTRES
  void _showFilterModal(BuildContext context) {
    // 1️⃣ Capturer le BLoC actuel AVANT d'ouvrir le modal via le context parent
    final searchBloc = context.read<SearchPageBlocM>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // 2️⃣ Réinjecter le BLoC dans le nouveau context du modal
        return BlocProvider.value(
          value: searchBloc,
          child: Builder(
            builder: (context) => _buildFilterModalContent(context),
          ),
        );
      },
    );
  }

  Widget _buildFilterModalContent(BuildContext context) {
    final state = context.read<SearchPageBlocM>().state;
    // Variables locales pour le modal
    double localMin = state.minPrice;
    double localMax = state.maxPrice;
    final TextEditingController cityCtrl = TextEditingController(text: state.city);

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filtres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              
              // 1. Prix
              const Text('Prix (FCFA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              RangeSlider(
                values: RangeValues(localMin, localMax),
                min: 0,
                max: 1000000,
                divisions: 20,
                labels: RangeLabels('${localMin.round()}', '${localMax.round()}'),
                activeColor: const Color(0xFF2E7D32),
                onChanged: (values) {
                  setModalState(() {
                    localMin = values.start;
                    localMax = values.end;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${localMin.round()} FCFA', style: TextStyle(color: Colors.grey[600])),
                  Text('${localMax.round()} FCFA', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Ville
              const Text('Ville / Commune', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: cityCtrl,
                decoration: InputDecoration(
                  hintText: 'Ex: Cocody, Abidjan...',
                  prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Reset
                        context.read<SearchPageBlocM>().add(const UpdateFilters(minPrice: 0, maxPrice: 1000000, city: ''));
                        context.read<SearchPageBlocM>().add(PerformGlobalSearch(state.query));
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Appliquer
                        context.read<SearchPageBlocM>().add(UpdateFilters(
                          minPrice: localMin,
                          maxPrice: localMax,
                          city: cityCtrl.text,
                        ));
                         // Lancer la recherche avec les nouveaux filtres
                        context.read<SearchPageBlocM>().add(PerformGlobalSearch(state.query));
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Appliquer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar(Map<String, int> counts) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF2E7D32), // ✅ Standard Green
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF2E7D32), // ✅ Standard Green
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: [
          const Tab(text: 'Tout'),
          Tab(text: 'Services (${counts['services']})'),
          Tab(text: 'Freelances (${counts['freelances']})'),
          Tab(text: 'Presta. (${counts['prestataires']})'), // ✅ Tab Label
          Tab(text: 'Shop (${counts['articles']})'),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<String> history) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Récents", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                GestureDetector(
                  onTap: () {
                     context.read<SearchPageBlocM>().add(ClearHistory());
                  },
                  child: const Text("Effacer", style: TextStyle(color: Colors.red, fontSize: 13)),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                final item = history[index];
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.grey, size: 20),
                  title: Text(item),
                  trailing: const Icon(Icons.north_west, size: 16, color: Colors.grey),
                  onTap: () => _onSuggestionTap(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(List<String> suggestions) {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            leading: const Icon(Icons.search, color: Color(0xFF2E7D32), size: 20), // 🔍 for active search
            title: Text(suggestion),
            onTap: () => _onSuggestionTap(suggestion),
          );
        },
      ),
    );
  }

  // 🎨 EMPTY STATE (No Query / No Results)
  Widget _buildEmptyState() {
    return EmptyStateWidget(
      imagePath: 'assets/recherche_vide.png',
      title: 'Aucun résultat',
      message: 'Essayez avec d\'autres mots-clés ou filtres',
      imageSize: 180,
    );
  }

  // --- TAB: TOUT (Summary) ---
  Widget _buildAllTab(SearchPageStateM state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.services.isNotEmpty) ...[
          _buildSectionHeader('Services', 1, state.counts['services'] ?? 0),
          ...state.services.take(2).map((s) => _buildServiceCard(s)).toList(),
          const SizedBox(height: 16),
        ],
        
        if (state.freelances.isNotEmpty) ...[
          _buildSectionHeader('Freelances', 2, state.counts['freelances'] ?? 0),
          _buildHorizontalScroll(
            state.freelances.take(5).map((f) => _buildFreelanceSquare(f)).toList()
          ),
          const SizedBox(height: 16),
        ],

        if (state.prestataires.isNotEmpty) ...[
          _buildSectionHeader('Prestataires', 3, state.counts['prestataires'] ?? 0),
          _buildHorizontalScroll(
            state.prestataires.take(5).map((p) => _buildFreelanceSquare(p)).toList() 
          ),
          const SizedBox(height: 16),
        ],

        if (state.articles.isNotEmpty) ...[
          _buildSectionHeader('Boutique', 4, state.counts['articles'] ?? 0),
          _buildArticleGrid(state.articles.take(2).toList()), 
        ],
      ],
    );
  }

  // --- TAB: SERVICES ---
  Widget _buildServicesTab(SearchPageStateM state) {
    if (state.services.isEmpty) return const Center(child: Text("Aucun service trouvé"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.services.length,
      itemBuilder: (context, index) => _buildServiceCard(state.services[index]),
    );
  }

  // --- TAB: FREELANCES ---
  Widget _buildFreelancesTab(SearchPageStateM state) {
    if (state.freelances.isEmpty) return const Center(child: Text("Aucun freelance trouvé"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.freelances.length,
      itemBuilder: (context, index) => _buildFreelanceCard(state.freelances[index]),
    );
  }

  // --- TAB: PRESTATAIRES ---
  Widget _buildPrestatairesTab(SearchPageStateM state) {
    if (state.prestataires.isEmpty) return const Center(child: Text("Aucun prestataire trouvé"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.prestataires.length,
      itemBuilder: (context, index) => _buildFreelanceCard(state.prestataires[index]), // Reuse Card
    );
  }

  // --- TAB: ARTICLES ---
  Widget _buildShopTab(SearchPageStateM state) {
    if (state.articles.isEmpty) return const Center(child: Text("Aucun article trouvé"));
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: state.articles.length,
      itemBuilder: (context, index) => _buildArticleCard(state.articles[index]),
    );
  }

  // --- WIDGET HELPER METHODS ---

  Widget _buildSectionHeader(String title, int tabIndex, int count) {
    if (count == 0) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          GestureDetector(
            onTap: () => _tabController.animateTo(tabIndex),
            child: const Text('Voir tout', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)), // ✅ Standard Green
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalScroll(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children.map((c) => Padding(padding: const EdgeInsets.only(right: 12), child: c)).toList()),
    );
  }

  Widget _buildArticleGrid(List<dynamic> articles) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.75,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: articles.map((a) => _buildArticleCard(a)).toList(),
    );
  }

  // --- CARDS ---

  Widget _buildServiceCard(dynamic service) {
    // Extract properties safely
    final String name = service['nomservice'] ?? 'Service';
    final String image = service['imageservice'] ?? '';
    final int price = int.tryParse(service['prixmoyen']?.toString() ?? '0') ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AppImage(
            imageUrl: image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('À partir de $price FCFA', style: TextStyle(color: Colors.green[700])),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(
                title: name,
                image: image,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFreelanceSquare(dynamic freelance) {
    final String name = freelance['name'] ?? 'John Doe';
    final String job = freelance['job'] ?? 'Prestataire';
    final String image = freelance['imagePath'] ?? '';

    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
            child: image.isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(height: 8),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(job, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

    Widget _buildFreelanceCard(dynamic freelance) {
    final String name = freelance['name'] ?? 'John Doe';
    final String job = freelance['job'] ?? 'Prestataire';
    final String image = freelance['imagePath'] ?? '';
    final dynamic rating = freelance['rating'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
          child: image.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Text(job),
            const SizedBox(width: 8),
            const Icon(Icons.star, size: 14, color: Colors.amber),
            Text(' $rating'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderProfileScreen(
                providerId: freelance['_id'] ?? '',
                providerData: freelance,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleCard(dynamic article) {
    final String name = article['nomArticle'] ?? 'Article';
    final String image = article['photoArticle'] ?? '';
    // ✅ Fix: Parsing sécurisé car le backend envoie parfois une String
    final int price = int.tryParse(article['prixArticle']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: () {
        // Construction de l'objet Product
        final product = shop_model.Product(
          id: article['_id'] ?? '',
          name: name,
          image: image,
          size: '', // Info non dispo direct ici, on laisse vide
          price: price.toString(),
          brand: article['marque'] ?? 'Générique',
          vendeurId: article['vendeur'] is Map ? article['vendeur']['_id'] : article['vendeur'],
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  image, 
                  width: double.infinity, 
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.shopping_bag)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                  ),
                  Text('$price FCFA', 
                    style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13) // ✅ Standard Green
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
