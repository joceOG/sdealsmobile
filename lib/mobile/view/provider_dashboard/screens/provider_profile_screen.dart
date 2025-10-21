import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/provider_profile_bloc.dart';
import '../bloc/provider_profile_event.dart';
import '../bloc/provider_profile_state.dart';
import '../../../../data/services/authCubit.dart';

// 🎯 ÉCRAN PROFIL PRESTATAIRE MAGNIFIQUE
class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _prestataireId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Récupérer l'ID du prestataire depuis AuthCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _prestataireId = authState.utilisateur.idutilisateur;
      // Charger les données du profil
      context
          .read<ProviderProfileBloc>()
          .add(LoadProviderProfile(_prestataireId!));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildProfileAppBar(),
      body: BlocBuilder<ProviderProfileBloc, ProviderProfileState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildProfileHeader(state),
              _buildTabSelector(),
              Expanded(
                child: _buildProfileContent(state),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🎨 APP BAR PROFIL
  PreferredSizeWidget _buildProfileAppBar() {
    return AppBar(
      backgroundColor: Colors.green.shade600,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Row(
        children: [
          Icon(Icons.person, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Mon Profil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showEditProfile(),
          icon: Icon(Icons.edit, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 👤 EN-TÊTE DU PROFIL
  Widget _buildProfileHeader(ProviderProfileState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
            Colors.green.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Photo de profil
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.handyman,
                color: Colors.green.shade600,
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nom et statut
          Text(
            'Expert Prestataire',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Statut avec badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Profil Vérifié',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Statistiques rapides
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('Missions', '24', Icons.assignment),
              _buildHeaderStat('Note', '4.8/5', Icons.star),
              _buildHeaderStat('Clients', '18', Icons.people),
            ],
          ),
        ],
      ),
    );
  }

  // 📊 STATISTIQUE EN-TÊTE
  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // 📊 SÉLECTEUR D'ONGlets
  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Informations', icon: Icon(Icons.info)),
          Tab(text: 'Performance', icon: Icon(Icons.analytics)),
          Tab(text: 'Paramètres', icon: Icon(Icons.settings)),
        ],
      ),
    );
  }

  // 📊 CONTENU DU PROFIL
  Widget _buildProfileContent(ProviderProfileState state) {
    if (state is ProviderProfileLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is ProviderProfileError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _refreshProfile(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildInformationTab(state),
        _buildPerformanceTab(state),
        _buildSettingsTab(state),
      ],
    );
  }

  // 📋 ONGLET INFORMATIONS
  Widget _buildInformationTab(ProviderProfileState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoSection(),
          const SizedBox(height: 20),
          _buildServicesSection(),
          const SizedBox(height: 20),
          _buildContactSection(),
        ],
      ),
    );
  }

  // 📈 ONGLET PERFORMANCE
  Widget _buildPerformanceTab(ProviderProfileState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
          const SizedBox(height: 20),
          _buildAchievements(),
        ],
      ),
    );
  }

  // ⚙️ ONGLET PARAMÈTRES
  Widget _buildSettingsTab(ProviderProfileState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAccountSettings(),
          const SizedBox(height: 20),
          _buildNotificationSettings(),
          const SizedBox(height: 20),
          _buildPrivacySettings(),
          const SizedBox(height: 20),
          _buildDangerZone(),
        ],
      ),
    );
  }

  // 📋 SECTION INFORMATIONS
  Widget _buildInfoSection() {
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
              Icon(Icons.info, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Informations personnelles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Nom complet', 'Jean Dupont'),
          _buildInfoItem('Email', 'jean.dupont@email.com'),
          _buildInfoItem('Téléphone', '+225 07 12 34 56 78'),
          _buildInfoItem('Date d\'inscription', '15 Janvier 2024'),
          _buildInfoItem('Statut', 'Actif'),
        ],
      ),
    );
  }

  // 🔧 ÉLÉMENT D'INFORMATION
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💼 SECTION SERVICES
  Widget _buildServicesSection() {
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
              Icon(Icons.work, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Services proposés',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildServiceChip('Plomberie', Colors.blue),
          _buildServiceChip('Électricité', Colors.orange),
          _buildServiceChip('Peinture', Colors.purple),
          _buildServiceChip('Menuiserie', Colors.brown),
        ],
      ),
    );
  }

  // 🏷️ CHIP DE SERVICE
  Widget _buildServiceChip(String service, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 8),
      child: Chip(
        label: Text(
          service,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: color,
        avatar: Icon(Icons.check, color: Colors.white, size: 16),
      ),
    );
  }

  // 📞 SECTION CONTACT
  Widget _buildContactSection() {
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
              Icon(Icons.location_on, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Zone de service',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Adresse', 'Abidjan, Côte d\'Ivoire'),
          _buildInfoItem('Rayon de service', '15 km'),
          _buildInfoItem('Disponibilité', '7j/7, 24h/24'),
        ],
      ),
    );
  }

  // 📊 CARTES DE STATISTIQUES
  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Missions terminées',
          '24',
          '+3 cette semaine',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Note moyenne',
          '4.8/5',
          'Basé sur 18 avis',
          Icons.star,
          Colors.amber,
        ),
        _buildStatCard(
          'Revenus du mois',
          '125K FCFA',
          '+15% vs mois dernier',
          Icons.monetization_on,
          Colors.blue,
        ),
        _buildStatCard(
          'Taux de réussite',
          '96%',
          '+2% cette semaine',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  // 📊 CARTE DE STATISTIQUE
  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 📈 ACTIVITÉ RÉCENTE
  Widget _buildRecentActivity() {
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
              Icon(Icons.timeline, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Activité récente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'Mission terminée',
            'Réparation plomberie - Client Marie',
            'Il y a 2 heures',
            Icons.check_circle,
            Colors.green,
          ),
          _buildActivityItem(
            'Nouvelle mission',
            'Installation électrique - Client Paul',
            'Il y a 4 heures',
            Icons.assignment,
            Colors.blue,
          ),
          _buildActivityItem(
            'Avis reçu',
            '5 étoiles - Excellent travail !',
            'Il y a 1 jour',
            Icons.star,
            Colors.amber,
          ),
        ],
      ),
    );
  }

  // 📋 ÉLÉMENT D'ACTIVITÉ
  Widget _buildActivityItem(
    String title,
    String description,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🏆 RÉCOMPENSES
  Widget _buildAchievements() {
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
              Icon(Icons.emoji_events, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Récompenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildAchievementBadge('Expert', Icons.star, Colors.amber),
              _buildAchievementBadge('Fiable', Icons.verified, Colors.green),
              _buildAchievementBadge('Rapide', Icons.speed, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  // 🏅 BADGE DE RÉCOMPENSE
  Widget _buildAchievementBadge(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ⚙️ PARAMÈTRES DU COMPTE
  Widget _buildAccountSettings() {
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
            'Informations personnelles',
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
            'Documents et pièces',
            Icons.verified_user,
            () => _showIdentityVerification(),
          ),
        ],
      ),
    );
  }

  // 🔔 PARAMÈTRES DE NOTIFICATION
  Widget _buildNotificationSettings() {
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
        ],
      ),
    );
  }

  // 🔒 PARAMÈTRES DE CONFIDENTIALITÉ
  Widget _buildPrivacySettings() {
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
            'Lire notre politique',
            Icons.policy,
            () => _showPrivacyPolicy(),
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
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
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
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
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
  Widget _buildDangerItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
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

  void _refreshProfile() {
    if (_prestataireId != null) {
      context
          .read<ProviderProfileBloc>()
          .add(LoadProviderProfile(_prestataireId!));
    }
  }

  void _showEditProfile() {
    // TODO: Naviguer vers l'écran d'édition
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Édition du profil - En développement')),
    );
  }

  void _showChangePassword() {
    // TODO: Naviguer vers le changement de mot de passe
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Changement de mot de passe - En développement')),
    );
  }

  void _showIdentityVerification() {
    // TODO: Naviguer vers la vérification d'identité
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Vérification d\'identité - En développement')),
    );
  }

  void _showDataManagement() {
    // TODO: Naviguer vers la gestion des données
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestion des données - En développement')),
    );
  }

  void _showPrivacyPolicy() {
    // TODO: Naviguer vers la politique de confidentialité
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Politique de confidentialité - En développement')),
    );
  }

  void _showDeactivateAccount() {
    // TODO: Afficher le dialogue de désactivation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Désactivation du compte - En développement')),
    );
  }

  void _showDeleteAccount() {
    // TODO: Afficher le dialogue de suppression
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suppression du compte - En développement')),
    );
  }

  void _toggleNotification(String type, bool value) {
    // TODO: Mettre à jour les paramètres de notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Notification $type: ${value ? 'activée' : 'désactivée'}')),
    );
  }
}
