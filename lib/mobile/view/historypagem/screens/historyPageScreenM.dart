import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/history.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/services/local_storage_service.dart';
import '../../../../design_system/design_system.dart';
import '../../common/widgets/unauthenticated_banner.dart';
import '../../searchpagem/screens/searchPageScreenM.dart';
import '../historypageblocm/historyPageBlocM.dart';
import '../historypageblocm/historyPageEventM.dart';
import '../historypageblocm/historyPageStateM.dart';
import 'historyDetailScreenM.dart';

/// Historique — Annonces consultées + Recherches récentes (storage local).
/// Style Airbnb : titre à gauche, retour, pas de chrome admin.
class HistoryPageScreenM extends StatefulWidget {
  const HistoryPageScreenM({super.key});

  @override
  State<HistoryPageScreenM> createState() => _HistoryPageScreenMState();
}

class _HistoryPageScreenMState extends State<HistoryPageScreenM> {
  static const double _hPad = 20;

  /// 0 = Annonces consultées, 1 = Recherches récentes
  int _tab = 0;

  final _localStorage = LocalStorageService();
  List<String> _recentSearches = [];
  bool _searchesLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<HistoryPageBlocM>().add(const LoadHistoryDataM(limit: 50));
    _loadSearches();
  }

  Future<void> _loadSearches() async {
    setState(() => _searchesLoading = true);
    final list = await _localStorage.getSearchHistory();
    if (!mounted) return;
    setState(() {
      _recentSearches = list;
      _searchesLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const UnauthenticatedBanner(
        appBarTitle: 'Historique',
        icon: Icons.history_rounded,
        title: 'Votre historique',
        description:
            'Connectez-vous pour retrouver vos consultations et recherches.',
      );
    }

    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context),
            _buildHeader(),
            _buildTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: _tab == 0
                  ? _buildConsultationsTab()
                  : _buildSearchesTab(),
            ),
          ],
        ),
      ),
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
          const Spacer(),
          if (_tab == 1 && _recentSearches.isNotEmpty)
            TextButton(
              onPressed: _confirmClearSearches,
              child: Text(
                'Effacer',
                style: SDTypography.labelLarge.copyWith(
                  color: SDColors.primary600,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
            _tab == 0
                ? 'Historique des consultations'
                : 'Recherches récentes',
            style: SDTypography.displayMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _tab == 0
                ? 'Retrouvez vos recherches et visites'
                : 'Vos dernières recherches',
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 4),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              label: 'Annonces consultées',
              selected: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _segment(
              label: 'Recherches récentes',
              selected: _tab == 1,
              onTap: () {
                setState(() => _tab = 1);
                _loadSearches();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? SDColors.primary600 : SDColors.neutral100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SDTypography.labelMedium.copyWith(
            color: selected ? SDColors.white : SDColors.neutral900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ─── Annonces consultées ───────────────────────────────────────────

  Widget _buildConsultationsTab() {
    return BlocConsumer<HistoryPageBlocM, HistoryPageStateM>(
      listener: (context, state) {
        if (state is HistoryPageErrorM) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: SDColors.error500,
            ),
          );
        }
        if (state is HistoryDeletedM) {
          context
              .read<HistoryPageBlocM>()
              .add(const LoadHistoryDataM(limit: 50));
        }
      },
      builder: (context, state) {
        if (state is HistoryPageLoadingM || state is HistoryPageInitialM) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = state is HistoryPageLoadedM
            ? state.history
            : state is RecentHistoryLoadedM
                ? state.recentHistory
                : <History>[];

        if (items.isEmpty) {
          return _empty(
            icon: Icons.history_rounded,
            title: 'Aucune consultation',
            message: 'Les annonces que vous consultez apparaîtront ici.',
          );
        }

        final groups = _groupByDay(items);
        return RefreshIndicator(
          color: SDColors.primary600,
          onRefresh: () async {
            context
                .read<HistoryPageBlocM>()
                .add(const LoadHistoryDataM(limit: 50));
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 24),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final g = groups[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 16, bottom: 8),
                    child: Text(
                      g.label,
                      style: SDTypography.titleMedium.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...g.items.map(_buildHistoryRow),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryRow(History h) {
    final subtitle = h.localisation?.ville?.isNotEmpty == true
        ? h.localisation!.ville!
        : _typeLabel(h.objetType);
    final timeLabel = _timeMeta(h.dateConsultation);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _openDetail(h),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _thumb(h),
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
                              h.titre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.titleMedium.copyWith(
                                color: SDColors.neutral900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            timeLabel,
                            style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.neutral600,
                        ),
                      ),
                      if (h.note != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: SDColors.warning500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              h.note!.toStringAsFixed(1).replaceAll('.', ','),
                              style: SDTypography.labelMedium.copyWith(
                                color: SDColors.neutral900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              icon: const Icon(
                                Icons.more_vert,
                                color: SDColors.neutral500,
                              ),
                              onSelected: (v) {
                                if (v == 'detail') _openDetail(h);
                                if (v == 'delete') _confirmDelete(h);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'detail',
                                  child: Text('Voir le détail'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ] else
                        Align(
                          alignment: Alignment.centerRight,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            icon: const Icon(
                              Icons.more_vert,
                              color: SDColors.neutral500,
                            ),
                            onSelected: (v) {
                              if (v == 'detail') _openDetail(h);
                              if (v == 'delete') _confirmDelete(h);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'detail',
                                child: Text('Voir le détail'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Supprimer'),
                              ),
                            ],
                          ),
                        ),
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

  Widget _thumb(History h) {
    final url = h.image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        height: 72,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _thumbFallback(h.objetType),
              )
            : _thumbFallback(h.objetType),
      ),
    );
  }

  Widget _thumbFallback(String type) {
    return ColoredBox(
      color: SDColors.neutral100,
      child: Icon(
        type == 'ARTICLE' || type == 'VENDEUR'
            ? Icons.shopping_bag_outlined
            : type == 'FREELANCE'
                ? Icons.laptop_mac_rounded
                : Icons.handyman_outlined,
        color: SDColors.neutral400,
      ),
    );
  }

  // ─── Recherches récentes ───────────────────────────────────────────

  Widget _buildSearchesTab() {
    if (_searchesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recentSearches.isEmpty) {
      return _empty(
        icon: Icons.search_off_rounded,
        title: 'Aucune recherche récente',
        message: 'Vos recherches apparaîtront ici pour un accès rapide.',
      );
    }

    // Pas de timestamps côté SharedPreferences → une seule section.
    return RefreshIndicator(
      color: SDColors.primary600,
      onRefresh: _loadSearches,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 24),
        children: [
          Text(
            'Récentes',
            style: SDTypography.titleMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._recentSearches.map(_buildSearchPill),
        ],
      ),
    );
  }

  Widget _buildSearchPill(String query) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _openSearch(query),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SDColors.neutral200),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: SDColors.neutral500),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SDTypography.bodyLarge.copyWith(
                      color: SDColors.neutral900,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    await _localStorage.removeFromHistory(query);
                    await _loadSearches();
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: SDColors.neutral500,
                  ),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  List<({String label, List<History> items})> _groupByDay(List<History> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<History>>{};

    for (final h in all) {
      final d = DateTime(
        h.dateConsultation.year,
        h.dateConsultation.month,
        h.dateConsultation.day,
      );
      final key = d == today
          ? 'Aujourd\'hui'
          : d == yesterday
              ? 'Hier'
              : DateFormat('d MMMM yyyy', 'fr_FR').format(d);
      map.putIfAbsent(key, () => []).add(h);
    }

    // Ordre : Aujourd'hui, Hier, puis dates décroissantes déjà dans list order
    final order = <String>[];
    if (map.containsKey('Aujourd\'hui')) order.add('Aujourd\'hui');
    if (map.containsKey('Hier')) order.add('Hier');
    for (final k in map.keys) {
      if (k != 'Aujourd\'hui' && k != 'Hier') order.add(k);
    }
    return order.map((k) => (label: k, items: map[k]!)).toList();
  }

  String _timeMeta(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) {
      return DateFormat('HH:mm').format(date);
    }
    if (d == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    }
    return DateFormat('d MMM', 'fr_FR').format(date);
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'FREELANCE':
        return 'Freelance';
      case 'ARTICLE':
      case 'VENDEUR':
        return 'Vente & Achat';
      case 'PRESTATAIRE':
      case 'SERVICE':
      case 'PRESTATION':
        return 'Métiers';
      default:
        return type;
    }
  }

  Widget _empty({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: SDColors.neutral400),
            const SizedBox(height: 16),
            Text(
              title,
              style: SDTypography.titleMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(History h) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => HistoryPageBlocM(),
          child: HistoryDetailScreenM(history: h),
        ),
      ),
    );
  }

  void _confirmDelete(History h) {
    if (h.id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Retirer « ${h.titre} » de l\'historique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<HistoryPageBlocM>()
                  .add(DeleteHistoryM(historyId: h.id!));
            },
            child: Text(
              'Supprimer',
              style: SDTypography.labelLarge.copyWith(color: SDColors.error500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearSearches() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer les recherches'),
        content: const Text(
          'Supprimer toutes vos recherches récentes ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Effacer',
              style: SDTypography.labelLarge.copyWith(color: SDColors.error500),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _localStorage.clearHistory();
      await _loadSearches();
    }
  }

  void _openSearch(String query) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchPageScreenM(initialQuery: query),
      ),
    );
  }
}
