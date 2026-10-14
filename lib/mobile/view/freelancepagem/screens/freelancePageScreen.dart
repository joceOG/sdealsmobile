import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/freelance_hub_cache.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/freelance_discover_card.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageStateM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';

import '../../../../design_system/colors.dart';
import '../../../../design_system/responsive.dart';
import '../../../../design_system/sd_illustrations.dart';
import '../../../../design_system/spacing.dart';
import '../../../../design_system/typography.dart';
import '../../../../design_system/widgets/sd_illustration.dart';
import '../../../../design_system/widgets/sd_feedback_states.dart';
import '../../common/widgets/universe_hub_header.dart';
import '../freelancepageblocm/freelancePageBlocM.dart';
import '../freelancepageblocm/freelancePageEventM.dart';
import '../freelance_hub_discovery.dart';
import '../models/freelance_model.dart';
import 'freelance_details_screen.dart';

class FreelancePageScreen extends StatelessWidget {
  final List<dynamic> categories;
  final ApiClient? apiClient;

  /// Cache du hub. Les tests peuvent en injecter un isolé.
  final FreelanceHubCache? cache;

  const FreelancePageScreen({
    Key? key,
    this.categories = const [],
    this.apiClient,
    this.cache,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Le BLoC est recréé à chaque ouverture (rien n'est gardé en vie) ;
      // c'est le cache qui évite le spinner à la réouverture.
      create: (_) => FreelancePageBlocM(
        apiClient: apiClient,
        cache: cache ?? FreelanceHubCache.shared,
      )
        ..add(LoadCategorieDataM())
        ..add(LoadServicesEvent())
        ..add(LoadFreelancersEvent()),
      child: const _FreelanceBody(),
    );
  }
}

// ── Corps principal ────────────────────────────────────────────────────────────

class _FreelanceBody extends StatefulWidget {
  const _FreelanceBody();

