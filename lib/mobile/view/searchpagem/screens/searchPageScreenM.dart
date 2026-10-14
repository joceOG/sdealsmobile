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
import '../../shoppingpagem/shoppingpageblocm/shoppingPageStateM.dart'
    as shop_model;
import '../../../../data/models/vendeur.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageEventM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/searchpageblocm/searchPageStateM.dart';
import '../../common/widgets/app_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sdealsmobile/data/config/client_feature_flags.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/data/utils/network_user_message.dart';
import '../../common/widgets/skeleton_loader.dart';

class SearchPageScreenM extends StatelessWidget {
  final int initialIndex;

  /// Si renseigné, lance la recherche globale au chargement (ex. depuis Explorer).
  final String? initialQuery;

  /// `metiers` | `freelance` | `emarket` | `global`
  final String scope;

  /// Suggestions « À découvrir » fournies par l'appelant (termes réels de
  /// l'univers). Prioritaires sur la liste éditoriale du périmètre.
  final List<String>? discoveryTerms;

  const SearchPageScreenM({
    super.key,
    this.initialIndex = 0,
    this.initialQuery,
    this.scope = 'global',
    this.discoveryTerms,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchPageBlocM(scope: scope),
      child: _SearchBody(
        initialIndex: initialIndex,
        initialQuery: initialQuery,
        scope: scope,
        discoveryTerms: discoveryTerms,
      ),
    );
  }
}

class _SearchBody extends StatefulWidget {
  final int initialIndex;
  final String? initialQuery;
  final String scope;
  final List<String>? discoveryTerms;

