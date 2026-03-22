import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/models/prestataire.dart';
import 'package:sdealsmobile/data/models/vendeur.dart';
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
import 'package:sdealsmobile/mobile/view/shoppingpagem/screens/shoppingPageScreenM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageBlocM.dart';
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageEventM.dart'
    as shop_ev;
import 'package:sdealsmobile/mobile/view/shoppingpagem/shoppingpageblocm/shoppingPageStateM.dart'
    as shop_state;
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../common/widgets/app_image.dart';
import '../../common/widgets/skeleton_loader.dart';

/// Filtre type Figma (chips sous la recherche).
enum _ExplorerUniverse { tous, metiers, freelance, marketplace }

/// Onglet **Explorer** : hub découverte (Figma) + lien vers recherche globale.
class ExplorerPageScreen extends StatelessWidget {
  const ExplorerPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => JobPageBlocM()
            ..add(const LoadProviderMatchingM(serviceType: '', location: '')),
        ),
        BlocProvider(
          create: (_) => FreelancePageBlocM()
            ..add(free_ev.LoadCategorieDataM())
            ..add(free_ev.LoadFreelancersEvent())
            ..add(free_ev.LoadServicesEvent()),
        ),
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
  _ExplorerUniverse _universe = _ExplorerUniverse.tous;

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
      _universe == _ExplorerUniverse.tous ||
      _universe == _ExplorerUniverse.marketplace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
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
                    _buildTopTitle(context),
                    SizedBox(height: SDSpacing.md),
                    _buildSearchRow(context),
                    SizedBox(height: SDSpacing.xs),
                    _buildChips(),
                    SizedBox(height: SDSpacing.lg),
                    if (_showMetiers) ...[
                      _buildMetiersSection(context),
                      SizedBox(height: SDSpacing.xl),
                    ],
                    if (_showFreelance) ...[
                      _buildFreelanceSection(context),
                      SizedBox(height: SDSpacing.xl),
                    ],
                    if (_showMarketplace) ...[
                      _buildProductsSection(context),
                      SizedBox(height: SDSpacing.xl),
                      _buildShopsSection(context),
                    ],
                    SizedBox(height: SDSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Même gabarit que Freelance / Marketplace : titre noir, pas de bandeau vert.
  Widget _buildTopTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explorer',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SDTypography.headlineSmall.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: SDSpacing.xxxs),
        Text(
          'Services, freelances & shopping',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SDTypography.bodySmall.copyWith(
            color: SDColors.neutral500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  /// Même barre que `_buildSearchField` (Freelance / Explorer) : pill 28, ombre légère.
  Widget _buildSearchRow(BuildContext context) {
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
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _openSearch(),
              decoration: InputDecoration(
                hintText:
                    'Rechercher service, produit ou prestataire..',
                hintStyle: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral400,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: SDTypography.bodyMedium.copyWith(fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => _openSearch(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SDColors.primary600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: SDColors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  /// Segment **Tous | Métiers** (chip) ; titre de section : Prestataires près de moi.
  Widget _buildChips() {
    const peachBg = Color(0xFFF5E6D8);
    const peachText = Color(0xFF5D4037);
    const beigeFreelance = Color(0xFFF0EFEA);

    /// Contenu d’un segment (le parent [Row] fournit la largeur via [Expanded]).
    Widget segmentCell({
      required String label,
      required _ExplorerUniverse value,
      required bool selected,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _universe = value),
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                style: SDTypography.labelMedium.copyWith(
                  color: selected
                      ? SDColors.primary700
                      : SDColors.neutral600,
                  fontWeight:
                      selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget standaloneChip({
      required String label,
      required _ExplorerUniverse value,
      required Color background,
      required Color textColor,
      bool selectedBold = true,
    }) {
      final selected = _universe == value;
      // Pas d'[AnimatedContainer] : bordure width 0 → 1.5 provoquait des tweens invalides
      // et assert Widget.canUpdate après setState / hot reload.
      return Padding(
        key: ValueKey<String>('explorer_chip_$label'),
        padding: const EdgeInsets.only(left: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _universe = value),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? SDColors.primary400
                      : background,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: SDColors.neutral900.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                label,
                style: SDTypography.labelMedium.copyWith(
                  color: textColor,
                  fontWeight: selected && selectedBold
                      ? FontWeight.w800
                      : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Largeur fixe : obligatoire pour [Expanded] dans un scroll horizontal.
          SizedBox(
            key: const ValueKey('explorer_segment_tous_metiers'),
            width: 200,
            child: Container(
              decoration: BoxDecoration(
                color: SDColors.primary50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: SDColors.primary100.withOpacity(0.6),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: segmentCell(
                        label: 'Tous',
                        value: _ExplorerUniverse.tous,
                        selected: _universe == _ExplorerUniverse.tous,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 22,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: SDColors.primary200.withOpacity(0.85),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: segmentCell(
                        label: 'Métiers',
                        value: _ExplorerUniverse.metiers,
                        selected: _universe == _ExplorerUniverse.metiers,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          standaloneChip(
            label: 'Freelance',
            value: _ExplorerUniverse.freelance,
            background: beigeFreelance,
            textColor: SDColors.neutral800,
          ),
          standaloneChip(
            label: 'Marketplace',
            value: _ExplorerUniverse.marketplace,
            background: peachBg,
            textColor: peachText,
          ),
          Padding(
            key: const ValueKey('explorer_chip_more'),
            padding: const EdgeInsets.only(left: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showExplorerMoreSheet(context),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: SDColors.neutral100,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: SDColors.neutral900.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: SDColors.primary600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: SDColors.primary600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: SDColors.primary600,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExplorerMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SDSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explorer',
                style: SDTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: SDSpacing.sm),
              ListTile(
                leading: Icon(Icons.manage_search, color: SDColors.primary600),
                title: const Text('Vue complète — recherche globale'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openSearch();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String titleBold,
    required String titleLight,
    required VoidCallback onSeeAll,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: SDTypography.titleMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(text: titleBold),
                TextSpan(
                  text: titleLight,
                  style: SDTypography.titleMedium.copyWith(
                    color: SDColors.neutral600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onSeeAll,
          icon: const Icon(Icons.arrow_forward, size: 14),
          label: Text('Voir tout', style: SDTypography.labelSmall),
          style: TextButton.styleFrom(
            foregroundColor: SDColors.primary600,
            padding: SDSpacing.chipPadding,
            minimumSize: const Size(0, 32),
          ),
        ),
      ],
    );
  }

  Widget _buildMetiersSection(BuildContext context) {
    return BlocBuilder<JobPageBlocM, JobPageStateM>(
      builder: (context, state) {
        final list = state.matchedProviders;
        if (state.isMatchingLoading && list.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                titleBold: 'Prestataires',
                titleLight: ' près de moi',
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JobPageScreenM()),
                ),
              ),
              SizedBox(height: SDSpacing.sm),
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
          );
        }
        if (list.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                titleBold: 'Prestataires',
                titleLight: ' près de moi',
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JobPageScreenM()),
                ),
              ),
              SizedBox(height: SDSpacing.sm),
              Text(
                'Aucun prestataire pour le moment. Découvrez Métiers.',
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral500,
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              titleBold: 'Prestataires',
              titleLight: ' près de moi',
              onSeeAll: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JobPageScreenM()),
              ),
            ),
            SizedBox(height: SDSpacing.sm),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
                itemBuilder: (context, i) {
                  return _MetierCard(
                    prestataire: list[i],
                    distanceKm: (0.4 + (i + 1) * 0.22).toStringAsFixed(1),
                  );
                },
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
        final list = state.freelancers.take(12).toList();
        if (state.isLoading && list.isEmpty) {
          return Column(
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
              SizedBox(height: SDSpacing.sm),
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
          );
        }
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
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
            SizedBox(height: SDSpacing.sm),
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
        );
      },
    );
  }

  Widget _buildProductsSection(BuildContext context) {
    return BlocBuilder<ShoppingPageBlocM, shop_state.ShoppingPageStateM>(
      builder: (context, state) {
        final raw = state.filteredProducts ?? state.products ?? [];
        final list = raw.take(10).toList();
        if ((state.isLoading ?? false) && list.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                titleBold: 'Produits',
                titleLight: ' tendance',
                onSeeAll: _openMarketplace,
              ),
              SizedBox(height: SDSpacing.sm),
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
          );
        }
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              titleBold: 'Produits',
              titleLight: ' tendance',
              onSeeAll: _openMarketplace,
            ),
            SizedBox(height: SDSpacing.sm),
            SizedBox(
              height: 228,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => SizedBox(width: SDSpacing.sm),
                itemBuilder: (context, i) {
                  final p = list[i];
                  final pct = 10 + (p.id.hashCode.abs() % 21);
                  return _ProductTrendCard(
                    product: p,
                    discountPercent: pct,
                    bloc: context.read<ShoppingPageBlocM>(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShopsSection(BuildContext context) {
    return BlocBuilder<ShoppingPageBlocM, shop_state.ShoppingPageStateM>(
      builder: (context, state) {
        final shops = state.filteredVendeurs ?? state.vendeurs ?? [];
        final list = shops.take(8).toList();
        if (list.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                titleBold: 'Boutiques',
                titleLight: ' autour de moi',
                onSeeAll: _openMarketplace,
              ),
              SizedBox(height: SDSpacing.sm),
              Text(
                'Boutiques en cours de chargement…',
                style: SDTypography.bodySmall.copyWith(
                  color: SDColors.neutral500,
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              titleBold: 'Boutiques',
              titleLight: ' autour de moi',
              onSeeAll: _openMarketplace,
            ),
            SizedBox(height: SDSpacing.sm),
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
        );
      },
    );
  }
}

class _MetierCard extends StatelessWidget {
  final Prestataire prestataire;
  final String distanceKm;

  const _MetierCard({
    required this.prestataire,
    required this.distanceKm,
  });

  bool get _busy =>
      prestataire.utilisateur.idutilisateur.hashCode % 3 == 0;

  @override
  Widget build(BuildContext context) {
    // Évite « null » si prenom est null (interpolation) ou si l'API renvoie le mot « null ».
    final raw = prestataire.utilisateur.fullName.trim();
    final shortName = raw
            .split(RegExp(r'\s+'))
            .where((w) =>
                w.isNotEmpty && w.toLowerCase() != 'null')
            .join(' ')
            .trim();
    final displayName =
        shortName.isEmpty ? 'Prestataire' : shortName;
    final note = double.tryParse(prestataire.note ?? '') ?? 4.5;

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
                  child: prestataire.selfie != null &&
                          prestataire.selfie!.startsWith('http')
                      ? AppImage(
                          imageUrl: prestataire.selfie!,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(Icons.near_me, size: 12, color: SDColors.primary600),
                  Text(
                    ' $distanceKm km',
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.primary600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.star_rounded,
                      size: 14, color: SDColors.warning500),
                  Text(
                    note.toStringAsFixed(1),
                    style: SDTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: _busy
                      ? SDColors.error50
                      : SDColors.success50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _busy ? 'Occupé(e)' : 'Disponible',
                  textAlign: TextAlign.center,
                  style: SDTypography.labelSmall.copyWith(
                    color: _busy ? SDColors.error600 : SDColors.success700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
    final verified =
        freelance.verificationDocuments?.isVerified == true;

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
  final int discountPercent;
  final ShoppingPageBlocM bloc;

  const _ProductTrendCard({
    required this.product,
    required this.discountPercent,
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
              child: Stack(
                children: [
                  Padding(
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
                                placeholderAsset:
                                    'assets/products/default.png',
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
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: SDColors.error500,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-$discountPercent%',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
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
                child: vendeur.shopLogo != null &&
                        vendeur.shopLogo!.isNotEmpty
                    ? AppImage(
                        imageUrl: vendeur.shopLogo!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: SDColors.primary50,
                        child: Icon(Icons.storefront,
                            color: SDColors.primary600),
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
