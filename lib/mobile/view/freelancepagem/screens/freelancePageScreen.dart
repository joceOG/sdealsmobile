import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/models/categorie.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:sdealsmobile/data/utils/media_url.dart';
import 'package:sdealsmobile/mobile/view/freelancepagem/freelancepageblocm/freelancePageStateM.dart';
import 'package:sdealsmobile/mobile/view/common/widgets/app_image.dart';
import 'package:sdealsmobile/mobile/view/searchpagem/screens/searchPageScreenM.dart';

import '../../../../design_system/colors.dart';
import '../../../../design_system/widgets/sd_app_bar_icon_button.dart';
import '../../../../design_system/spacing.dart';
import '../../../../design_system/typography.dart';
import '../../../../design_system/widgets/sd_entity_card.dart';
import '../../../../design_system/widgets/sd_feedback_states.dart';
import '../freelancepageblocm/freelancePageBlocM.dart';
import '../freelancepageblocm/freelancePageEventM.dart';
import '../models/freelance_model.dart';
import 'freelance_details_screen.dart';

/// Nombre max de catégories affichées sur le hub (le reste via « Voir toutes »).
const int _kCategoryPreviewCount = 8;

String _formatFcfaHour(double v) {
  if (v <= 0) return '';
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

/// Null si pas de note réelle (jamais « 0.0 » inventé).
String? _ratingLabelOrNull(double rating) {
  if (rating <= 0) return null;
  return rating.toStringAsFixed(1);
}

String _freelanceListSubtitle(FreelanceModel f) {
  final parts = <String>[
    displayOrFallback(f.job, f.category),
    if (_ratingLabelOrNull(f.rating) != null) _ratingLabelOrNull(f.rating)!,
    if (f.hourlyRate > 0) _formatFcfaHour(f.hourlyRate),
  ];
  return parts.where((e) => e.trim().isNotEmpty).join(' · ');
}

class FreelancePageScreen extends StatelessWidget {
  final List<dynamic> categories;
  /// Injection optionnelle (tests / stubs).
  final ApiClient? apiClient;

  const FreelancePageScreen({
    Key? key,
    this.categories = const [],
    this.apiClient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // STAB-13B Phase 2 — hub talent-first : catégories + freelances uniquement.
    // LoadServicesEvent retiré (Services populaires hors V1).
    return BlocProvider(
      create: (_) => FreelancePageBlocM(apiClient: apiClient)
        ..add(LoadCategorieDataM())
        ..add(LoadFreelancersEvent()),
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
              return const Center(
                child: SDLoadingInline(message: 'Chargement…'),
              );
            }

            if (state.error != null && state.error!.isNotEmpty) {
              return Center(
                child: SDErrorState(
                  message: state.error!,
                  onRetry: () => context
                      .read<FreelancePageBlocM>()
                      .add(LoadCategorieDataM()),
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopHeader(context),
                        SizedBox(height: SDSpacing.md),
                        _buildSearchField(context),
                        SizedBox(height: SDSpacing.lg),
                        _buildCategoryGrid(context, state),
                        SizedBox(height: SDSpacing.md),
                        Center(
                            child:
                                _buildSeeAllCategoriesButton(context, state)),
                        SizedBox(height: SDSpacing.xl),
                        _buildSectionHeaderRow(
                          leadingIcon: Icons.people_outline,
                          title: 'Freelances recommandés',
                          actionLabel: 'Voir tout',
                          onAction: () => _openAllFreelancers(context),
                          titleMaxLines: 2,
                        ),
                        SizedBox(height: SDSpacing.sm),
                        _buildRecommendedFreelancers(state),
                        if (_popularSkills(state).isNotEmpty) ...[
                          SizedBox(height: SDSpacing.xl),
                          _buildSectionTitleOnly(
                            leadingIcon: Icons.tag,
                            title: 'Compétences populaires',
                          ),
                          SizedBox(height: SDSpacing.sm),
                          _buildPopularSkillsChips(context, state),
                        ],
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
            style: SDTypography.displayMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
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
                'Quelle compétence recherchez-vous ?',
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
        // Ratio plus bas = cellules plus hautes (évite overflow labels 2 lignes @320).
        childAspectRatio: 0.68,
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

  /// Skills agrégées depuis les freelances réels (pas de fake catalogue).
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

  Widget _buildPopularSkillsChips(
      BuildContext context, FreelancePageStateM state) {
    final skills = _popularSkills(state);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .map(
            (s) => ActionChip(
              label: Text(
                s,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SDTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: SDColors.neutral800,
                ),
              ),
              backgroundColor: SDColors.neutral50,
              side: BorderSide(color: SDColors.neutral200),
              onPressed: () => _openSearchFreelance(context, query: s),
              visualDensity: VisualDensity.compact,
            ),
          )
          .toList(),
    );
  }

  Widget _buildRecommendedFreelancers(FreelancePageStateM state) {
    if (state.isLoadingFreelancers) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: SDSpacing.md),
        child: Center(
          child: SDLoadingInline(message: 'Chargement des freelances…'),
        ),
      );
    }

    if (state.freelancersError != null && state.freelancersError!.isNotEmpty) {
      return SDErrorState(
        message: state.freelancersError!,
        onRetry: () =>
            context.read<FreelancePageBlocM>().add(LoadFreelancersEvent()),
      );
    }

    if (state.isFreelancersEmpty || state.freelancers.isEmpty) {
      // Pas de SizedBox(height: 100) — évite BOTTOM OVERFLOWED.
      return SDEmptyState(
        title: 'Aucun freelance disponible',
        message: 'De nouveaux talents apparaîtront bientôt.',
        icon: Icons.people_outline,
      );
    }

    final list = state.freelancers.take(8).toList();
    // Hauteur ≥ ~236 pour que SDEntityCard ne passe pas en mode compact
    // (CTA « Voir le profil » masqué si maxHeight/textScale < 210).
    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
        itemBuilder: (context, i) => _FreelanceTalentCard(freelancer: list[i]),
      ),
    );
  }

  void _openSearchFreelance(BuildContext context, {String? query}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchPageScreenM(
          initialIndex: 2,
          initialQuery: query,
        ),
      ),
    );
  }

  void _openAllFreelancers(BuildContext context) {
    final bloc = context.read<FreelancePageBlocM>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const _FreelanceAllListPage(title: 'Freelances recommandés'),
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
    // imagecategorie = backend / dashboard admin. Icône DS seulement si URL absente.
    final img = normalizeMediaUrl(categorie.imagecategorie);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final iconH =
              (constraints.maxHeight * 0.52).clamp(34.0, 52.0).toDouble();
          final iconSize = (iconH * 0.5).clamp(18.0, 28.0).toDouble();
          return Column(
            children: [
              Container(
                height: iconH,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: SDColors.primary50.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SDColors.primary100),
                ),
                clipBehavior: Clip.antiAlias,
                child: img != null
                    ? SizedBox(
                        width: double.infinity,
                        height: iconH,
                        child: AppImage(
                          imageUrl: img,
                          height: iconH,
                          fit: BoxFit.cover,
                          borderRadius: 14,
                        ),
                      )
                    : Center(
                        child: Icon(
                          _iconForName(categorie.nomcategorie),
                          color: SDColors.primary600,
                          size: iconSize,
                        ),
                      ),
              ),
              SizedBox(height: SDSpacing.xxxs),
              Expanded(
                child: Text(
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
              ),
            ],
          );
        },
      ),
    );
  }
}


