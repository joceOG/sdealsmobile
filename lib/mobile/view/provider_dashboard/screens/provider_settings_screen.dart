import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sdealsmobile/data/utils/legal_urls.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../design_system/design_system.dart';
import '../../profilpagem/screens/about_screen.dart';
import '../../profilpagem/screens/help_support_screen.dart';
import '../../common/role_shell_navigation.dart';
import '../bloc/provider_profile_bloc.dart';
import '../bloc/provider_profile_event.dart';
import '../bloc/provider_profile_state.dart';
import 'provider_profile_screen.dart';

// ⚙️ ÉCRAN PARAMÈTRES PRESTATAIRE
class ProviderSettingsScreen extends StatefulWidget {
  final String? prestataireDocId;

  const ProviderSettingsScreen({super.key, this.prestataireDocId});

  @override
  State<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends State<ProviderSettingsScreen> {
  final ApiClient _apiClient = ApiClient();

  final Map<String, bool> _notifTypes = {
    'newMissions': true,
    'messages': true,
    'payments': true,
    'reviews': true,
    'promotions': false,
    'system': true,
  };
  bool _notifLoading = true;
  bool _notifSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotificationPrefs();
    });
  }

  Future<void> _loadNotificationPrefs() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      if (mounted) setState(() => _notifLoading = false);
      return;
    }
    final userId = auth.utilisateur.idutilisateur;
    if (userId.isEmpty) {
      if (mounted) setState(() => _notifLoading = false);
      return;
    }
    try {
      final response = await _apiClient.get(
        '/preferences/user/$userId',
        token: auth.token,
      );
      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response);
        Map<String, dynamic>? types;
        if (data is Map) {
          final prefs = data['preferences'] is Map
              ? data['preferences'] as Map
              : data;
          final notifs = prefs['notifications'];
          if (notifs is Map && notifs['types'] is Map) {
            types = Map<String, dynamic>.from(notifs['types'] as Map);
          }
        }
        if (types != null && mounted) {
          setState(() {
            for (final key in _notifTypes.keys) {
              if (types!.containsKey(key)) {
                _notifTypes[key] = types[key] != false;
              }
            }
          });
        }
      }
    } catch (_) {
      // Garder les défauts
    } finally {
      if (mounted) setState(() => _notifLoading = false);
    }
  }

  Future<void> _toggleNotification(String typeKey, bool value) async {
    final previous = Map<String, bool>.from(_notifTypes);
    setState(() {
      _notifTypes[typeKey] = value;
      _notifSaving = true;
    });

    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      setState(() {
        _notifTypes.addAll(previous);
        _notifSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expirée — reconnectez-vous')),
      );
      return;
    }
    final userId = auth.utilisateur.idutilisateur;
    if (userId.isEmpty) {
      setState(() {
        _notifTypes.addAll(previous);
        _notifSaving = false;
      });
      return;
    }

    try {
      final response = await _apiClient.put(
        '/preferences/user/$userId',
        body: {
          'notifications': {
            'types': Map<String, bool>.from(_notifTypes),
          },
        },
        token: auth.token,
      );
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() => _notifTypes.addAll(previous));
        String message = 'Impossible de sauvegarder la préférence';
        try {
          final data = ApiClient.decodeJson(response);
          if (data is Map &&
              (data['error'] != null || data['message'] != null)) {
            message = (data['error'] ?? data['message']).toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _notifTypes.addAll(previous));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _notifSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildSettingsAppBar(),
      body: BlocListener<ProviderProfileBloc, ProviderProfileState>(
        listener: (context, state) {
          if (state is PasswordChanged) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mot de passe changé avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is AccountDeactivated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.reason),
                backgroundColor: Colors.orange.shade700,
              ),
            );
            context.read<AuthCubit>().switchActiveRole('CLIENT');
            if (context.canPop()) {
              context.pop();
            }
          } else if (state is AccountDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.reason),
                backgroundColor: Colors.red.shade700,
              ),
            );
            context.read<AuthCubit>().logout();
            context.go('/login');
          } else if (state is ProviderProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        child: BlocBuilder<ProviderProfileBloc, ProviderProfileState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Votre espace professionnel',
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMonEspaceSection(),
                  const SizedBox(height: 16),
                  _buildPhoneNotificationsSection(),
                  const SizedBox(height: 16),
                  _buildNotificationPrefsSection(),
                  const SizedBox(height: 16),
                  _buildHelpSection(),
                  const SizedBox(height: 16),
                  _buildUnavailableOptionsSection(),
                  const SizedBox(height: 16),
                  _buildPrivacySection(),
                  const SizedBox(height: 16),
                  _buildSecuritySection(),
                  const SizedBox(height: 16),
                  _buildDangerZone(),
                  const SizedBox(height: 24),
                  _buildLogoutButton(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSettingsAppBar() {
    return SDWhiteAppBar.appBar(
      title: 'Paramètres',
      titleStyle: SDTypography.titleLarge,
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: SDTypography.labelLarge.copyWith(
                color: SDColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _iconWell(IconData icon, {bool disabled = false}) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: disabled ? SDColors.neutral100 : SDColors.primary50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 22,
        color: disabled ? SDColors.neutral500 : SDColors.primary700,
      ),
    );
  }

  Widget _navRow({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _iconWell(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SDTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SDColors.neutral900,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: SDTypography.caption
                          .copyWith(color: SDColors.neutral500),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right,
                        color: SDColors.neutral400, size: 22)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _unavailableBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral300),
      ),
      child: Text(
        'Indisponible',
        style: SDTypography.labelSmall.copyWith(
          color: SDColors.neutral600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMonEspaceSection() {
    return _sectionCard(
      title: 'Mon espace',
      children: [
        _navRow(
          icon: Icons.person_outline,
          title: 'Mon profil professionnel',
          subtitle: 'Présentation, service et zone',
          onTap: _openProfessionalProfile,
        ),
        Divider(height: 1, color: SDColors.neutral200),
        _navRow(
          icon: Icons.home_work_outlined,
          title: 'Retour à l’espace client',
          subtitle: 'Conserver ma connexion',
          onTap: _switchToClientMode,
        ),
      ],
    );
  }

  Widget _buildPhoneNotificationsSection() {
    return _sectionCard(
      title: 'Notifications',
      children: [
        _navRow(
          icon: Icons.notifications_none_outlined,
          title: 'Notifications de l’application',
          subtitle: 'Gérer les autorisations du téléphone',
          trailing: const Icon(Icons.open_in_new,
              color: SDColors.primary700, size: 20),
          onTap: _openAppNotificationSettings,
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return _sectionCard(
      title: 'Aide et informations',
      children: [
        _navRow(
          icon: Icons.help_outline,
          title: 'Aide et support',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            );
          },
        ),
        Divider(height: 1, color: SDColors.neutral200),
        _navRow(
          icon: Icons.info_outline,
          title: 'À propos de Soutrali Deals',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUnavailableOptionsSection() {
    return _sectionCard(
      title: 'Options indisponibles',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Ces réglages ne sont pas encore modifiables.',
            style: SDTypography.caption.copyWith(color: SDColors.neutral500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _iconWell(Icons.language, disabled: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Langue',
                      style: SDTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SDColors.neutral700,
                      ),
                    ),
                    Text(
                      'Français',
                      style: SDTypography.caption
                          .copyWith(color: SDColors.neutral500),
                    ),
                  ],
                ),
              ),
              _unavailableBadge(),
            ],
          ),
        ),
        Divider(height: 1, color: SDColors.neutral200),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _iconWell(Icons.privacy_tip_outlined, disabled: true),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Préférences de confidentialité',
                  style: SDTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: SDColors.neutral700,
                  ),
                ),
              ),
              _unavailableBadge(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _confirmLogout,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.logout, color: SDColors.error600, size: 22),
            const SizedBox(width: 10),
            Text(
              'Se déconnecter',
              style: SDTypography.bodyLarge.copyWith(
                color: SDColors.error600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // go (pas pop + push) : remplace toute la pile pro par le shell client.
  void _switchToClientMode() {
    goToClientShell(context);
  }

  Future<void> _openAppNotificationSettings() async {
    final opened = await openAppSettings();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d’ouvrir les réglages du téléphone. '
            'Ouvrez-les manuellement pour les notifications.',
          ),
        ),
      );
    }
  }

  void _openProfessionalProfile() {
    final auth = context.read<AuthCubit>().state;
    final token = auth is AuthAuthenticated ? auth.token : null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider<ProviderProfileBloc>(
          create: (context) {
            final bloc = ProviderProfileBloc();
            if (token != null) bloc.setToken(token);
            return bloc;
          },
          child: ProviderProfileScreen(prestataireDocId: widget.prestataireDocId),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthCubit>().logout();
              context.go('/login');
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPrefsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: SDColors.primary700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Préférences de notification',
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SDColors.neutral800,
                ),
              ),
              if (_notifLoading || _notifSaving) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildSwitchItem(
            'Nouvelles missions',
            'Recevoir les notifications de nouvelles missions',
            _notifTypes['newMissions'] ?? true,
            (value) => _toggleNotification('newMissions', value),
          ),
          _buildSwitchItem(
            'Messages clients',
            'Notifications des messages clients',
            _notifTypes['messages'] ?? true,
            (value) => _toggleNotification('messages', value),
          ),
          _buildSwitchItem(
            'Paiements',
            'Notifications de paiements reçus',
            _notifTypes['payments'] ?? true,
            (value) => _toggleNotification('payments', value),
          ),
          _buildSwitchItem(
            'Avis et évaluations',
            'Notifications des avis clients',
            _notifTypes['reviews'] ?? true,
            (value) => _toggleNotification('reviews', value),
          ),
          _buildSwitchItem(
            'Promotions',
            'Offres et promotions SoutraLi',
            _notifTypes['promotions'] ?? false,
            (value) => _toggleNotification('promotions', value),
          ),
          _buildSwitchItem(
            'Notifications système',
            'Mises à jour et maintenance',
            _notifTypes['system'] ?? true,
            (value) => _toggleNotification('system', value),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return _sectionCard(
      title: 'Confidentialité et données',
      children: [
        _navRow(
          icon: Icons.data_usage,
          title: 'Gérer les données',
          subtitle: 'Télécharger ou supprimer vos données',
          onTap: () => openLegalUrl(context, LegalUrls.confidentialite),
        ),
        Divider(height: 1, color: SDColors.neutral200),
        _navRow(
          icon: Icons.policy_outlined,
          title: 'Politique de confidentialité',
          subtitle: 'Lire notre politique',
          onTap: () => openLegalUrl(context, LegalUrls.confidentialite),
        ),
        Divider(height: 1, color: SDColors.neutral200),
        _navRow(
          icon: Icons.description_outlined,
          title: 'Conditions d’utilisation',
          subtitle: 'Lire nos conditions',
          onTap: () => openLegalUrl(context, LegalUrls.cgu),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return _sectionCard(
      title: 'Sécurité du compte',
      children: [
        _navRow(
          icon: Icons.lock_outline,
          title: 'Changer le mot de passe',
          subtitle: 'Protection de votre compte',
          onTap: _showPasswordDialog,
        ),
        Divider(height: 1, color: SDColors.neutral200),
        _navRow(
          icon: Icons.devices,
          title: 'Sessions actives',
          subtitle: 'Gérer les appareils connectés',
          onTap: () => _showUnavailable('Sessions actives'),
        ),
        Divider(height: 1, color: SDColors.neutral200),
        _navRow(
          icon: Icons.history,
          title: 'Historique de connexion',
          onTap: () => _showUnavailable('Historique de connexion'),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Zone dangereuse',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDangerItem(
            'Désactiver le compte',
            'Suspendre temporairement votre espace Métiers',
            Icons.pause_circle,
            Colors.orange,
            _confirmDeactivatePrestataire,
          ),
          _buildDangerItem(
            'Supprimer le compte',
            'Désactiver définitivement votre compte utilisateur',
            Icons.delete_forever,
            Colors.red,
            _confirmDeleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: _notifLoading || _notifSaving ? null : onChanged,
        activeColor: Colors.green.shade600,
      ),
    );
  }

  Widget _buildDangerItem(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios,
          color: color.withOpacity(0.7), size: 16),
      onTap: onTap,
    );
  }

  void _showUnavailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — non disponible pour le moment')),
    );
  }

  void _confirmDeactivatePrestataire() {
    final id = widget.prestataireDocId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil prestataire introuvable'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Désactiver l\'espace Métiers ?'),
        content: const Text(
          'Votre profil prestataire sera suspendu et vous ne recevrez plus de missions. '
          'Vous pourrez le réactiver plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(dialogContext);
              final auth = context.read<AuthCubit>().state;
              if (auth is AuthAuthenticated) {
                context.read<ProviderProfileBloc>().setToken(auth.token);
              }
              context
                  .read<ProviderProfileBloc>()
                  .add(DeactivateAccount(id, 'Désactivation volontaire'));
            },
            child: const Text('Désactiver',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: const Text(
          'Votre compte utilisateur sera désactivé. Cette action nécessite une '
          'reconnexion éventuelle via le support pour réactivation. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              final auth = context.read<AuthCubit>().state;
              if (auth is AuthAuthenticated) {
                context.read<ProviderProfileBloc>().setToken(auth.token);
              }
              final id = widget.prestataireDocId ?? '';
              context
                  .read<ProviderProfileBloc>()
                  .add(DeleteAccount(id, 'Suppression demandée'));
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    var submitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Changer le mot de passe'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe actuel',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    submitting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final current = currentPasswordController.text.trim();
                        final next = newPasswordController.text.trim();
                        final confirm = confirmPasswordController.text.trim();

                        if (current.isEmpty || next.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez remplir tous les champs'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        if (next != confirm) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Les mots de passe ne correspondent pas'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        if (next.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Le nouveau mot de passe doit contenir au moins 6 caractères'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        final auth = context.read<AuthCubit>().state;
                        if (auth is! AuthAuthenticated ||
                            auth.token.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Session expirée — reconnectez-vous'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => submitting = true);
                        final bloc = context.read<ProviderProfileBloc>();
                        bloc.setToken(auth.token);
                        bloc.add(ChangePassword(
                          widget.prestataireDocId ?? '',
                          current,
                          next,
                        ));
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      },
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      ),
    );
  }
}
