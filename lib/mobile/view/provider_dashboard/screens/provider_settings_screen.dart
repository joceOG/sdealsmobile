import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/provider_profile_bloc.dart';
import '../bloc/provider_profile_state.dart';

// ⚙️ ÉCRAN PARAMÈTRES PRESTATAIRE
class ProviderSettingsScreen extends StatefulWidget {
  const ProviderSettingsScreen({super.key});

  @override
  State<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends State<ProviderSettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildSettingsAppBar(),
      body: BlocBuilder<ProviderProfileBloc, ProviderProfileState>(
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
    );
  }

  // 🎨 APP BAR PARAMÈTRES
  PreferredSizeWidget _buildSettingsAppBar() {
    return AppBar(
      backgroundColor: Colors.green.shade600,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Row(
        children: [
          Icon(Icons.settings, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Paramètres',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 👤 SECTION COMPTE
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
            () => _showChangePassword(),
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

  // 🔔 SECTION NOTIFICATIONS
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
            ],
          ),
          const SizedBox(height: 16),
          _buildSwitchItem(
            'Nouvelles missions',
            'Recevoir les notifications de nouvelles missions',
            true,
            (value) => _toggleNotification('missions', value),
          ),
          _buildSwitchItem(
            'Messages clients',
            'Notifications des messages clients',
            true,
            (value) => _toggleNotification('messages', value),
          ),
          _buildSwitchItem(
            'Paiements',
            'Notifications de paiements reçus',
            true,
            (value) => _toggleNotification('payments', value),
          ),
          _buildSwitchItem(
            'Avis et évaluations',
            'Notifications des avis clients',
            true,
            (value) => _toggleNotification('reviews', value),
          ),
          _buildSwitchItem(
            'Promotions',
            'Offres et promotions SoutraLi',
            false,
            (value) => _toggleNotification('promotions', value),
          ),
          _buildSwitchItem(
            'Notifications système',
            'Mises à jour et maintenance',
            true,
            (value) => _toggleNotification('system', value),
          ),
        ],
      ),
    );
  }

  // 🔒 SECTION CONFIDENTIALITÉ
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
            () => _showDataManagement(),
          ),
          _buildSettingItem(
            'Politique de confidentialité',
            'Lire notre politique de confidentialité',
            Icons.policy,
            () => _showPrivacyPolicy(),
          ),
          _buildSettingItem(
            'Conditions d\'utilisation',
            'Lire nos conditions d\'utilisation',
            Icons.description,
            () => _showTermsOfService(),
          ),
        ],
      ),
    );
  }

  // 🔐 SECTION SÉCURITÉ
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
            'Authentification à deux facteurs',
            'Sécuriser votre compte avec 2FA',
            Icons.security,
            () => _showTwoFactorAuth(),
          ),
          _buildSettingItem(
            'Sessions actives',
            'Gérer les appareils connectés',
            Icons.devices,
            () => _showActiveSessions(),
          ),
          _buildSettingItem(
            'Historique de connexion',
            'Voir l\'historique des connexions',
            Icons.history,
            () => _showLoginHistory(),
          ),
        ],
      ),
    );
  }

  // 🗑️ ZONE DANGEREUSE
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
            'Suspendre temporairement votre compte',
            Icons.pause_circle,
            Colors.orange,
            () => _showDeactivateAccount(),
          ),
          _buildDangerItem(
            'Supprimer le compte',
            'Supprimer définitivement votre compte',
            Icons.delete_forever,
            Colors.red,
            () => _showDeleteAccount(),
          ),
        ],
      ),
    );
  }

  // ⚙️ ÉLÉMENT DE PARAMÈTRE
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

  // 🔄 ÉLÉMENT AVEC SWITCH
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
        onChanged: onChanged,
        activeColor: Colors.green.shade600,
      ),
    );
  }

  // 🚨 ÉLÉMENT DANGEREUX
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

  // 🔧 MÉTHODES UTILITAIRES

  void _showEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Édition du profil - En développement')),
    );
  }

  void _showChangePassword() {
    _showPasswordDialog();
  }

  void _showIdentityVerification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Vérification d\'identité - En développement')),
    );
  }

  void _showDataManagement() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestion des données - En développement')),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Politique de confidentialité - En développement')),
    );
  }

  void _showTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Conditions d\'utilisation - En développement')),
    );
  }

  void _showTwoFactorAuth() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Authentification à deux facteurs - En développement')),
    );
  }

  void _showActiveSessions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sessions actives - En développement')),
    );
  }

  void _showLoginHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Historique de connexion - En développement')),
    );
  }

  void _showDeactivateAccount() {
    _showDeactivateDialog();
  }

  void _showDeleteAccount() {
    _showDeleteDialog();
  }

  void _toggleNotification(String type, bool value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Notification $type: ${value ? 'activée' : 'désactivée'}')),
    );
  }

  // 🔐 DIALOGUE CHANGEMENT DE MOT DE PASSE
  void _showPasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter le changement de mot de passe
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Mot de passe changé avec succès')),
              );
            },
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  // ⏸️ DIALOGUE DÉSACTIVATION
  void _showDeactivateDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Désactiver le compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir désactiver votre compte ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter la désactivation
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compte désactivé avec succès')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  // 🗑️ DIALOGUE SUPPRESSION
  void _showDeleteDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ATTENTION: Cette action est irréversible. Toutes vos données seront supprimées définitivement.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (obligatoire)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter la suppression
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compte supprimé avec succès')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
