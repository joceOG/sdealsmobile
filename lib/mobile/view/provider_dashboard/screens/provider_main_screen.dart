import 'package:flutter/material.dart';
import 'package:sdealsmobile/data/models/utilisateur.dart';
import 'package:sdealsmobile/mobile/view/common/screens/ai_assistant_chat_screen.dart';
import 'package:sdealsmobile/data/services/authCubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/missions_bloc.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/planning_bloc.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/messages_bloc.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/notifications_bloc.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/soutrapay_bloc.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_missions_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_planning_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_messages_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_notifications_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_soutrapay_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_profile_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/provider_profile_bloc.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_settings_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/screens/provider_statistics_screen.dart';
import 'package:sdealsmobile/mobile/view/provider_dashboard/bloc/provider_statistics_bloc.dart';

class ProviderMainScreen extends StatefulWidget {
  final Utilisateur? utilisateur; // ⚡ reçoit le prestataire (nullable)

  const ProviderMainScreen({Key? key, this.utilisateur}) : super(key: key);

  @override
  _ProviderMainScreenState createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> {
  int _currentIndex = 0;

  // Titres des écrans pour l'AppBar
  final List<String> _titles = [
    'Espace Prestataire',
    'Missions',
    'Planning',
    'Messages',
    'Profil'
  ];

  // Solde SoutraPay (simulé)
  final String _balance = '125,000 FCFA';

  // ✅ DASHBOARD AVEC VÉRIFICATION DU STATUT
  Widget _buildSimpleDashboard() {
    // 🎯 VÉRIFIER LE STATUT DU PRESTATAIRE
    final prestataireStatus = _getPrestataireStatus();

    if (prestataireStatus == 'incomplete') {
      return _buildIncompleteProfileDashboard();
    } else if (prestataireStatus == 'pending') {
      return _buildPendingValidationDashboard();
    } else {
      return _buildActiveDashboard();
    }
  }

  // 🚨 DASHBOARD POUR PROFIL INCOMPLET
  Widget _buildIncompleteProfileDashboard() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🚨 MESSAGE D'ALERTE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '⚠️ Votre inscription n\'est pas complète !',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '📋 Finalisez votre profil pour accéder aux missions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '📄 Documents requis : CNI, selfie, localisation',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🔘 BOUTON DE FINALISATION
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/prestataire-finalization');
                },
                icon: Icon(Icons.check_circle, color: Colors.white),
                label: Text(
                  'Finaliser mon profil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 📊 STATISTIQUES DÉSACTIVÉES
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.lock, color: Colors.grey[500], size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Fonctionnalités verrouillées',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Finalisez votre profil pour débloquer toutes les fonctionnalités',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⏳ DASHBOARD POUR VALIDATION EN COURS
  Widget _buildPendingValidationDashboard() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⏳ MESSAGE D'ATTENTE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hourglass_empty,
                          color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '⏳ Votre profil est en cours de validation',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '📋 Notre équipe vérifie vos documents',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '📧 Vous recevrez une notification par email',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🔘 BOUTON RETOUR CLIENT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<AuthCubit>().switchActiveRole('CLIENT');
                  context.push('/homepage');
                },
                icon: Icon(Icons.home, color: Colors.white),
                label: Text(
                  'Retour au mode Client',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ DASHBOARD ACTIF MAGNIFIQUE (FONCTIONNEL)
  Widget _buildActiveDashboard() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎨 EN-TÊTE DE BIENVENUE MAGNIFIQUE
            _buildMagnificentWelcomeHeader(),

            const SizedBox(height: 24),

            // 📊 STATISTIQUES AVANCÉES
            _buildAdvancedStatsSection(),

            const SizedBox(height: 24),

            // 📈 GRAPHIQUES MINIATURES
            _buildMiniChartsSection(),

            const SizedBox(height: 24),

            // ⚡ ACTIONS RAPIDES INTELLIGENTES
            _buildSmartActionsSection(),

            const SizedBox(height: 24),

            // 🎯 RÉCAPITULATIF QUOTIDIEN
            _buildDailySummarySection(),
          ],
        ),
      ),
    );
  }

  // 🎨 EN-TÊTE DE BIENVENUE MAGNIFIQUE
  Widget _buildMagnificentWelcomeHeader() {
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.handyman,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour ${widget.utilisateur?.prenom ?? 'Prestataire'} !',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expert Prestataire • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+12%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Gérez vos missions et maximisez vos revenus',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // 📊 STATISTIQUES AVANCÉES
  Widget _buildAdvancedStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Colors.green.shade600, size: 24),
            const SizedBox(width: 8),
            Text(
              'Vos performances',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showDetailedStats(),
              icon: Icon(Icons.more_horiz, size: 16),
              label: Text('Voir tout'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildAdvancedStatCard(
              'Missions actives',
              '8',
              '+2 cette semaine',
              Icons.assignment,
              Colors.blue,
              Colors.blue.shade50,
            ),
            _buildAdvancedStatCard(
              'Revenus du mois',
              '125K FCFA',
              '+15% vs mois dernier',
              Icons.monetization_on,
              Colors.green,
              Colors.green.shade50,
            ),
            _buildAdvancedStatCard(
              'Clients satisfaits',
              '4.8/5',
              'Basé sur 24 avis',
              Icons.star,
              Colors.amber,
              Colors.amber.shade50,
            ),
            _buildAdvancedStatCard(
              'Taux de réussite',
              '96%',
              '+3% cette semaine',
              Icons.check_circle,
              Colors.purple,
              Colors.purple.shade50,
            ),
          ],
        ),
      ],
    );
  }

  // 📈 GRAPHIQUES MINIATURES
  Widget _buildMiniChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.show_chart, color: Colors.green.shade600, size: 24),
            const SizedBox(width: 8),
            Text(
              'Évolution des revenus',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '7 derniers jours',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenus hebdomadaires',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '45,200 FCFA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '+8.2% cette semaine',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '📈 Graphique\nen développement',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ⚡ ACTIONS RAPIDES INTELLIGENTES
  Widget _buildSmartActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: Colors.green.shade600, size: 24),
            const SizedBox(width: 8),
            Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSmartActionButton(
                'Nouvelles missions',
                '3 disponibles',
                Icons.add_circle,
                Colors.blue,
                () =>
                    setState(() => _currentIndex = 1), // Naviguer vers Missions
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmartActionButton(
                'Mon planning',
                '2 rendez-vous',
                Icons.calendar_today,
                Colors.green,
                () =>
                    setState(() => _currentIndex = 2), // Naviguer vers Planning
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSmartActionButton(
                'Messages',
                '2 non lus',
                Icons.message,
                Colors.orange,
                () =>
                    setState(() => _currentIndex = 3), // Naviguer vers Messages
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmartActionButton(
                'SoutraPay',
                '125K FCFA',
                Icons.account_balance_wallet,
                Colors.purple,
                () => _showSoutraPayScreen(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🎯 RÉCAPITULATIF QUOTIDIEN
  Widget _buildDailySummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.green.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Récapitulatif du jour',
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
              Expanded(
                child: _buildDailyStat(
                  'Missions terminées',
                  '2',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildDailyStat(
                  'Revenus du jour',
                  '15K FCFA',
                  Icons.monetization_on,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDailyStat(
                  'Nouveaux clients',
                  '1',
                  Icons.person_add,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildDailyStat(
                  'Messages reçus',
                  '3',
                  Icons.message,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🎨 CARTE DE STATISTIQUE AVANCÉE
  Widget _buildAdvancedStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    Color backgroundColor,
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ⚡ BOUTON D'ACTION INTELLIGENT
  Widget _buildSmartActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Icon(Icons.arrow_forward_ios,
                    color: Colors.grey[400], size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📊 STATISTIQUE QUOTIDIENNE
  Widget _buildDailyStat(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 📊 AFFICHER LES STATISTIQUES DÉTAILLÉES
  void _showDetailedStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques détaillées'),
        content: const Text('Fonctionnalité en développement...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ✅ ÉCRANS STATIQUES SANS BLOCBUILDER
  Widget _buildSimpleMissions() {
    return BlocProvider(
      create: (context) => MissionsBloc(),
      child: const ProviderMissionsScreen(),
    );
  }

  Widget _buildSimplePlanning() {
    return BlocProvider<PlanningBloc>(
      create: (context) => PlanningBloc(),
      child: const ProviderPlanningScreen(),
    );
  }

  Widget _buildSimpleMessages() {
    return BlocProvider<MessagesBloc>(
      create: (context) => MessagesBloc(),
      child: const ProviderMessagesScreen(),
    );
  }

  Widget _buildSimpleProfile() {
    return BlocProvider<ProviderProfileBloc>(
      create: (context) => ProviderProfileBloc(),
      child: const ProviderProfileScreen(),
    );
  }

  // 🎨 APP BAR MAGNIFIQUE POUR EXPERT PRESTATAIRE
  PreferredSizeWidget _buildExpertAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade600,
              Colors.green.shade800,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // 🎯 TITRE AVEC AVATAR
                Expanded(
                  child: Row(
                    children: [
                      // Avatar du prestataire
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.green.shade100],
                          ),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.handyman,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Titre et sous-titre
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _titles[_currentIndex],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Expert Prestataire',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 🎯 ACTIONS EXPERT
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Notifications avec badge animé
                    _buildNotificationButton(),
                    const SizedBox(width: 6),

                    // Solde SoutraPay élégant
                    _buildSoldeButton(context),
                    const SizedBox(width: 6),

                    // Menu expert
                    _buildExpertMenu(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔔 BOUTON NOTIFICATIONS AVEC BADGE
  Widget _buildNotificationButton() {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 20),
            onPressed: () {
              _showNotificationsScreen();
            },
            padding: EdgeInsets.zero,
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: const Text(
              '3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  // 💰 BOUTON SOLDE SOUTRAPAY
  Widget _buildSoldeButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _showSoutraPayScreen(),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _balance,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 MENU EXPERT
  Widget _buildExpertMenu(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50), // Afficher le menu EN DESSOUS
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profil':
            _showProviderProfile();
            break;
          case 'parametres':
            _showProviderSettings();
            break;
          case 'statistiques':
            _showProviderStatistics();
            break;
          case 'assistant':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AIAssistantChatScreen(),
              ),
            );
            break;
          case 'soutrapay':
            _showSoutraPayScreen();
            break;
          case 'retour_client':
            _switchToClientMode(context);
            break;
          case 'deconnexion':
            _logout(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'profil',
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.green.shade600),
              const SizedBox(width: 12),
              const Text('Mon Profil'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'parametres',
          child: Row(
            children: [
              Icon(Icons.settings, color: Colors.green.shade600),
              const SizedBox(width: 12),
              const Text('Paramètres'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'statistiques',
          child: Row(
            children: [
              Icon(Icons.analytics, color: Colors.green.shade600),
              const SizedBox(width: 12),
              const Text('Statistiques'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'assistant',
          child: Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.green.shade600),
              const SizedBox(width: 12),
              const Text('Assistant IA'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'soutrapay',
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.green.shade600),
              const SizedBox(width: 12),
              const Text('SoutraPay'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'retour_client',
          child: Row(
            children: [
              Icon(Icons.home, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Text('Retour Client',
                  style: TextStyle(color: Colors.blue.shade600)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'deconnexion',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade600),
              const SizedBox(width: 12),
              Text('Déconnexion', style: TextStyle(color: Colors.red.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  // 🔄 SWITCH VERS MODE CLIENT
  void _switchToClientMode(BuildContext context) {
    try {
      context.read<AuthCubit>().switchActiveRole('CLIENT');
      Future.delayed(const Duration(milliseconds: 100), () {
        context.push('/homepage');
      });
    } catch (e) {
      print('Erreur lors du switch de rôle: $e');
      context.push('/homepage');
    }
  }

  // 🚪 DÉCONNEXION
  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().logout();
              context.push('/login');
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⚡ SOLUTION RADICALE : Écrans statiques pour éviter la boucle infinie
    final List<Widget> _screens = [
      _buildSimpleDashboard(),
      _buildSimpleMissions(),
      _buildSimplePlanning(),
      _buildSimpleMessages(),
      _buildSimpleProfile(),
    ];

    return Scaffold(
      appBar: _buildExpertAppBar(context),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildExpertBottomNavBar(context),
    );
  }

  // 🎨 BOTTOM NAV BAR MAGNIFIQUE POUR EXPERT PRESTATAIRE
  Widget _buildExpertBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade600,
            Colors.green.shade800,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildExpertNavItem(
                  0, Icons.home_outlined, Icons.home, 'Accueil'),
              _buildExpertNavItem(
                  1, Icons.assignment_outlined, Icons.assignment, 'Missions'),
              _buildExpertNavItem(2, Icons.calendar_today_outlined,
                  Icons.calendar_today, 'Planning'),
              _buildExpertNavItem(
                  3, Icons.message_outlined, Icons.message, 'Messages'),
              _buildExpertNavItem(
                  4, Icons.person_outline, Icons.person, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 ÉLÉMENT DE NAVIGATION EXPERT
  Widget _buildExpertNavItem(
      int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône avec animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? filledIcon : outlineIcon,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                size: isActive ? 24 : 22,
              ),
            ),
            const SizedBox(height: 4),
            // Label avec style adaptatif
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: isActive ? 12 : 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔔 AFFICHER L'ÉCRAN DE NOTIFICATIONS
  void _showNotificationsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<NotificationsBloc>(
          create: (context) => NotificationsBloc(),
          child: const ProviderNotificationsScreen(),
        ),
      ),
    );
  }

  // 💰 AFFICHER L'ÉCRAN SOUTRAPAY
  void _showSoutraPayScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<SoutraPayBloc>(
          create: (context) => SoutraPayBloc(),
          child: const ProviderSoutraPayScreen(),
        ),
      ),
    );
  }

  // 👤 AFFICHER L'ÉCRAN PROFIL PRESTATAIRE
  void _showProviderProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<ProviderProfileBloc>(
          create: (context) => ProviderProfileBloc(),
          child: const ProviderProfileScreen(),
        ),
      ),
    );
  }

  // ⚙️ AFFICHER L'ÉCRAN PARAMÈTRES
  void _showProviderSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<ProviderProfileBloc>(
          create: (context) => ProviderProfileBloc(),
          child: const ProviderSettingsScreen(),
        ),
      ),
    );
  }

  // 📊 AFFICHER L'ÉCRAN STATISTIQUES
  void _showProviderStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<ProviderStatisticsBloc>(
          create: (context) => ProviderStatisticsBloc(),
          child: const ProviderStatisticsScreen(),
        ),
      ),
    );
  }

  // 🎯 MÉTHODE POUR VÉRIFIER LE STATUT DU PRESTATAIRE
  String _getPrestataireStatus() {
    // TODO: Récupérer le statut depuis l'API
    // Pour l'instant, on simule avec 'incomplete' pour tester
    return 'incomplete'; // 'incomplete', 'pending', 'active'
  }
}