// --- Talent card (profil freelance honnête) ---

class _FreelanceTalentCard extends StatelessWidget {
  final FreelanceModel freelancer;

  const _FreelanceTalentCard({required this.freelancer});

  @override
  Widget build(BuildContext context) {
    final imageUrl = safeImageUrl(freelancer.imagePath);
    final hasRating = freelancer.rating > 0;
    final hasRate = freelancer.hourlyRate > 0;
    final skills = freelancer.skills
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(2)
        .join(' · ');
    final avail = freelancer.availabilityStatus.trim();
    // Uniquement si le backend a une dispo réelle (pas le fallback « Non renseigné »).
    final showAvail =
        avail.toLowerCase() == 'disponible' || avail.toLowerCase() == 'available';

    return SDEntityCard(
      type: SDEntityCardType.freelance,
      title: displayOrFallback(freelancer.name, 'Freelance'),
      subtitle: displayOrFallback(freelancer.job, freelancer.category),
      fallbackIcon: Icons.laptop_mac_rounded,
      imageUrl: imageUrl,
      ratingText: hasRating ? freelancer.rating.toStringAsFixed(1) : null,
      metaText: skills.isNotEmpty ? skills : null,
      statusText: showAvail ? 'Disponible' : null,
      priceText: hasRate ? _formatFcfaHour(freelancer.hourlyRate) : null,
      ctaLabel: 'Voir le profil',
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
              final avatarUrl = safeImageUrl(f.imagePath);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : const AssetImage('assets/profile_picture.jpg')
                          as ImageProvider,
                ),
                title: Text(
                  displayOrFallback(f.name, 'Freelance'),
                  style: SDTypography.titleSmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _freelanceListSubtitle(f),
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
              final avatarUrl = safeImageUrl(f.imagePath);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : const AssetImage('assets/profile_picture.jpg')
                          as ImageProvider,
                ),
                title: Text(
                  displayOrFallback(f.name, 'Freelance'),
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  _freelanceListSubtitle(f),
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
