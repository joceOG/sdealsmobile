import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/models/favorite.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';

import '../../../../design_system/design_system.dart';
import '../../common/widgets/empty_state_widget.dart';
import '../../common/widgets/unauthenticated_banner.dart';
import '../favorispageblocm/favoritePageBlocM.dart';
import '../favorispageblocm/favoritePageEventM.dart';
import '../favorispageblocm/favoritePageStateM.dart';
import 'favoriteDetailScreenM.dart';

/// Mes Favoris — style Airbnb / Figma (titre à gauche, chips univers, cards).
class FavoritePageScreenM extends StatefulWidget {
  const FavoritePageScreenM({super.key});

  @override
  State<FavoritePageScreenM> createState() => _FavoritePageScreenMState();
}

class _FavoritePageScreenMState extends State<FavoritePageScreenM> {
  static const double _hPad = 20;

  /// null = Tous ; sinon filtre univers Figma.
  String? _universe;
  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const _universes = <({String? id, String label})>[
    (id: null, label: 'Tous'),
    (id: 'metiers', label: 'Métiers'),
    (id: 'freelance', label: 'Freelance'),
    (id: 'marketplace', label: 'Vente & Achat'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<FavoritePageBlocM>().add(LoadFavoritesM());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Favorite> _filter(List<Favorite> all) {
    var list = all.where((f) => f.estActif).toList();
    switch (_universe) {
      case 'metiers':
        list = list
            .where((f) =>
                f.objetType == 'PRESTATAIRE' ||
                f.objetType == 'SERVICE' ||
                f.objetType == 'PRESTATION')
            .toList();
        break;
      case 'freelance':
        list = list.where((f) => f.objetType == 'FREELANCE').toList();
        break;
      case 'marketplace':
        list = list
            .where((f) =>
                f.objetType == 'ARTICLE' ||
                f.objetType == 'VENDEUR' ||
                f.objetType == 'COMMANDE')
            .toList();
        break;
    }
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((f) {
      final hay = [
        f.titre,
        f.description ?? '',
        f.categorie ?? '',
        f.localisation?.ville ?? '',
        f.objetType,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  String _subtitleFor(Favorite f) {
    final loc = f.localisation?.ville;
    if (loc != null && loc.isNotEmpty) return loc;
    switch (f.objetType) {
      case 'FREELANCE':
        return 'Freelance';
      case 'ARTICLE':
      case 'VENDEUR':
        return 'Vente & Achat';
      case 'PRESTATAIRE':
      case 'SERVICE':
      case 'PRESTATION':
        return f.categorie?.isNotEmpty == true ? f.categorie! : 'Métiers';
      default:
        return f.categorie ?? f.objetType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const UnauthenticatedBanner(
        appBarTitle: 'Mes favoris',
        icon: Icons.favorite_outline_rounded,
        title: 'Vos coups de cœur',
        description:
            'Connectez-vous pour sauvegarder vos prestataires, freelances et produits favoris et les retrouver facilement.',
      );
    }

    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: BlocConsumer<FavoritePageBlocM, FavoritePageStateM>(
          listener: (context, state) {
            if (state.hasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error ?? 'Erreur inconnue'),
                  backgroundColor: SDColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final items = _filter(state.favorites ?? []);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                _buildHeader(),
                if (_searchOpen) _buildSearchField(),
                _buildUniverseChips(),
                const SizedBox(height: 8),
                Expanded(
                  child: state.isLoading && (state.favorites == null)
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          color: SDColors.primary600,
                          onRefresh: () async {
                            context
                                .read<FavoritePageBlocM>()
                                .add(RefreshFavoritesM());
                          },
                          child: items.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.sizeOf(context).height *
                                              0.55,
                                      child: EmptyStateWidget(
                                        imagePath: 'assets/favoris_vides.png',
                                        title: 'Aucun favori',
                                        message:
                                            'Explorez Métiers, Freelance ou Marketplace et enregistrez vos coups de cœur.',
                                        imageSize: 140,
                                        action: SDButton(
                                          text: 'Explorer les professionnels',
                                          type: SDButtonType.outlined,
                                          icon: Icons.search_rounded,
                                          onPressed: () =>
                                              Navigator.of(context).maybePop(),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                      _hPad, 8, _hPad, 24),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, i) =>
                                      _buildFavoriteCard(items[i]),
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

  /// Écran poussé depuis Profil → retour (pas cloche notifs Figma).
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
            tooltip: 'Retour',
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchController.clear();
                  _query = '';
                }
              });
            },
            icon: Icon(
              _searchOpen ? Icons.close : Icons.search,
              color: SDColors.neutral900,
            ),
            tooltip: _searchOpen ? 'Fermer la recherche' : 'Rechercher',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mes Favoris',
            style: SDTypography.displayMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Retrouvez vos coups de cœur',
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 4),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (v) => setState(() => _query = v),
        style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral900),
        decoration: InputDecoration(
          hintText: 'Rechercher un favori…',
          hintStyle: SDTypography.bodyMedium.copyWith(
            color: SDColors.neutral500,
          ),
          prefixIcon: const Icon(Icons.search, color: SDColors.neutral500),
          filled: true,
          fillColor: SDColors.neutral100,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildUniverseChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 4),
        itemCount: _universes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final u = _universes[index];
          final selected = _universe == u.id;
          return GestureDetector(
            onTap: () => setState(() => _universe = u.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? SDColors.primary600 : SDColors.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                u.label,
                style: SDTypography.labelLarge.copyWith(
                  color: selected ? SDColors.white : SDColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Favorite favorite) {
    final note = favorite.note;
    final subtitle = _subtitleFor(favorite);

    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _navigateToDetail(favorite),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: SDColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SDColors.neutral200),
            boxShadow: [
              BoxShadow(
                color: SDColors.neutral900.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumb(favorite),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              favorite.titre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.titleMedium.copyWith(
                                color: SDColors.neutral900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showRemoveDialog(favorite),
                            child: const Icon(
                              Icons.favorite,
                              color: SDColors.primary600,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.neutral600,
                        ),
                      ),
                      if (note != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: SDColors.warning500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              note.toStringAsFixed(1).replaceAll('.', ','),
                              style: SDTypography.labelMedium.copyWith(
                                color: SDColors.neutral900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumb(Favorite favorite) {
    final url = favorite.image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        height: 72,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _thumbFallback(favorite),
              )
            : _thumbFallback(favorite),
      ),
    );
  }

  Widget _thumbFallback(Favorite favorite) {
    IconData icon;
    switch (favorite.objetType) {
      case 'FREELANCE':
        icon = Icons.laptop_mac_rounded;
        break;
      case 'ARTICLE':
      case 'VENDEUR':
        icon = Icons.shopping_bag_outlined;
        break;
      default:
        icon = Icons.handyman_outlined;
    }
    return ColoredBox(
      color: SDColors.neutral100,
      child: Icon(icon, color: SDColors.neutral400, size: 28),
    );
  }

  void _navigateToDetail(Favorite favorite) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => FavoritePageBlocM(),
          child: FavoriteDetailScreenM(favorite: favorite),
        ),
      ),
    );
  }

  void _showRemoveDialog(Favorite favorite) {
    if (favorite.id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer des favoris'),
        content: Text('Retirer « ${favorite.titre} » de vos favoris ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<FavoritePageBlocM>()
                  .add(DeleteFavoriteM(favoriteId: favorite.id!));
            },
            child: Text(
              'Retirer',
              style: SDTypography.labelLarge.copyWith(color: SDColors.error500),
            ),
          ),
        ],
      ),
    );
  }
}