  const _SearchBody({
    this.initialIndex = 0,
    this.initialQuery,
    this.scope = 'global',
    this.discoveryTerms,
  });

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody>
    with SingleTickerProviderStateMixin {
  static final TextStyle _searchLineTextStyle =
      SDTypography.bodyMedium.copyWith(
    color: SDColors.neutral900,
    fontSize: 14,
  );

  /// Liste éditoriale multi-univers (recherche globale uniquement).
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

  /// Liste éditoriale du périmètre Métiers (sans terme Freelance).
  static const _popularMetiers = [
    'Plombier',
    'Électricien',
    'Coiffeur',
    'Menuisier',
    'Maçon',
    'Couturier',
    'Photographe',
  ];

  /// Suggestions cohérentes avec le périmètre. Freelance / E-marché n'ont
  /// pas de liste éditoriale : seulement des termes réels passés par
  /// l'appelant, sinon la section est masquée (jamais « Plombier » en
  /// recherche Freelance).
  List<String> get _discoveryTerms {
    final provided = (widget.discoveryTerms ?? const <String>[])
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (provided.isNotEmpty) return provided;
    switch (widget.scope) {
      case 'metiers':
        return _popularMetiers;
      case 'global':
        return _popularSearches;
      default:
        return const [];
    }
  }

  String _discoverySubtitle() {
    switch (widget.scope) {
      case 'metiers':
        return 'Métiers et artisans à Abidjan…';
      case 'freelance':
        return 'Freelances et compétences, à distance ou au projet…';
      default:
        return ClientFeatureFlags.emarketEnabled
            ? 'Services, freelances, produits ou boutiques à Abidjan…'
            : 'Services et freelances à Abidjan…';
    }
  }

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _tabController;
  Timer? _debounce;
  bool _showSuggestions = false;
  bool _scheduleSearchFocus = false;

  @override
  void initState() {
    super.initState();
    final tabCount = ClientFeatureFlags.searchTabLabels.length;
    final safeIndex =
        ClientFeatureFlags.clampSearchTabIndex(widget.initialIndex);
    _tabController =
        TabController(length: tabCount, vsync: this, initialIndex: safeIndex);

    // Listen to tab changes to dismiss keyboard
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        FocusScope.of(context).unfocus();
      }
    });

    // Focus clavier après la transition de page (évite IME + push en parallèle).
    _scheduleSearchFocus = widget.initialQuery?.trim().isEmpty ?? true;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_scheduleSearchFocus) return;
    _scheduleSearchFocus = false;

    void openKeyboard() {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
    }

    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => openKeyboard());
      return;
    }

    void onRouteStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(onRouteStatus);
      WidgetsBinding.instance.addPostFrameCallback((_) => openKeyboard());
    }

    animation.addStatusListener(onRouteStatus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<SearchPageBlocM>().add(FetchSuggestions(query));
      setState(() => _showSuggestions = true);
    });
  }

  void _onSubmit(String query) {
    final q = query.trim();
    if (q.length >= 2) {
      context.read<SearchPageBlocM>().add(PerformGlobalSearch(q));
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
      backgroundColor:
          SDColors.neutral50, // Light grey background like Facebook/Telegram
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
            final msg = userFacingNetworkMessage(state.error);
            return Center(
              child: Padding(
                padding: EdgeInsets.all(SDSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(msg,
                        textAlign: TextAlign.center,
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.neutral800,
                        )),
                    SizedBox(height: SDSpacing.sm),
                    ElevatedButton(
                      onPressed: () {
                        final q = _searchController.text.trim();
                        if (q.length >= 2) {
                          context
                              .read<SearchPageBlocM>()
                              .add(PerformGlobalSearch(q));
                        }
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
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
            if (typedQuery.length >= 1 && state.suggestions.isNotEmpty) {
              return _buildSuggestionsList(state.suggestions, typedQuery);
            }
            if (typedQuery.length >= 1) {
              return _buildDiscoveryPanel(state.history,
                  filterQuery: typedQuery);
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
                      if (ClientFeatureFlags.emarketEnabled) ...[
                        _buildShopTab(state),
                        _buildVendorsTab(state),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }

          if (state.hasSearched) {
            return _buildNoResultsState(state.query, scope: state.scope);
          }

          return _buildDiscoveryPanel(state.history);
        },
      ),
    );
  }

  String _searchHintText() {
    if (widget.scope == 'metiers') {
      return 'Rechercher un métier ou un besoin';
    }
    if (widget.scope == 'freelance') {
      return 'Rechercher une compétence freelance';
    }
    return 'Que recherchez-vous\u00a0?';
  }

  PreferredSizeWidget _buildAppBar() {
    final canPop = Navigator.of(context).canPop();
    final hasQuery = _searchController.text.isNotEmpty;
    return SDWhiteAppBar.appBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      leading: canPop
          ? IconButton(
              tooltip: 'Retour',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(Icons.arrow_back, size: 22),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : const SizedBox(width: 8),
      titleWidget: Row(
        children: [
          Expanded(child: _buildAppBarSearchField(hasQuery: hasQuery)),
          IconButton(
            tooltip: 'Filtres',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.only(left: 4),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(Icons.tune_outlined, size: 22),
            color: SDColors.neutral700,
            onPressed: () => _showFilterModal(context),
          ),
        ],
      ),
    );
  }

  /// Barre unique (Explorer) : blanc, bordure neutre fine, sans contour vert au focus.
  Widget _buildAppBarSearchField({required bool hasQuery}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      padding: const EdgeInsets.only(left: 10, right: 2),
      child: Row(
        children: [
          const Icon(Icons.search, color: SDColors.neutral600, size: 22),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
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
                hintText: _searchHintText(),
                hintStyle: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral500,
                  fontSize: 14,
                ),
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              style: _searchLineTextStyle,
              cursorColor: SDColors.primary600,
              textInputAction: TextInputAction.search,
            ),
          ),
          if (hasQuery)
            IconButton(
              tooltip: 'Effacer',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.close, size: 18),
              color: SDColors.neutral500,
              onPressed: () {
                _searchController.clear();
                context.read<SearchPageBlocM>().add(ClearSearch());
                context.read<SearchPageBlocM>().add(LoadHistory());
                setState(() => _showSuggestions = true);
                _onSearchChanged('');
              },
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
    final TextEditingController cityCtrl =
        TextEditingController(text: state.city);

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(SDSpacing.borderRadiusLarge)),
          ),
          padding: EdgeInsets.only(
              left: SDSpacing.md,
              right: SDSpacing.md,
              top: SDSpacing.md,
              bottom: MediaQuery.of(context).viewInsets.bottom + SDSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtres',
                      style: SDTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.close, color: SDColors.neutral900),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: SDColors.neutral200),

              // 1. Prix
              Text('Prix (FCFA)',
                  style: SDTypography.titleSmall
                      .copyWith(fontWeight: FontWeight.bold)),
              RangeSlider(
                values: RangeValues(localMin, localMax),
                min: 0,
                max: 1000000,
                divisions: 20,
                labels:
                    RangeLabels('${localMin.round()}', '${localMax.round()}'),
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
                  Text('${localMin.round()} FCFA',
                      style: SDTypography.bodySmall
                          .copyWith(color: SDColors.neutral600)),
                  Text('${localMax.round()} FCFA',
                      style: SDTypography.bodySmall
                          .copyWith(color: SDColors.neutral600)),
                ],
              ),
              SizedBox(height: SDSpacing.sm),

              // 2. Ville
              Text('Ville / Commune',
                  style: SDTypography.titleSmall
                      .copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: SDSpacing.xs),
              TextField(
                controller: cityCtrl,
                decoration: InputDecoration(
                  hintText: 'Ex: Cocody, Abidjan...',
                  prefixIcon:
                      Icon(Icons.location_on, color: SDColors.neutral500),
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(SDSpacing.borderRadiusMedium)),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: SDSpacing.sm, vertical: 0),
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
                        context.read<SearchPageBlocM>().add(const UpdateFilters(
                            minPrice: 0, maxPrice: 1000000, city: ''));
                        context
                            .read<SearchPageBlocM>()
                            .add(PerformGlobalSearch(state.query));
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SDColors.neutral600,
                        side: BorderSide(color: SDColors.neutral400),
                      ),
                      child: Text('Réinitialiser',
                          style: SDTypography.labelMedium),
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
                        context
                            .read<SearchPageBlocM>()
                            .add(PerformGlobalSearch(state.query));
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SDColors.primary600,
                        foregroundColor: SDColors.white,
                      ),
                      child: Text('Appliquer',
                          style: SDTypography.labelMedium
                              .copyWith(color: SDColors.white)),
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

  int _countForSearchTab(String label, Map<String, int> counts) {
    switch (label) {
      case 'Services':
        return counts['services'] ?? 0;
      case 'Freelances':
        return counts['freelances'] ?? 0;
      case 'Professionnels':
      case 'Presta.':
        return counts['prestataires'] ?? 0;
      case 'Shop':
        return counts['articles'] ?? 0;
      case 'Boutiques':
        return counts['vendeurs'] ?? 0;
      default:
        return 0;
    }
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
        labelStyle:
            SDTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
        tabs: [
          for (final label in ClientFeatureFlags.searchTabLabels)
            Tab(
              text: label == 'Tout'
                  ? label
                  : '$label (${_countForSearchTab(label, counts)})',
            ),
        ],
      ),
    );
  }

  List<String> _validHistoryEntries(List<String> history) {
    final seen = <String>{};
    final out = <String>[];
    for (final item in history) {
      final q = cleanDisplayPart(item);
      if (q == null) continue;
      final key = q.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(q);
    }
    return out;
  }

  Widget _compactSearchListRow({
    required Widget leading,
    required Widget label,
    Widget? trailing,
    VoidCallback? onTap,
    bool showDivider = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider)
          Divider(height: 1, indent: 52, color: SDColors.neutral200),
        Material(
          color: SDColors.white,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SDSpacing.md,
                vertical: 12,
              ),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(child: label),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryPanel(List<String> history, {String filterQuery = ''}) {
    final cleaned = _validHistoryEntries(history);
    final filteredHistory = filterQuery.isEmpty
        ? cleaned
        : cleaned
            .where((h) => h.toLowerCase().contains(filterQuery.toLowerCase()))
            .toList();

    final discoveryTerms = _discoveryTerms;

    return Container(
      color: SDColors.white,
      child: ListView(
        // Le Scaffold (resizeToAvoidBottomInset) réduit déjà le corps au-dessus
        // du clavier. Ajouter viewInsets ici (lu sur le contexte de l'état,
        // au-dessus du Scaffold) doublait l'inset clavier et faisait varier
        // ce padding à chaque image de l'animation du clavier. L'inset système
        // reste stable clavier ouvert ou fermé.
        padding: EdgeInsets.only(
          bottom: SDResponsive.systemBottomInset(context) + SDSpacing.lg,
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                SDSpacing.md, SDSpacing.md, SDSpacing.md, SDSpacing.xs),
            child: Text(
              'Que cherchez-vous ?',
              style: SDTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SDSpacing.md),
            child: Text(
              _discoverySubtitle(),
              style:
                  SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
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
            ...filteredHistory.asMap().entries.map((entry) {
              final item = entry.value;
              return _compactSearchListRow(
                showDivider: entry.key > 0,
                leading:
                    Icon(Icons.history, color: SDColors.neutral500, size: 20),
                label: Text(item, style: _searchLineTextStyle, maxLines: 2),
                trailing: IconButton(
                  tooltip: 'Retirer',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(Icons.close, size: 18, color: SDColors.neutral400),
                  onPressed: () => context
                      .read<SearchPageBlocM>()
                      .add(RemoveFromHistory(item)),
                ),
                onTap: () => _onSuggestionTap(item),
              );
            }),
          ],
          if (discoveryTerms.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                  SDSpacing.md, SDSpacing.md, SDSpacing.md, SDSpacing.sm),
              child: Row(
                children: [
                  Text(
                    'À découvrir',
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
                children: discoveryTerms.map((term) {
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
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    final display = cleanDisplayPart(text) ?? text.trim();
    if (display.isEmpty) {
      return Text('', style: _searchLineTextStyle);
    }
    if (query.isEmpty) {
      return Text(display, style: _searchLineTextStyle);
    }
    final lower = display.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) {
      return Text(display, style: _searchLineTextStyle);
    }
    final base = _searchLineTextStyle;
    final matchStyle = base.copyWith(
      fontWeight: FontWeight.w700,
      color: SDColors.primary800,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: display.substring(0, idx)),
          TextSpan(
            text: display.substring(idx, idx + q.length),
            style: matchStyle,
          ),
          TextSpan(text: display.substring(idx + q.length)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSuggestionsList(List<String> suggestions, String query) {
    final trimmed = query.trim();
    final visible = suggestions
        .map((s) => cleanDisplayPart(s))
        .whereType<String>()
        .toList();
    if (visible.isEmpty && trimmed.isNotEmpty) {
      return Container(
        color: SDColors.white,
        padding: EdgeInsets.all(SDSpacing.md),
        child: Text(
          'Aucune suggestion pour « $trimmed »',
          style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
        ),
      );
    }
    return Container(
      color: SDColors.white,
      child: ListView(
        // Même règle que le panneau découverte : pas de second inset clavier.
        padding: EdgeInsets.only(
          bottom: SDResponsive.systemBottomInset(context),
        ),
        children: [
          if (trimmed.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                SDSpacing.md,
                SDSpacing.md,
                SDSpacing.md,
                SDSpacing.xs,
              ),
              child: Text(
                'Suggestions pour « $trimmed »',
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SDColors.neutral900,
                ),
              ),
            ),
          ...List.generate(visible.length, (index) {
            final suggestion = visible[index];
            return _compactSearchListRow(
              showDivider: index > 0,
              leading: Icon(Icons.search, color: SDColors.neutral600, size: 20),
              label: _buildHighlightedText(suggestion, trimmed),
              trailing:
                  Icon(Icons.north_west, size: 16, color: SDColors.neutral400),
              onTap: () => _onSuggestionTap(suggestion),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(String query, {String scope = 'global'}) {
    final trimmed = query.trim();
    final message = trimmed.isEmpty
        ? 'Essayez avec d\'autres mots-clés ou filtres'
        : scope != 'global'
            ? 'Rien pour « $trimmed » dans ce contexte.'
            : 'Rien pour « $trimmed ». Essayez un autre mot ou changez d\'onglet.';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (trimmed.isNotEmpty) ...[
                      const SDIllustration(
                        asset: SDIllustrations.searchEmpty,
                      ),
                      const SizedBox(height: 24),
                    ],
                    const Text(
                      'Aucun résultat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (scope != 'global' && trimmed.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: OutlinedButton(
                          onPressed: () {
                            context
                                .read<SearchPageBlocM>()
                                .add(const ExpandSearchToGlobal());
                          },
                          child: const Text(
                            'Rechercher dans les autres univers',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _allTabHasHiddenResults(SearchPageStateM state) {
    if ((state.counts['services'] ?? 0) > 3) return true;
    if ((state.counts['freelances'] ?? 0) > 5) return true;
    if ((state.counts['prestataires'] ?? 0) > 5) return true;
    if (ClientFeatureFlags.emarketEnabled) {
      if ((state.counts['articles'] ?? 0) > 2) return true;
      if ((state.counts['vendeurs'] ?? 0) > 3) return true;
    }
    return false;
  }

  int _firstTabWithOverflow(SearchPageStateM state) {
    if ((state.counts['services'] ?? 0) > 3) return 1;
    if ((state.counts['freelances'] ?? 0) > 5) return 2;
    if ((state.counts['prestataires'] ?? 0) > 5) return 3;
    if (ClientFeatureFlags.emarketEnabled) {
      if ((state.counts['articles'] ?? 0) > 2) return 4;
      if ((state.counts['vendeurs'] ?? 0) > 3) return 5;
    }
    return 1;
  }

  // --- TAB: TOUT (Summary) ---
  Widget _buildAllTab(SearchPageStateM state) {
    return ListView(
      padding: EdgeInsets.all(SDSpacing.sm),
      children: [
        if (state.query.trim().isNotEmpty) _buildSearchIntentBanner(state),
        if (state.services.isNotEmpty) ...[
          _buildScopedSectionHeader(
            title: 'Services',
            scopeLabel: 'Métiers',
            tabIndex: 1,
            count: state.counts['services'] ?? 0,
          ),
          ...state.services.take(3).map((s) => _buildServiceCard(s)).toList(),
          SizedBox(height: SDSpacing.sm),
        ],
        if (ClientFeatureFlags.emarketEnabled && state.articles.isNotEmpty) ...[
          _buildScopedSectionHeader(
            title: 'Produits',
            scopeLabel: 'E-marché',
            tabIndex: 4,
            count: state.counts['articles'] ?? 0,
          ),
          _buildArticleGrid(state.articles.take(2).toList()),
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
          _buildSectionHeader(
              'Prestataires', 3, state.counts['prestataires'] ?? 0),
          _buildHorizontalScroll(
            state.prestataires
                .take(5)
                .map((p) => _buildPersonSquare(p, isFreelance: false))
                .toList(),
          ),
          SizedBox(height: SDSpacing.sm),
        ],
        if (ClientFeatureFlags.emarketEnabled && state.vendeurs.isNotEmpty) ...[
          _buildSectionHeader('Boutiques', 5, state.counts['vendeurs'] ?? 0),
          ...state.vendeurs.take(3).map(_buildVendorCard),
        ],
        if (state.hasSearched &&
            state.query.trim().length >= 2 &&
            _allTabHasHiddenResults(state))
          Padding(
            padding: EdgeInsets.only(top: SDSpacing.sm),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _tabController.animateTo(_firstTabWithOverflow(state));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SDColors.primary600,
                  foregroundColor: SDColors.white,
                  padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(SDSpacing.borderRadiusMedium),
                  ),
                ),
                child: Text(
                  'Voir tous les résultats →',
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Carte d’intention : besoin métier (ex. robinet → plombier), pas un achat produit.
  Widget _buildSearchIntentBanner(SearchPageStateM state) {
    final query = state.query.trim();
    if (query.isEmpty || state.services.isEmpty) {
      return const SizedBox.shrink();
    }
    final top = state.services.first;
    if (top is! Map) return const SizedBox.shrink();
    final kind = top['matchKind']?.toString() ?? '';
    final isNeedMatch = kind.contains('need');
    if (!isNeedMatch) return const SizedBox.shrink();

    final serviceName = top['nomservice']?.toString() ?? 'un professionnel';
    final buyHint = ClientFeatureFlags.emarketEnabled &&
        (state.articles.isNotEmpty || state.vendeurs.isNotEmpty);

    return Padding(
      padding: EdgeInsets.only(bottom: SDSpacing.sm),
      child: Material(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            final sid = top['_id']?.toString() ?? top['idservice']?.toString();
            final img = top['imageservice']?.toString() ?? '';
            if (sid == null || sid.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailPage(
                  title: serviceName,
                  image: img,
                  serviceId: sid,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SDColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.build_outlined,
                      color: SDColors.primary600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    buyHint
                        ? 'Besoin lié à « $query » ? Trouvez un $serviceName ou parcourez les produits ci-dessous.'
                        : 'Besoin lié à « $query » ? Explorez les services de $serviceName.',
                    style: SDTypography.bodySmall.copyWith(
                      color: SDColors.neutral800,
                      height: 1.35,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: SDColors.neutral400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScopedSectionHeader({
    required String title,
    required String scopeLabel,
    required int tabIndex,
    required int count,
  }) {
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: SDSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: SDTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () => _tabController.animateTo(tabIndex),
            child: Text(
              scopeLabel,
              style: SDTypography.labelMedium.copyWith(
                color: SDColors.primary700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB: SERVICES ---
  Widget _buildServicesTab(SearchPageStateM state) {
    if (state.services.isEmpty)
      return Center(
          child: Text("Aucun service trouvé",
              style: SDTypography.bodyMedium
                  .copyWith(color: SDColors.neutral600)));
    return ListView.builder(
      padding: EdgeInsets.all(SDSpacing.sm),
      itemCount: state.services.length,
      itemBuilder: (context, index) => _buildServiceCard(state.services[index]),
    );
  }

  // --- TAB: FREELANCES ---
  Widget _buildFreelancesTab(SearchPageStateM state) {
    if (state.freelances.isEmpty)
      return Center(
          child: Text("Aucun freelance trouvé",
              style: SDTypography.bodyMedium
                  .copyWith(color: SDColors.neutral600)));
    return ListView.builder(
      padding: EdgeInsets.all(SDSpacing.sm),
      itemCount: state.freelances.length,
      itemBuilder: (context, index) =>
          _buildPersonCard(state.freelances[index], isFreelance: true),
    );
  }

  // --- TAB: PRESTATAIRES ---
  Widget _buildPrestatairesTab(SearchPageStateM state) {
    if (state.prestataires.isEmpty)
      return Center(
          child: Text("Aucun prestataire trouvé",
              style: SDTypography.bodyMedium
                  .copyWith(color: SDColors.neutral600)));
    return ListView.builder(
      padding: EdgeInsets.all(SDSpacing.sm),
      itemCount: state.prestataires.length,
      itemBuilder: (context, index) =>
          _buildPersonCard(state.prestataires[index], isFreelance: false),
    );
  }

  // --- TAB: ARTICLES ---
  Widget _buildShopTab(SearchPageStateM state) {
    if (state.articles.isEmpty)
      return Center(
          child: Text("Aucun article trouvé",
              style: SDTypography.bodyMedium
                  .copyWith(color: SDColors.neutral600)));
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
        trailing:
            Icon(Icons.arrow_forward_ios, size: 14, color: SDColors.neutral400),
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
          Text(title,
              style: SDTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () => _tabController.animateTo(tabIndex),
            child: Text('Voir tout',
                style: SDTypography.labelMedium.copyWith(
                    color: SDColors.primary600, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalScroll(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: children
              .map((c) => Padding(
                  padding: EdgeInsets.only(right: SDSpacing.xs), child: c))
              .toList()),
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
    final String name = displayOrFallback(service['nomservice'], 'Service');
    final String image = service['imageservice']?.toString() ?? '';
    final cat = service['categorie'];
    final String categoryName = cat is Map
        ? (cleanDisplayPart(cat['nomcategorie']) ?? '')
        : (cleanDisplayPart(service['nomcategorie']) ?? '');
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
        boxShadow: [
          BoxShadow(color: SDColors.neutral900.withOpacity(0.05), blurRadius: 4)
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        onTap: () {
          if (sid == null) return;
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
        child: Padding(
          padding: EdgeInsets.all(SDSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(SDSpacing.borderRadiusSmall),
                child: AppImage(
                  imageUrl: image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: SDSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.titleSmall.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (categoryName.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.labelSmall
                            .copyWith(color: SDColors.neutral500),
                      ),
                    ],
                    SizedBox(height: 4),
                    Text(
                      'Trouver un professionnel',
                      style: SDTypography.labelSmall.copyWith(
                        color: SDColors.primary700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: SDColors.neutral400),
            ],
          ),
        ),
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
    final String job =
        person['job'] ?? (isFreelance ? 'Freelance' : 'Prestataire');
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
            BoxShadow(
                color: SDColors.neutral900.withOpacity(0.05), blurRadius: 4)
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
    final String job =
        person['job'] ?? (isFreelance ? 'Freelance' : 'Prestataire');
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
          child: image.isEmpty
              ? Icon(Icons.person, color: SDColors.neutral400)
              : null,
        ),
        title: Text(name,
            style:
                SDTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
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
    final int price =
        int.tryParse(article['prixArticle']?.toString() ?? '0') ?? 0;

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
          vendeurId: article['vendeur'] is Map
              ? article['vendeur']['_id']
              : article['vendeur'],
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
          boxShadow: [
            BoxShadow(
                color: SDColors.neutral900.withOpacity(0.05), blurRadius: 4)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(SDSpacing.borderRadiusMedium)),
                child: Image.network(
                  image,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: SDColors.neutral200,
                      child:
                          Icon(Icons.shopping_bag, color: SDColors.neutral400)),
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
                      style: SDTypography.bodySmall
                          .copyWith(fontWeight: FontWeight.bold)),
                  Text('$price FCFA',
                      style: SDTypography.labelMedium.copyWith(
                          color: SDColors.primary600,
                          fontWeight: FontWeight.bold) // ✅ Standard Green
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
