import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/security.dart';
import '../securitypageblocm/securityPageBlocM.dart';
import '../securitypageblocm/securityPageEventM.dart';
import '../securitypageblocm/securityPageStateM.dart';
import 'twoFactorSetupScreenM.dart';
import 'securitySettingsScreenM.dart';
import '../../../../design_system/design_system.dart';

/// Sécurité — maquette Figma. Pas de PIN / biométrie (absents backend).
class SecurityPageScreenM extends StatefulWidget {
  const SecurityPageScreenM({Key? key}) : super(key: key);

  @override
  State<SecurityPageScreenM> createState() => _SecurityPageScreenMState();
}

class _SecurityPageScreenMState extends State<SecurityPageScreenM> {
  static const double _hPad = 20;

  @override
  void initState() {
    super.initState();
    context.read<SecurityPageBlocM>().add(LoadSecurityDataEventM());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SDColors.neutral50,
      body: SafeArea(
        child: BlocConsumer<SecurityPageBlocM, SecurityPageStateM>(
          listener: (context, state) {
            if (state is SecurityPageErrorStateM) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: SDColors.error500,
                ),
              );
            } else if (state is SecurityPageSuccessStateM) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: SDColors.success500,
                ),
              );
            } else if (state is SessionTerminatedStateM) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: SDColors.success500,
                ),
              );
              context.read<SecurityPageBlocM>().add(LoadSecurityDataEventM());
            } else if (state is LoginHistoryClearedStateM) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: SDColors.success500,
                ),
              );
            } else if (state is SecuritySettingsUpdatedStateM) {
              context.read<SecurityPageBlocM>().add(LoadSecurityDataEventM());
            }
          },
          builder: (context, state) {
            final loaded =
                state is SecurityPageLoadedStateM ? state : null;

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, _hPad, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: SDColors.neutral900,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 16),
                  child: Text(
                    'Sécurité',
                    style: SDTypography.displayMedium.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (state is SecurityPageLoadingStateM && loaded == null)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: SDColors.primary600,
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _hPad),
                    child: _settingsCard(loaded),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 12),
                    child: Text(
                      'Appareils récents',
                      style: SDTypography.titleMedium.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (loaded == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _hPad),
                      child: Text(
                        'Impossible de charger les sessions.',
                        style: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral500),
                      ),
                    )
                  else if (loaded.sessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _hPad),
                      child: Text(
                        'Aucune session active',
                        style: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral500),
                      ),
                    )
                  else
                    ..._buildSessionCards(loaded.sessions),
                  if (loaded != null && loaded.sessions.length > 1) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _hPad),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final sorted = [...loaded.sessions]..sort((a, b) {
                                final aT = a.lastActivity ?? a.createdAt;
                                final bT = b.lastActivity ?? b.createdAt;
                                return bT.compareTo(aT);
                              });
                          final currentId = sorted.isNotEmpty ? sorted.first.id : null;
                          context.read<SecurityPageBlocM>().add(
                                TerminateAllOtherSessionsEventM(
                                  keepSessionId: currentId,
                                ),
                              );
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Déconnecter les autres appareils'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SDColors.error500,
                          side: BorderSide(color: SDColors.error500.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _settingsCard(SecurityPageLoadedStateM? loaded) {
    return Container(
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        children: [
          _navTile(
            icon: Icons.lock_outline,
            title: 'Mot de passe',
            trailing: Text(
              '********',
              style: SDTypography.bodyMedium.copyWith(
                color: SDColors.neutral500,
              ),
            ),
            onTap: () => _openWithBloc(const SecuritySettingsScreenM()),
          ),
          _divider(),
          _navTile(
            icon: Icons.security_outlined,
            title: 'Authentification à deux facteurs',
            trailing: Switch(
              value: loaded?.twoFactorEnabled ?? false,
              onChanged: (_) =>
                  _openWithBloc(const TwoFactorSetupScreenM()),
              activeThumbColor: SDColors.white,
              activeTrackColor: SDColors.primary600,
              inactiveThumbColor: SDColors.white,
              inactiveTrackColor: SDColors.neutral300,
            ),
            showChevron: false,
            onTap: () => _openWithBloc(const TwoFactorSetupScreenM()),
          ),
          _divider(),
          if (loaded != null) ...[
            _navTile(
              icon: Icons.notifications_none_outlined,
              title: 'Alertes de connexion',
              trailing: Switch(
                value: loaded.settings.loginNotifications,
                onChanged: (v) {
                  context.read<SecurityPageBlocM>().add(
                        UpdateSecuritySettingsEventM(
                          settings: {'loginNotifications': v},
                        ),
                      );
                },
                activeThumbColor: SDColors.white,
                activeTrackColor: SDColors.primary600,
                inactiveThumbColor: SDColors.white,
                inactiveTrackColor: SDColors.neutral300,
              ),
              showChevron: false,
              onTap: null,
            ),
            _divider(),
          ],
          _navTile(
            icon: Icons.history,
            title: 'Historique des connexions',
            onTap: () => _openWithBloc(const _HistorySubScreen()),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSessionCards(List<SecuritySession> sessions) {
    final sorted = [...sessions]..sort((a, b) {
        final aT = a.lastActivity ?? a.createdAt;
        final bT = b.lastActivity ?? b.createdAt;
        return bT.compareTo(aT);
      });
    final currentId = sorted.isNotEmpty ? sorted.first.id : null;

    return [
      for (final session in sorted)
        Padding(
          padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 10),
          child: _sessionCard(
            session: session,
            isCurrent: session.id != null && session.id == currentId,
          ),
        ),
    ];
  }

  Widget _sessionCard({
    required SecuritySession session,
    required bool isCurrent,
  }) {
    final when = _formatActivity(session.lastActivity ?? session.createdAt);
    final loc = session.location.trim().isEmpty
        ? 'Localisation inconnue'
        : session.location;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _deviceIcon(session.deviceType),
            color: SDColors.neutral700,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: session.isActive
                            ? SDColors.primary600
                            : SDColors.neutral400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        session.deviceName,
                        style: SDTypography.bodyLarge.copyWith(
                          color: SDColors.neutral900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: SDColors.primary600.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Appareil actuel',
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.primary700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$loc · $when',
                  style: SDTypography.bodySmall.copyWith(
                    color: SDColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent && session.id != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: SDColors.neutral500),
              onSelected: (value) {
                if (value == 'disconnect') {
                  context.read<SecurityPageBlocM>().add(
                        TerminateSessionEventM(sessionId: session.id!),
                      );
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'disconnect',
                  child: Text(
                    'Déconnecter',
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.error500,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: SDColors.neutral800, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: SDTypography.bodyLarge.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (showChevron) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: SDColors.neutral400,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: SDColors.neutral200, indent: 48);

  void _openWithBloc(Widget child) {
    final bloc = context.read<SecurityPageBlocM>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: child,
        ),
      ),
    );
  }

  static IconData _deviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
      case 'phone':
      case 'android':
      case 'ios':
        return Icons.smartphone_outlined;
      case 'tablet':
        return Icons.tablet_outlined;
      case 'desktop':
      case 'web':
        return Icons.laptop_outlined;
      case 'laptop':
        return Icons.laptop_outlined;
      default:
        return Icons.devices_outlined;
    }
  }

  static String _formatActivity(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 5) return 'Maintenant';
    if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays == 1) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Hier à $h:$m';
    }
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

// ─── Historique des connexions (API existante) ─────────────────────

class _HistorySubScreen extends StatefulWidget {
  const _HistorySubScreen();

  @override
  State<_HistorySubScreen> createState() => _HistorySubScreenState();
}

class _HistorySubScreenState extends State<_HistorySubScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SecurityPageBlocM>().add(LoadLoginHistoryEventM());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          context.read<SecurityPageBlocM>().add(LoadSecurityDataEventM());
        }
      },
      child: Scaffold(
      backgroundColor: SDColors.neutral50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Historique des connexions',
                      style: SDTypography.displaySmall.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          title: const Text('Effacer l\'historique ?'),
                          content: const Text(
                            'Tous les enregistrements d\'historique de connexion seront supprimés.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogCtx);
                                context
                                    .read<SecurityPageBlocM>()
                                    .add(ClearLoginHistoryEventM());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SDColors.error500,
                              ),
                              child: const Text(
                                'Effacer',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      'Effacer',
                      style: SDTypography.labelLarge.copyWith(
                        color: SDColors.error500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<SecurityPageBlocM, SecurityPageStateM>(
                builder: (context, state) {
                  if (state is LoginHistoryClearedStateM) {
                    return Center(
                      child: Text(
                        'Aucun historique',
                        style: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral500),
                      ),
                    );
                  }
                  if (state is! LoginHistoryLoadedStateM) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: SDColors.primary600,
                      ),
                    );
                  }
                  final history = state.loginHistory;
                  if (history.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucun historique',
                        style: SDTypography.bodyMedium
                            .copyWith(color: SDColors.neutral500),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final when = _SecurityPageScreenMState._formatActivity(
                        item.lastActivity ?? item.createdAt,
                      );
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: SDColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SDColors.neutral200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _SecurityPageScreenMState._deviceIcon(
                                item.deviceType,
                              ),
                              color: SDColors.neutral700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.deviceName,
                                    style: SDTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: SDColors.neutral900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.location.isEmpty ? '—' : item.location} · $when',
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
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
