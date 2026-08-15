import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/data/utils/legal_urls.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../design_system/design_system.dart';
import '../bloc/provider_profile_bloc.dart';
import '../bloc/provider_profile_event.dart';
import '../bloc/provider_profile_state.dart';

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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAccountSection(),
                  const SizedBox(height: 20),
                  _buildNotificationSection(),
                  const SizedBox(height: 20),
                  _buildPrivacySection(),
                  const SizedBox(height: 20),
                  _buildSecuritySection(),
                  const SizedBox(height: 20),
                  _buildDangerZone(),
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
    );
  }

  Widget _buildAccountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_circle,
                  color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Compte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            'Modifier le profil',
            'Informations personnelles et professionnelles',
            Icons.edit,
            () => _showEditProfile(),
          ),
          _buildSettingItem(
            'Changer le mot de passe',
            'Sécurité du compte',
            Icons.lock,
            () => _showPasswordDialog(),
          ),
          _buildSettingItem(
            'Vérification d\'identité',
            'Documents et pièces justificatives',
            Icons.verified_user,
            () => _showIdentityVerification(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Confidentialité',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            'Gérer les données',
            'Télécharger ou supprimer vos données',
            Icons.data_usage,
            () => openLegalUrl(context, LegalUrls.confidentialite),
          ),
          _buildSettingItem(
            'Politique de confidentialité',
            'Lire notre politique de confidentialité',
            Icons.policy,
            () => openLegalUrl(context, LegalUrls.confidentialite),
          ),
          _buildSettingItem(
            'Conditions d\'utilisation',
            'Lire nos conditions d\'utilisation',
            Icons.description,
            () => openLegalUrl(context, LegalUrls.cgu),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Sécurité',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            'Sessions actives',
            'Gérer les appareils connectés',
            Icons.devices,
            () => _showUnavailable('Sessions actives'),
          ),
          _buildSettingItem(
            'Historique de connexion',
            'Voir l\'historique des connexions',
            Icons.history,
            () => _showUnavailable('Historique de connexion'),
          ),
        ],
      ),
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

  Widget _buildSettingItem(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green.shade600),
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
      trailing:
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
      onTap: onTap,
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

  void _showEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Utilisez l\'onglet Profil pour modifier bio et description'),
      ),
    );
  }

  void _showIdentityVerification() {
    _showUnavailable('Vérification d\'identité');
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
