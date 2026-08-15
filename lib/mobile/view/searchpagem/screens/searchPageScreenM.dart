import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../design_system/design_system.dart'; // ✅ Import DS
import '../../jobpagem/screens/detailPageScreenM.dart';
import '../../jobpagem/screens/provider_profile_screen.dart';
import '../../freelancepagem/models/freelance_model.dart';
import '../../freelancepagem/screens/freelance_details_screen.dart';
import '../../shoppingpagem/screens/productDetailsScreenM.dart';
import '../../shoppingpagem/screens/vendorDetailsScreenM.dart';
import '../../shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';
import '../../shoppingpagem/shoppingpageblocm/shoppingPageStateM.dart' as shop_model;
import '../../../../data/models/vendeur.dart';
import '../../common/widgets/empty_state_widget.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageEventM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageStateM.dart';
import '../../common/widgets/app_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../common/widgets/skeleton_loader.dart';

class SearchPageScreenM extends StatelessWidget {
  final int initialIndex;
  /// Si renseigné, lance la recherche globale au chargement (ex. depuis Explorer).
  final String? initialQuery;

  const SearchPageScreenM({
    super.key,
    this.initialIndex = 0,
    this.initialQuery,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchPageBlocM(),
      child: _SearchBody(
        initialIndex: initialIndex,
        initialQuery: initialQuery,
      ),
    );
  }
}

class _SearchBody extends StatefulWidget {
  final int initialIndex;
  final String? initialQuery;

