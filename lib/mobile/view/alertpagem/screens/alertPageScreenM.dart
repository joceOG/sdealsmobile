import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/alert.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../design_system/design_system.dart';
import '../alertpageblocm/alertPageBlocM.dart';
import '../alertpageblocm/alertPageEventM.dart';
import '../alertpageblocm/alertPageStateM.dart';
import 'alertDetailScreenM.dart';
import 'alertSettingsScreenM.dart';

/// Notifications (inbox) — dates, contexte et distinction des non-lus.
class AlertPageScreenM extends StatefulWidget {
  const AlertPageScreenM({super.key});

  @override
  State<AlertPageScreenM> createState() => _AlertPageScreenMState();
}

class _AlertPageScreenMState extends State<AlertPageScreenM> {
  static const double _hPad = 20;

  /// null = toutes ; NON_LUE ; ARCHIVEE
  String? _filterStatut;

  String? get _userId {
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) return auth.utilisateur.idutilisateur;
    return null;
  }

  void _reload() {
    context.read<AlertPageBlocM>().add(
          LoadAlertsDataM(limit: 50, userId: _userId),
        );
  }

  @override
  void initState() {
    super.initState();
    context.read<AlertPageBlocM>().add(
          LoadAlertsDataM(limit: 50, userId: _userId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: BlocConsumer<AlertPageBlocM, AlertPageStateM>(
          listener: (context, state) {
            if (state is AlertMarkedAsReadM ||
                state is AlertDeletedM ||
                state is AlertArchivedM ||
                state is AllAlertsMarkedAsReadM) {
              _reload();
            }
          },
          builder: (context, state) {
            final loaded = state is AlertPageLoadedM;
            final error = state is AlertPageErrorM;
            final all = loaded ? state.alerts : <Alert>[];
            final unread = all.where((a) => a.statut == 'NON_LUE').length;
            final archived = all.where((a) => a.statut == 'ARCHIVEE').length;
            final filtered = _applyFilter(all);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                _buildChips(
                  showCounts: loaded,
                  unread: unread,
                  archived: archived,
                  showArchived: loaded || !error,
                ),
                if (loaded && unread > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 0),
                      child: TextButton(
                        onPressed: () => context.read<AlertPageBlocM>().add(
                              MarkAllAsReadM(userId: _userId),
                            ),
                        child: Text(
                          'Tout marquer comme lu',
                          style: SDTypography.labelMedium.copyWith(
                            color: SDColors.primary600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildBody(context, state, filtered),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Alert> _applyFilter(List<Alert> all) {
    if (_filterStatut == null) {
      return all.where((a) => a.statut != 'ARCHIVEE').toList();
    }
    return all.where((a) => a.statut == _filterStatut).toList();
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
                  'Notifications',
                  style: SDTypography.titleLarge.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Vos messages et mises à jour',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) =>
                        AlertPageBlocM()..add(const LoadAlertPreferencesM()),
                    child: const AlertSettingsScreenM(),
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: SDColors.neutral900,
            ),
            tooltip: 'Préférences',
          ),
        ],
      ),
    );
  }

  Widget _buildChips({
    required bool showCounts,
    required int unread,
    required int archived,
    required bool showArchived,
  }) {
    final chips = <({String? id, String label})>[
      (
        id: null,
        label: 'Toutes',
      ),
      (
        id: 'NON_LUE',
        label: showCounts && unread > 0 ? 'Non lues ($unread)' : 'Non lues',
      ),
      if (showArchived)
        (
          id: 'ARCHIVEE',
          label: showCounts && archived > 0
              ? 'Archivées ($archived)'
              : 'Archivées',
        ),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 4),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final c = chips[index];
          final selected = _filterStatut == c.id;
          return GestureDetector(
            onTap: () => setState(() => _filterStatut = c.id),
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
                c.label,
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

  String? _contextLine(Alert alert) {
    final data = alert.donnees;
    if (data != null) {
      for (final key in const [
        'service',
        'nomservice',
        'titre',
        'prestationTitre',
        'mission',
      ]) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return null;
  }

  String _sectionLabel(DateTime date) {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return "Aujourd'hui";
    if (day == yesterday) return 'Hier';
    return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
  }

  String _timeLabel(Alert alert) {
    final created = alert.createdAt.toLocal();
    final now = DateTime.now();
    final day = DateTime(created.year, created.month, created.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final hh = created.hour.toString().padLeft(2, '0');
    final mm = created.minute.toString().padLeft(2, '0');
    if (day == yesterday) return 'Hier, $hh:$mm';
    if (day == today) return alert.dateFormatee;
    return alert.dateFormatee;
  }

  List<Object> _groupedRows(List<Alert> alerts) {
    final rows = <Object>[];
    String? last;
    for (final alert in alerts) {
      final section = _sectionLabel(alert.createdAt);
      if (section != last) {
        rows.add(section);
        last = section;
      }
      rows.add(alert);
    }
    return rows;
  }

  Widget _buildAlertCard(Alert alert) {
    final iconData = _iconForType(alert.type);
    final tint = _tintForType(alert.type);
    final unread = alert.estNonLue;
    final photo = alert.expediteurPhoto;
    final contextLine = _contextLine(alert);

    return Material(
      color: unread ? SDColors.primary50 : SDColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (unread && alert.id != null) {
            context.read<AlertPageBlocM>().add(MarkAsReadM(alertId: alert.id!));
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => AlertPageBlocM(),
                child: AlertDetailScreenM(alert: alert),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: unread ? SDColors.primary50 : SDColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread ? SDColors.primary200 : SDColors.neutral200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeading(
                  photo: photo,
                  iconData: iconData,
                  tint: tint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert.titre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SDTypography.titleMedium.copyWith(
                                color: SDColors.neutral900,
                                fontWeight:
                                    unread ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeLabel(alert),
                            style: SDTypography.bodySmall.copyWith(
                              color: SDColors.neutral500,
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: SDColors.primary600,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (alert.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          alert.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if (contextLine != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(_contextIcon(alert.type),
                                size: 14, color: SDColors.neutral500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                contextLine,
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
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: SDColors.neutral400,
                  ),
                  tooltip: 'Actions',
                  onSelected: (v) {
                    if (alert.id == null) return;
                    if (v == 'read') {
                      context
                          .read<AlertPageBlocM>()
                          .add(MarkAsReadM(alertId: alert.id!));
                    } else if (v == 'archive') {
                      context
                          .read<AlertPageBlocM>()
                          .add(ArchiveAlertM(alertId: alert.id!));
                    } else if (v == 'delete') {
                      context
                          .read<AlertPageBlocM>()
                          .add(DeleteAlertM(alertId: alert.id!));
                    }
                  },
                  itemBuilder: (_) => [
                    if (unread)
                      const PopupMenuItem(
                        value: 'read',
                        child: Text('Marquer comme lue'),
                      ),
                    if (alert.statut != 'ARCHIVEE')
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Archiver'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
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

  Widget _buildLeading({
    required String? photo,
    required IconData iconData,
    required Color tint,
  }) {
    if (photo != null && photo.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 48,
          height: 48,
          child: Image.network(
            photo,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _iconBubble(iconData, tint),
          ),
        ),
      );
    }
    return _iconBubble(iconData, tint);
  }

  Widget _iconBubble(IconData iconData, Color tint) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: tint, size: 24),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AlertPageStateM state,
    List<Alert> filtered,
  ) {
    if (state is AlertPageLoadingM || state is AlertPageInitialM) {
      return const Center(
        child: CircularProgressIndicator(color: SDColors.primary600),
      );
    }

    if (state is AlertPageErrorM) {
      return _errorState();
    }

    if (filtered.isEmpty) {
      return RefreshIndicator(
        color: SDColors.primary600,
        onRefresh: () async => _reload(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: _emptyState(),
            ),
          ],
        ),
      );
    }

    final rows = _groupedRows(filtered);
    return RefreshIndicator(
      color: SDColors.primary600,
      onRefresh: () async => _reload(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 24),
        itemCount: rows.length,
        separatorBuilder: (context, i) {
          final next = i + 1 < rows.length ? rows[i + 1] : null;
          if (next is String) return const SizedBox(height: 16);
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, i) {
          final row = rows[i];
          if (row is String) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                row,
                style: SDTypography.titleSmall.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }
          return _buildAlertCard(row as Alert);
        },
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: SDColors.primary50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              size: 40,
              color: SDColors.neutral700,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Impossible de charger\nles notifications',
            textAlign: TextAlign.center,
            style: SDTypography.titleLarge.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Réessayez dans un instant.',
            textAlign: TextAlign.center,
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
            ),
          ),
          const SizedBox(height: 24),
          SDButton(
            text: 'Réessayer',
            icon: Icons.refresh_rounded,
            fullWidth: true,
            onPressed: _reload,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'Vos notifications s\'afficheront ici.',
              textAlign: TextAlign.center,
              style: SDTypography.bodySmall.copyWith(
                color: SDColors.neutral500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: SDColors.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: SDTypography.titleMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos notifications s\'afficheront ici.',
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

  IconData _contextIcon(String type) {
    switch (type) {
      case 'MESSAGE_RECU':
      case 'MESSAGE':
        return Icons.work_outline;
      case 'MISSION_ACCEPTEE':
      case 'NOUVELLE_MISSION':
      case 'MISSION_DEMARREE':
      case 'MISSION_TERMINEE':
      case 'MISSION_REFUSEE':
      case 'PRESTATION':
        return Icons.build_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'NOUVELLE_MISSION':
        return Icons.assignment_outlined;
      case 'MISSION_ACCEPTEE':
        return Icons.build_outlined;
      case 'MISSION_REFUSEE':
        return Icons.cancel_outlined;
      case 'MISSION_DEMARREE':
        return Icons.play_circle_outline;
      case 'MISSION_TERMINEE':
        return Icons.check_circle_outline;
      case 'EVALUATION_RECUE':
        return Icons.star_outline;
      case 'COMMANDE':
        return Icons.shopping_bag_outlined;
      case 'PRESTATION':
        return Icons.handyman_outlined;
      case 'PAIEMENT':
        return Icons.payments_outlined;
      case 'MESSAGE_RECU':
      case 'MESSAGE':
        return Icons.chat_bubble_outline;
      case 'PROMOTION':
        return Icons.local_offer_outlined;
      case 'RAPPEL':
        return Icons.alarm_outlined;
      case 'VERIFICATION':
        return Icons.verified_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _tintForType(String type) {
    switch (type) {
      case 'NOUVELLE_MISSION':
      case 'MISSION_ACCEPTEE':
      case 'PRESTATION':
        return SDColors.primary600;
      case 'MESSAGE_RECU':
      case 'MESSAGE':
        return SDColors.info500;
      case 'MISSION_DEMARREE':
      case 'MISSION_TERMINEE':
        return SDColors.info600;
      case 'PAIEMENT':
        return SDColors.warning600;
      case 'PROMOTION':
        return SDColors.error500;
      default:
        return SDColors.neutral600;
    }
  }
}
