import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/models/service.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageStateM.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';

import '../../../../design_system/colors.dart';
import '../../../../design_system/widgets/sd_app_bar_icon_button.dart';
import '../../../../design_system/spacing.dart';
import '../../../../design_system/typography.dart';
import '../../../../design_system/widgets/sd_entity_card.dart';
import '../freelancepageblocm/freelancePageBlocM.dart';
import '../freelancepageblocm/freelancePageEventM.dart';
import '../models/freelance_model.dart';
import 'freelance_details_screen.dart';

/// Nombre max de catégories affichées sur le hub (le reste via « Voir toutes »).
const int _kCategoryPreviewCount = 8;

String _formatFcfaHour(double v) {
  if (v >= 1000) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} FCFA/h';
  }
  return '${v.toStringAsFixed(0)} FCFA/h';
}

class FreelancePageScreen extends StatelessWidget {
  final List<dynamic> categories;

  const FreelancePageScreen({Key? key, this.categories = const []})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FreelancePageBlocM()
        ..add(LoadCategorieDataM())
        ..add(LoadFreelancersEvent())
        ..add(LoadServicesEvent()),
      child: const _FreelancePageScreenContent(),
    );
  }
}

class _FreelancePageScreenContent extends StatefulWidget {
  const _FreelancePageScreenContent({Key? key}) : super(key: key);

  @override
  State<_FreelancePageScreenContent> createState() =>
      _FreelancePageScreenContentState();
}