  @override
  State<_FreelanceBody> createState() => _FreelanceBodyState();
}

class _FreelanceBodyState extends State<_FreelanceBody> {
  void _openFreelanceSearch() => _openSearchFreelance(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UniverseHubHeader(
            copy: UniverseHubCopy.freelance,
            onSearch: _openFreelanceSearch,
            onFilter: _openFreelanceSearch,
          ),
          Expanded(
            child: BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
              builder: (context, state) {
                if (state.isLoading &&
                    (state.listItems == null || state.listItems!.isEmpty) &&
                    state.services.isEmpty &&
                    state.freelancers.isEmpty) {
                  return const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (state.error != null &&
                    state.error!.isNotEmpty &&
                    state.freelancers.isEmpty &&
                    state.services.isEmpty) {
                  return Center(
                    child: SDSectionNeedsConnection(
                      detail: state.error!,
                      onRetry: () => context
                          .read<FreelancePageBlocM>()
                          .add(LoadCategorieDataM()),
                    ),
                  );
                }
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: SDSpacing.xs),
                          _buildIllustratedServices(context, state),
                          const SizedBox(height: SDSpacing.sectionInterval),
                          _buildAllServicesBanner(context, state),
                          const SizedBox(height: SDSpacing.sectionInterval),
                          _buildFreelancers(context, state),
                          if (_popularSkills(state).isNotEmpty) ...[
                            const SizedBox(height: SDSpacing.sectionInterval),
                            _buildSkills(context, state),
                          ],
                          // Écran poussé sans barre d'onglets, bord à bord :
                          // la fin du scroll doit dépasser la barre système
                          // (sinon « Voir le profil » reste sous les boutons
                          // Android).
                          SizedBox(
                            height: SDSpacing.lg +
                                SDResponsive.systemBottomInset(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Catégories (3 colonnes, icons cohérentes) ────────────────────────────────

  List<Categorie> _cats(FreelancePageStateM state) =>
      (state.listItems ?? []).cast<Categorie>();

  /// Grille hub : intentions éditoriales + services réels (voir [pickFreelanceHubDiscoveryServices]).
  List<Service> _illustratedServices(FreelancePageStateM state) {
    return pickFreelanceHubDiscoveryServices(state.services, max: 6);
  }

  Widget _buildIllustratedServices(
    BuildContext context,
    FreelancePageStateM state,
  ) {
    if (state.isLoadingServices && state.services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final all = _illustratedServices(state);
    if (all.isEmpty) {
      if (state.servicesError.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SDSectionNeedsConnection(
            detail: 'Les services Freelance ne sont pas enregistrés ici.',
            onRetry: () => context
                .read<FreelancePageBlocM>()
                .add(LoadServicesEvent()),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    const preview = 6;
    final shown = all.take(preview).toList();
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final useTwoColumns =
        MediaQuery.sizeOf(context).width < 360 || textScale > 1.15;
    final columnCount = useTwoColumns ? 2 : 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Trouvez votre service',
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
              ),
              if (state.services.length > preview)
                GestureDetector(
                  onTap: () =>
                      _openAllIllustratedServices(context, state.services),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tout voir',
                        style: SDTypography.labelMedium.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 16, color: SDColors.primary700),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: SDSpacing.xs),
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              mainAxisSpacing: SDSpacing.cardInterval,
              crossAxisSpacing: SDSpacing.cardInterval,
              childAspectRatio: useTwoColumns ? 1.0 : 0.82,
            ),
            itemCount: shown.length,
            itemBuilder: (context, i) => _HubServiceTile(
              service: shown[i],
              onTap: () => _openService(context, shown[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllServicesBanner(
    BuildContext context,
    FreelancePageStateM state,
  ) {
    final cats = _cats(state);
    if (cats.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openAllCategories(context, cats),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SDColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.grid_view_rounded,
                      color: SDColors.primary600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tous les services freelance',
                        style: SDTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                      Text(
                        'Parcourez les catégories',
                        style: SDTypography.bodySmall
                            .copyWith(color: SDColors.neutral600),
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
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCategories(BuildContext context, FreelancePageStateM state) {
    final all = _cats(state);
    if (all.isEmpty && state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (all.isEmpty) return const SizedBox.shrink();

    // Aperçu : 6 catégories max (2 lignes × 3)
    const preview = 6;
    final shown = all.take(preview).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section — même pattern que JobPage
          Row(
            children: [
              Expanded(
                child: Text(
                  'Catégories',
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
              ),
              if (all.length > preview)
                TextButton(
                  onPressed: () => _openAllCategories(context, all),
                  style: TextButton.styleFrom(
                    foregroundColor: SDColors.primary700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: SDSpacing.xs, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Voir tout',
                    style: SDTypography.labelMedium.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SDSpacing.xs),
          // Grille 3 colonnes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: SDSpacing.xs,
              crossAxisSpacing: SDSpacing.xs,
              childAspectRatio: 0.95,
            ),
            itemCount: shown.length,
            itemBuilder: (context, i) => _CategoryTile(
              categorie: shown[i],
              onTap: () => _openCategory(context, shown[i].nomcategorie),
            ),
          ),
        ],
      ),
    );
  }

  // ── Freelancers ──────────────────────────────────────────────────────────────

  Widget _buildFreelancers(BuildContext context, FreelancePageStateM state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  color: SDColors.primary600, size: 20),
              const SizedBox(width: SDSpacing.xxs),
              Expanded(
                child: Text(
                  'Freelances à découvrir',
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
              ),
              if (state.freelancers.length > 4)
                TextButton(
                  onPressed: () => _openAllFreelancers(context),
                  style: TextButton.styleFrom(
                    foregroundColor: SDColors.primary700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: SDSpacing.xs, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Voir tout',
                    style: SDTypography.labelMedium.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SDSpacing.xxs),
          _buildFreelancerList(context, state),
          if (state.freelancers.length > 1) ...[
            const SizedBox(height: SDSpacing.xxs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _openAllFreelancers(context),
                child: Text(
                  'Voir tous les freelances',
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.primary700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFreelancerList(BuildContext context, FreelancePageStateM state) {
    final list = state.freelancers.take(6).toList();

    // États exclusifs. `isLoadingFreelancers` est aussi levé par le filtre
    // catégorie des sous-pages (même BLoC) : les freelances déjà chargés
    // restent affichés au lieu d'un nouveau chargement au retour sur le hub.
    if (list.isEmpty &&
        (state.isLoadingFreelancers || !state.freelancersLoaded)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: SDSpacing.xs),
        child: Center(
            child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (list.isEmpty &&
        state.freelancersError != null &&
        state.freelancersError!.isNotEmpty) {
      return SDErrorState(
        message: state.freelancersError!,
        onRetry: () => context
            .read<FreelancePageBlocM>()
            .add(LoadFreelancersEvent(force: true)),
      );
    }

    if (list.isEmpty) {
      return SDEmptyState(
        title: 'Aucun freelance disponible',
        message: 'Les profils apparaîtront dès leur publication.',
        icon: Icons.people_outline_rounded,
      );
    }

    void openProfile(FreelanceModel f) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FreelanceDetailsScreen(freelance: f),
          ),
        );

    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: SDSpacing.xs),
      itemBuilder: (context, i) => FreelanceDiscoverCard(
        freelance: list[i],
        onViewProfile: () => openProfile(list[i]),
      ),
    );
  }

  // ── Compétences ──────────────────────────────────────────────────────────────

  List<String> _popularSkills(FreelancePageStateM state) {
    final counts = <String, int>{};
    for (final f in state.freelancers) {
      for (final s in f.skills) {
        final t = s.trim();
        if (t.isEmpty) continue;
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toList();
  }

  Widget _buildSkills(BuildContext context, FreelancePageStateM state) {
    final skills = _popularSkills(state);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tag_rounded,
                  color: SDColors.primary600, size: 20),
              const SizedBox(width: SDSpacing.xxs),
              Expanded(
                child: Text(
                  'Explorer par compétence',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SDSpacing.xs),
          Wrap(
            spacing: SDSpacing.xxs,
            runSpacing: SDSpacing.xxs,
            children: skills
                .map((s) => ActionChip(
                      label: Text(
                        s,
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.neutral800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: SDColors.neutral50,
                      side: const BorderSide(color: SDColors.neutral200),
                      onPressed: () => _openSearchFreelance(context, query: s),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _openService(BuildContext context, Service service) {
    final bloc = context.read<FreelancePageBlocM>();
    final catName = service.categorie?.nomcategorie ?? service.nomservice;
    bloc.add(FilterByCategoryEvent(catName));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: PopScope(
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) bloc.add(ClearFiltersEvent());
            },
            child: _FreelanceServiceDetailScreen(
              service: service,
              onChangeService: () {
                Navigator.of(context).pop();
                _openAllIllustratedServices(
                    context, bloc.state.services.toList());
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openAllIllustratedServices(
    BuildContext context,
    List<Service> services,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AllServicesPage(
          services: services,
          onOpen: (s) {
            Navigator.of(context).pop();
            _openService(context, s);
          },
        ),
      ),
    );
  }

  void _openCategory(BuildContext context, String categoryName) {
    final bloc = context.read<FreelancePageBlocM>();
    bloc.add(FilterByCategoryEvent(categoryName));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: PopScope(
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) bloc.add(ClearFiltersEvent());
            },
            child: _FreelanceCategoryResultsPage(categoryName: categoryName),
          ),
        ),
      ),
    );
  }

  void _openAllCategories(BuildContext context, List<Categorie> all) async {
    final bloc = context.read<FreelancePageBlocM>();
    final selected = await Navigator.of(context).push<Categorie>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: _AllCategoriesPage(categories: all),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    _openCategory(context, selected.nomcategorie);
  }

  void _openAllFreelancers(BuildContext context) {
    final bloc = context.read<FreelancePageBlocM>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const _AllFreelancersPage(),
        ),
      ),
    );
  }

  /// Suggestions « À découvrir » de la recherche Freelance : uniquement des
  /// termes réels du hub (services Freelance chargés + compétences des
  /// profils). Jamais la liste éditoriale Métiers (Plombier, Maçon…).
  List<String> _searchDiscoveryTerms() {
    final state = context.read<FreelancePageBlocM>().state;
    final seen = <String>{};
    final out = <String>[];
    void add(String raw) {
      final t = raw.trim();
      if (t.isEmpty || !seen.add(t.toLowerCase())) return;
      out.add(t);
    }

    for (final s in _illustratedServices(state)) {
      add(s.nomservice);
    }
    for (final s in _popularSkills(state)) {
      add(s);
    }
    return out.take(8).toList();
  }

  /// Toujours dans le périmètre Freelance (chips compétence comme en-tête) :
  /// l'élargissement à toute l'app reste un choix explicite dans l'écran.
  void _openSearchFreelance(BuildContext context, {String? query}) {
    final terms = _searchDiscoveryTerms();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchPageScreenM(
          initialIndex: 2,
          initialQuery: query,
          scope: 'freelance',
          discoveryTerms: terms,
        ),
      ),
    );
  }
}

// ── Tuile service illustrée (imageservice dashboard) ──────────────────────────

class _HubServiceTile extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;

  const _HubServiceTile({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imgUrl = normalizeMediaUrl(service.imageservice);
    final shortLabel = freelanceServiceShortLabel(service);
    return Semantics(
      button: true,
      label: service.nomservice,
      child: Material(
        color: SDColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SDColors.neutral200),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: imgUrl != null
                    ? AppImage(imageUrl: imgUrl, fit: BoxFit.cover)
                    : ColoredBox(
                        color: SDColors.primary50,
                        child: Icon(
                          freelanceServiceFallbackIcon(service),
                          color: SDColors.primary600,
                          size: 28,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 5, 4, 6),
                child: Text(
                  shortLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tous les services (groupés par catégorie) ─────────────────────────────────

class _AllServicesPage extends StatefulWidget {
  final List<Service> services;
  final void Function(Service) onOpen;

  const _AllServicesPage({required this.services, required this.onOpen});

  @override
  State<_AllServicesPage> createState() => _AllServicesPageState();
}

class _AllServicesPageState extends State<_AllServicesPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _selectedCat; // null = "Toutes"

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final cats = <String>{};
    for (final s in widget.services) {
      final c = s.categorie?.nomcategorie;
      if (c != null && c.isNotEmpty) cats.add(c);
    }
    return cats.toList()..sort();
  }

  List<Service> get _filtered {
    var list = widget.services;
    if (_selectedCat != null) {
      list =
          list.where((s) => s.categorie?.nomcategorie == _selectedCat).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((s) =>
              s.nomservice.toLowerCase().contains(q) ||
              s.aliases.any((a) => a.toLowerCase().contains(q)))
          .toList();
    }
    return list;
  }

  Map<String, List<Service>> get _grouped {
    final map = <String, List<Service>>{};
    for (final s in _filtered) {
      final c = s.categorie?.nomcategorie ?? 'Autres';
      (map[c] ??= []).add(s);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cats = _categories;
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header vert
            Container(
              color: SDColors.primary50,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: SDColors.neutral900, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tous les services',
                            style: SDTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: SDColors.neutral900,
                            ),
                          ),
                          Text(
                            'Univers Freelance',
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Barre de recherche
                  Container(
                    decoration: BoxDecoration(
                      color: SDColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SDColors.neutral200),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un service',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: SDColors.neutral400, size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                                child: const Icon(Icons.close_rounded,
                                    color: SDColors.neutral400, size: 18),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        hintStyle: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral400),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Chips catégories
            if (cats.isNotEmpty)
              Container(
                color: SDColors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      _catChip('Toutes', _selectedCat == null,
                          () => setState(() => _selectedCat = null)),
                      ...cats.map((c) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _catChip(c, _selectedCat == c,
                                () => setState(() => _selectedCat = c)),
                          )),
                    ],
                  ),
                ),
              ),
            const Divider(height: 1, color: SDColors.neutral100),
            // ── Liste groupée
            Expanded(
              child: grouped.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun service trouvé.',
                        style: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral500),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 32),
                      children: [
                        for (final entry in grouped.entries) ...[
                          _ServiceSectionHeader(categoryName: entry.key),
                          ...entry.value.map(
                            (s) => _ServiceListRow(
                              service: s,
                              onTap: () => widget.onOpen(s),
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

  Widget _catChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? SDColors.primary600 : SDColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? SDColors.primary600 : SDColors.neutral200,
          ),
        ),
        child: Text(
          label,
          style: SDTypography.labelSmall.copyWith(
            color: selected ? SDColors.white : SDColors.neutral700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ServiceSectionHeader extends StatelessWidget {
  final String categoryName;
  const _ServiceSectionHeader({required this.categoryName});

  static IconData _icon(String name) {
    final n = name.toLowerCase();
    if (n.contains('design') || n.contains('graphi') || n.contains('créa'))
      return Icons.palette_outlined;
    if (n.contains('vidéo') || n.contains('video') || n.contains('montage'))
      return Icons.play_circle_outline_rounded;
    if (n.contains('photo')) return Icons.photo_camera_outlined;
    if (n.contains('illustr')) return Icons.brush_outlined;
    if (n.contains('développ') ||
        n.contains('dev') ||
        n.contains('code') ||
        n.contains('program')) return Icons.code_rounded;
    if (n.contains('cloud') || n.contains('ia') || n.contains('tech'))
      return Icons.computer_outlined;
    if (n.contains('market') || n.contains('communi'))
      return Icons.campaign_outlined;
    if (n.contains('seo') || n.contains('référenc'))
      return Icons.search_rounded;
    if (n.contains('rédac') || n.contains('content') || n.contains('texte'))
      return Icons.article_outlined;
    if (n.contains('audio') || n.contains('son') || n.contains('music'))
      return Icons.music_note_outlined;
    if (n.contains('form') || n.contains('cours')) return Icons.school_outlined;
    if (n.contains('traduc') || n.contains('langue'))
      return Icons.translate_rounded;
    if (n.contains('data') || n.contains('analys'))
      return Icons.analytics_outlined;
    if (n.contains('admin') || n.contains('assist'))
      return Icons.folder_copy_outlined;
    if (n.contains('business') || n.contains('financ'))
      return Icons.bar_chart_rounded;
    return Icons.work_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(_icon(categoryName), size: 22, color: SDColors.primary600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              categoryName,
              style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: SDColors.neutral900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceListRow extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;
  const _ServiceListRow({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imgUrl = normalizeMediaUrl(service.imageservice);
    final alias = service.aliases.isNotEmpty ? service.aliases.first : null;

    return Material(
      color: SDColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: SDColors.neutral100)),
          ),
          child: Row(
            children: [
              // Miniature
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: imgUrl != null
                      ? AppImage(imageUrl: imgUrl, fit: BoxFit.cover)
                      : ColoredBox(
                          color: SDColors.primary50,
                          child: Icon(
                            _ServiceSectionHeader._icon(
                                service.categorie?.nomcategorie ?? ''),
                            color: SDColors.primary600,
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Nom + alias
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.nomservice,
                      style: SDTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SDColors.neutral900,
                      ),
                    ),
                    if (alias != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        alias,
                        style: SDTypography.bodySmall
                            .copyWith(color: SDColors.neutral500),
                      ),
                    ],
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
  }
}

// ── Écran détail service (Capture 2) ─────────────────────────────────────────

class _FreelanceServiceDetailScreen extends StatefulWidget {
  final Service service;
  final VoidCallback? onChangeService;

  const _FreelanceServiceDetailScreen({
    required this.service,
    this.onChangeService,
  });

  @override
  State<_FreelanceServiceDetailScreen> createState() =>
      _FreelanceServiceDetailScreenState();
}

class _FreelanceServiceDetailScreenState
    extends State<_FreelanceServiceDetailScreen> {
  late final TextEditingController _searchCtrl;
  String _sortBy = 'rating';

  /// Catégorie actuellement sélectionnée dans le panneau filtre (null = toutes).
  String? _activeFilterCategory;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.service.nomservice);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catName = widget.service.categorie?.nomcategorie ?? 'Freelance';

    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header
            _buildHeader(catName),
            // ── Search bar
            _buildSearchBar(),
            // ── Filter chips
            _buildFilterChips(),
            const Divider(height: 1, color: SDColors.neutral100),
            // ── Titre section + tri
            _buildSectionTitle(context),
            const Divider(height: 1, color: SDColors.neutral100),
            // ── Liste freelances
            Expanded(
              child: BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
                builder: (ctx, state) => _buildList(ctx, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String catName) {
    return Container(
      color: SDColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + breadcrumb
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_rounded,
                    size: 22, color: SDColors.neutral900),
              ),
              const SizedBox(width: 10),
              Text(
                'Freelance\u00a0·\u00a0$catName',
                style: SDTypography.labelSmall
                    .copyWith(color: SDColors.neutral500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Titre du service
          Text(
            widget.service.nomservice,
            style: SDTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w900,
              color: SDColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Comparez les profils et leurs réalisations.',
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: widget.onChangeService,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Changer de service',
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.primary600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: SDColors.primary600),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: SDColors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: SDColors.neutral50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SDColors.neutral200),
        ),
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded,
                color: SDColors.neutral400, size: 20),
            suffixIcon: GestureDetector(
              onTap: () => _searchCtrl.clear(),
              child: const Icon(Icons.close_rounded,
                  color: SDColors.neutral400, size: 18),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            hintStyle:
                SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final isFiltered = _activeFilterCategory != null;
    return Container(
      color: SDColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
          builder: (ctx, state) => Row(
            children: [
              _filterChip(
                icon: Icons.tune_rounded,
                label: isFiltered
                    ? (_activeFilterCategory ?? 'Filtres')
                    : 'Filtres',
                active: isFiltered,
                onTap: () => _openFilterSheet(ctx, state),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'Tarif horaire',
                trailing: Icons.keyboard_arrow_down_rounded,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'Localisation',
                trailing: Icons.keyboard_arrow_down_rounded,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ouvre le panneau « Filtres de recherche » en bottom sheet.
  void _openFilterSheet(BuildContext ctx, FreelancePageStateM state) {
    final bloc = ctx.read<FreelancePageBlocM>();
    final categories = state.listItems ?? const <Categorie>[];

    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FreelanceFilterSheet(
        categories: categories,
        initialCategory: _activeFilterCategory,
        onApply: (selectedCat) {
          setState(() => _activeFilterCategory = selectedCat);
          if (selectedCat == null) {
            bloc.add(ClearFiltersEvent());
          } else {
            bloc.add(FilterByCategoryEvent(selectedCat));
          }
        },
      ),
    );
  }

  Widget _filterChip({
    IconData? icon,
    required String label,
    IconData? trailing,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final fg = active ? SDColors.primary700 : SDColors.neutral700;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? SDColors.primary50 : SDColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? SDColors.primary600 : SDColors.neutral200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 5),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.labelSmall.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 2),
              Icon(trailing, size: 16, color: fg),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Text(
            'Professionnels',
            style: SDTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: SDColors.neutral900,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() {
              _sortBy = _sortBy == 'rating' ? 'hourlyRate' : 'rating';
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SDColors.neutral50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SDColors.neutral200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_vert_rounded,
                      size: 16, color: SDColors.neutral600),
                  const SizedBox(width: 4),
                  Text(
                    'Trier',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.neutral600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: SDColors.neutral600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, FreelancePageStateM state) {
    if (state.isLoadingFreelancers) {
      return const Center(
        child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    var list = List<FreelanceModel>.from(state.filteredFreelancers);
    if (_sortBy == 'hourlyRate') {
      list.sort((a, b) => a.hourlyRate.compareTo(b.hourlyRate));
    } else {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }

    if (list.isEmpty) {
      final showIllustration = state.freelancersLoaded &&
          !state.isLoadingFreelancers &&
          state.freelancersError == null &&
          (state.filterError == null || state.filterError!.isEmpty);
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showIllustration) ...[
                        const SDIllustration(
                          asset: SDIllustrations.professionalsEmpty,
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        'Aucun professionnel pour ce service.',
                        textAlign: TextAlign.center,
                        style: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral500),
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

    final shown = list.take(10).toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: shown.length + 1, // +1 pour le bouton final
      separatorBuilder: (_, __) => const SizedBox(height: SDSpacing.xs),
      itemBuilder: (ctx, i) {
        if (i == shown.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () => context
                  .read<FreelancePageBlocM>()
                  .add(LoadFreelancersEvent(force: true)),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              iconAlignment: IconAlignment.end,
              label: const Text('Afficher plus de profils'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SDColors.primary600,
                side: const BorderSide(color: SDColors.primary600),
                minimumSize:
                    const Size(double.infinity, SDSpacing.minTouchTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SDSpacing.radiusButton),
                ),
                textStyle: SDTypography.labelMedium
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          );
        }
        final f = shown[i];
        return _ServiceFreelancerCard(
          freelancer: f,
          onViewProfile: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FreelanceDetailsScreen(freelance: f),
            ),
          ),
        );
      },
    );
  }
}

// ── Carte freelance avec portfolio (écran détail service) ────────────────────

class _ServiceFreelancerCard extends StatelessWidget {
  final FreelanceModel freelancer;
  final VoidCallback onViewProfile;

  const _ServiceFreelancerCard({
    required this.freelancer,
    required this.onViewProfile,
  });

  static String _formatRate(double rate) {
    if (rate <= 0) return '';
    final s = rate.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u00a0');
      buf.write(s[i]);
    }
    return '${buf.toString()}\u00a0FCFA\u00a0/\u00a0heure';
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl =
        freelancer.imagePath.startsWith('http') ? freelancer.imagePath : null;
    final initial = freelancer.name.trim().isNotEmpty
        ? freelancer.name.trim()[0].toUpperCase()
        : '?';
    final hasJob =
        freelancer.job.isNotEmpty && freelancer.job != 'Non renseigné';
    final skill =
        freelancer.skills.isNotEmpty ? freelancer.skills.first.trim() : null;
    final jobLine = [
      if (hasJob) freelancer.job,
      if (skill != null && skill.isNotEmpty) skill,
    ].join('\u00a0·\u00a0');
    final hasLocation = freelancer.location.isNotEmpty;
    final hasRate = freelancer.hourlyRate > 0;
    final portfolio = freelancer.portfolioItems
        .where((p) => p.imageUrl.startsWith('http'))
        .take(2)
        .toList();
    final hasPortfolio = portfolio.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        border: Border.all(color: SDColors.neutral200),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Profil
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: imgUrl != null
                      ? AppImage(imageUrl: imgUrl, fit: BoxFit.cover)
                      : ColoredBox(
                          color: SDColors.primary50,
                          child: Center(
                            child: Text(
                              initial,
                              style: SDTypography.titleSmall.copyWith(
                                color: SDColors.primary600,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Nom + job + localisation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      freelancer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                      ),
                    ),
                    if (jobLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        jobLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.primary600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (hasLocation) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: SDColors.neutral400),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              freelancer.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.bodySmall.copyWith(
                                color: SDColors.neutral500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.favorite_border_rounded,
                  size: 20, color: SDColors.neutral400),
            ],
          ),
          // ── Portfolio
          if (hasPortfolio) ...[
            const SizedBox(height: 12),
            Text(
              'Aperçu des réalisations',
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(portfolio.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: AppImage(
                          imageUrl: portfolio[i].imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
          // ── Prix + bouton
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasRate)
                Expanded(
                  child: Text(
                    _formatRate(freelancer.hourlyRate),
                    style: SDTypography.titleSmall.copyWith(
                      color: SDColors.primary600,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                const Spacer(),
              FilledButton.icon(
                onPressed: onViewProfile,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                iconAlignment: IconAlignment.end,
                label: const Text('Voir le profil'),
                style: FilledButton.styleFrom(
                  backgroundColor: SDColors.primary600,
                  minimumSize: const Size(0, 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SDSpacing.radiusButton),
                  ),
                  textStyle: SDTypography.labelSmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tuile catégorie (3 colonnes) ──────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final Categorie categorie;
  final VoidCallback onTap;

  const _CategoryTile({required this.categorie, required this.onTap});

  static IconData _icon(String name) {
    final n = name.toLowerCase();
    if (n.contains('design') || n.contains('graphi'))
      return Icons.palette_outlined;
    if (n.contains('développ') || n.contains('dev') || n.contains('program'))
      return Icons.code_rounded;
    if (n.contains('market') || n.contains('communi'))
      return Icons.campaign_outlined;
    if (n.contains('business') || n.contains('financ') || n.contains('compta'))
      return Icons.bar_chart_rounded;
    if (n.contains('rédac') || n.contains('content') || n.contains('texte'))
      return Icons.article_outlined;
    if (n.contains('admin') || n.contains('assist'))
      return Icons.folder_copy_outlined;
    if (n.contains('vidéo') || n.contains('video') || n.contains('montage'))
      return Icons.play_circle_outline_rounded;
    if (n.contains('form') || n.contains('cours')) return Icons.school_outlined;
    if (n.contains('photo')) return Icons.photo_camera_outlined;
    if (n.contains('traduc') || n.contains('langue'))
      return Icons.translate_rounded;
    if (n.contains('audio') || n.contains('son') || n.contains('music'))
      return Icons.music_note_outlined;
    if (n.contains('data') || n.contains('analys'))
      return Icons.analytics_outlined;
    if (n.contains('seo') || n.contains('référenc'))
      return Icons.search_rounded;
    return Icons.work_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = normalizeMediaUrl(categorie.imagecategorie);
    // Ne tente pas d'afficher le damier s'il provient du fichier source.
    // L'icône DS est plus fiable si pas d'image http valide.
    final hasValidImage = imgUrl != null;

    return Material(
      color: SDColors.neutral50,
      borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
            border: Border.all(color: SDColors.neutral100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: hasValidImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AppImage(
                            imageUrl: imgUrl,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Icon(
                            _icon(categorie.nomcategorie),
                            size: 28,
                            color: SDColors.primary600,
                          ),
                        ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                  child: Text(
                    categorie.nomcategorie,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.neutral800,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Vignette freelance en mode liste (un seul résultat) ───────────────────────

class _FreelancerListTile extends StatelessWidget {
  final FreelanceModel freelancer;

  const _FreelancerListTile({required this.freelancer});

  @override
  Widget build(BuildContext context) {
    final imgUrl = safeImageUrl(freelancer.imagePath);
    final initial = freelancer.name.trim().isNotEmpty
        ? freelancer.name.trim()[0].toUpperCase()
        : '?';
    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FreelanceDetailsScreen(freelance: freelancer),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SDSpacing.radiusCard),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: imgUrl != null
                      ? AppImage(
                          imageUrl: imgUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
                          color: SDColors.primary50,
                          child: Center(
                            child: Text(
                              initial,
                              style: SDTypography.titleSmall.copyWith(
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
                      displayOrFallback(freelancer.name, 'Freelance'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                      ),
                    ),
                    Text(
                      displayOrFallback(freelancer.job, freelancer.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.bodySmall
                          .copyWith(color: SDColors.neutral600),
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
  }
}

// ── Page résultats catégorie ──────────────────────────────────────────────────

class _FreelanceCategoryResultsPage extends StatelessWidget {
  final String categoryName;

  const _FreelanceCategoryResultsPage({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: AppBar(
        backgroundColor: SDColors.white,
        foregroundColor: SDColors.neutral900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(categoryName,
            style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800, color: SDColors.neutral900)),
      ),
      body: BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
        builder: (context, state) {
          return Column(
            children: [
              // Bandeau d'erreur filtre
              if (state.filterError != null && state.filterError!.isNotEmpty)
                ColoredBox(
                  color: SDColors.warning50,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 16, color: SDColors.warning700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.filterError!,
                            style: SDTypography.labelSmall
                                .copyWith(color: SDColors.warning700),
                            maxLines: 2,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context
                              .read<FreelancePageBlocM>()
                              .add(FilterByCategoryEvent(categoryName,
                                  force: true)),
                          style: TextButton.styleFrom(
                            foregroundColor: SDColors.warning700,
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (state.isLoadingFreelancers)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: _buildList(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, FreelancePageStateM state) {
    final list = state.filteredFreelancers;
    if (list.isEmpty && !state.isLoadingFreelancers) {
      if (state.filterError != null && state.filterError!.isNotEmpty ||
          state.freelancersError != null && state.freelancersError!.isNotEmpty) {
        return SDSectionNeedsConnection(
          detail:
              'Cette catégorie n’a pas pu être chargée. Ce n’est pas une liste vide.',
          onRetry: () {
            final category = state.selectedCategory;
            context.read<FreelancePageBlocM>().add(
                  category == null || category == 'Tous'
                      ? LoadFreelancersEvent(force: true)
                      : FilterByCategoryEvent(category, force: true),
                );
          },
        );
      }
      final showIllustration = state.freelancersLoaded &&
          state.freelancersError == null &&
          (state.filterError == null || state.filterError!.isEmpty);
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showIllustration) ...[
                        const SDIllustration(
                          asset: SDIllustrations.professionalsEmpty,
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        'Aucun freelance pour cette catégorie.',
                        textAlign: TextAlign.center,
                        style: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral500),
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
    return ListView.separated(
      // Padding explicite = pas d'inset auto : ajouter la barre système.
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 24 + SDResponsive.systemBottomInset(context)),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: SDSpacing.xs),
      itemBuilder: (context, i) {
        final f = list[i];
        return _FreelancerListTile(freelancer: f);
      },
    );
  }
}

// ── Toutes les catégories (grille) ────────────────────────────────────────────

class _AllCategoriesPage extends StatelessWidget {
  final List<Categorie> categories;

  const _AllCategoriesPage({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: AppBar(
        backgroundColor: SDColors.white,
        foregroundColor: SDColors.neutral900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Toutes les catégories',
            style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800, color: SDColors.neutral900)),
      ),
      body: GridView.builder(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + SDResponsive.systemBottomInset(context)),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: SDSpacing.xs,
          crossAxisSpacing: SDSpacing.xs,
          childAspectRatio: 0.95,
        ),
        itemCount: categories.length,
        itemBuilder: (context, i) => _CategoryTile(
          categorie: categories[i],
          onTap: () => Navigator.of(context).pop<Categorie>(categories[i]),
        ),
      ),
    );
  }
}

// ── Tous les freelances (liste verticale) ─────────────────────────────────────

class _AllFreelancersPage extends StatelessWidget {
  const _AllFreelancersPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: AppBar(
        backgroundColor: SDColors.white,
        foregroundColor: SDColors.neutral900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Tous les freelances',
            style: SDTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800, color: SDColors.neutral900)),
      ),
      body: BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
        builder: (context, state) {
          final list = state.freelancers;
          if (list.isEmpty) {
            return Center(
              child: SDEmptyState(
                title: 'Aucun freelance',
                message: 'Les profils apparaîtront dès leur publication.',
                icon: Icons.people_outline_rounded,
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 24 + SDResponsive.systemBottomInset(context)),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: SDSpacing.xs),
            itemBuilder: (context, i) =>
                _FreelancerListTile(freelancer: list[i]),
          );
        },
      ),
    );
  }
}

// ── Panneau Filtres de recherche ──────────────────────────────────────────────

/// Bottom sheet « Filtres de recherche » — sélection par catégorie (un seul choix).
///
/// Appelle [onApply] avec `null` quand « Réinitialiser » est pressé,
/// et avec le nom de la catégorie sélectionnée sinon.
class _FreelanceFilterSheet extends StatefulWidget {
  final List<Categorie> categories;
  final String? initialCategory;
  final ValueChanged<String?> onApply;

  const _FreelanceFilterSheet({
    required this.categories,
    required this.onApply,
    this.initialCategory,
  });

  @override
  State<_FreelanceFilterSheet> createState() => _FreelanceFilterSheetState();
}

class _FreelanceFilterSheetState extends State<_FreelanceFilterSheet> {
  /// null = « Toutes les catégories »
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCategory;
  }

  void _apply() {
    widget.onApply(_selected);
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() => _selected = null);
    widget.onApply(null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories;

    return Container(
      decoration: const BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SDColors.neutral200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // ── Header titre + X
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtres de recherche',
                        style: SDTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SDColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Univers Freelance',
                        style: SDTypography.bodySmall
                            .copyWith(color: SDColors.neutral500),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.close_rounded,
                        size: 22, color: SDColors.neutral600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── Corps scrollable (section Catégorie)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de section
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Catégorie',
                          style: SDTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: SDColors.neutral900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Un seul choix',
                          style: SDTypography.caption.copyWith(
                            color: SDColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Option « Toutes les catégories »
                  _CategoryRow(
                    icon: Icons.grid_view_rounded,
                    label: 'Toutes les catégories',
                    selected: _selected == null,
                    onTap: () => setState(() => _selected = null),
                  ),
                  // Catégories dynamiques
                  ...categories.map(
                    (cat) => _CategoryRow(
                      icon: _ServiceSectionHeader._icon(cat.nomcategorie),
                      label: cat.nomcategorie,
                      selected: _selected == cat.nomcategorie,
                      onTap: () => setState(() => _selected = cat.nomcategorie),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Pied fixe : Réinitialiser + Afficher les résultats
          const Divider(height: 1, color: SDColors.neutral100),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SDColors.primary700,
                        side: const BorderSide(color: SDColors.primary600),
                        minimumSize: const Size(
                            double.infinity, SDSpacing.minTouchTarget),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _apply,
                      style: FilledButton.styleFrom(
                        backgroundColor: SDColors.primary600,
                        minimumSize: const Size(
                            double.infinity, SDSpacing.minTouchTarget),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Afficher les résultats'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne de catégorie dans le panneau filtre.
class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? SDColors.primary50 : SDColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? SDColors.primary300 : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? SDColors.primary700 : SDColors.neutral500,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: SDTypography.bodyMedium.copyWith(
                  color: selected ? SDColors.primary800 : SDColors.neutral800,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Radio
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? SDColors.primary600 : Colors.transparent,
                border: Border.all(
                  color: selected ? SDColors.primary600 : SDColors.neutral300,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Center(
                      child:
                          Icon(Icons.circle, size: 10, color: SDColors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// (fin du fichier)
