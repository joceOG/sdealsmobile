import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../design_system/design_system.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../../../../data/services/authCubit.dart';
import '../utils/provider_notification_destination.dart';

/// Liste des notifications prestataire (maquette : Toutes / Non lues, cartes groupées).
class ProviderNotificationsScreen extends StatefulWidget {
  const ProviderNotificationsScreen({
    super.key,
    this.prestataireDocId,
    this.onOpenMissions,
    this.onOpenMessages,
  });

  final String? prestataireDocId;

  /// Ouvre l’onglet Mes missions (ex. détail indisponible).
  final VoidCallback? onOpenMissions;

  /// Ouvre l’onglet Messages (conversation sans route directe).
  final VoidCallback? onOpenMessages;

  @override
  State<ProviderNotificationsScreen> createState() =>
      _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState extends State<ProviderNotificationsScreen> {
  String? _userId;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _userId = authState.utilisateur.idutilisateur;
      context.read<NotificationsBloc>().setToken(authState.token);
      context
          .read<NotificationsBloc>()
          .add(LoadPrestataireNotifications(_userId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.white,
      appBar: SDWhiteAppBar.appBar(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Notifications',
              style: SDTypography.titleLarge.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Votre activité professionnelle',
              style: SDTypography.caption.copyWith(color: SDColors.neutral500),
            ),
          ],
        ),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              final unread =
                  state is NotificationsLoaded ? state.totalUnread : 0;
              if (unread <= 0 || _userId == null) {
                return const SizedBox(width: 8);
              }
              return TextButton(
                onPressed: _markAllAsRead,
                child: Text(
                  'Tout marquer comme lu',
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.primary600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: _buildFilterChips(state),
              ),
              Expanded(child: _buildBody(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(NotificationsState state) {
    final unread =
        state is NotificationsLoaded ? state.totalUnread : 0;

    return Row(
      children: [
        _filterChip(
          label: 'Toutes',
          selected: !_showUnreadOnly,
          badge: null,
          onTap: () {
            if (_showUnreadOnly) {
              setState(() => _showUnreadOnly = false);
              _reloadAll();
            }
          },
        ),
        const SizedBox(width: 10),
        _filterChip(
          label: 'Non lues',
          selected: _showUnreadOnly,
          badge: unread > 0 ? unread : null,
          onTap: () {
            if (!_showUnreadOnly) {
              setState(() => _showUnreadOnly = true);
              _reloadUnread();
            }
          },
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required int? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? SDColors.primary700 : SDColors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? SDColors.primary700 : SDColors.primary600,
              width: 1.5,
            ),
            color: selected ? SDColors.primary700 : SDColors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: SDTypography.labelLarge.copyWith(
                  color: selected ? SDColors.white : SDColors.primary700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? SDColors.white : SDColors.primary700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badge',
                    style: SDTypography.labelSmall.copyWith(
                      color:
                          selected ? SDColors.primary700 : SDColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state is NotificationsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is NotificationsError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: SDColors.error500),
              const SizedBox(height: 12),
              Text(state.message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _showUnreadOnly ? _reloadUnread : _reloadAll,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (state is! NotificationsLoaded) {
      return const SizedBox.shrink();
    }

    var items = state.notifications.cast<Map<String, dynamic>>();
    if (_showUnreadOnly) {
      items = items.where((n) => n['statut'] == 'NON_LUE').toList();
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    final today = <Map<String, dynamic>>[];
    final older = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (final n in items) {
      final date = _parseDate(n['createdAt']);
      if (date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        today.add(n);
      } else {
        older.add(n);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (today.isNotEmpty) ...[
          _sectionTitle('Aujourd’hui'),
          ...today.map(_buildNotificationCard),
        ],
        if (older.isNotEmpty) ...[
          const SizedBox(height: 8),
          _sectionTitle('Plus anciennes'),
          ...older.map(_buildNotificationCard),
        ],
      ],
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        label,
        style: SDTypography.titleSmall.copyWith(
          color: SDColors.neutral700,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isUnread = notification['statut'] == 'NON_LUE';
    final titre = '${notification['titre'] ?? 'Notification'}';
    final message = '${notification['message'] ?? ''}';
    final destination = resolveProviderNotificationDestination(notification);
    final type = '${notification['type'] ?? 'SYSTEME'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? SDColors.primary50 : SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _iconWell(type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              titre,
                              style: SDTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isUnread
                                    ? SDColors.neutral900
                                    : SDColors.neutral800,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: SDColors.primary600,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          message,
                          style: SDTypography.bodyMedium.copyWith(
                            color: SDColors.neutral600,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (destination.detailUnavailable) ...[
                        const SizedBox(height: 10),
                        _unavailableBadge(),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _formatNotificationTime(notification['createdAt']),
                        style: SDTypography.caption
                            .copyWith(color: SDColors.neutral500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (destination.hasFooterAction)
            InkWell(
              onTap: () => _onNotificationAction(notification, destination),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: SDColors.neutral200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        destination.actionLabel!,
                        style: SDTypography.labelLarge.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: SDColors.primary700,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconWell(String type) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Icon(
        _iconForType(type),
        color: SDColors.primary700,
        size: 22,
      ),
    );
  }

  Widget _unavailableBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SDColors.neutral300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 14, color: SDColors.neutral600),
          const SizedBox(width: 6),
          Text(
            'Détail indisponible',
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.neutral700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showUnreadOnly
                  ? Icons.mark_email_read_outlined
                  : Icons.notifications_none_outlined,
              size: 56,
              color: SDColors.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              _showUnreadOnly
                  ? 'Aucune notification non lue'
                  : 'Aucune notification',
              style: SDTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre activité apparaîtra ici.',
              textAlign: TextAlign.center,
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reloadAll() {
    if (_userId == null) return;
    context
        .read<NotificationsBloc>()
        .add(LoadPrestataireNotifications(_userId!));
  }

  void _reloadUnread() {
    if (_userId == null) return;
    context.read<NotificationsBloc>().add(LoadUnreadNotifications(_userId!));
  }

  void _markAsReadIfNeeded(Map<String, dynamic> notification) {
    final notificationId = notification['_id']?.toString();
    if (notificationId == null || _userId == null) return;
    if (notification['statut'] == 'NON_LUE') {
      context.read<NotificationsBloc>().add(
            MarkNotificationAsRead(notificationId, _userId!),
          );
    }
  }

  void _onNotificationAction(
    Map<String, dynamic> notification,
    ProviderNotificationDestination destination,
  ) {
    _markAsReadIfNeeded(notification);

    if (destination.detailUnavailable &&
        destination.kind == ProviderNotificationNavKind.none) {
      return;
    }

    switch (destination.kind) {
      case ProviderNotificationNavKind.mission:
        final id = destination.missionId;
        if (id == null) return;
        context.push(
          '/mission-details/$id',
          extra: widget.prestataireDocId == null
              ? null
              : {'prestataireDocId': widget.prestataireDocId},
        );
        break;
      case ProviderNotificationNavKind.conversation:
        final convId = destination.conversationId;
        if (convId != null && convId.isNotEmpty) {
          context.push('/chat/$convId');
        } else {
          widget.onOpenMessages?.call();
          if (context.mounted) Navigator.pop(context);
        }
        break;
      case ProviderNotificationNavKind.missionsList:
        Navigator.pop(context);
        widget.onOpenMissions?.call();
        break;
      case ProviderNotificationNavKind.none:
        break;
    }
  }

  void _markAllAsRead() {
    if (_userId == null) return;
    context
        .read<NotificationsBloc>()
        .add(MarkAllNotificationsAsRead(_userId!));
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  String _formatNotificationTime(dynamic createdAt) {
    final date = _parseDate(createdAt);
    if (date == null) return '';

    final now = DateTime.now();
    final local = date.toLocal();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    if (sameDay) {
      final diff = now.difference(local);
      if (diff.inMinutes < 1) return 'À l’instant';
      if (diff.inHours < 1) {
        return 'Il y a ${diff.inMinutes} min';
      }
      return DateFormat('HH:mm').format(local);
    }

    return DateFormat('d MMMM', 'fr_FR').format(local);
  }

  IconData _iconForType(String type) {
    final t = type.toUpperCase();
    if (t.contains('MESSAGE')) return Icons.chat_bubble_outline;
    if (t.contains('PAIEMENT')) return Icons.payments_outlined;
    if (t.contains('PRESTATION') || t.contains('MISSION')) {
      return Icons.work_outline;
    }
    if (t.contains('RAPPEL') || t.contains('PLAN')) {
      return Icons.event_outlined;
    }
    return Icons.notifications_none_outlined;
  }
}