class _FreelancePageScreenContentState
    extends State<_FreelancePageScreenContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
          builder: (context, state) {
            if (state.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: SDColors.primary600),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      SDSpacing.md,
                      SDSpacing.xs,
                      SDSpacing.md,
                      SDSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopHeader(context),
                        SizedBox(height: SDSpacing.md),
                        _buildSearchField(context),
                        SizedBox(height: SDSpacing.lg),
                        _buildCategoryGrid(context, state),
                        SizedBox(height: SDSpacing.md),
                        Center(child: _buildSeeAllCategoriesButton(context, state)),
                        SizedBox(height: SDSpacing.xl),
                        _buildSectionHeaderRow(
                          leadingIcon: Icons.build,
                          title: 'Services populaires',
                          actionLabel: 'Tout',
                          onAction: () => _openSearchFreelance(context),
                        ),
                        SizedBox(height: SDSpacing.sm),
                        _buildPopularServicesRow(state),
                        SizedBox(height: SDSpacing.xl),
                        _buildSectionHeaderRow(
                          leadingIcon: Icons.people,
                          title: 'Freelances disponibles',
                          actionLabel: 'Voir tout',
                          onAction: () => _openAllFreelancers(context),
                          titleMaxLines: 2,
                        ),
                        SizedBox(height: SDSpacing.sm),
                        _buildAvailableFreelancersRow(state),
                        SizedBox(height: SDSpacing.xl),
                        _buildSectionTitleOnly(
                          leadingIcon: Icons.flash_on,
                          title: 'Offres rapides',
                        ),
                        SizedBox(height: SDSpacing.sm),
                        _buildQuickOffers(context),
                        SizedBox(height: SDSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Freelance',
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SDTypography.headlineSmall.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: SDColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: SDColors.neutral200),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, color: SDColors.neutral900),
            tooltip: 'Fermer',
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  /// Même gabarit que Métiers (`JobPageScreenM._buildHeroSearchBar`).
  Widget _buildSearchField(BuildContext context) {
    void openSearch() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SearchPageScreenM(initialIndex: 2),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SDSpacing.sm,
        vertical: SDSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SDColors.primary100, width: 1),
        boxShadow: [
          BoxShadow(
            color: SDColors.neutral900.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: SDColors.primary600, size: 20),
          SizedBox(width: SDSpacing.xs),
          Expanded(
            child: GestureDetector(
              onTap: openSearch,
              behavior: HitTestBehavior.opaque,
              child: Text(
                'Quel service freelance cherchez-vous ?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral400,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: openSearch,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SDColors.primary600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.tune, color: SDColors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  List<Categorie> _categoriesList(FreelancePageStateM state) {
    final raw = state.listItems;
    if (raw == null) return [];
    return raw.cast<Categorie>();
  }

  Widget _buildCategoryGrid(BuildContext context, FreelancePageStateM state) {
    final all = _categoriesList(state);
    final preview = all.take(_kCategoryPreviewCount).toList();

    if (preview.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: SDSpacing.md),
        child: Text(
          'Catégories en cours de chargement…',
          style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: preview.length,
      itemBuilder: (context, index) {
        final cat = preview[index];
        return _CategoryCell(
          categorie: cat,
          onTap: () => _openCategory(context, cat.nomcategorie),
        );
      },
    );
  }

  Widget _buildSeeAllCategoriesButton(
      BuildContext context, FreelancePageStateM state) {
    final all = _categoriesList(state);
    if (all.length <= _kCategoryPreviewCount) {
      return const SizedBox.shrink();
    }
    return OutlinedButton(
      onPressed: () async {
        final selected = await Navigator.of(context).push<Categorie>(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<FreelancePageBlocM>(),
              child: _FreelanceAllCategoriesPage(categories: all),
            ),
          ),
        );
        if (!mounted || selected == null) return;
        _openCategory(context, selected.nomcategorie);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: SDColors.primary600,
        side: BorderSide(color: SDColors.primary600.withOpacity(0.35)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: SDSpacing.lg,
          vertical: SDSpacing.sm,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Voir toutes les catégories',
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.primary600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward, size: 14, color: SDColors.primary600),
        ],
      ),
    );
  }

  /// Même pattern que `JobPageScreenM` (Catégories / Services populaires / Artisans proches).
  Widget _buildSectionHeaderRow({
    required IconData leadingIcon,
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
    int titleMaxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(leadingIcon, color: SDColors.primary600, size: 22),
        SizedBox(width: SDSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: SDTypography.titleMedium.copyWith(
              color: SDColors.neutral900,
            ),
            maxLines: titleMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.arrow_forward, size: 14),
          label: Text(actionLabel, style: SDTypography.labelSmall),
          style: TextButton.styleFrom(
            foregroundColor: SDColors.primary600,
            padding: SDSpacing.chipPadding,
            minimumSize: const Size(0, 32),
          ),
        ),
      ],
    );
  }

  /// Titre de section sans CTA (même typo que Métiers).
  Widget _buildSectionTitleOnly({
    required IconData leadingIcon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(leadingIcon, color: SDColors.primary600, size: 22),
        SizedBox(width: SDSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: SDTypography.titleMedium.copyWith(
              color: SDColors.neutral900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPopularServicesRow(FreelancePageStateM state) {
    if (state.isLoadingServices) {
      return SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: SDColors.primary600),
        ),
      );
    }
    if (state.servicesError.isNotEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'Impossible de charger les services',
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
        ),
      );
    }
    final services = state.services.take(12).toList();
    if (services.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'Aucun service pour le moment',
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
        ),
      );
    }

    return SizedBox(
      height: 228,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
        itemBuilder: (context, index) {
          final service = services[index];
          final hint = _serviceRatingHint(state, service);
          return _PopularServiceCard(
            service: service,
            rating: hint.$1,
            reviewLabel: hint.$2,
            onTap: () => _openSearchFreelance(context),
          );
        },
      ),
    );
  }

  /// (rating affichée, libellé avis). Si pas de données fiables, note null → UI adaptée.
  (double?, String?) _serviceRatingHint(
      FreelancePageStateM state, Service service) {
    final catName = service.categorie?.nomcategorie;
    if (catName == null || catName.isEmpty) return (null, null);
    final matches = state.freelancers
        .where((f) =>
            f.category.toLowerCase().trim() == catName.toLowerCase().trim())
        .toList();
    if (matches.isEmpty) return (null, null);
    final avg =
        matches.fold<double>(0, (s, f) => s + f.rating) / matches.length;
    final jobs = matches.fold<int>(0, (s, f) => s + f.completedJobs);
    return (avg, '$jobs mission${jobs > 1 ? 's' : ''}');
  }

  Widget _buildAvailableFreelancersRow(FreelancePageStateM state) {
    final list = state.freelancers
        .where((f) =>
            f.availabilityStatus.toLowerCase().contains('disponible'))
        .toList();
    if (list.isEmpty) {
      final fallback = state.freelancers.take(8).toList();
      if (fallback.isEmpty) {
        return SizedBox(
          height: 80,
          child: Center(
            child: Text(
              'Aucun freelance pour le moment',
              style:
                  SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
            ),
          ),
        );
      }
      return SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: fallback.length,
          separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
          itemBuilder: (context, i) => _FreelanceAvailabilityCard(
            freelancer: fallback[i],
            forceAvailableBadge: false,
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
        itemBuilder: (context, i) => _FreelanceAvailabilityCard(
          freelancer: list[i],
          forceAvailableBadge: true,
        ),
      ),
    );
  }

  Widget _buildQuickOffers(BuildContext context) {
    const offers = <Map<String, dynamic>>[
      {'label': 'CV en 1h', 'icon': Icons.description_outlined},
      {'label': 'Logo Pro', 'icon': Icons.rocket_launch_outlined},
      {'label': 'Site urgent', 'icon': Icons.bolt_outlined},
    ];

    return Row(
      children: [
        for (var i = 0; i < offers.length; i++) ...[
          if (i > 0) SizedBox(width: SDSpacing.sm),
          Expanded(
            child: _QuickOfferTile(
              label: offers[i]['label'] as String,
              icon: offers[i]['icon'] as IconData,
              onTap: () => _openSearchFreelance(context),
            ),
          ),
        ],
      ],
    );
  }

  void _openSearchFreelance(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SearchPageScreenM(initialIndex: 2),
      ),
    );
  }

  void _openAllFreelancers(BuildContext context) {
    final bloc = context.read<FreelancePageBlocM>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const _FreelanceAllListPage(title: 'Freelances disponibles'),
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
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                bloc.add(ClearFiltersEvent());
              }
            },
            child: _FreelanceCategoryResultsPage(categoryName: categoryName),
          ),
        ),
      ),
    );
  }
}

