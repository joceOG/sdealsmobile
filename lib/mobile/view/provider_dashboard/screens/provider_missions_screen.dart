import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sdealsmobile/data/services/api_client.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:sdealsmobile/data/errors/api_exception.dart';
import 'package:sdealsmobile/data/services/auth_professional_access.dart';
import 'package:sdealsmobile/data/utils/display_text.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../models/provider_mission.dart';

/// Écran Missions prestataire — layout type Figma (aperçu + chips + cartes).
class ProviderMissionsScreen extends StatefulWidget {
  final String? prestataireDocId;

  const ProviderMissionsScreen({Key? key, this.prestataireDocId}) : super(key: key);

  @override
  ProviderMissionsScreenState createState() => ProviderMissionsScreenState();
}

class ProviderMissionsScreenState extends State<ProviderMissionsScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  bool _showSearch = false;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all | nouvelles | en_cours | terminees
  String? _selectedDateFilter; // today | week | month | null

  List<Map<String, dynamic>> _availableMissions = [];
  List<Map<String, dynamic>> _ongoingMissions = [];
  List<Map<String, dynamic>> _completedMissions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _mutatingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMissions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Appelé depuis l’AppBar parent.
  void toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  /// Appelé depuis l’AppBar parent.
  void openFilters() => _showFilterSheet();

  /// Recharge après retour du détail (conserve filtres / recherche).
  Future<void> reload() => _loadMissions();

  Future<void> _loadMissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthCubit>().state;
      if (auth is! AuthAuthenticated) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Connexion requise';
        });
        return;
      }

      final prestataireDocId = widget.prestataireDocId;
      final utilisateurId = auth.utilisateur.idutilisateur;

      Future<List<Map<String, dynamic>>> byStatus(String status) {
        return _apiClient.getPrestationsByStatus(
          token: auth.token,
          status: status,
          prestataireId: prestataireDocId,
        );
      }

      if (prestataireDocId != null) {
        final available = await byStatus('EN_ATTENTE');
        final accepted = await byStatus('ACCEPTEE');
        final ongoing = await byStatus('EN_COURS');
        final completed = await byStatus('TERMINEE');
        if (!mounted) return;
        setState(() {
          _availableMissions = available;
          _ongoingMissions = [...accepted, ...ongoing];
          _completedMissions = completed;
          _isLoading = false;
        });
      } else {
        final available = await _apiClient.getPrestationsByStatus(
            token: auth.token, status: 'EN_ATTENTE');
        final accepted = await _apiClient.getPrestationsByStatus(
            token: auth.token, status: 'ACCEPTEE');
        final ongoing = await _apiClient.getPrestationsByStatus(
            token: auth.token, status: 'EN_COURS');
        final completed = await _apiClient.getPrestationsByStatus(
            token: auth.token, status: 'TERMINEE');

        bool matchUser(m) =>
            m['prestataire']?['utilisateur']?.toString() == utilisateurId ||
            m['prestataire']?.toString() == utilisateurId;

        if (!mounted) return;
        setState(() {
          _availableMissions = available.where(matchUser).toList();
          _ongoingMissions = [
            ...accepted.where(matchUser),
            ...ongoing.where(matchUser),
          ];
          _completedMissions = completed.where(matchUser).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ApiException.userFacing(e);
      });
    }
  }

  Future<void> _changeStatus(
    Map<String, dynamic> mission,
    String newStatus,
    String successMessage,
  ) async {
    final id = prestationIdOf(mission);
    if (id == null || _mutatingId != null) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;
    setState(() => _mutatingId = id);
    try {
      await _apiClient.updatePrestationStatus(
        token: auth.token,
        prestationId: id,
        newStatus: newStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadMissions();
    } catch (e) {
      if (!mounted) return;
      await refreshProfessionalCapabilitiesAfterBlock(context, e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiException.userFacing(e)),
          backgroundColor: SDColors.error500,
        ),
      );
    } finally {
      if (mounted) setState(() => _mutatingId = null);
    }
  }

  Future<void> _acceptMission(Map<String, dynamic> mission) =>
      _changeStatus(mission, 'ACCEPTEE', 'Mission acceptée');

  Future<void> _rejectMission(Map<String, dynamic> mission) =>
      _changeStatus(mission, 'REFUSEE', 'Mission refusée');

  Future<void> _completeMission(Map<String, dynamic> mission) =>
      _changeStatus(mission, 'TERMINEE', 'Mission terminée');

  Future<void> _openDetail(Map<String, dynamic> mission) async {
    final id = prestationIdOf(mission);
    if (id == null) return;
    final changed = await context.push<bool>(
      '/mission-details/$id',
      extra: widget.prestataireDocId == null
          ? null
          : {'prestataireDocId': widget.prestataireDocId},
    );
    if (changed == true && mounted) await _loadMissions();
  }

  Future<void> _startMission(Map<String, dynamic> mission) =>
      _changeStatus(mission, 'EN_COURS', 'Mission démarrée');

  List<Map<String, dynamic>> get _sourceList {
    switch (_statusFilter) {
      case 'nouvelles':
        return _availableMissions;
      case 'en_cours':
        return _ongoingMissions;
      case 'terminees':
        return _completedMissions;
      default:
        return [
          ..._availableMissions,
          ..._ongoingMissions,
          ..._completedMissions,
        ];
    }
  }

  String _missionType(Map<String, dynamic> mission) {
    switch (prestationStatusOf(mission)) {
      case 'TERMINEE':
        return 'completed';
      case 'EN_COURS':
        return 'ongoing';
      case 'ACCEPTEE':
        return 'accepted';
      case 'REFUSEE':
      case 'ANNULEE':
      case 'LITIGE':
        return 'readonly';
      default:
        return 'available';
    }
  }

  List<Map<String, dynamic>> _filteredMissions() {
    var list = List<Map<String, dynamic>>.from(_sourceList);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) {
        final name = prestationClientName(m, fallback: '').toLowerCase();
        final lieu = prestationLocationLabel(m).toLowerCase();
        final title = prestationServiceTitle(m).toLowerCase();
        final notes = (cleanDisplayPart(m['notesClient']) ?? '').toLowerCase();
        return name.contains(q) ||
            lieu.contains(q) ||
            title.contains(q) ||
            notes.contains(q);
      }).toList();
    }

    if (_selectedDateFilter != null) {
      final now = DateTime.now();
      list = list.where((m) {
        final raw = m['datePrestation'] ?? m['createdAt'];
        final d = DateTime.tryParse('$raw');
        if (d == null) return false;
        final local = d.toLocal();
        switch (_selectedDateFilter) {
          case 'today':
            return local.year == now.year &&
                local.month == now.month &&
                local.day == now.day;
          case 'week':
            return now.difference(local).inDays <= 7;
          case 'month':
            return local.year == now.year && local.month == now.month;
          default:
            return true;
        }
      }).toList();
    }

    return list;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SDColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SDColors.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Filtrer par période',
                  style: SDTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SDColors.neutral900,
                  ),
                ),
                const SizedBox(height: 12),
                ...[
                  (null, 'Toutes les dates'),
                  ('today', 'Aujourd\'hui'),
                  ('week', 'Cette semaine'),
                  ('month', 'Ce mois'),
                ].map((e) {
                  final selected = _selectedDateFilter == e.$1;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: SDColors.neutral900,
                    ),
                    title: Text(e.$2,
                        style: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral900)),
                    onTap: () {
                      setState(() => _selectedDateFilter = e.$1);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final missions = _filteredMissions();

    return ColoredBox(
      color: SDColors.white,
      child: RefreshIndicator(
        onRefresh: _loadMissions,
        color: SDColors.primary600,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCard(),
                    if (_showSearch) ...[
                      const SizedBox(height: 12),
                      _buildSearchField(),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildSearchScopeHint(),
                      ],
                    ],
                    const SizedBox(height: 20),
                    _buildSectionHeader(),
                    const SizedBox(height: 12),
                    _buildStatusChips(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 40, color: SDColors.neutral900),
                        const SizedBox(height: 12),
                        Text(_errorMessage!,
                            textAlign: TextAlign.center,
                            style: SDTypography.bodyMedium
                                .copyWith(color: SDColors.neutral600)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loadMissions,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (missions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.work_outline_rounded,
                            size: 48, color: SDColors.neutral900.withOpacity(0.35)),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Aucun résultat dans la liste affichée'
                              : 'Aucune mission pour ce filtre',
                          style: SDTypography.titleSmall.copyWith(
                            color: SDColors.neutral900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _emptyListHint(),
                          style: SDTypography.bodySmall
                              .copyWith(color: SDColors.neutral500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final mission = missions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MissionCard(
                          mission: mission,
                          type: _missionType(mission),
                          busy: _mutatingId != null,
                          canOperate:
                              context.watch<AuthCubit>().state.canOperatePrestataire,
                          onOpen: () => _openDetail(mission),
                          onAccept: () => _acceptMission(mission),
                          onReject: () => _rejectMission(mission),
                          onStart: () => _startMission(mission),
                          onComplete: () => _completeMission(mission),
                        ),
                      );
                    },
                    childCount: missions.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SDColors.primary800,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Aperçu de mes activités',
                  style: SDTypography.titleSmall.copyWith(
                    color: SDColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Material(
                color: SDColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _showFilterSheet,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedDateFilter == 'today'
                              ? 'Aujourd\'hui'
                              : _selectedDateFilter == 'week'
                                  ? 'Cette semaine'
                                  : _selectedDateFilter == 'month'
                                      ? 'Ce mois'
                                      : 'Toutes les dates',
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: SDColors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  icon: Icons.inbox_outlined,
                  value: '${_availableMissions.length + _ongoingMissions.length + _completedMissions.length}',
                  label: 'Demandes\nreçues',
                ),
              ),
              Expanded(
                child: _OverviewStat(
                  icon: Icons.pending_actions_outlined,
                  value: '${_ongoingMissions.length}',
                  label: 'Missions\nen cours',
                ),
              ),
              Expanded(
                child: _OverviewStat(
                  icon: Icons.check_circle_outline_rounded,
                  value: '${_completedMissions.length}',
                  label: 'Missions\nterminées',
                ),
              ),
              Expanded(
                child: _OverviewStat(
                  icon: Icons.star_border_rounded,
                  value: '—',
                  label: 'Note\nmoyenne',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusFilterLabel() {
    switch (_statusFilter) {
      case 'nouvelles':
        return 'nouvelles demandes';
      case 'en_cours':
        return 'missions en cours et acceptées';
      case 'terminees':
        return 'missions terminées';
      default:
        return 'toutes les missions chargées (nouvelles, en cours, terminées)';
    }
  }

  String _emptyListHint() {
    if (_searchQuery.isNotEmpty) {
      return 'La recherche ne parcourt que les ${_statusFilterLabel()}. '
          'Essayez un autre filtre de statut, effacez la recherche ou actualisez la liste.';
    }
    return 'Tirez pour actualiser ou changez de filtre.';
  }

  Widget _buildSearchScopeHint() {
    return Text(
      'Recherche limitée aux ${_statusFilterLabel()} déjà chargées — '
      'ce n’est pas une recherche sur toute la plateforme.',
      style: SDTypography.labelSmall.copyWith(
        color: SDColors.neutral500,
        height: 1.35,
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      onChanged: (v) => setState(() => _searchQuery = v),
      style: SDTypography.bodyMedium.copyWith(color: SDColors.neutral900),
      decoration: InputDecoration(
        hintText: 'Filtrer dans la liste affichée…',
        hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral400),
        prefixIcon: const Icon(Icons.search_rounded, color: SDColors.neutral900),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close_rounded, color: SDColors.neutral900),
          onPressed: toggleSearch,
        ),
        filled: true,
        fillColor: SDColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: SDColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: SDColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SDColors.neutral900, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Text(
          'Demandes de mission',
          style: SDTypography.titleSmall.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (_availableMissions.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: SDColors.primary50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_availableMissions.length} nouvelles',
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.primary700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChips() {
    Widget chip(String id, String label, {int? badge}) {
      final selected = _statusFilter == id;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          selected: selected,
          showCheckmark: false,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (badge != null && badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? SDColors.white : SDColors.primary600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: SDTypography.labelSmall.copyWith(
                      color: selected ? SDColors.primary700 : SDColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          labelStyle: SDTypography.labelMedium.copyWith(
            color: selected ? SDColors.white : SDColors.neutral900,
            fontWeight: FontWeight.w600,
          ),
          selectedColor: SDColors.primary700,
          backgroundColor: SDColors.white,
          side: BorderSide(
            color: selected ? SDColors.primary700 : SDColors.neutral200,
          ),
          onSelected: (_) => setState(() => _statusFilter = id),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('all', 'Toutes'),
          chip('nouvelles', 'Nouvelles', badge: _availableMissions.length),
          chip('en_cours', 'En cours', badge: _ongoingMissions.length),
          chip('terminees', 'Terminées'),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _OverviewStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: SDColors.white, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: SDTypography.titleMedium.copyWith(
            color: SDColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: SDTypography.labelSmall.copyWith(
            color: SDColors.white.withOpacity(0.85),
            height: 1.15,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Map<String, dynamic> mission;
  final String type;
  final bool busy;
  final bool canOperate;
  final VoidCallback onOpen;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const _MissionCard({
    required this.mission,
    required this.type,
    required this.busy,
    required this.canOperate,
    required this.onOpen,
    required this.onAccept,
    required this.onReject,
    required this.onStart,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final clientName = prestationClientName(mission);
    final title = prestationServiceTitle(mission);
    final adresse = cleanDisplayPart(mission['adresse']);
    final ville = cleanDisplayPart(mission['ville']);
    final lieu = [ville, adresse].whereType<String>().join(', ');
    final notes = cleanDisplayPart(mission['notesClient']) ?? '';
    final montant = mission['montantTotal'] ?? mission['budget'] ?? 0;
    final montantStr = montant is num && montant > 0
        ? '${NumberFormat('#,###', 'fr_FR').format(montant)} FCFA'
        : 'Sur devis';
    final when = _relativeTime(mission['createdAt'] ?? mission['datePrestation']);

    final badge = switch (type) {
      'accepted' => (
          'Acceptée',
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309)
        ),
      'ongoing' => (
          'En cours',
          const Color(0xFFDBEAFE),
          const Color(0xFF1D4ED8)
        ),
      'completed' => ('Terminée', SDColors.primary50, SDColors.primary700),
      'readonly' => (
          prestationStatusLabel(prestationStatusOf(mission)),
          SDColors.neutral100,
          SDColors.neutral700
        ),
      _ => ('Nouveau', SDColors.primary50, SDColors.primary700),
    };

    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.$2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge.$1,
                  style: SDTypography.labelSmall.copyWith(
                    color: badge.$3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                when,
                style: SDTypography.labelSmall
                    .copyWith(color: SDColors.neutral500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: SDColors.neutral100,
                child: const Icon(Icons.person_outline_rounded,
                    color: SDColors.neutral900),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SDTypography.titleSmall.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (clientName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        clientName,
                        style: SDTypography.bodySmall
                            .copyWith(color: SDColors.neutral600),
                      ),
                    ],
                    if (lieu.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 14, color: SDColors.neutral900),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lieu,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.bodySmall
                                  .copyWith(color: SDColors.neutral600),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SDTypography.bodySmall
                            .copyWith(color: SDColors.neutral500),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    montantStr,
                    style: SDTypography.labelLarge.copyWith(
                      color: SDColors.primary700,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    type == 'available' ? 'Budget estimé' : 'Montant',
                    style: SDTypography.labelSmall
                        .copyWith(color: SDColors.neutral500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildActions(),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final statut = prestationStatusOf(mission);
    final actions = visibleProviderActions(
      statut: statut,
      isOwner: true,
      canOperate: canOperate,
    );
    final showAccept = actions.contains(ProviderMissionAction.accept);
    final showRefuse = actions.contains(ProviderMissionAction.refuse);
    final showStart = actions.contains(ProviderMissionAction.start);
    final showComplete = actions.contains(ProviderMissionAction.complete);

    if (showRefuse && showAccept) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: busy ? null : onReject,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Refuser'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SDColors.neutral900,
                side: BorderSide(color: SDColors.neutral300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: busy ? null : onAccept,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Accepter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SDColors.primary600,
                foregroundColor: SDColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }
    if (showStart) {
      return ElevatedButton.icon(
        onPressed: busy ? null : onStart,
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
        label: const Text('Démarrer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: SDColors.primary600,
          foregroundColor: SDColors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 44),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    if (showComplete) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.work_outline_rounded, size: 18),
              label: const Text('Voir la mission'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SDColors.neutral900,
                side: BorderSide(color: SDColors.neutral300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: busy ? null : onComplete,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Terminer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SDColors.primary600,
                foregroundColor: SDColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }
    return OutlinedButton.icon(
      onPressed: onOpen,
      icon: const Icon(Icons.visibility_outlined, size: 18),
      label: const Text('Voir la mission'),
      style: OutlinedButton.styleFrom(
        foregroundColor: SDColors.neutral900,
        side: BorderSide(color: SDColors.neutral300),
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _relativeTime(dynamic raw) {
    final d = DateTime.tryParse('$raw')?.toLocal();
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return DateFormat('d MMM', 'fr_FR').format(d);
  }
}
