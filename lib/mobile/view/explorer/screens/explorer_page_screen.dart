import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/models/vendeur.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageBlocM.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageEventM.dart'
    as free_ev;
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageStateM.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/models/freelance_model.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/screens/freelance_details_screen.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/screens/freelancePageScreen.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageEventM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageStateM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/jobPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/provider_profile_screen.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/screens/productDetailsScreenM.dart';
import 'package:sdealsmobile/data/config/client_feature_flags.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageEventM.dart'
    as shop_ev;
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageStateM.dart'
    as shop_state;
import 'package:sdealsmobile/mobile/view/common/widgets/client_universe_pictograms.dart';
import 'package:sdealsmobile/mobile/view/locationpagem/locationpageblocm/locationPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/locationpagem/screens/locationPageScreenM.dart';
import 'package:go_router/go_router.dart';

import 'package:sdealsmobile/mobile/view/explorer/widgets/explorer_metiers_map_panel.dart';
import '../../../../design_system/design_system.dart';
import '../../common/widgets/app_image.dart';
import '../../common/widgets/skeleton_loader.dart';

/// Filtre type Figma (chips sous la recherche).
enum _ExplorerUniverse { tous, metiers, freelance, marketplace }

enum _ExplorerViewMode { list, map }

/// Onglet **Explorer** : hub découverte + recherche globale.
/// Liste (feed multi-univers) | Carte (Métiers / géo) — même écran, style Airbnb.
class ExplorerPageScreen extends StatelessWidget {
  const ExplorerPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => JobPageBlocM()
            ..add(LoadCategorieDataJobM())
            ..add(const LoadProviderMatchingM(serviceType: '', location: '')),
        ),
        BlocProvider(
          create: (_) => FreelancePageBlocM()
            ..add(free_ev.LoadCategorieDataM())
            ..add(free_ev.LoadFreelancersEvent())
            ..add(free_ev.LoadServicesEvent()),
        ),
        if (ClientFeatureFlags.emarketEnabled)
          BlocProvider(
            create: (_) => ShoppingPageBlocM()
              ..add(shop_ev.LoadCategorieDataM())
              ..add(shop_ev.LoadProductsEvent())
              ..add(shop_ev.LoadVendeursEvent()),
          ),
      ],
      child: const _ExplorerBody(),
    );
  }
}

class _ExplorerBody extends StatefulWidget {
  const _ExplorerBody();

  @override
  State<_ExplorerBody> createState() => _ExplorerBodyState();
}

