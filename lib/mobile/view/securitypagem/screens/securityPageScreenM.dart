import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/api_client.dart';
import '../securitypageblocm/securityPageBlocM.dart';
import '../securitypageblocm/securityPageEventM.dart';
import '../securitypageblocm/securityPageStateM.dart';
import 'twoFactorSetupScreenM.dart';
import 'securitySettingsScreenM.dart';

// ✅ Design System
import '../../../../design_system/design_system.dart';

class SecurityPageScreenM extends StatefulWidget {
  const SecurityPageScreenM({Key? key}) : super(key: key);

  @override
  State<SecurityPageScreenM> createState() => _SecurityPageScreenMState();
}

class _SecurityPageScreenMState extends State<SecurityPageScreenM>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Charger les données de sécurité au démarrage
    context.read<SecurityPageBlocM>().add(LoadSecurityDataEventM());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SecurityPageBlocM(
        apiClient: ApiClient(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Sécurité du compte',
            style: SDTypography.titleLarge.copyWith(color: SDColors.white),
          ),
          backgroundColor: SDColors.primary600,
          foregroundColor: SDColors.white,
          leading: const BackButton(color: SDColors.white),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: SDColors.white,
            labelColor: SDColors.white,
            unselectedLabelColor: SDColors.white.withOpacity(0.7),
            labelStyle: SDTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: SDTypography.labelMedium,
            tabs: const [
              Tab(icon: Icon(Icons.security), text: 'Général'),
              Tab(icon: Icon(Icons.phone_android), text: 'Sessions'),
              Tab(icon: Icon(Icons.notifications), text: 'Alertes'),
              Tab(icon: Icon(Icons.settings), text: 'Paramètres'),
            ],
          ),
        ),
        body: BlocConsumer<SecurityPageBlocM, SecurityPageStateM>(
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
            }
          },
          builder: (context, state) {
            if (state is SecurityPageLoadingStateM) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(state),
                _buildSessionsTab(state),
                _buildAlertsTab(state),
                _buildSettingsTab(state),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.read<SecurityPageBlocM>().add(RefreshSecurityDataEventM());
          },
          backgroundColor: Colors.teal,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }

  // 🔐 ONGLET GÉNÉRAL
  Widget _buildGeneralTab(SecurityPageStateM state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SDSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de sécurité générale
          Card(
            color: SDColors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
            child: Padding(
              padding: EdgeInsets.all(SDSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: SDColors.primary600),
                      SizedBox(width: SDSpacing.xs),
                      Text(
                        'Sécurité générale',
                        style: SDTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SDSpacing.md),
                  if (state is SecurityPageLoadedStateM) ...[
                    _buildSecurityItem(
                      'Authentification à deux facteurs',
                      state.twoFactorEnabled ? 'Activée' : 'Désactivée',
                      state.twoFactorEnabled ? SDColors.success500 : SDColors.warning500,
                      Icons.phone_android,
                    ),
                    _buildSecurityItem(
                      'Sessions actives',
                      '${state.sessions.length}',
                      SDColors.info500,
                      Icons.devices,
                    ),
                    _buildSecurityItem(
                      'Alertes non lues',
                      '${state.alerts.where((a) => !a.isRead).length}',
                      SDColors.error500,
                      Icons.notifications,
                    ),
                    _buildSecurityItem(
                      'Appareils de confiance',
                      '${state.trustedDevices.length}',
                      SDColors.secondary500,
                      Icons.verified_user,
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: SDSpacing.md),

          // Actions rapides
          Card(
            color: SDColors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
            child: Padding(
              padding: EdgeInsets.all(SDSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Actions rapides',
                    style: SDTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: SDSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TwoFactorSetupScreenM(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.phone_android),
                          label: const Text('2FA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SDColors.primary600,
                            foregroundColor: SDColors.white,
                            padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                          ),
                        ),
                      ),
                      SizedBox(width: SDSpacing.xs),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SecuritySettingsScreenM(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('Paramètres'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SDColors.info600,
                            foregroundColor: SDColors.white,
                            padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📱 ONGLET SESSIONS
  Widget _buildSessionsTab(SecurityPageStateM state) {
    return Column(
      children: [
        // Barre d'actions
        Padding(
          padding: EdgeInsets.all(SDSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<SecurityPageBlocM>().add(LoadSessionsEventM());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
                    backgroundColor: SDColors.primary600,
                    foregroundColor: SDColors.white,
                  ),
                ),
              ),
              SizedBox(width: SDSpacing.sm),
              ElevatedButton.icon(
                onPressed: () {
                  _showTerminateAllDialog();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Tout fermer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SDColors.error600,
                  foregroundColor: SDColors.white,
                  padding: EdgeInsets.symmetric(vertical: SDSpacing.sm, horizontal: SDSpacing.md),
                ),
              ),
            ],
          ),
        ),

        // Liste des sessions
        Expanded(
          child: _buildSessionsList(state),
        ),
      ],
    );
  }

  // 🚨 ONGLET ALERTES
  Widget _buildAlertsTab(SecurityPageStateM state) {
    return Column(
      children: [
        // Barre de recherche et filtres
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher des alertes...',
                  hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
                  prefixIcon: const Icon(Icons.search, color: SDColors.neutral500),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: SDColors.neutral500),
                    onPressed: () {
                      _searchController.clear();
                      context
                          .read<SecurityPageBlocM>()
                          .add(LoadSecurityAlertsEventM());
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    borderSide: BorderSide(color: SDColors.neutral300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    borderSide: BorderSide(color: SDColors.neutral300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    borderSide: BorderSide(color: SDColors.primary600),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    context.read<SecurityPageBlocM>().add(
                          SearchSecurityAlertsEventM(query: value),
                        );
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFilter,
                      decoration: InputDecoration(
                        labelText: 'Filtrer par',
                        labelStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                          borderSide: BorderSide(color: SDColors.neutral300),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.sm),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Toutes')),
                        DropdownMenuItem(value: 'high', child: Text('Élevée')),
                        DropdownMenuItem(
                            value: 'medium', child: Text('Moyenne')),
                        DropdownMenuItem(value: 'low', child: Text('Faible')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value!;
                        });
                        if (value != 'all') {
                          context.read<SecurityPageBlocM>().add(
                                FilterSecurityAlertsEventM(severity: value!),
                              );
                        } else {
                          context
                              .read<SecurityPageBlocM>()
                              .add(LoadSecurityAlertsEventM());
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      context
                          .read<SecurityPageBlocM>()
                          .add(MarkAllAlertsAsReadEventM());
                    },
                    icon: const Icon(Icons.mark_email_read),
                    tooltip: 'Marquer tout comme lu',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Liste des alertes
        Expanded(
          child: _buildAlertsList(state),
        ),
      ],
    );
  }

  // ⚙️ ONGLET PARAMÈTRES
  Widget _buildSettingsTab(SecurityPageStateM state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SDSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: SDColors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
            child: Padding(
              padding: EdgeInsets.all(SDSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paramètres de sécurité',
                    style: SDTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: SDSpacing.md),
                  if (state is SecurityPageLoadedStateM) ...[
                    _buildSettingItem(
                      'Notifications de connexion',
                      state.settings.loginNotifications,
                      (value) {
                        context.read<SecurityPageBlocM>().add(
                              UpdateSecuritySettingsEventM(
                                settings: {'loginNotifications': value},
                              ),
                            );
                      },
                    ),
                    _buildSettingItem(
                      'Authentification à deux facteurs requise',
                      state.settings.twoFactorRequired,
                      (value) {
                        context.read<SecurityPageBlocM>().add(
                              UpdateSecuritySettingsEventM(
                                settings: {'twoFactorRequired': value},
                              ),
                            );
                      },
                    ),
                    _buildSettingItem(
                      'Délai d\'expiration de session',
                      state.settings.sessionTimeout,
                      (value) {
                        context.read<SecurityPageBlocM>().add(
                              UpdateSecuritySettingsEventM(
                                settings: {'sessionTimeout': value},
                              ),
                            );
                      },
                    ),
                    _buildSettingItem(
                      'Sessions multiples autorisées',
                      state.settings.allowMultipleSessions,
                      (value) {
                        context.read<SecurityPageBlocM>().add(
                              UpdateSecuritySettingsEventM(
                                settings: {'allowMultipleSessions': value},
                              ),
                            );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 MÉTHODES UTILITAIRES
  Widget _buildSecurityItem(
      String title, String value, Color color, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SDSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: SDSpacing.sm),
          Expanded(
            child: Text(title, style: SDTypography.bodyMedium),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: SDSpacing.sm, vertical: SDSpacing.xxs),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
            ),
            child: Text(
              value,
              style: SDTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: SDTypography.bodyMedium),
      value: value,
      onChanged: onChanged,
      activeColor: SDColors.primary600,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSessionsList(SecurityPageStateM state) {
    if (state is SecurityPageLoadedStateM) {
      final sessions = state.sessions;

      if (sessions.isEmpty) {
        return const Center(
          child: Text('Aucune session active'),
        );
      }

      return ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: SDSpacing.md, vertical: SDSpacing.xxs),
            color: SDColors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium)),
            child: ListTile(
              leading: Icon(
                _getDeviceIcon(session.deviceType),
                color: session.isActive ? SDColors.success500 : SDColors.neutral400,
              ),
              title: Text(session.deviceName, style: SDTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${session.deviceType} • ${session.location}', style: SDTypography.bodySmall),
                  Text('IP: ${session.ipAddress}', style: SDTypography.bodySmall),
                  if (session.lastActivity != null)
                    Text(
                        'Dernière activité: ${_formatDate(session.lastActivity!)}',
                        style: SDTypography.bodySmall,
                    ),
                ],
              ),
              trailing: session.isActive
                  ? IconButton(
                      icon: const Icon(Icons.logout, color: SDColors.error500),
                      onPressed: () {
                        context.read<SecurityPageBlocM>().add(
                              TerminateSessionEventM(sessionId: session.id!),
                            );
                      },
                    )
                  : const Icon(Icons.check_circle, color: SDColors.neutral400),
            ),
          );
        },
      );
    }

    return const Center(
      child: Text('Chargement des sessions...'),
    );
  }

  Widget _buildAlertsList(SecurityPageStateM state) {
    if (state is SecurityAlertsLoadedStateM) {
      final alerts = state.alerts;

      if (alerts.isEmpty) {
        return const Center(
          child: Text('Aucune alerte de sécurité'),
        );
      }

      return ListView.builder(
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(
                _getAlertIcon(alert.severity),
                color: _getAlertColor(alert.severity),
              ),
              title: Text(alert.title),
              subtitle: Text(alert.message),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!alert.isRead)
                    const Icon(Icons.circle, color: Colors.red, size: 12),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      context.read<SecurityPageBlocM>().add(
                            DeleteAlertEventM(alertId: alert.id!),
                          );
                    },
                  ),
                ],
              ),
              onTap: () {
                if (!alert.isRead) {
                  context.read<SecurityPageBlocM>().add(
                        MarkAlertAsReadEventM(alertId: alert.id!),
                      );
                }
              },
            ),
          );
        },
      );
    }

    return const Center(
      child: Text('Chargement des alertes...'),
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet;
      case 'desktop':
        return Icons.computer;
      case 'laptop':
        return Icons.laptop;
      default:
        return Icons.device_unknown;
    }
  }

  IconData _getAlertIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return SDColors.error500;
      case 'medium':
        return SDColors.warning500;
      case 'low':
        return SDColors.success500;
      default:
        return SDColors.info500;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showTerminateAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer toutes les sessions'),
        content: const Text(
          'Êtes-vous sûr de vouloir terminer toutes les autres sessions ? '
          'Vous devrez vous reconnecter sur tous vos autres appareils.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<SecurityPageBlocM>()
                  .add(TerminateAllOtherSessionsEventM());
            },
            style: ElevatedButton.styleFrom(backgroundColor: SDColors.error600),
            child:
                Text('Terminer', style: SDTypography.labelLarge.copyWith(color: SDColors.white)),
          ),
        ],
      ),
    );
  }
}
