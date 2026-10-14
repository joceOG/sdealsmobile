import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdealsmobile/data/config/client_feature_flags.dart';
import 'package:sdealsmobile/data/models/favorite.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';

import '../../../../design_system/design_system.dart';
import '../../common/widgets/unauthenticated_banner.dart';
import '../favorispageblocm/favoritePageBlocM.dart';
import '../favorispageblocm/favoritePageEventM.dart';
import '../favorispageblocm/favoritePageStateM.dart';
import 'favoriteDetailScreenM.dart';

/// Mes favoris — profils enregistrés, recherche et cœur accessible.
class FavoritePageScreenM extends StatefulWidget {
  const FavoritePageScreenM({super.key});

  @override
  State<FavoritePageScreenM> createState() => _FavoritePageScreenMState();
}

class _FavoritePageScreenMState extends State<FavoritePageScreenM> {
  static const double _hPad = 20;

  /// null = Tous ; sinon filtre univers réel.
  String? _universe;

  /// Le premier état du bloc a `favorites: []` avant la réponse API.
  /// L'illustration n'est autorisée qu'après un cycle chargement → terminé.
  bool _loadStarted = false;
  bool _favoritesReady = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<({String? id, String label})> get _universes {
    return [
      (id: null, label: 'Tous'),
      (id: 'metiers', label: 'Métiers'),
      (id: 'freelance', label: 'Freelance'),
      if (ClientFeatureFlags.emarketEnabled)
        (id: 'marketplace', label: 'Vente & Achat'),
    ];
  }

  @override
  void initState() {
    super.initState();
    context.read<FavoritePageBlocM>().add(const LoadFavoritesM());
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

  String _jobLine(Favorite f) {
    if (f.categorie != null && f.categorie!.trim().isNotEmpty) {
      return f.categorie!.trim();
    }
    switch (f.objetType) {
      case 'FREELANCE':
        return 'Freelance';
      case 'ARTICLE':
      case 'VENDEUR':
      case 'COMMANDE':
        return 'E-marché';
      case 'PRESTATAIRE':
      case 'SERVICE':
      case 'PRESTATION':
        return 'Métiers';
      default:
        return f.objetType;
    }
  }

  String _universeChipLabel(Favorite f) {
    switch (f.objetType) {
      case 'FREELANCE':
        return 'Freelance';
      case 'ARTICLE':
      case 'VENDEUR':
      case 'COMMANDE':
        return 'E-marché';
      default:
        return 'Métiers';
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
            if (state.isLoading) {
              _loadStarted = true;
            } else if (_loadStarted) {
              _favoritesReady = true;
            }
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
                _buildSearchField(),
                _buildUniverseChips(),
                if (_favoritesReady &&
                    (state.favorites ?? const <Favorite>[]).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 0),
                    child: Text(
                      items.length <= 1
                          ? '${items.length} profil enregistré'
                          : '${items.length} profils enregistrés',
                      style: SDTypography.bodySmall.copyWith(
                        color: SDColors.neutral500,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(child: _buildFavoritesBody(context, state, items)),
                if (_favoritesReady &&
                    (state.favorites ?? const <Favorite>[]).isNotEmpty &&
                    items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: SDColors.neutral500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Touchez un cœur pour retirer un favori.',
                            style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFavoritesBody(
    BuildContext context,
    FavoritePageStateM state,
    List<Favorite> items,
  ) {
    final favorites = state.favorites ?? const <Favorite>[];
    if (!_favoritesReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      color: SDColors.primary600,
      onRefresh: () async {
        context.read<FavoritePageBlocM>().add(const RefreshFavoritesM());
      },
      child: favorites.isEmpty && state.hasError
          ? _scrollableCenter(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.error ?? 'Impossible de charger les favoris.',
                    textAlign: TextAlign.center,
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SDButton(
                    text: 'Réessayer',
                    icon: Icons.refresh_rounded,
                    onPressed: () => context
                        .read<FavoritePageBlocM>()
                        .add(const LoadFavoritesM()),
                  ),
                ],
              ),
            )
          : favorites.isEmpty
              ? _scrollableCenter(_buildEmptyFavorites(context))
              : items.isEmpty
                  ? _scrollableCenter(_buildEmptyFavorites(
                      context,
                      showIllustration: false,
                    ))
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _buildFavoriteCard(items[i]),
                    ),
    );
  }

  Widget _scrollableCenter(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  /// [showIllustration] reste faux pour un filtre ou une recherche sans
  /// résultat : des favoris existent, ce n'est pas SD-ILL-004.
  Widget _buildEmptyFavorites(
    BuildContext context, {
    bool showIllustration = true,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIllustration)
          const SDIllustration(
            asset: SDIllustrations.favoritesEmptyConnected,
          ),
        if (showIllustration) const SizedBox(height: 24),
        Text(
          showIllustration
              ? 'Aucun favori pour le moment'
              : 'Aucun profil dans ce filtre',
          style: SDTypography.titleLarge.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          showIllustration
              ? 'Enregistrez les profils qui vous plaisent pour les retrouver ici.'
              : 'Essayez un autre filtre ou une autre recherche.',
          style: SDTypography.bodyMedium.copyWith(
            color: SDColors.neutral600,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        if (showIllustration) ...[
          const SizedBox(height: 24),
          SDButton(
            text: 'Explorer',
            icon: Icons.explore_outlined,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ],
    );
  }

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes favoris',
                  style: SDTypography.titleLarge.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Vos profils enregistrés',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral500,
                  ),
                ),
              ],
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
        onChanged: (v) => setState(() => _query = v),
        style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral900),
        decoration: InputDecoration(
          hintText: 'Rechercher un favori',
          hintStyle: SDTypography.bodyMedium.copyWith(
            color: SDColors.neutral500,
          ),
          prefixIcon: const Icon(Icons.search, color: SDColors.neutral500),
          filled: true,
          fillColor: SDColors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: SDColors.neutral200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: SDColors.primary600),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: SDColors.neutral200),
          ),
        ),
      ),
    );
  }

  Widget _buildUniverseChips() {
    final universes = _universes;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 4),
        itemCount: universes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final u = universes[index];
          final selected = _universe == u.id;
          return GestureDetector(
            onTap: () => setState(() => _universe = u.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? SDColors.primary600 : SDColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? SDColors.primary600 : SDColors.neutral200,
                ),
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
    final city = favorite.localisation?.ville.trim() ?? '';
    final chip = _universeChipLabel(favorite);

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
              children: [
                _buildThumb(favorite),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.titleMedium.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _jobLine(favorite),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral600,
                        ),
                      ),
                      if (city.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: SDColors.neutral500,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SDTypography.bodySmall.copyWith(
                                  color: SDColors.neutral500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: SDColors.primary50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          chip,
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.primary700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Retirer ${favorite.titre} des favoris',
                      child: IconButton(
                        onPressed: () => _showRemoveDialog(favorite),
                        tooltip: 'Retirer des favoris',
                        icon: const Icon(
                          Icons.favorite,
                          color: SDColors.primary600,
                          size: 22,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: SDColors.neutral400,
                    ),
                  ],
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
    return ClipOval(
      child: SizedBox(
        width: 56,
        height: 56,
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
      color: SDColors.primary50,
      child: Icon(icon, color: SDColors.primary600, size: 24),
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
