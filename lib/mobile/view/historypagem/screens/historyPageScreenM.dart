import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../data/config/client_feature_flags.dart';
import '../../../../data/models/history.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/services/local_storage_service.dart';
import '../../../../data/utils/network_user_message.dart';
import '../../../../design_system/design_system.dart';
import '../../common/widgets/unauthenticated_banner.dart';
import '../../freelancepagem/models/freelance_model.dart';
import '../../freelancepagem/screens/freelance_details_screen.dart';
import '../../jobpagem/screens/provider_profile_screen.dart';
import '../../searchpagem/screens/searchPageScreenM.dart';
import '../historypageblocm/historyPageBlocM.dart';
import '../historypageblocm/historyPageEventM.dart';
import '../historypageblocm/historyPageStateM.dart';

/// Historique — profils consultés (API) et recherches récentes (local).
class HistoryPageScreenM extends StatefulWidget {
  const HistoryPageScreenM({super.key});

  @override
  State<HistoryPageScreenM> createState() => _HistoryPageScreenMState();
}

class _HistoryPageScreenMState extends State<HistoryPageScreenM> {
  static const double _hPad = 20;

  /// 0 = Profils consultés, 1 = Recherches récentes
  int _tab = 0;

  final _localStorage = LocalStorageService();
  final _api = ApiClient();
  List<SearchHistoryEntry> _recentSearches = [];
  bool _searchesLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<HistoryPageBlocM>().add(const LoadHistoryDataM(limit: 50));
    _loadSearches();
  }

  Future<void> _loadSearches() async {
    setState(() => _searchesLoading = true);
    final list = await _localStorage.getSearchHistoryEntries();
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
            _buildTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: _tab == 0 ? _buildConsultationsTab() : _buildSearchesTab(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historique',
                  style: SDTypography.titleLarge.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Retrouvez vos dernières visites et recherches.',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 4),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              label: 'Profils',
              selected: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _segment(
              label: 'Recherches',
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
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? SDColors.primary600 : SDColors.neutral100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SDTypography.labelLarge.copyWith(
            color: selected ? SDColors.white : SDColors.neutral900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterHint(String text) {
    return Row(
      children: [
        const Icon(
          Icons.history_rounded,
          size: 16,
          color: SDColors.neutral500,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: SDTypography.bodySmall.copyWith(
              color: SDColors.neutral500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationsTab() {
    return BlocConsumer<HistoryPageBlocM, HistoryPageStateM>(
      listener: (context, state) {
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
        if (state is HistoryPageErrorM) {
          return _errorBody(
            message: state.message.isNotEmpty
                ? state.message
                : 'Impossible de charger l\'historique.',
            onRetry: () => context
                .read<HistoryPageBlocM>()
                .add(const LoadHistoryDataM(limit: 50)),
          );
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
            message: 'Les profils que vous ouvrez apparaîtront ici.',
          );
        }

        final groups = _groupProfilesByDay(items);
        return RefreshIndicator(
          color: SDColors.primary600,
          onRefresh: () async {
            context
                .read<HistoryPageBlocM>()
                .add(const LoadHistoryDataM(limit: 50));
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 16),
            itemCount: groups.length + 1,
            itemBuilder: (context, i) {
              if (i == groups.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: _buildFooterHint(
                    'Ouvrez un profil pour le consulter à nouveau.',
                  ),
                );
              }
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
                  ...g.items.map(_buildProfileRow),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(History h) {
    final job = (h.categorie != null && h.categorie!.trim().isNotEmpty)
        ? h.categorie!.trim()
        : _typeLabel(h.objetType);
    final chip = _universeChipForType(h.objetType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openProfile(h),
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
                  _profileThumb(h),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.titre,
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
                          job,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SDTypography.bodySmall.copyWith(
                            color: SDColors.neutral600,
                          ),
                        ),
                        if (chip != null) ...[
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
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: SDColors.neutral400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileThumb(History h) {
    final url = h.image;
    final initials = _initials(h.titre);
    return ClipOval(
      child: SizedBox(
        width: 56,
        height: 56,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsAvatar(initials),
              )
            : _initialsAvatar(initials),
      ),
    );
  }

  Widget _initialsAvatar(String initials) {
    return ColoredBox(
      color: SDColors.primary50,
      child: Center(
        child: Text(
          initials,
          style: SDTypography.titleMedium.copyWith(
            color: SDColors.primary700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

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

    final groups = _groupSearchesByDay(_recentSearches);
    return RefreshIndicator(
      color: SDColors.primary600,
      onRefresh: _loadSearches,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 16),
        itemCount: groups.length + 1,
        itemBuilder: (context, i) {
          if (i == groups.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: _buildFooterHint(
                'Touchez une recherche pour la relancer.',
              ),
            );
          }
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
              ...g.items.map(_buildSearchRow),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchRow(SearchHistoryEntry entry) {
    final chip = _universeChipForScope(entry.scope);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openSearch(entry),
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: SDColors.primary50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: SDColors.primary700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.query,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SDTypography.titleMedium.copyWith(
                            color: SDColors.neutral900,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (chip != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            chip,
                            style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Relancer',
                    onPressed: () => _openSearch(entry),
                    icon: const Icon(
                      Icons.north_east_rounded,
                      color: SDColors.primary600,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<({String label, List<History> items})> _groupProfilesByDay(
    List<History> all,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<History>>{};

    for (final h in all) {
      final local = h.dateConsultation.toLocal();
      final d = DateTime(
        local.year,
        local.month,
        local.day,
      );
      final key = d == today
          ? 'Aujourd\'hui'
          : d == yesterday
              ? 'Hier'
              : DateFormat('d MMMM yyyy', 'fr_FR').format(d);
      map.putIfAbsent(key, () => []).add(h);
    }

    final order = <String>[];
    if (map.containsKey('Aujourd\'hui')) order.add('Aujourd\'hui');
    if (map.containsKey('Hier')) order.add('Hier');
    for (final k in map.keys) {
      if (k != 'Aujourd\'hui' && k != 'Hier') order.add(k);
    }
    return order.map((k) => (label: k, items: map[k]!)).toList();
  }

  List<({String label, List<SearchHistoryEntry> items})> _groupSearchesByDay(
    List<SearchHistoryEntry> all,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<SearchHistoryEntry>>{};

    for (final e in all) {
      final at = e.at?.toLocal();
      String key;
      if (at == null) {
        key = 'Récentes';
      } else {
        final d = DateTime(at.year, at.month, at.day);
        key = d == today
            ? 'Aujourd\'hui'
            : d == yesterday
                ? 'Hier'
                : DateFormat('d MMMM yyyy', 'fr_FR').format(d);
      }
      map.putIfAbsent(key, () => []).add(e);
    }

    final order = <String>[];
    if (map.containsKey('Aujourd\'hui')) order.add('Aujourd\'hui');
    if (map.containsKey('Hier')) order.add('Hier');
    for (final k in map.keys) {
      if (k != 'Aujourd\'hui' && k != 'Hier' && k != 'Récentes') {
        order.add(k);
      }
    }
    if (map.containsKey('Récentes')) order.add('Récentes');
    return order.map((k) => (label: k, items: map[k]!)).toList();
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'FREELANCE':
        return 'Freelance';
      case 'ARTICLE':
      case 'VENDEUR':
        return ClientFeatureFlags.emarketEnabled ? 'Vente & Achat' : type;
      case 'PRESTATAIRE':
      case 'SERVICE':
      case 'PRESTATION':
        return 'Métiers';
      default:
        return type;
    }
  }

  String? _universeChipForType(String type) {
    switch (type) {
      case 'FREELANCE':
        return 'Freelance';
      case 'PRESTATAIRE':
      case 'SERVICE':
      case 'PRESTATION':
        return 'Métiers';
      case 'ARTICLE':
      case 'VENDEUR':
      case 'COMMANDE':
        return ClientFeatureFlags.emarketEnabled ? 'Vente & Achat' : null;
      default:
        return null;
    }
  }

  String? _universeChipForScope(String? scope) {
    switch (scope) {
      case 'metiers':
        return 'Métiers';
      case 'freelance':
        return 'Freelance';
      case 'emarket':
        return ClientFeatureFlags.emarketEnabled ? 'Vente & Achat' : null;
      default:
        return null;
    }
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    String firstChar(String s) {
      final r = s.runes;
      if (r.isEmpty) return '';
      return String.fromCharCode(r.first).toUpperCase();
    }

    if (parts.length == 1) return firstChar(parts.first);
    return '${firstChar(parts[0])}${firstChar(parts[1])}';
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

  Widget _errorBody({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral600,
              ),
            ),
            const SizedBox(height: 16),
            SDButton(
              text: 'Réessayer',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProfile(History h) async {
    final id = h.objetId?.trim() ?? '';
    if (id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce profil n\'est plus disponible.')),
      );
      return;
    }

    switch (h.objetType) {
      case 'PRESTATAIRE':
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(providerId: id),
          ),
        );
        return;
      case 'FREELANCE':
        await _openFreelance(id);
        return;
      default:
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de rouvrir cet élément.'),
          ),
        );
    }
  }

  Future<void> _openFreelance(String id) async {
    try {
      final raw = await _api.getFreelanceById(id);
      if (!mounted) return;
      final model = FreelanceModel.fromBackend(Map<String, dynamic>.from(raw));
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FreelanceDetailsScreen(freelance: model),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingNetworkMessage(e))),
      );
    }
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

  void _openSearch(SearchHistoryEntry entry) {
    var scope = entry.scope ?? 'global';
    if (scope == 'emarket' && !ClientFeatureFlags.emarketEnabled) {
      scope = 'global';
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchPageScreenM(
          initialQuery: entry.query,
          scope: scope,
        ),
      ),
    );
  }
}