  const _SearchBody({this.initialIndex = 0, this.initialQuery});

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> with SingleTickerProviderStateMixin {
  static const _popularSearches = [
    'Plombier',
    'Électricien',
    'Coiffeur',
    'Développeur web',
    'Menuisier',
    'Maçon',
    'Couturier',
    'Photographe',
  ];

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounce;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    final safeIndex = widget.initialIndex.clamp(0, 5);
    _tabController = TabController(length: 6, vsync: this, initialIndex: safeIndex);
    
    // Listen to tab changes to dismiss keyboard
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        FocusScope.of(context).unfocus();
      }
    });

    // Charger l'historique au démarrage (+ recherche initiale depuis Explorer)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchPageBlocM>().add(LoadHistory());
      final q = widget.initialQuery?.trim();
      if (q != null && q.isNotEmpty) {
        _searchController.text = q;
        context.read<SearchPageBlocM>().add(PerformGlobalSearch(q));
      } else {
        setState(() => _showSuggestions = true);
      }
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
      backgroundColor: SDColors.neutral50, // Light grey background like Facebook/Telegram
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

          final typedQuery = _searchController.text.trim();
          final hasResults = state.services.isNotEmpty ||
              state.articles.isNotEmpty ||
              state.freelances.isNotEmpty ||
              state.prestataires.isNotEmpty ||
              state.vendeurs.isNotEmpty;

          // Overlay discovery / suggestions (avant ou pendant la saisie)
          if (_showSuggestions && !state.hasSearched) {
            if (typedQuery.isEmpty) {
              return _buildDiscoveryPanel(state.history);
            }
            if (state.suggestions.isNotEmpty) {
              return _buildSuggestionsList(state.suggestions, typedQuery);
            }
            return _buildDiscoveryPanel(state.history, filterQuery: typedQuery);
          }

          if (_showSuggestions && state.hasSearched && typedQuery.isNotEmpty) {
            if (state.suggestions.isNotEmpty) {
              return _buildSuggestionsList(state.suggestions, typedQuery);
            }
          }

          if (hasResults) {
            return Column(
              children: [
                _buildTabBar(state.counts),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllTab(state),
                      _buildServicesTab(state),
                      _buildFreelancesTab(state),
                      _buildPrestatairesTab(state),
                      _buildShopTab(state),
                      _buildVendorsTab(state),
                    ],
                  ),
                ),
              ],
            );
          }

          if (state.hasSearched) {
            return _buildNoResultsState(state.query);
          }

          return _buildDiscoveryPanel(state.history);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final canPop = Navigator.of(context).canPop();
    return SDWhiteAppBar.appBar(
      automaticallyImplyLeading: false,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : SizedBox(width: SDSpacing.sm),
      titleWidget: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: SDColors.neutral50,
                borderRadius: BorderRadius.circular(SDSpacing.borderRadiusLarge),
                border: Border.all(color: SDColors.primary100),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  if (value.trim().isEmpty) {
                    context.read<SearchPageBlocM>().add(ClearSearch());
                    context.read<SearchPageBlocM>().add(LoadHistory());
                    setState(() => _showSuggestions = true);
                  } else {
                    setState(() => _showSuggestions = true);
                  }
                  _onSearchChanged(value);
                },
                onSubmitted: _onSubmit,
                onTap: () {
                  setState(() => _showSuggestions = true);
                  _onSearchChanged(_searchController.text);
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher services, produits...',
                  hintStyle:
                      SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
                  prefixIcon: Icon(Icons.search, color: SDColors.primary600, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: SDColors.neutral500, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context.read<SearchPageBlocM>().add(ClearSearch());
                            context.read<SearchPageBlocM>().add(LoadHistory());
                            setState(() => _showSuggestions = true);
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: SDSpacing.xs,
                    vertical: SDSpacing.xs,
                  ),
                ),
                style: SDTypography.bodyMedium,
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
          SizedBox(width: SDSpacing.xs),
          GestureDetector(
            onTap: () => _showFilterModal(context),
            child: Container(
              padding: EdgeInsets.all(SDSpacing.xs),
              decoration: BoxDecoration(
                color: SDColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: SDColors.neutral200),
                boxShadow: [
                  BoxShadow(color: SDColors.neutral900.withOpacity(0.08), blurRadius: 4),
                ],
              ),
              child: Icon(Icons.tune, color: SDColors.primary600, size: 20),
            ),
          ),
        ],
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
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(SDSpacing.borderRadiusLarge)),
          ),
          padding: EdgeInsets.only(
            left: SDSpacing.md, right: SDSpacing.md, top: SDSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + SDSpacing.md
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtres', style: SDTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.close, color: SDColors.neutral900),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: SDColors.neutral200),
              
              // 1. Prix
              Text('Prix (FCFA)', style: SDTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              RangeSlider(
                values: RangeValues(localMin, localMax),
                min: 0,
                max: 1000000,
                divisions: 20,
                labels: RangeLabels('${localMin.round()}', '${localMax.round()}'),
                activeColor: SDColors.primary600,
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
                  Text('${localMin.round()} FCFA', style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600)),
                  Text('${localMax.round()} FCFA', style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600)),
                ],
              ),
              SizedBox(height: SDSpacing.sm),

              // 2. Ville
              Text('Ville / Commune', style: SDTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: SDSpacing.xs),
              TextField(
                controller: cityCtrl,
                decoration: InputDecoration(
                  hintText: 'Ex: Cocody, Abidjan...',
                  prefixIcon: Icon(Icons.location_on, color: SDColors.neutral500),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                  contentPadding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: 0),
                ),
              ),
              SizedBox(height: SDSpacing.md),

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
                        foregroundColor: SDColors.neutral600,
                        side: BorderSide(color: SDColors.neutral400),
                      ),
                      child: Text('Réinitialiser', style: SDTypography.labelMedium),
                    ),
                  ),
                  SizedBox(width: SDSpacing.xs),
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
                        backgroundColor: SDColors.primary600,
                        foregroundColor: SDColors.white,
                      ),
                      child: Text('Appliquer', style: SDTypography.labelMedium.copyWith(color: SDColors.white)),
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
      color: SDColors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: SDColors.primary600,
        unselectedLabelColor: SDColors.neutral500,
        indicatorColor: SDColors.primary600,
        indicatorWeight: 3,
        labelStyle: SDTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
        tabs: [
          const Tab(text: 'Tout'),
          Tab(text: 'Services (${counts['services'] ?? 0})'),
          Tab(text: 'Freelances (${counts['freelances'] ?? 0})'),
          Tab(text: 'Presta. (${counts['prestataires'] ?? 0})'),
          Tab(text: 'Shop (${counts['articles'] ?? 0})'),
          Tab(text: 'Boutiques (${counts['vendeurs'] ?? 0})'),
        ],
      ),
    );
  }

  Widget _buildDiscoveryPanel(List<String> history, {String filterQuery = ''}) {
    final filteredHistory = filterQuery.isEmpty
        ? history
        : history
            .where((h) => h.toLowerCase().contains(filterQuery.toLowerCase()))
            .toList();

    return Container(
      color: SDColors.white,
      child: ListView(
        padding: EdgeInsets.only(bottom: SDSpacing.lg),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                SDSpacing.md, SDSpacing.md, SDSpacing.md, SDSpacing.xs),
            child: Text(
              'Que cherchez-vous ?',
              style: SDTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
            child: Text(
              'Services, freelances, produits ou boutiques à Abidjan…',
              style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
            ),
          ),
          if (filteredHistory.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                  SDSpacing.md, SDSpacing.md, SDSpacing.md, SDSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Récents',
                    style: SDTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SDColors.neutral500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        context.read<SearchPageBlocM>().add(ClearHistory()),
                    child: Text(
                      'Effacer tout',
                      style: SDTypography.bodySmall
                          .copyWith(color: SDColors.error500),
                    ),
                  ),
                ],
              ),
            ),
            ...filteredHistory.map((item) {
              return ListTile(
                leading:
                    Icon(Icons.history, color: SDColors.neutral500, size: 20),
                title: Text(item, style: SDTypography.bodyMedium),
                trailing: IconButton(
                  icon: Icon(Icons.close, size: 18, color: SDColors.neutral400),
                  onPressed: () => context
                      .read<SearchPageBlocM>()
                      .add(RemoveFromHistory(item)),
                ),
                onTap: () => _onSuggestionTap(item),
              );
            }),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(
                SDSpacing.md, SDSpacing.md, SDSpacing.md, SDSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.trending_up, size: 18, color: SDColors.primary600),
                SizedBox(width: SDSpacing.xxs),
                Text(
                  'Populaires',
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: SDColors.neutral700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
            child: Wrap(
              spacing: SDSpacing.xs,
              runSpacing: SDSpacing.xs,
              children: _popularSearches.map((term) {
                return ActionChip(
                  label: Text(term, style: SDTypography.labelMedium),
                  backgroundColor: SDColors.primary50,
                  side: BorderSide(color: SDColors.primary100),
                  onPressed: () => _onSuggestionTap(term),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text, style: SDTypography.bodyMedium);
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) {
      return Text(text, style: SDTypography.bodyMedium);
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, idx),
            style: SDTypography.bodyMedium,
          ),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: SDTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.primary700,
            ),
          ),
          TextSpan(
            text: text.substring(idx + query.length),
            style: SDTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(List<String> suggestions, String query) {
    return Container(
      color: SDColors.white,
      child: ListView.separated(
        itemCount: suggestions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, indent: SDSpacing.sm, color: SDColors.neutral200),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            leading: Icon(Icons.search, color: SDColors.primary700, size: 20),
            title: _buildHighlightedText(suggestion, query),
            trailing:
                Icon(Icons.north_west, size: 16, color: SDColors.neutral400),
            onTap: () => _onSuggestionTap(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildNoResultsState(String query) {
    return EmptyStateWidget(
      imagePath: 'assets/recherche_vide.png',
      title: 'Aucun résultat',
      message: query.isEmpty
          ? 'Essayez avec d\'autres mots-clés ou filtres'
          : 'Rien pour « $query ». Essayez un autre mot ou changez d\'onglet.',
      imageSize: 180,
    );
  }

  // --- TAB: TOUT (Summary) ---
  Widget _buildAllTab(SearchPageStateM state) {
    return ListView(
      padding: EdgeInsets.all(SDSpacing.sm),
      children: [
        if (state.services.isNotEmpty) ...[
          _buildSectionHeader('Services', 1, state.counts['services'] ?? 0),
          ...state.services.take(2).map((s) => _buildServiceCard(s)).toList(),
          SizedBox(height: SDSpacing.sm),
        ],
        
        if (state.freelances.isNotEmpty) ...[
          _buildSectionHeader('Freelances', 2, state.counts['freelances'] ?? 0),
          _buildHorizontalScroll(
            state.freelances
                .take(5)
                .map((f) => _buildPersonSquare(f, isFreelance: true))
                .toList(),
          ),
          SizedBox(height: SDSpacing.sm),
        ],

        if (state.prestataires.isNotEmpty) ...[
          _buildSectionHeader('Prestataires', 3, state.counts['prestataires'] ?? 0),
          _buildHorizontalScroll(
            state.prestataires
                .take(5)
                .map((p) => _buildPersonSquare(p, isFreelance: false))
                .toList(),
          ),
          SizedBox(height: SDSpacing.sm),
        ],

        if (state.articles.isNotEmpty) ...[
          _buildSectionHeader('Boutique', 4, state.counts['articles'] ?? 0),
          _buildArticleGrid(state.articles.take(2).toList()),
          SizedBox(height: SDSpacing.sm),
        ],

        if (state.vendeurs.isNotEmpty) ...[
          _buildSectionHeader('Boutiques', 5, state.counts['vendeurs'] ?? 0),
          ...state.vendeurs.take(3).map(_buildVendorCard),
        ],
      ],
    );
  }

  // --- TAB: SERVICES ---
  Widget _buildServicesTab(SearchPageStateM state) {
    if (state.services.isEmpty) return Center(child: Text("Aucun service trouvé", style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600)));
    return ListView.builder(
      padding: EdgeInsets.all(SDSpacing.sm),
      itemCount: state.services.length,
      itemBuilder: (context, index) => _buildServiceCard(state.services[index]),
    );
  }

  // --- TAB: FREELANCES ---
  Widget _buildFreelancesTab(SearchPageStateM state) {
    if (state.freelances.isEmpty) return Center(child: Text("Aucun freelance trouvé", style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600)));
    return ListView.builder(
      padding: EdgeInsets.all(SDSpacing.sm),
      itemCount: state.freelances.length,
      itemBuilder: (context, index) =>
          _buildPersonCard(state.freelances[index], isFreelance: true),
    );
  }

  // --- TAB: PRESTATAIRES ---
  Widget _buildPrestatairesTab(SearchPageStateM state) {
    if (state.prestataires.isEmpty) return Center(child: Text("Aucun prestataire trouvé", style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600)));
    return ListView.builder(
      padding: EdgeInsets.all(SDSpacing.sm),
      itemCount: state.prestataires.length,
      itemBuilder: (context, index) =>
          _buildPersonCard(state.prestataires[index], isFreelance: false),
    );
  }

  // --- TAB: ARTICLES ---
  Widget _buildShopTab(SearchPageStateM state) {
    if (state.articles.isEmpty) return Center(child: Text("Aucun article trouvé", style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600)));
    return GridView.builder(
      padding: EdgeInsets.all(SDSpacing.sm),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: SDSpacing.sm,
        crossAxisSpacing: SDSpacing.sm,
      ),
      itemCount: state.articles.length,
      itemBuilder: (context, index) => _buildArticleCard(state.articles[index]),
    );
  }

  // --- TAB: BOUTIQUES ---
  Widget _buildVendorsTab(SearchPageStateM state) {
    if (state.vendeurs.isEmpty) {
      return Center(
        child: Text(
          'Aucune boutique trouvée',
          style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(SDSpacing.sm),
      itemCount: state.vendeurs.length,
      itemBuilder: (context, index) => _buildVendorCard(state.vendeurs[index]),
    );
  }

  void _openVendor(dynamic raw) {
    try {
      final map = Map<String, dynamic>.from(raw as Map);
      final vendeur = Vendeur.fromJson(map);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VendorDetailsScreenM(vendeur: vendeur),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’ouvrir la boutique : $e')),
      );
    }
  }

  Widget _buildVendorCard(dynamic vendeur) {
    final name = vendeur['shopName']?.toString() ?? 'Boutique';
    final logo = vendeur['shopLogo']?.toString() ?? '';
    final ville = vendeur['ville']?.toString() ?? '';
    final rating = vendeur['rating']?.toString() ?? '0';

    return Container(
      margin: EdgeInsets.only(bottom: SDSpacing.xs),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(color: SDColors.neutral900.withOpacity(0.05), blurRadius: 4)
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: SDColors.secondary50,
          backgroundImage:
              logo.isNotEmpty ? CachedNetworkImageProvider(logo) : null,
          child: logo.isEmpty
              ? Icon(Icons.storefront_rounded, color: SDColors.secondary600)
              : null,
        ),
        title: Text(
          name,
          style: SDTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          [
            if (ville.isNotEmpty) ville,
            '★ $rating',
          ].join(' · '),
          style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: SDColors.neutral400),
        onTap: () => _openVendor(vendeur),
      ),
    );
  }

  // --- WIDGET HELPER METHODS ---

  Widget _buildSectionHeader(String title, int tabIndex, int count) {
    if (count == 0) return SizedBox();
    return Padding(
      padding: EdgeInsets.only(bottom: SDSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: SDTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () => _tabController.animateTo(tabIndex),
            child: Text('Voir tout', 
              style: SDTypography.labelMedium.copyWith(color: SDColors.primary600, fontWeight: FontWeight.bold)
            ), 
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalScroll(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children.map((c) => Padding(padding: EdgeInsets.only(right: SDSpacing.xs), child: c)).toList()),
    );
  }

  Widget _buildArticleGrid(List<dynamic> articles) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.75,
      mainAxisSpacing: SDSpacing.sm,
      crossAxisSpacing: SDSpacing.sm,
      children: articles.map((a) => _buildArticleCard(a)).toList(),
    );
  }

  // --- CARDS ---

  Widget _buildServiceCard(dynamic service) {
    // Extract properties safely
    final String name = service['nomservice'] ?? 'Service';
    final String image = service['imageservice'] ?? '';
    final int price = int.tryParse(service['prixmoyen']?.toString() ?? '0') ?? 0;
    final String? sid = () {
      final a = service['_id']?.toString().trim();
      final b = service['idservice']?.toString().trim();
      final v = (a != null && a.isNotEmpty) ? a : (b ?? '');
      return v.isNotEmpty ? v : null;
    }();
    
    return Container(
      margin: EdgeInsets.only(bottom: SDSpacing.xs),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        boxShadow: [BoxShadow(color: SDColors.neutral900.withOpacity(0.05), blurRadius: 4)],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(SDSpacing.xs),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
          child: AppImage(
            imageUrl: image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(name, style: SDTypography.titleSmall),
        subtitle: Text('À partir de $price FCFA', style: SDTypography.bodySmall.copyWith(color: SDColors.success500)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: SDColors.neutral500),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(
                title: name,
                image: image,
                serviceId: sid,
              ),
            ),
          );
        },
      ),
    );
  }

  void _openSearchPerson(dynamic person, {required bool isFreelance}) {
    final id = person['_id']?.toString() ?? '';
    if (id.isEmpty) return;

    if (isFreelance) {
      final model = FreelanceModel.fromBackend(
        Map<String, dynamic>.from(person as Map),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FreelanceDetailsScreen(freelance: model),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderProfileScreen(
          providerId: id,
          providerData: Map<String, dynamic>.from(person as Map),
        ),
      ),
    );
  }

  Widget _buildPersonSquare(dynamic person, {required bool isFreelance}) {
    final String name = person['name'] ?? 'Profil';
    final String job = person['job'] ?? (isFreelance ? 'Freelance' : 'Prestataire');
    final String image = person['imagePath']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _openSearchPerson(person, isFreelance: isFreelance),
      child: Container(
        width: 100,
        padding: EdgeInsets.all(SDSpacing.xs),
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          boxShadow: [
            BoxShadow(color: SDColors.neutral900.withOpacity(0.05), blurRadius: 4)
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
              child: image.isEmpty
                  ? Icon(Icons.person, color: SDColors.neutral400)
                  : null,
            ),
            SizedBox(height: SDSpacing.xs),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.bodySmall
                    .copyWith(fontWeight: FontWeight.bold)),
            Text(job,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.labelSmall
                    .copyWith(color: SDColors.neutral500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCard(dynamic person, {required bool isFreelance}) {
    final String name = person['name'] ?? 'Profil';
    final String job = person['job'] ?? (isFreelance ? 'Freelance' : 'Prestataire');
    final String image = person['imagePath']?.toString() ?? '';
    final dynamic rating = person['rating'] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: SDSpacing.xs),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(color: SDColors.neutral900.withOpacity(0.05), blurRadius: 4)
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage:
              image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
          child:
              image.isEmpty ? Icon(Icons.person, color: SDColors.neutral400) : null,
        ),
        title: Text(name,
            style: SDTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(job,
                  style: SDTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            SizedBox(width: SDSpacing.xs),
            Icon(Icons.star, size: 14, color: SDColors.warning500),
            Text(' $rating', style: SDTypography.bodySmall),
          ],
        ),
        onTap: () => _openSearchPerson(person, isFreelance: isFreelance),
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
            builder: (_) => BlocProvider(
              create: (_) => ShoppingPageBlocM(),
              child: ProductDetails(product: product),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
          boxShadow: [BoxShadow(color: SDColors.neutral900.withOpacity(0.05), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(SDSpacing.borderRadiusMedium)),
                child: Image.network(
                  image, 
                  width: double.infinity, 
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: SDColors.neutral200, child: Icon(Icons.shopping_bag, color: SDColors.neutral400)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(SDSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)
                  ),
                  Text('$price FCFA', 
                    style: SDTypography.labelMedium.copyWith(color: SDColors.primary600, fontWeight: FontWeight.bold) // ✅ Standard Green
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