// --- Category cell (grid) ---

class _CategoryCell extends StatelessWidget {
  final Categorie categorie;
  final VoidCallback onTap;

  const _CategoryCell({required this.categorie, required this.onTap});

  IconData _iconForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('design')) return Icons.palette_outlined;
    if (n.contains('dévelop') || n.contains('dev')) return Icons.code;
    if (n.contains('market')) return Icons.campaign_outlined;
    if (n.contains('business') || n.contains('finance'))
      return Icons.bar_chart_rounded;
    if (n.contains('rédac') || n.contains('redac')) return Icons.article_outlined;
    if (n.contains('admin')) return Icons.folder_copy_outlined;
    if (n.contains('vidéo') || n.contains('video')) return Icons.play_circle_outline;
    if (n.contains('form')) return Icons.school_outlined;
    if (n.contains('photo')) return Icons.photo_camera_outlined;
    if (n.contains('traduc')) return Icons.translate;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final img = categorie.imagecategorie;
    final hasNetworkImage =
        img.isNotEmpty && (img.startsWith('http://') || img.startsWith('https://'));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: SDColors.primary50.withOpacity(0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SDColors.primary100),
            ),
            child: Center(
              child: hasNetworkImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: img,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                          _iconForName(categorie.nomcategorie),
                          color: SDColors.primary600,
                          size: 28,
                        ),
                      ),
                    )
                  : Icon(
                      _iconForName(categorie.nomcategorie),
                      color: SDColors.primary600,
                      size: 28,
                    ),
            ),
          ),
          SizedBox(height: SDSpacing.xxxs),
          Text(
            categorie.nomcategorie,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.neutral800,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Popular service card (horizontal) ---

class _PopularServiceCard extends StatelessWidget {
  final Service service;
  final double? rating;
  final String? reviewLabel;
  final VoidCallback onTap;

  const _PopularServiceCard({
    required this.service,
    required this.rating,
    required this.reviewLabel,
    required this.onTap,
  });

  String _priceLine() {
    final p = service.prixmoyen.trim();
    if (p.isEmpty) return 'Sur devis';
    return 'À partir de $p FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: SDColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SDColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: SDColors.neutral900.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: SizedBox(
                height: 96,
                width: double.infinity,
                child: service.imageservice.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: service.imageservice,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: SDColors.neutral100,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: SDColors.primary50,
                          child: Icon(Icons.image_outlined,
                              color: SDColors.primary400, size: 40),
                        ),
                      )
                    : Container(
                        color: SDColors.primary50,
                        child: Icon(Icons.handyman_outlined,
                            color: SDColors.primary500, size: 40),
                        alignment: Alignment.center,
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                SDSpacing.xs,
                SDSpacing.xs,
                SDSpacing.xs,
                SDSpacing.xxs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.nomservice,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelLarge.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: SDSpacing.xxxs),
                  Text(
                    _priceLine(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (rating != null) ...[
                    SizedBox(height: SDSpacing.xxxs),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 16, color: SDColors.warning600),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: SDTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SDColors.neutral800,
                          ),
                        ),
                        if (reviewLabel != null) ...[
                          Expanded(
                            child: Text(
                              ' · $reviewLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.labelSmall.copyWith(
                                color: SDColors.neutral500,
                              ),
                            ),
                          ),
                        ],
                      ],
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

// --- Freelance availability card ---

class _FreelanceAvailabilityCard extends StatelessWidget {
  final FreelanceModel freelancer;
  final bool forceAvailableBadge;

