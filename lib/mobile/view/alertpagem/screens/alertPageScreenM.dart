import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/alert.dart';
import '../../../../design_system/design_system.dart';
import '../alertpageblocm/alertPageBlocM.dart';
import '../alertpageblocm/alertPageEventM.dart';
import '../alertpageblocm/alertPageStateM.dart';
import 'alertDetailScreenM.dart';
import 'alertSettingsScreenM.dart';

/// Notifications (inbox) — restyle Airbnb.
/// Inbox notifications réelle (pas faux switches Actif/Inactif Figma).
class AlertPageScreenM extends StatefulWidget {
  const AlertPageScreenM({super.key});

  @override
  State<AlertPageScreenM> createState() => _AlertPageScreenMState();
}

class _AlertPageScreenMState extends State<AlertPageScreenM> {
  static const double _hPad = 20;

  /// null = toutes ; NON_LUE ; ARCHIVEE
  String? _filterStatut;

  @override
  void initState() {
    super.initState();
    context.read<AlertPageBlocM>().add(const LoadAlertsDataM(limit: 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      body: SafeArea(
        child: BlocConsumer<AlertPageBlocM, AlertPageStateM>(
          listener: (context, state) {
            if (state is AlertPageErrorM) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: SDColors.error500,
                ),
              );
            }
            if (state is AlertMarkedAsReadM ||
                state is AlertDeletedM ||
                state is AlertArchivedM ||
                state is AllAlertsMarkedAsReadM) {
              context
                  .read<AlertPageBlocM>()
                  .add(const LoadAlertsDataM(limit: 50));
            }
          },
          builder: (context, state) {
            final all = state is AlertPageLoadedM ? state.alerts : <Alert>[];
            final unread =
                all.where((a) => a.statut == 'NON_LUE').length;
            final archived =
                all.where((a) => a.statut == 'ARCHIVEE').length;
            final filtered = _applyFilter(all);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                _buildHeader(),
                _buildChips(
                  total: all.length,
                  unread: unread,
                  archived: archived,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: state is AlertPageLoadingM ||
                          state is AlertPageInitialM
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          color: SDColors.primary600,
                          onRefresh: () async {
                            context
                                .read<AlertPageBlocM>()
                                .add(const LoadAlertsDataM(limit: 50));
                          },
                          child: filtered.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.sizeOf(context).height *
                                              0.45,
                                      child: _emptyState(),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                      _hPad, 8, _hPad, 24),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, i) =>
                                      _buildAlertCard(filtered[i]),
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
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => AlertPageBlocM()
                      ..add(const LoadAlertPreferencesM()),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: SDTypography.displayMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Messages et alertes de l’app',
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips({
    required int total,
    required int unread,
    required int archived,
  }) {
    final chips = <({String? id, String label})>[
      (id: null, label: 'Toutes (${total - archived})'),
      (id: 'NON_LUE', label: 'Non lues ($unread)'),
      (id: 'ARCHIVEE', label: 'Archivées ($archived)'),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? SDColors.primary600 : SDColors.neutral100,
                borderRadius: BorderRadius.circular(12),
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

  Widget _buildAlertCard(Alert alert) {
    final iconData = _iconForType(alert.type);
    final tint = _tintForType(alert.type);
    final unread = alert.estNonLue;

    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (unread && alert.id != null) {
            context
                .read<AlertPageBlocM>()
                .add(MarkAsReadM(alertId: alert.id!));
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
            color: SDColors.white,
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: tint, size: 24),
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
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: SDColors.primary600,
                                shape: BoxShape.circle,
                              ),
                            ),
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
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        _typeLabel(alert.type),
                        style: SDTypography.labelMedium.copyWith(
                          color: SDColors.primary600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Créée le ${DateFormat('d MMM yyyy', 'fr_FR').format(alert.createdAt)}',
                        style: SDTypography.bodySmall.copyWith(
                          color: SDColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: SDColors.neutral500,
                  ),
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
              'Aucune alerte',
              style: SDTypography.titleMedium.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos notifications importantes apparaîtront ici.',
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

  String _typeLabel(String type) {
    switch (type) {
      case 'COMMANDE':
        return 'Commande';
      case 'PRESTATION':
        return 'Prestation';
      case 'PAIEMENT':
        return 'Paiement';
      case 'MESSAGE':
        return 'Message';
      case 'PROMOTION':
        return 'Promotion';
      case 'RAPPEL':
        return 'Rappel';
      case 'VERIFICATION':
        return 'Vérification';
      case 'SYSTEME':
        return 'Système';
      default:
        return type;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'COMMANDE':
        return Icons.shopping_bag_outlined;
      case 'PRESTATION':
        return Icons.handyman_outlined;
      case 'PAIEMENT':
        return Icons.payments_outlined;
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
      case 'COMMANDE':
        return SDColors.primary600;
      case 'PRESTATION':
        return SDColors.info600;
      case 'PAIEMENT':
        return SDColors.warning600;
      case 'MESSAGE':
        return SDColors.info500;
      case 'PROMOTION':
        return SDColors.error500;
      default:
        return SDColors.neutral600;
    }
  }
}
