import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/services/auth_professional_access.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';
import '../models/provider_mission.dart';

/// Détail d’une prestation (mission Métiers) — GET `/prestation/:id`.
class ProviderMissionDetailScreen extends StatefulWidget {
  const ProviderMissionDetailScreen({
    super.key,
    required this.missionId,
    this.initial,
    this.prestataireDocId,
  });

  final String missionId;
  final Map<String, dynamic>? initial;
  final String? prestataireDocId;

  @override
  State<ProviderMissionDetailScreen> createState() =>
      _ProviderMissionDetailScreenState();
}

class _ProviderMissionDetailScreenState
    extends State<ProviderMissionDetailScreen> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  int? _errorStatus;
  Map<String, dynamic>? _mission;
  bool _mutating = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _mission = Map<String, dynamic>.from(widget.initial!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.missionId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Identifiant de mission manquant.';
        _errorStatus = 400;
      });
      return;
    }

    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated || auth.token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Session expirée — reconnectez-vous.';
        _errorStatus = 401;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _errorStatus = null;
    });

    try {
      final data = await _api.getPrestationById(
        token: auth.token,
        id: widget.missionId,
      );
      if (!mounted) return;
      setState(() {
        _mission = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final status = e is ApiException ? e.statusCode : null;
      setState(() {
        _loading = false;
        _errorStatus = status;
        _error = _messageForError(e, status);
      });
    }
  }

  String _messageForError(Object e, int? status) {
    if (status == 404) return 'Cette mission est introuvable.';
    if (status == 403) return 'Accès refusé à cette mission.';
    if (status == 401) return 'Session expirée — reconnectez-vous.';
    return ApiException.userFacing(e);
  }

  bool get _isOwner {
    final mission = _mission;
    if (mission == null) return false;
    final auth = context.read<AuthCubit>().state;
    final userId =
        auth is AuthAuthenticated ? auth.utilisateur.idutilisateur : null;
    return isProviderOwnerOfPrestation(
      mission,
      prestataireDocId: widget.prestataireDocId,
      utilisateurId: userId,
    );
  }

  Future<void> _runAction(ProviderMissionAction action) async {
    if (_mutating) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) return;

    setState(() => _mutating = true);
    try {
      await _api.updatePrestationStatus(
        token: auth.token,
        prestationId: widget.missionId,
        newStatus: targetStatusFor(action),
      );
      _changed = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_successLabel(action)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
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
      if (mounted) setState(() => _mutating = false);
    }
  }

  String _successLabel(ProviderMissionAction action) {
    switch (action) {
      case ProviderMissionAction.accept:
        return 'Mission acceptée';
      case ProviderMissionAction.refuse:
        return 'Mission refusée';
      case ProviderMissionAction.start:
        return 'Mission démarrée';
      case ProviderMissionAction.complete:
        return 'Mission terminée';
    }
  }

  void _pop() => Navigator.pop(context, _changed);

  bool _isScheduleWish(String statut) {
    switch (statut.toUpperCase()) {
      case 'EN_ATTENTE':
        return true;
      default:
        return false;
    }
  }

  String? _receivedRelativeLabel(Map<String, dynamic> mission) {
    final raw = mission['createdAt'] ?? mission['dateCommande'];
    if (raw == null) return null;
    final date = DateTime.tryParse(raw.toString())?.toLocal();
    if (date == null) return null;
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Reçue à l’instant';
    if (diff.inHours < 1) {
      return 'Reçue il y a ${diff.inMinutes} min';
    }
    if (diff.inDays < 1) {
      return 'Reçue il y a ${diff.inHours} h';
    }
    return 'Reçue le ${DateFormat('d MMM', 'fr_FR').format(date)}';
  }

  String? _serviceCategoryLabel(Map<String, dynamic> mission) {
    final service = mission['service'];
    if (service is Map) {
      final cat = service['categorie'];
      if (cat is Map) {
        final name = cleanDisplayPart(cat['nom'] ?? cat['name']);
        if (name != null) return name;
      }
      return cleanDisplayPart(
        service['nomservice'] ?? service['nom'] ?? service['name'],
      );
    }
    return cleanDisplayPart(mission['typeService']);
  }

  String _clientInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  List<({String label, String value, IconData icon})> _practicalRows(
    Map<String, dynamic> mission,
    String statut,
  ) {
    final wish = _isScheduleWish(statut);
    final datePrefix = wish ? 'souhaitée' : 'confirmée';
    final timePrefix = wish ? 'souhaité' : 'confirmé';

    final rows = <({String label, String value, IconData icon})>[];

    final date = DateTime.tryParse(
      '${mission['datePrestation'] ?? ''}',
    )?.toLocal();
    if (date != null) {
      final formatted = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
      final cap = formatted.isNotEmpty
          ? '${formatted[0].toUpperCase()}${formatted.substring(1)}'
          : formatted;
      rows.add((
        label: 'Date $datePrefix',
        value: cap,
        icon: Icons.calendar_today_outlined,
      ));
    }

    final heureDebut = cleanDisplayPart(mission['heureDebut']);
    final heureFin = cleanDisplayPart(mission['heureFin']);
    if (heureDebut != null) {
      final value = heureFin != null ? '$heureDebut – $heureFin' : heureDebut;
      rows.add((
        label: 'Horaire $timePrefix',
        value: value,
        icon: Icons.schedule_outlined,
      ));
    }

    final adresse = cleanDisplayPart(mission['adresse']);
    final ville = cleanDisplayPart(mission['ville']);
    final lieuParts = [
      if (adresse != null) adresse,
      if (ville != null) ville,
    ];
    if (lieuParts.isNotEmpty) {
      rows.add((
        label: 'Lieu d’intervention',
        value: lieuParts.join(', '),
        icon: Icons.place_outlined,
      ));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _pop();
      },
      child: Scaffold(
        backgroundColor: SDColors.white,
        appBar: SDWhiteAppBar.appBar(
          title: 'Détail de la mission',
          titleStyle: SDTypography.titleLarge,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _mission == null) {
      return _loadingSkeleton();
    }
    if (_error != null && _mission == null) {
      return _fatalErrorView();
    }
    if (_mission == null) {
      return _notFoundView();
    }

    final mission = _isOwner
        ? _mission!
        : prestationForNonOwnerDisplay(_mission!);
    final statut = prestationStatusOf(mission);
    final title = prestationServiceTitle(mission);
    final category = _serviceCategoryLabel(mission);
    final showCategory = category != null &&
        category.toLowerCase() != title.toLowerCase();
    final description = cleanDisplayPart(mission['description']) ??
        cleanDisplayPart(mission['notesClient']);
    final tarif = formatOptionalPrice(
      mission['montantTotal'] ?? mission['tarifHoraire'],
      suffix: 'FCFA',
    );
    final canOperate = context.watch<AuthCubit>().state.canOperatePrestataire;
    final actions = visibleProviderActions(
      statut: statut,
      isOwner: _isOwner,
      canOperate: canOperate,
    );
    final List<({String label, String value, IconData icon})> practical =
        _isOwner ? _practicalRows(mission, statut) : [];
    final clientName = prestationClientName(mission);
    final received = _receivedRelativeLabel(mission);

    return Column(
      children: [
        if (_loading)
          const LinearProgressIndicator(
            minHeight: 2,
            color: SDColors.primary600,
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _statusHeader(statut, received),
              const SizedBox(height: 16),
              Text(
                title,
                style: SDTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SDColors.neutral900,
                ),
              ),
              if (showCategory) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _iconWell(Icons.handyman_outlined),
                    const SizedBox(width: 10),
                    Text(
                      category,
                      style: SDTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SDColors.neutral800,
                      ),
                    ),
                  ],
                ),
              ],
              if (statut == 'EN_ATTENTE' && _isOwner) ...[
                const SizedBox(height: 16),
                _infoBanner(
                  'Cette demande attend votre réponse.',
                ),
              ],
              if (description != null && _isOwner) ...[
                const SizedBox(height: 24),
                _sectionTitle('La demande'),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: SDTypography.bodyMedium.copyWith(
                    color: SDColors.neutral700,
                    height: 1.45,
                  ),
                ),
              ],
              if (practical.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle('Informations pratiques'),
                const SizedBox(height: 10),
                _practicalCard(practical),
              ],
              if (_isOwner) ...[
                const SizedBox(height: 24),
                _sectionTitle('Client'),
                const SizedBox(height: 10),
                _clientCard(clientName),
              ],
              if (tarif != null && _isOwner) ...[
                const SizedBox(height: 20),
                _practicalCard([
                  (
                    label: 'Tarif',
                    value: tarif,
                    icon: Icons.payments_outlined,
                  ),
                ]),
              ],
              if (!_isOwner) ...[
                const SizedBox(height: 24),
                _infoBanner(
                  'Accès limité : vous ne voyez pas les informations sensibles '
                  'de cette mission.',
                  tone: SDColors.neutral100,
                ),
              ] else if (!canOperate &&
                  (statut == 'EN_ATTENTE' || statut == 'ACCEPTEE')) ...[
                const SizedBox(height: 20),
                Text(
                  'Votre profil Prestataire n’est pas encore autorisé '
                  'à accepter ou démarrer une mission.',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral500,
                  ),
                ),
              ],
            ],
          ),
        ),
        _actionFooter(actions),
      ],
    );
  }

  Widget _loadingSkeleton() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _skeletonBox(height: 32, width: 160),
              const SizedBox(height: 16),
              _skeletonBox(height: 28, width: double.infinity),
              const SizedBox(height: 12),
              _skeletonBox(height: 20, width: 120),
              const SizedBox(height: 24),
              _skeletonBox(height: 72, width: double.infinity),
              const SizedBox(height: 24),
              _sectionTitle('Informations pratiques'),
              const SizedBox(height: 10),
              _skeletonBox(height: 140, width: double.infinity),
            ],
          ),
        ),
        _actionFooter(const [], disabled: true),
      ],
    );
  }

  Widget _skeletonBox({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _fatalErrorView() {
    final status = _errorStatus;
    final message = _error ?? 'Une erreur est survenue.';

    if (status == 403) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SDEmptyState(
            title: 'Accès refusé',
            message: message,
            icon: Icons.lock_outline,
            action: SDButton(
              text: 'Retour',
              type: SDButtonType.outlined,
              onPressed: _pop,
            ),
          ),
        ),
      );
    }

    if (status == 404) {
      return _notFoundView();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SDErrorState(
          message: message,
          onRetry: _load,
        ),
      ),
    );
  }

  Widget _notFoundView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SDEmptyState(
          title: 'Mission introuvable',
          message:
              'Cette mission n’existe plus ou n’est plus accessible depuis votre compte.',
          icon: Icons.search_off_outlined,
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SDButton(text: 'Retour aux missions', onPressed: _pop),
              const SizedBox(height: 8),
              SDButton(
                text: 'Réessayer',
                type: SDButtonType.outlined,
                onPressed: _load,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusHeader(String statut, String? received) {
    final label = prestationStatusLabel(statut);
    final icon = _statusIcon(statut);
    final colors = _statusColors(statut);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colors.fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: SDTypography.labelMedium.copyWith(
                  color: colors.fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (received != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              received,
              style: SDTypography.caption.copyWith(color: SDColors.neutral500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  ({Color bg, Color fg}) _statusColors(String statut) {
    switch (statut.toUpperCase()) {
      case 'REFUSEE':
      case 'ANNULEE':
        return (bg: SDColors.error50, fg: SDColors.error600);
      case 'TERMINEE':
        return (bg: SDColors.neutral100, fg: SDColors.neutral700);
      case 'EN_COURS':
        return (bg: const Color(0xFFEFF6FF), fg: const Color(0xFF2563EB));
      default:
        return (bg: SDColors.primary50, fg: SDColors.primary700);
    }
  }

  IconData _statusIcon(String statut) {
    switch (statut.toUpperCase()) {
      case 'EN_COURS':
        return Icons.play_circle_outline;
      case 'TERMINEE':
        return Icons.check_circle_outline;
      case 'REFUSEE':
        return Icons.cancel_outlined;
      case 'ACCEPTEE':
      case 'CONFIRMEE':
        return Icons.event_available_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: SDTypography.titleSmall.copyWith(
        fontWeight: FontWeight.w800,
        color: SDColors.neutral900,
      ),
    );
  }

  Widget _iconWell(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SDColors.primary50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: SDColors.primary700),
    );
  }

  Widget _infoBanner(String text, {Color? tone}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone ?? SDColors.primary50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: tone != null ? SDColors.neutral600 : SDColors.primary700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _practicalCard(
    List<({String label, String value, IconData icon})> rows,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: SDColors.neutral200),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconWell(rows[i].icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].label,
                          style: SDTypography.caption.copyWith(
                            color: SDColors.neutral500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rows[i].value,
                          style: SDTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SDColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _clientCard(String clientName) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: SDColors.primary50,
            child: Text(
              _clientInitials(clientName),
              style: SDTypography.labelLarge.copyWith(
                color: SDColors.primary700,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: SDTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'À l’origine de la demande',
                  style: SDTypography.caption.copyWith(
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

  Widget _actionFooter(
    List<ProviderMissionAction> actions, {
    bool disabled = false,
  }) {
    final showBar = disabled || actions.isNotEmpty;
    if (!showBar) return const SizedBox.shrink();

    final bottom = SDResponsive.occupiedBottomInset(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
      child: disabled
          ? Row(
              children: [
                Expanded(child: _skeletonBox(height: 48, width: 0)),
                const SizedBox(width: 10),
                Expanded(child: _skeletonBox(height: 48, width: 0)),
              ],
            )
          : _actionBar(actions),
    );
  }

  Widget _actionBar(List<ProviderMissionAction> actions) {
    if (actions.contains(ProviderMissionAction.refuse) &&
        actions.contains(ProviderMissionAction.accept)) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _mutating
                  ? null
                  : () => _runAction(ProviderMissionAction.refuse),
              style: OutlinedButton.styleFrom(
                foregroundColor: SDColors.error600,
                side: const BorderSide(color: SDColors.error500),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Refuser',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: _mutating
                  ? null
                  : () => _runAction(ProviderMissionAction.accept),
              style: FilledButton.styleFrom(
                backgroundColor: SDColors.primary700,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _mutating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SDColors.white,
                      ),
                    )
                  : const Text(
                      'Accepter',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      );
    }

    if (actions.length == 1) {
      return FilledButton(
        onPressed: _mutating ? null : () => _runAction(actions.first),
        style: FilledButton.styleFrom(
          backgroundColor: SDColors.primary700,
          minimumSize: const Size.fromHeight(48),
        ),
        child: Text(
          _actionLabel(actions.first),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    if (actions.length == 2) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _mutating ? null : () => _runAction(actions.first),
              child: Text(_actionLabel(actions.first)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: _mutating ? null : () => _runAction(actions.last),
              style: FilledButton.styleFrom(
                backgroundColor: SDColors.primary700,
              ),
              child: Text(_actionLabel(actions.last)),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  String _actionLabel(ProviderMissionAction action) {
    switch (action) {
      case ProviderMissionAction.accept:
        return 'Accepter';
      case ProviderMissionAction.refuse:
        return 'Refuser';
      case ProviderMissionAction.start:
        return 'Démarrer';
      case ProviderMissionAction.complete:
        return 'Terminer la mission';
    }
  }
}
