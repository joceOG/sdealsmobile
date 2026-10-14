import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/data/models/vendeur.dart';
import 'package:sdealsmobile/data/services/freelance_hub_cache.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageBlocM.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageEventM.dart'
    as free_ev;
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageStateM.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/models/freelance_model.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/screens/freelance_details_screen.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelance_hub_discovery.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/screens/freelancePageScreen.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageEventM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/jobpageblocm/jobPageStateM.dart';
import 'package:sdealsmobile/mobile/view/jobpagem/screens/detailPageScreenM.dart';
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
import 'package:sdealsmobile/mobile/view/common/widgets/provider_photo_card.dart';
import 'package:go_router/go_router.dart';

import 'package:sdealsmobile/mobile/view/explorer/widgets/explorer_metiers_map_panel.dart';
import '../../../../design_system/design_system.dart';
import '../../common/widgets/app_image.dart';
import '../../common/widgets/freelance_discover_card.dart';
import '../../homepagem/home_place_label.dart';
import '../../common/widgets/universe_service_shortcut_card.dart';
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
            ..add(LoadServiceDataJobM())  // charge les raccourcis Métiers (shortcuts)
            ..add(const LoadProviderMatchingM(serviceType: '', location: '')),
        ),
        BlocProvider(
          create: (_) => FreelancePageBlocM(cache: FreelanceHubCache.shared)
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

  /// Périmètre de recherche = univers sélectionné dans Explorer. « Tous »
  /// reste global ; ailleurs l'élargissement global est un choix explicite
  /// proposé par l'écran de recherche.
  String get _searchScope {
    switch (_universe) {
      case _ExplorerUniverse.metiers:
        return 'metiers';
      case _ExplorerUniverse.freelance:
        return 'freelance';
      case _ExplorerUniverse.marketplace:
        return 'emarket';
      case _ExplorerUniverse.tous:
        return 'global';
    }
  }

  void _openSearch([String? query]) {
    final q = (query ?? _searchCtrl.text).trim();
    final scope = _searchScope;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchPageScreenM(
          initialQuery: q.isEmpty ? null : q,
          scope: scope,
          // Onglet « Freelances » d'emblée, comme depuis le hub Freelance.
          initialIndex: scope == 'freelance' ? 2 : 0,
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

  /// Navigation depuis une carte service Freelance → _FreelanceCategoryPage
  /// avec le bon contexte (catégorie réelle + libellé service).
  void _navigateToServiceCategory(BuildContext context, Service s) {
    final catName = s.categorie?.nomcategorie ?? s.nomservice;
    final bloc = context.read<FreelancePageBlocM>();
    bloc.add(free_ev.FilterByCategoryEvent(catName));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: PopScope(
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) bloc.add(free_ev.ClearFiltersEvent());
            },
            child: _FreelanceCategoryPage(
              categoryName: catName,
              serviceName: s.nomservice,
            ),
          ),
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
                          child: _buildServiceShortcutsMetiers(context),
                        ),
                      if (_universe == _ExplorerUniverse.freelance)
                        SliverToBoxAdapter(
                          child: _buildServiceShortcutsFreelance(context),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_showMetiers) _buildMetiersGrid(context),
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ligne 1 : titre + bascule Liste/Carte
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Explorer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.titleLarge.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_mapAvailable && !showMap) _buildListMapToggle(),
                ],
              ),
              const SizedBox(height: 8),
              // Ligne 2 : barre de recherche
              _buildSearchRow(context),
              const SizedBox(height: 8),
              // Ligne 3 : localisation + sélecteur univers
              Row(
                children: [
                  // Localisation compacte
                  Semantics(
                    button: true,
                    label: 'Ville ${SDClientLocationPolicy.fallbackCity}. Modifier',
                    child: InkWell(
                      onTap: _openLocation,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: SDColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: SDColors.neutral200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on,
                                size: 13, color: SDColors.primary600),
                            const SizedBox(width: 3),
                            Text(
                              SDClientLocationPolicy.fallbackCity,
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.neutral900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sélecteur univers compact
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildUniverseChip(
                            label: 'Métiers',
                            value: _ExplorerUniverse.metiers,
                            icon: const ClientUniversePictogram.metiers(size: 14),
                          ),
                          const SizedBox(width: 6),
                          _buildUniverseChip(
                            label: 'Freelance',
                            value: _ExplorerUniverse.freelance,
                            icon: const ClientUniversePictogram.freelance(size: 14),
                          ),
                          if (ClientFeatureFlags.emarketEnabled) ...[
                            const SizedBox(width: 6),
                            _buildUniverseChip(
                              label: 'Marché',
                              value: _ExplorerUniverse.marketplace,
                              icon: const Icon(Icons.shopping_bag_rounded,
                                  size: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUniverseChip({
    required String label,
    required _ExplorerUniverse value,
    required Widget icon,
  }) {
    final selected = _universe == value;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Univers $label',
      child: GestureDetector(
        onTap: () => _selectUniverse(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? SDColors.primary600 : SDColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? SDColors.primary600 : SDColors.neutral200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  selected ? SDColors.white : SDColors.primary600,
                  BlendMode.srcIn,
                ),
                child: icon,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: SDTypography.labelSmall.copyWith(
                  color: selected ? SDColors.white : SDColors.neutral800,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
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

  /// Libellé court — même logique que JobPage.
  static String _shortcutLabel(String name) {
    const labelMap = <String, String>{
      'plomberie': 'Plombier',
      'plombier': 'Plombier',
      'électricité': 'Électricien',
      'electricite': 'Électricien',
      'électricien': 'Électricien',
      'aide ménagère': 'Ménage',
      'aide menagere': 'Ménage',
      'ménagère': 'Ménage',
      'menagere': 'Ménage',
      'ménage': 'Ménage',
      'menage': 'Ménage',
      'maçonnerie': 'Maçon',
      'maconnerie': 'Maçon',
      'maçon': 'Maçon',
      'mécanique auto': 'Mécanicien auto',
      'mecanique auto': 'Mécanicien auto',
      'mécanicien': 'Mécanicien auto',
      'coiffure': 'Coiffeur',
      'coiffeur': 'Coiffeur',
    };
    final lower = name.toLowerCase().trim();
    for (final entry in labelMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return name.length > 14 ? '${name.substring(0, 13)}…' : name;
  }

  /// Tarif formaté depuis un Prestataire — jamais "0 FCFA".
  static String? _tarifFor(Prestataire p) {
    double v = p.prixprestataire;
    String? suffix;
    if (v <= 0 && p.tarifHoraireMin != null && p.tarifHoraireMin! > 0) {
      v = p.tarifHoraireMin!;
      suffix = '/h';
    }
    if (v <= 0) return null;
    final digits = v.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('\u00a0');
      buf.write(digits[i]);
    }
    return '${buf.toString()} FCFA${suffix ?? ''}';
  }

  /// Commune/quartier lisible — jamais GPS.
  static String? _locationFor(Prestataire p) {
    final zones = p.zoneIntervention ?? const <String>[];
    return firstReadablePlace([
      ...zones,
      p.localisation,
    ]);
  }

  /// Note valide — jamais 0.0.
  static double? _noteFor(Prestataire p) {
    final v =
        double.tryParse(p.note?.replaceAll(',', '.').trim() ?? '');
    return (v != null && v > 0) ? v : null;
  }

  /// Raccourcis Métiers — photo plein-format, vrais serviceId, navigation → DetailPage.
  Widget _buildServiceShortcutsMetiers(BuildContext context) {
    return BlocBuilder<JobPageBlocM, JobPageStateM>(
      builder: (context, state) {
        final items = state.shortcuts.take(6).toList();
        if (items.isEmpty) {
          if (state.isLoading2) return const SizedBox.shrink();
          // Pas de raccourcis configurés → accès direct à JobPage
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JobPageScreenM()),
              ),
              icon: const Icon(Icons.handyman_outlined, size: 16),
              label: const Text('Tous les métiers'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SDColors.primary700,
                side: const BorderSide(color: SDColors.primary200),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre + lien "Tous les métiers" sur la même ligne.
              // Wrap garantit que le lien passe à la ligne plutôt que de
              // comprimer le titre sur écran étroit ou texte agrandi.
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Quel professionnel cherchez-vous\u00a0?',
                        style: SDTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const JobPageScreenM()),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tous les m\u00e9tiers',
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.primary600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward,
                              size: 13, color: SDColors.primary600),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final s = items[index];
                    final img = normalizeMediaUrl(s.imageservice);
                    final label = _shortcutLabel(s.nomservice);
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetailPage(
                            title: s.nomservice,
                            image: img ?? '',
                            serviceId: s.idservice,
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 116,
                          height: 128,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              img != null
                                  ? AppImage(imageUrl: img, fit: BoxFit.cover)
                                  : Container(
                                      color: SDColors.primary100,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                          Icons.handyman_outlined,
                                          color: SDColors.primary500,
                                          size: 36),
                                    ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.70),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 8,
                                bottom: 8,
                                right: 4,
                                child: Text(
                                  label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: SDTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  /// Carrousel de services Freelance — cartes illustrées, navigation → résultats catégorie.
  Widget _buildServiceShortcutsFreelance(BuildContext context) {
    return BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
      builder: (context, state) {
        final isLoading = state.isLoadingServices;
        final services = pickFreelanceHubDiscoveryServices(state.services, max: 6);

        // Skeletons pendant le chargement
        if (isLoading && services.isEmpty) {
          return _buildFreelanceServicesSkeletons();
        }

        if (services.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre + "Tout voir" — Wrap évite la compression sur petit écran
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Quel service recherchez-vous\u00a0?',
                        style: SDTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const FreelancePageScreen(categories: []),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tout voir',
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.primary600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 13, color: SDColors.primary600),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SDSpacing.xs),
              SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 16),
                  itemCount: services.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: SDSpacing.cardInterval),
                  itemBuilder: (context, i) {
                    final s = services[i];
                    final img = normalizeMediaUrl(s.imageservice);
                    final label = freelanceServiceShortLabel(s);
                    return UniverseServiceShortcutCard(
                      label: label,
                      semanticsLabel: s.nomservice,
                      imageUrl: img,
                      fallbackIcon: freelanceServiceFallbackIcon(s),
                      onTap: () =>
                          _navigateToServiceCategory(context, services[i]),
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

  Widget _buildFreelanceServicesSkeletons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonWidget.rounded(width: 220, height: 20, borderRadius: 4),
          const SizedBox(height: 10),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => SkeletonWidget.rounded(
                  width: 116, height: 128, borderRadius: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SDColors.neutral200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewModeBtn(
            label: 'Liste',
            icon: Icons.view_list_rounded,
            selected: _viewMode == _ExplorerViewMode.list,
            onTap: () => setState(() => _viewMode = _ExplorerViewMode.list),
          ),
          _ViewModeBtn(
            label: 'Carte',
            icon: Icons.map_outlined,
            selected: _viewMode == _ExplorerViewMode.map,
            onTap: () => setState(() => _viewMode = _ExplorerViewMode.map),
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
                    'Que recherchez-vous\u00a0?',
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
  // ignore: unused_element
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

  // ignore: unused_element
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

  Widget _buildMetiersGrid(BuildContext context) {
    return BlocBuilder<JobPageBlocM, JobPageStateM>(
      builder: (context, state) {
        // displayProviders : nearby prioritaire sur matched, filtres chips respectés.
        // Explorer affiche tous les profils autorisés (pas seulement ceux avec photo).
        final list = state.displayProviders.take(12).toList();
        final isLoading = state.isMatchingLoading || state.isNearbyLoading;
        final errorMsg = state.matchError.isNotEmpty
            ? state.matchError
            : state.nearbyError.isNotEmpty
                ? state.nearbyError
                : null;

        // Titre de section — toujours présent
        final sectionTitle = Padding(
          padding: const EdgeInsets.only(bottom: SDSpacing.xxs),
          child: Text(
            'Découvrir des professionnels',
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
        );

        // ── Liste vide ──────────────────────────────────────────────────────
        if (list.isEmpty) {
          // Skeleton : chargement en cours OU état initial avant que le BLoC
          // ait émis (isMatchingLoading=false mais matchedProviders vide sans erreur).
          // Ces deux états sont indiscernables sans flag supplémentaire ;
          // mieux vaut montrer un skeleton que la page blanche.
          if (isLoading || errorMsg == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle,
                GridView.builder(
                  shrinkWrap: true,
                  primary: false,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.67,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 4,
                  itemBuilder: (_, __) => _ProviderCardSkeleton(),
                ),
              ],
            );
          }
          // Erreur réseau sans données précédentes
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle,
              _ProvidersErrorState(
                onRetry: () => context.read<JobPageBlocM>().add(
                      const LoadProviderMatchingM(
                          serviceType: '', location: ''),
                    ),
              ),
            ],
          );
        }

        // ── Données disponibles ─────────────────────────────────────────────
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle,
            GridView.builder(
              shrinkWrap: true,
              primary: false,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.67,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final p = list[i];
                return ProviderPhotoCard(
                  name: joinPersonName(
                    prenom: p.utilisateur.prenom,
                    nom: p.utilisateur.nom,
                    fallback: 'Prestataire',
                  ),
                  metier: p.service.nomservice.trim().isNotEmpty
                      ? p.service.nomservice
                      : null,
                  photoUrl: providerPhotoUrl(
                    selfie: p.selfie,
                    photoProfil: p.utilisateur.photoProfil,
                  ),
                  note: _noteFor(p),
                  tarifLabel: _tarifFor(p),
                  location: _locationFor(p),
                  verified: p.verifier,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProviderProfileScreen(
                        providerId: p.idprestataire,
                        providerData: p.toJson(),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Rafraîchissement en échec avec données déjà visibles → bannière discrète
            if (errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_outlined,
                        size: 14, color: SDColors.neutral400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Actualisation impossible',
                        style: SDTypography.bodySmall
                            .copyWith(color: SDColors.neutral500),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: SDColors.primary600,
                      ),
                      onPressed: () => context.read<JobPageBlocM>().add(
                            const LoadProviderMatchingM(
                                serviceType: '', location: ''),
                          ),
                      child: Text('Réessayer',
                          style: SDTypography.labelSmall.copyWith(
                              color: SDColors.primary600)),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFreelanceSection(BuildContext context) {
    return BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
      builder: (context, state) {
        // Tous les profils autorisés — pas de filtre par image.
        final list = state.freelancers.take(12).toList();
        final count = state.freelancers.length;
        final isLoading = state.isLoadingFreelancers;
        final error = state.freelancersError;
        final loaded = state.freelancersLoaded;

        // En-tête de section : titre + compteur si données connues
        Widget sectionTitle = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Freelances \u00e0 d\u00e9couvrir',
              style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: SDColors.neutral900,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$count profil${count > 1 ? 's' : ''}',
                style: SDTypography.bodySmall
                    .copyWith(color: SDColors.neutral500),
              ),
            ],
          ],
        );

        // ── État : chargement / initial ───────────────────────────────────
        if (!loaded || (isLoading && list.isEmpty)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle,
              const SizedBox(height: SDSpacing.xxs),
              const _FreelanceCardSkeleton(),
            ],
          );
        }

        // ── État : erreur sans données ────────────────────────────────────
        if (list.isEmpty && error != null && error.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle,
              const SizedBox(height: SDSpacing.xxs),
              _explorerInlineState(
                title: 'Chargement impossible',
                message: 'V\u00e9rifiez votre connexion.',
                onRetry: () => context
                    .read<FreelancePageBlocM>()
                    .add(free_ev.LoadFreelancersEvent(force: true)),
              ),
            ],
          );
        }

        // ── État : vide après succès ─────────────────────────────────────
        if (list.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle,
              const SizedBox(height: SDSpacing.xxs),
              _explorerInlineState(
                title: 'Aucun freelance disponible',
                message: 'De nouveaux talents appara\u00eetront bient\u00f4t.',
                onRetry: () => context
                    .read<FreelancePageBlocM>()
                    .add(free_ev.LoadFreelancersEvent(force: true)),
              ),
            ],
          );
        }

        // ── Données disponibles ───────────────────────────────────────────
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle,
            const SizedBox(height: SDSpacing.xxs),
            ListView.separated(
              shrinkWrap: true,
              primary: false,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: SDSpacing.xs),
              itemBuilder: (context, i) => FreelanceDiscoverCard(
                freelance: list[i],
                onViewProfile: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        FreelanceDetailsScreen(freelance: list[i]),
                  ),
                ),
              ),
            ),
            // Bannière erreur discrète lors d'un rafraîchissement raté
            if (list.isNotEmpty && error != null && error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_outlined,
                        size: 14, color: SDColors.neutral400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Actualisation impossible',
                          style: SDTypography.bodySmall
                              .copyWith(color: SDColors.neutral500)),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: SDColors.primary600,
                      ),
                      onPressed: () => context
                          .read<FreelancePageBlocM>()
                          .add(free_ev.LoadFreelancersEvent(force: true)),
                      child: const Text('R\u00e9essayer'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: SDSpacing.md),
            // ── Encart "Un besoin précis ?" ────────────────────────────
            _PreciseNeedEncart(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FreelancePageScreen(categories: []),
                ),
              ),
            ),
          ],
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

// ignore: unused_element
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
                          ? AppImage(
                              imageUrl: freelance.imagePath,
                              fit: BoxFit.cover,
                            )
                          : ColoredBox(
                              color: SDColors.neutral100,
                              child: Icon(
                                Icons.person_outline_rounded,
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
                  if (freelance.rating > 0) ...[
                    Icon(Icons.star_rounded,
                        size: 14, color: SDColors.warning500),
                    Text(
                      freelance.rating.toStringAsFixed(1),
                      style: SDTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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

// ── Skeleton carte freelance ──────────────────────────────────────────────────

class _FreelanceCardSkeleton extends StatelessWidget {
  const _FreelanceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        border: Border.all(color: SDColors.neutral100),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonWidget.rounded(width: 100, height: 120, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonWidget.rounded(
                    width: double.infinity, height: 16, borderRadius: 4),
                const SizedBox(height: 6),
                SkeletonWidget.rounded(width: 100, height: 13, borderRadius: 4),
                const SizedBox(height: 8),
                SkeletonWidget.rounded(width: 80, height: 11, borderRadius: 4),
                const SizedBox(height: 8),
                Row(children: [
                  SkeletonWidget.rounded(width: 60, height: 24, borderRadius: 8),
                  const SizedBox(width: 6),
                  SkeletonWidget.rounded(width: 60, height: 24, borderRadius: 8),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Encart "Un besoin précis ?" ───────────────────────────────────────────────

class _PreciseNeedEncart extends StatelessWidget {
  final VoidCallback onTap;

  const _PreciseNeedEncart({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SDColors.primary100,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.search_rounded,
                size: 20, color: SDColors.primary600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Un besoin pr\u00e9cis\u00a0?',
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Explorez tous les services freelance.',
                  style:
                      SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Parcourir',
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.primary600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded,
                    size: 13, color: SDColors.primary600),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton carte prestataire ────────────────────────────────────────────────

class _ProviderCardSkeleton extends StatelessWidget {
  const _ProviderCardSkeleton();

  // ignore: unused_element — référencée dans _buildMetiersGrid via lambda
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        border: Border.all(color: SDColors.neutral100),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Zone photo skeleton
          Expanded(
            child: SkeletonWidget.rounded(
              borderRadius: 0,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Lignes texte skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonWidget.rounded(width: double.infinity, height: 14, borderRadius: 4),
                const SizedBox(height: 6),
                SkeletonWidget.rounded(width: 80, height: 11, borderRadius: 4),
                const SizedBox(height: 6),
                SkeletonWidget.rounded(width: 60, height: 11, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── État erreur section professionnels ────────────────────────────────────────

class _ProvidersErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProvidersErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: SDColors.neutral50,
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.wifi_rounded, size: 48, color: SDColors.neutral300),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: SDColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel, size: 20, color: SDColors.neutral400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Chargement impossible',
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vérifiez votre connexion.',
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: SDColors.primary600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SDSpacing.radiusButton),
                ),
              ),
              child: Text(
                'Réessayer',
                style: SDTypography.labelMedium.copyWith(
                  color: SDColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page résultats catégorie Freelance (depuis raccourcis Explorer).
/// Limite API : filtre par catégorie uniquement (pas par service).
class _FreelanceCategoryPage extends StatelessWidget {
  final String categoryName;

  /// Nom du service sélectionné — utilisé dans le sous-titre pour indiquer
  /// que le filtre s'applique à la catégorie associée, pas au service exact.
  final String serviceName;

  const _FreelanceCategoryPage({
    required this.categoryName,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: AppBar(
        backgroundColor: SDColors.white,
        foregroundColor: SDColors.neutral900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // Titre = nom réel de la catégorie, pas du service
        title: Text(
          categoryName,
          style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800, color: SDColors.neutral900),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Précision honnête sur la limite du filtre
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text(
              'Professionnels de la catégorie associée à\u00a0\u00ab\u00a0$serviceName\u00a0\u00bb',
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral500,
                height: 1.4,
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
              builder: (context, state) {
          if (state.isLoadingFreelancers) {
            return const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final list = state.filteredFreelancers;
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline_rounded,
                        size: 48, color: SDColors.neutral300),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun freelance pour cette catégorie.',
                      textAlign: TextAlign.center,
                      style: SDTypography.bodyMedium
                          .copyWith(color: SDColors.neutral500),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: SDSpacing.xs),
            itemBuilder: (context, i) {
              final f = list[i];
              final imgUrl = f.imagePath.startsWith('http')
                  ? f.imagePath
                  : null;
              return Material(
                color: SDColors.white,
                borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FreelanceDetailsScreen(freelance: f),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(SDSpacing.radiusCard),
                      border: Border.all(color: SDColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: imgUrl != null
                                ? AppImage(
                                    imageUrl: imgUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  )
                                : ColoredBox(
                                    color: SDColors.primary50,
                                    child: Center(
                                      child: Text(
                                        f.name.isNotEmpty
                                            ? f.name[0].toUpperCase()
                                            : '?',
                                        style:
                                            SDTypography.titleSmall.copyWith(
                                          color: SDColors.primary700,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: SDSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SDTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                f.job,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SDTypography.bodySmall.copyWith(
                                    color: SDColors.primary600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: SDColors.neutral400),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),  // BlocBuilder
    ),    // Expanded
  ],      // Column children
        ),      // Column (body)
    );
  }
}