  const _FreelanceAvailabilityCard({
    required this.freelancer,
    required this.forceAvailableBadge,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = forceAvailableBadge ||
        freelancer.availabilityStatus.toLowerCase().contains('disponible');
    final responseText = 'Répond en ${freelancer.responseTime}h';
    final ratingText = '${freelancer.rating.toStringAsFixed(1)}/5';
    final imageUrl = freelancer.imagePath.startsWith('http')
        ? freelancer.imagePath
        : null;
    final meta = freelancer.isTopRated
        ? 'Top Rated • $responseText'
        : '${freelancer.completedJobs} projets • $responseText';

    return SDEntityCard(
      type: SDEntityCardType.freelance,
      title: freelancer.name,
      subtitle: freelancer.job,
      fallbackIcon: Icons.laptop_mac_rounded,
      imageUrl: imageUrl,
      ratingText: ratingText,
      metaText: meta,
      statusText: showBadge ? 'Disponible' : freelancer.availabilityStatus,
      priceText: _formatFcfaHour(freelancer.hourlyRate),
      ctaLabel: 'Contacter',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FreelanceDetailsScreen(freelance: freelancer),
          ),
        );
      },
    );
  }
}

class _QuickOfferTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickOfferTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SDColors.neutral50,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: SDSpacing.md,
            horizontal: SDSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: SDColors.primary600, size: 26),
              SizedBox(height: SDSpacing.xxs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: SDColors.neutral800,
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

// --- Full category grid page ---

class _FreelanceAllCategoriesPage extends StatelessWidget {
  final List<Categorie> categories;

  const _FreelanceAllCategoriesPage({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDAppBarIconThemed(
        style: SDAppBarIconStyles.onLightSurface,
        bar: AppBar(
        elevation: 0,
        backgroundColor: SDColors.white,
        surfaceTintColor: SDColors.white,
        foregroundColor: SDColors.neutral900,
        title: Text(
          'Toutes les catégories',
          style: SDTypography.titleLarge.copyWith(color: SDColors.neutral900),
        ),
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(SDSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _CategoryCell(
            categorie: cat,
            onTap: () => Navigator.of(context).pop<Categorie>(cat),
          );
        },
      ),
    );
  }
}

// --- Category drill-down (filtered freelancers) ---

class _FreelanceCategoryResultsPage extends StatelessWidget {
  final String categoryName;

  const _FreelanceCategoryResultsPage({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDAppBarIconThemed(
        style: SDAppBarIconStyles.onLightSurface,
        bar: AppBar(
        elevation: 0,
        backgroundColor: SDColors.white,
        surfaceTintColor: SDColors.white,
        foregroundColor: SDColors.neutral900,
        title: Text(
          categoryName,
          style: SDTypography.titleLarge.copyWith(color: SDColors.neutral900),
        ),
        ),
      ),
      body: BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
        builder: (context, state) {
          final list = state.filteredFreelancers;
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(SDSpacing.lg),
                child: Text(
                  'Aucun freelance dans cette catégorie pour le moment.',
                  textAlign: TextAlign.center,
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.neutral500,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.all(SDSpacing.md),
            itemCount: list.length,
            separatorBuilder: (_, __) => SizedBox(height: SDSpacing.sm),
            itemBuilder: (context, i) {
              final f = list[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: f.imagePath.startsWith('http')
                      ? NetworkImage(f.imagePath)
                      : (f.imagePath.isNotEmpty
                          ? AssetImage(f.imagePath)
                          : const AssetImage('assets/profile_picture.jpg'))
                          as ImageProvider,
                ),
                title: Text(f.name,
                    style: SDTypography.titleSmall
                        .copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text('${f.job} · ${f.rating.toStringAsFixed(1)} ★'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FreelanceDetailsScreen(freelance: f),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// --- All freelancers vertical list ---

class _FreelanceAllListPage extends StatelessWidget {
  final String title;

  const _FreelanceAllListPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDAppBarIconThemed(
        style: SDAppBarIconStyles.onLightSurface,
        bar: AppBar(
        elevation: 0,
        backgroundColor: SDColors.white,
        surfaceTintColor: SDColors.white,
        foregroundColor: SDColors.neutral900,
        title: Text(
          title,
          style: SDTypography.titleLarge.copyWith(color: SDColors.neutral900),
        ),
        ),
      ),
      body: BlocBuilder<FreelancePageBlocM, FreelancePageStateM>(
        builder: (context, state) {
          final list = state.freelancers;
          if (list.isEmpty) {
            return Center(
              child: Text(
                'Aucun freelance',
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral500,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.all(SDSpacing.md),
            itemCount: list.length,
            separatorBuilder: (_, __) => SizedBox(height: SDSpacing.sm),
            itemBuilder: (context, i) {
              final f = list[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: f.imagePath.startsWith('http')
                      ? NetworkImage(f.imagePath)
                      : (f.imagePath.isNotEmpty
                          ? AssetImage(f.imagePath)
                          : const AssetImage('assets/profile_picture.jpg'))
                          as ImageProvider,
                ),
                title: Text(
                  f.name,
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${f.job} · ${f.rating.toStringAsFixed(1)} ★ · ${_formatFcfaHour(f.hourlyRate)}',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FreelanceDetailsScreen(freelance: f),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