class _ExplorerBodyState extends State<_ExplorerBody> {
  final TextEditingController _searchCtrl = TextEditingController();
  _ExplorerUniverse _universe = _ExplorerUniverse.metiers;
  _ExplorerViewMode _viewMode = _ExplorerViewMode.list;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openSearch([String? query]) {
    final q = (query ?? _searchCtrl.text).trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchPageScreenM(
          initialQuery: q.isEmpty ? null : q,
        ),
      ),
    );
  }

  void _openMarketplace() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ShoppingPageBlocM()
            ..add(shop_ev.LoadCategorieDataM())
            ..add(shop_ev.LoadProductsEvent()),
          child: const ShoppingPageScreenM(),
        ),
      ),
    );
  }

  bool get _showMetiers =>
      _universe == _ExplorerUniverse.tous ||
      _universe == _ExplorerUniverse.metiers;

  bool get _showFreelance =>
      _universe == _ExplorerUniverse.tous ||
      _universe == _ExplorerUniverse.freelance;

  bool get _showMarketplace =>
      ClientFeatureFlags.emarketEnabled &&
      (_universe == _ExplorerUniverse.tous ||
          _universe == _ExplorerUniverse.marketplace);

  /// Carte utile pour Métiers (et Tous = markers métiers).
  bool get _mapAvailable =>
      _universe == _ExplorerUniverse.tous ||
      _universe == _ExplorerUniverse.metiers;

  void _selectUniverse(_ExplorerUniverse value) {
    setState(() {
      _universe = value;
      // Conserver Liste par défaut ; Carte seulement si l'utilisateur la choisit.
      if (value == _ExplorerUniverse.freelance ||
          value == _ExplorerUniverse.marketplace) {
        _viewMode = _ExplorerViewMode.list;
      }
    });
  }

  void _openLocation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => LocationPageBlocM(),
          child: const LocationPageScreenM(),
        ),
      ),
    );
  }

  /// Affiche uniquement les cartes avec une vraie image (réseau ou asset).
  bool _hasDisplayableImage(String? url) {
    final v = url?.trim() ?? '';
    if (v.isEmpty || v.toLowerCase() == 'null') return false;
    final lower = v.toLowerCase();
    if (lower.contains('default.png') ||
        lower.contains('placeholder') ||
        lower.endsWith('/null')) {
      return false;
    }
    return v.startsWith('http') || v.startsWith('assets/');
  }

  @override
  Widget build(BuildContext context) {
    final showMap = _viewMode == _ExplorerViewMode.map && _mapAvailable;

    return Scaffold(
      backgroundColor: SDColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroHeader(context, showMap: showMap),
          Expanded(
            child: showMap
                ? const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: ExplorerMetiersMapPanel(),
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      if (_universe == _ExplorerUniverse.metiers ||
                          _universe == _ExplorerUniverse.tous)
                        SliverToBoxAdapter(
                          child: _buildQuickCategories(context),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_showMetiers) _buildMetiersSection(context),
                              if (_showFreelance)
                                _buildFreelanceSection(context),
                              if (_showMarketplace) ...[
                                _buildProductsSection(context),
                                _buildShopsSection(context),
                              ],
                              SizedBox(height: SDSpacing.lg),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, {required bool showMap}) {
    return Container(
      decoration: const BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explorer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.displayMedium.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: SDSpacing.xxxs),
              Text(
                'Services et freelances',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral600,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: SDSpacing.sm),
              _buildSearchRow(context),
              SizedBox(height: SDSpacing.sm),
              _buildLocationRow(),
              if (!showMap) ...[
                SizedBox(height: SDSpacing.sm),
                _buildUniverseIcons(),
              ],
              if (_mapAvailable) ...[
                SizedBox(height: SDSpacing.sm),
                _buildListMapToggle(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow() {
    return Semantics(
      button: true,
      label: 'Ville ${SDClientLocationPolicy.fallbackCity}. Modifier',
      child: InkWell(
        onTap: _openLocation,
        borderRadius: BorderRadius.circular(SDSpacing.radiusChip),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: SDSpacing.minTouchTarget),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                size: SDSpacing.iconStandard,
                color: SDColors.primary600,
              ),
              const SizedBox(width: SDSpacing.spaceSmall),
              Expanded(
                child: Text(
                  SDClientLocationPolicy.fallbackCity,
                  style: SDTypography.body.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Modifier',
                style: SDTypography.caption.copyWith(
                  color: SDColors.primary600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCategories(BuildContext context) {
    return BlocBuilder<JobPageBlocM, JobPageStateM>(
      builder: (context, state) {
        final cats = state.listItems.take(8).toList();
        if (cats.isEmpty && !state.isLoading) {
          if (state.error.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: _explorerInlineState(
                title: 'Catégories indisponibles',
                message: state.error,
                onRetry: () => context
                    .read<JobPageBlocM>()
                    .add(LoadCategorieDataJobM()),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catégories',
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SDColors.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 88,
                child: state.isLoading && cats.isEmpty
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 20),
                        itemCount: cats.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          if (index == cats.length) {
                            return _ExplorerCategoryChip(
                              label: 'Voir tout',
                              selected: false,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const JobPageScreenM(),
                                  ),
                                );
                              },
                            );
                          }
                          final c = cats[index];
                          return _ExplorerCategoryChip(
                            label: c.nomcategorie,
                            selected: false,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                    create: (_) => JobPageBlocM()
                                      ..add(LoadProvidersByCategoryM(
                                        category: c.nomcategorie,
                                      )),
                                    child: const JobPageScreenM(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListMapToggle() {
    return Container(
      margin: EdgeInsets.only(bottom: SDSpacing.sm),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ViewModeBtn(
              label: 'Liste',
              icon: Icons.view_list_rounded,
              selected: _viewMode == _ExplorerViewMode.list,
              onTap: () => setState(() => _viewMode = _ExplorerViewMode.list),
            ),
          ),
          Expanded(
            child: _ViewModeBtn(
              label: 'Carte',
              icon: Icons.map_outlined,
              selected: _viewMode == _ExplorerViewMode.map,
              onTap: () => setState(() => _viewMode = _ExplorerViewMode.map),
            ),
          ),
        ],
      ),
    );
  }

  /// Barre de recherche blanche ouvrant l'écran existant.
  Widget _buildSearchRow(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Rechercher un service ou une compétence',
      child: Material(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openSearch(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: SDColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SDColors.neutral200),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: SDColors.neutral600, size: 22),
                SizedBox(width: SDSpacing.xs),
                Expanded(
                  child: Text(
                    'Rechercher un service ou une compétence',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Univers actifs uniquement (Métiers / Freelance), pictogrammes 10D-2C.
  Widget _buildUniverseIcons() {
    final items = <({
      String label,
      _ExplorerUniverse value,
      Widget Function(bool selected) pictogram,
    })>[
      (
        label: 'Métiers',
        value: _ExplorerUniverse.metiers,
        pictogram: (selected) => selected
            ? ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  SDColors.white,
                  BlendMode.srcIn,
                ),
                child: const ClientUniversePictogram.metiers(size: 28),
              )
            : const ClientUniversePictogram.metiers(size: 28),
      ),
      (
        label: 'Freelance',
        value: _ExplorerUniverse.freelance,
        pictogram: (selected) => selected
            ? ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  SDColors.white,
                  BlendMode.srcIn,
                ),
                child: const ClientUniversePictogram.freelance(size: 28),
              )
            : const ClientUniversePictogram.freelance(size: 28),
      ),
      if (ClientFeatureFlags.emarketEnabled)
        (
          label: 'Vente & Achat',
          value: _ExplorerUniverse.marketplace,
          pictogram: (selected) => Icon(
                Icons.shopping_bag_rounded,
                color: selected ? SDColors.white : SDColors.primary600,
                size: 26,
              ),
        ),
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final meta = items[index];
          final selected = _universe == meta.value;
          return Semantics(
            button: true,
            selected: selected,
            label: 'Univers ${meta.label}',
            child: GestureDetector(
              onTap: () => _selectUniverse(meta.value),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 76,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: selected ? SDColors.primary600 : SDColors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: selected
                              ? SDColors.primary600
                              : SDColors.neutral200,
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: meta.pictogram(selected),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meta.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: SDTypography.labelSmall.copyWith(
                        color: selected
                            ? SDColors.primary700
                            : SDColors.neutral900,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader({
    required String titleBold,
    required String titleLight,
    required VoidCallback onSeeAll,
  }) {
    final titleStyle = SDTypography.titleLarge.copyWith(
      color: SDColors.neutral900,
      fontWeight: FontWeight.w800,
      fontSize: 22,
      height: 1.15,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: titleStyle,
              children: [
                TextSpan(text: titleBold),
                if (titleLight.trim().isNotEmpty)
                  TextSpan(
                    text: titleLight,
                    style: titleStyle.copyWith(
                      color: SDColors.neutral600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Voir tout',
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.neutral600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: SDColors.neutral600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Espacement compact entre sections (style Yango).
  Widget _sectionGap({required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(bottom: SDSpacing.md + 4),
      child: child,
    );
  }

  Widget _explorerInlineState({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SDSpacing.spaceRelated),
      decoration: BoxDecoration(
        color: SDColors.neutral50,
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
          ),
          const SizedBox(height: SDSpacing.spaceSmall),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetiersSection(BuildContext context) {
    return BlocBuilder<JobPageBlocM, JobPageStateM>(
      builder: (context, state) {
        // UX : n’afficher que les prestataires avec photo publique réelle.
        final list = state.matchedProviders
            .where((p) {
              final url = providerPhotoUrl(
                selfie: p.selfie,
                photoProfil: p.utilisateur.photoProfil,
              );
              return url != null && url.isNotEmpty;
            })
            .take(12)
            .toList();
        if (state.isMatchingLoading && list.isEmpty) {
          return _sectionGap(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  titleBold: 'Prestataires',
                  titleLight: '',
                  onSeeAll: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JobPageScreenM()),
                  ),
                ),
                SizedBox(height: SDSpacing.xs),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
                    itemBuilder: (_, __) => SkeletonWidget.rounded(
                      width: 156,
                      height: 196,
                      borderRadius: 18,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return _sectionGap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                titleBold: 'Prestataires',
                titleLight: '',
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JobPageScreenM()),
                ),
              ),
              SizedBox(height: SDSpacing.xs),
              SizedBox(
                height: 196,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
                  itemBuilder: (context, i) {
                    return _MetierCard(prestataire: list[i]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFreelanceSection(BuildContext context) {
    return BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
      builder: (context, state) {
        final list = state.freelancers
            .where((f) => _hasDisplayableImage(f.imagePath))
            .take(12)
            .toList();
        if (state.isLoading && list.isEmpty) {
          return _sectionGap(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  titleBold: 'Freelances',
                  titleLight: ' populaires',
                  onSeeAll: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FreelancePageScreen(categories: []),
                    ),
                  ),
                ),
                SizedBox(height: SDSpacing.xs),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
                    itemBuilder: (_, __) => SkeletonWidget.rounded(
                      width: 148,
                      height: 188,
                      borderRadius: 18,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return _sectionGap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                titleBold: 'Freelances',
                titleLight: ' populaires',
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FreelancePageScreen(categories: []),
                  ),
                ),
              ),
              SizedBox(height: SDSpacing.xs),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
                  itemBuilder: (context, i) {
                    return _FreelanceExplorerCard(freelance: list[i]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsSection(BuildContext context) {
    return BlocBuilder<ShoppingPageBlocM, shop_state.ShoppingPageStateM>(
      builder: (context, state) {
        final raw = state.filteredProducts ?? state.products ?? [];
        final list =
            raw.where((p) => _hasDisplayableImage(p.image)).take(10).toList();
        if ((state.isLoading ?? false) && list.isEmpty) {
          return _sectionGap(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  titleBold: 'Produits',
                  titleLight: ' tendance',
                  onSeeAll: _openMarketplace,
                ),
                SizedBox(height: SDSpacing.xs),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
                    itemBuilder: (_, __) => SkeletonWidget.rounded(
                      width: 152,
                      height: 208,
                      borderRadius: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (list.isEmpty) {
          final err = (state.error ?? '').trim();
          if (err.isNotEmpty) {
            return _sectionGap(
              child: _explorerInlineState(
                title: 'Catalogue indisponible',
                message: err,
                onRetry: () => context
                    .read<ShoppingPageBlocM>()
                    .add(shop_ev.LoadProductsEvent()),
              ),
            );
          }
          if (raw.isEmpty) {
            return _sectionGap(
              child: _explorerInlineState(
                title: 'Aucun article pour le moment',
                message:
                    'Le catalogue est vide. Revenez plus tard ou rafraîchissez.',
                onRetry: () => context
                    .read<ShoppingPageBlocM>()
                    .add(shop_ev.LoadProductsEvent()),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        return _sectionGap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                titleBold: 'Produits',
                titleLight: ' tendance',
                onSeeAll: _openMarketplace,
              ),
              SizedBox(height: SDSpacing.xs),
              SizedBox(
                height: 228,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
                  itemBuilder: (context, i) {
                    return _ProductTrendCard(
                      product: list[i],
                      bloc: context.read<ShoppingPageBlocM>(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShopsSection(BuildContext context) {
    return BlocBuilder<ShoppingPageBlocM, shop_state.ShoppingPageStateM>(
      builder: (context, state) {
        final shops = state.filteredVendeurs ?? state.vendeurs ?? [];
        final list = shops
            .where((v) => _hasDisplayableImage(v.shopLogo))
            .take(8)
            .toList();
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return _sectionGap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                titleBold: 'Boutiques',
                titleLight: '',
                onSeeAll: _openMarketplace,
              ),
              SizedBox(height: SDSpacing.xs),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
                  itemBuilder: (context, i) {
                    return _ShopPillCard(vendeur: list[i]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExplorerCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ExplorerCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 84,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: SDColors.primary50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? SDColors.primary600 : SDColors.primary100,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                label == 'Voir tout'
                    ? Icons.grid_view_rounded
                    : Icons.handyman_outlined,
                color: SDColors.primary600,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewModeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewModeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SDColors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      elevation: selected ? 1 : 0,
      shadowColor: SDColors.neutral900.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? SDColors.neutral900 : SDColors.neutral500,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: SDTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? SDColors.neutral900 : SDColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetierCard extends StatelessWidget {
  final Prestataire prestataire;

  const _MetierCard({required this.prestataire});

  @override
  Widget build(BuildContext context) {
    // STAB-12B — jamais « null alice »
    final displayName = joinPersonName(
      prenom: prestataire.utilisateur.prenom,
      nom: prestataire.utilisateur.nom,
      fallback: 'Prestataire',
    );
    final note = double.tryParse(prestataire.note ?? '');
    final metier = displayOrFallback(
      prestataire.service.nomservice,
      'Non renseigné',
    );
    final photoUrl = providerPhotoUrl(
      selfie: prestataire.selfie,
      photoProfil: prestataire.utilisateur.photoProfil,
    );

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(
              providerId: prestataire.idprestataire,
            ),
          ),
        );
      },
      child: Container(
        width: 158,
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SDColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: SDColors.neutral900.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SDColors.primary50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: photoUrl != null
                      ? AppImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          placeholderAsset: 'assets/profile_picture.jpg',
                        )
                      : Icon(Icons.engineering,
                          size: 48, color: SDColors.primary400),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (metier.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                child: Text(
                  metier,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.neutral600,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  if (note != null) ...[
                    Icon(Icons.star_rounded,
                        size: 14, color: SDColors.warning500),
                    Text(
                      ' ${note.toStringAsFixed(1)}',
                      style: SDTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreelanceExplorerCard extends StatelessWidget {
  final FreelanceModel freelance;

  const _FreelanceExplorerCard({required this.freelance});

  @override
  Widget build(BuildContext context) {
    final verified = freelance.verificationDocuments?.isVerified == true;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FreelanceDetailsScreen(freelance: freelance),
          ),
        );
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SDColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: SDColors.neutral900.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SDColors.neutral100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: freelance.imagePath.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: freelance.imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorWidget: (_, __, ___) => Icon(
                                Icons.person,
                                size: 40,
                                color: SDColors.neutral400,
                              ),
                            )
                          : Image.asset(
                              freelance.imagePath.isNotEmpty
                                  ? freelance.imagePath
                                  : 'assets/profile_picture.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: 40,
                                color: SDColors.neutral400,
                              ),
                            ),
                    ),
                  ),
                  if (verified)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: SDColors.success500,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: SDColors.white, size: 12),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
              child: Text(
                freelance.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: Text(
                freelance.job,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.neutral600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  Icon(Icons.star_rounded,
                      size: 14, color: SDColors.warning500),
                  Text(
                    freelance.rating.toStringAsFixed(1),
                    style: SDTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (freelance.hourlyRate > 0)
                    Text(
                      '${freelance.hourlyRate.toStringAsFixed(0)} F/h',
                      style: SDTypography.labelSmall.copyWith(
                        color: SDColors.primary600,
                        fontWeight: FontWeight.w700,
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
}

class _ProductTrendCard extends StatelessWidget {
  final shop_state.Product product;
  final ShoppingPageBlocM bloc;

  const _ProductTrendCard({
    required this.product,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: ProductDetails(product: product),
            ),
          ),
        );
      },
      child: Container(
        width: 154,
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SDColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: SDColors.neutral900.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: SDColors.neutral50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product.image.startsWith('http')
                        ? AppImage(
                            imageUrl: product.image,
                            fit: BoxFit.contain,
                            placeholderAsset: 'assets/products/default.png',
                          )
                        : Image.asset(
                            product.image.isNotEmpty
                                ? product.image
                                : 'assets/products/default.png',
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
              child: Text(
                product.price,
                style: SDTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SDColors.neutral900,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.labelSmall.copyWith(
                  color: SDColors.neutral700,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopPillCard extends StatelessWidget {
  final Vendeur vendeur;

  const _ShopPillCard({required this.vendeur});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        try {
          context.push('/vendeurDetails', extra: vendeur);
        } catch (_) {}
      },
      child: Container(
        width: 220,
        padding: EdgeInsets.all(SDSpacing.sm),
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SDColors.neutral200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 48,
                height: 48,
                child: vendeur.shopLogo != null && vendeur.shopLogo!.isNotEmpty
                    ? AppImage(
                        imageUrl: vendeur.shopLogo!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: SDColors.primary50,
                        child:
                            Icon(Icons.storefront, color: SDColors.primary600),
                      ),
              ),
            ),
            SizedBox(width: SDSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    vendeur.shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 14, color: SDColors.warning500),
                      Text(
                        vendeur.rating.toStringAsFixed(1),
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.neutral600,
                        ),
                      ),
                    ],
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
