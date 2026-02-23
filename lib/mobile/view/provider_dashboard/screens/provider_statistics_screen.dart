import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/provider_statistics_bloc.dart';
import '../bloc/provider_statistics_event.dart';
import '../bloc/provider_statistics_state.dart';
import '../../../../data/services/authCubit.dart';

// 📊 ÉCRAN STATISTIQUES PRESTATAIRE MAGNIFIQUE
class ProviderStatisticsScreen extends StatefulWidget {
  const ProviderStatisticsScreen({super.key});

  @override
  State<ProviderStatisticsScreen> createState() =>
      _ProviderStatisticsScreenState();
}

class _ProviderStatisticsScreenState extends State<ProviderStatisticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _prestataireId;
  String _selectedPeriod = 'Mois';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Récupérer l'ID du prestataire depuis AuthCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _prestataireId = authState.utilisateur.idutilisateur;
      // Charger les statistiques
      context
          .read<ProviderStatisticsBloc>()
          .add(LoadProviderStatistics(_prestataireId!));
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
      appBar: _buildStatisticsAppBar(),
      body: BlocBuilder<ProviderStatisticsBloc, ProviderStatisticsState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildStatisticsHeader(state),
              _buildPeriodSelector(),
              _buildTabSelector(),
              Expanded(
                child: _buildStatisticsContent(state),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🎨 APP BAR STATISTIQUES
  PreferredSizeWidget _buildStatisticsAppBar() {
    return AppBar(
      backgroundColor: Colors.green.shade600,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Row(
        children: [
          Icon(Icons.analytics, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Mes Statistiques',
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
          onPressed: () => _showExportOptions(),
          icon: Icon(Icons.download, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 📊 EN-TÊTE DES STATISTIQUES
  Widget _buildStatisticsHeader(ProviderStatisticsState state) {
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
          // Titre et période
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance du mois',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'fr').format(DateTime.now()),
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
                    Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+15%',
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
          const SizedBox(height: 20),

          // Statistiques principales
          Row(
            children: [
              _buildHeaderStat(
                  'Revenus', '125K FCFA', Icons.monetization_on, Colors.amber),
              _buildHeaderStat('Missions', '24', Icons.assignment, Colors.blue),
              _buildHeaderStat('Note', '4.8/5', Icons.star, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  // 📊 STATISTIQUE EN-TÊTE
  Widget _buildHeaderStat(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
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
      ),
    );
  }

  // 📅 SÉLECTEUR DE PÉRIODE
  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPeriodChip('Semaine', _selectedPeriod == 'Semaine'),
          _buildPeriodChip('Mois', _selectedPeriod == 'Mois'),
          _buildPeriodChip('Année', _selectedPeriod == 'Année'),
        ],
      ),
    );
  }

  // 📅 CHIP DE PÉRIODE
  Widget _buildPeriodChip(String period, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = period);
        _loadStatisticsForPeriod(period);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.green.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[600],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 📊 SÉLECTEUR D'ONGlets
  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: const [
          Tab(text: 'Revenus', icon: Icon(Icons.monetization_on, size: 16)),
          Tab(text: 'Missions', icon: Icon(Icons.assignment, size: 16)),
          Tab(text: 'Clients', icon: Icon(Icons.people, size: 16)),
          Tab(text: 'Performance', icon: Icon(Icons.trending_up, size: 16)),
        ],
      ),
    );
  }

  // 📊 CONTENU DES STATISTIQUES
  Widget _buildStatisticsContent(ProviderStatisticsState state) {
    if (state is ProviderStatisticsLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is ProviderStatisticsError) {
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
              onPressed: () => _refreshStatistics(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildRevenusTab(state),
        _buildMissionsTab(state),
        _buildClientsTab(state),
        _buildPerformanceTab(state),
      ],
    );
  }

  // 💰 ONGLET REVENUS
  Widget _buildRevenusTab(ProviderStatisticsState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRevenusCards(),
          const SizedBox(height: 20),
          _buildRevenusChart(),
          const SizedBox(height: 20),
          _buildRevenusBreakdown(),
        ],
      ),
    );
  }

  // 💰 CARTES DE REVENUS
  Widget _buildRevenusCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Revenus totaux',
          '125,000 FCFA',
          '+15% vs mois dernier',
          Icons.account_balance_wallet,
          Colors.green,
        ),
        _buildStatCard(
          'En attente',
          '25,000 FCFA',
          '3 paiements en cours',
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Moyenne/mission',
          '5,200 FCFA',
          '+8% cette semaine',
          Icons.trending_up,
          Colors.blue,
        ),
        _buildStatCard(
          'Objectif',
          '150,000 FCFA',
          '83% atteint',
          Icons.flag,
          Colors.purple,
        ),
      ],
    );
  }

  // 📈 GRAPHIQUE DES REVENUS
  Widget _buildRevenusChart() {
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
              Icon(Icons.show_chart, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Évolution des revenus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Graphique en développement',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💰 DÉTAIL DES REVENUS
  Widget _buildRevenusBreakdown() {
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
              Icon(Icons.pie_chart, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Répartition des revenus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBreakdownItem('Plomberie', '45,000 FCFA', 0.36, Colors.blue),
          _buildBreakdownItem(
              'Électricité', '35,000 FCFA', 0.28, Colors.orange),
          _buildBreakdownItem('Peinture', '25,000 FCFA', 0.20, Colors.purple),
          _buildBreakdownItem('Autres', '20,000 FCFA', 0.16, Colors.green),
        ],
      ),
    );
  }

  // 📊 ÉLÉMENT DE RÉPARTITION
  Widget _buildBreakdownItem(
      String category, String amount, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  // 📋 ONGLET MISSIONS
  Widget _buildMissionsTab(ProviderStatisticsState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMissionsCards(),
          const SizedBox(height: 20),
          _buildMissionsChart(),
          const SizedBox(height: 20),
          _buildMissionsTimeline(),
        ],
      ),
    );
  }

  // 📋 CARTES DE MISSIONS
  Widget _buildMissionsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Total missions',
          '24',
          '+3 cette semaine',
          Icons.assignment,
          Colors.blue,
        ),
        _buildStatCard(
          'Taux de réussite',
          '96%',
          '+2% ce mois',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Temps moyen',
          '2.5h',
          'Par mission',
          Icons.timer,
          Colors.orange,
        ),
        _buildStatCard(
          'Satisfaction',
          '4.8/5',
          'Note moyenne',
          Icons.star,
          Colors.purple,
        ),
      ],
    );
  }

  // 📈 GRAPHIQUE DES MISSIONS
  Widget _buildMissionsChart() {
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
                'Évolution des missions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Graphique en développement',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📅 TIMELINE DES MISSIONS
  Widget _buildMissionsTimeline() {
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
              Icon(Icons.history, color: Colors.green.shade600, size: 24),
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
          _buildTimelineItem(
            'Mission terminée',
            'Réparation plomberie - Client Marie',
            'Il y a 2 heures',
            Icons.check_circle,
            Colors.green,
          ),
          _buildTimelineItem(
            'Nouvelle mission',
            'Installation électrique - Client Paul',
            'Il y a 4 heures',
            Icons.assignment,
            Colors.blue,
          ),
          _buildTimelineItem(
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

  // 📅 ÉLÉMENT DE TIMELINE
  Widget _buildTimelineItem(String title, String description, String time,
      IconData icon, Color color) {
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

  // 👥 ONGLET CLIENTS
  Widget _buildClientsTab(ProviderStatisticsState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildClientsCards(),
          const SizedBox(height: 20),
          _buildClientsChart(),
          const SizedBox(height: 20),
          _buildTopClients(),
        ],
      ),
    );
  }

  // 👥 CARTES DE CLIENTS
  Widget _buildClientsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Clients totaux',
          '18',
          '+2 ce mois',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Clients fidèles',
          '12',
          '67% du total',
          Icons.favorite,
          Colors.red,
        ),
        _buildStatCard(
          'Nouveaux clients',
          '6',
          'Ce mois',
          Icons.person_add,
          Colors.green,
        ),
        _buildStatCard(
          'Satisfaction',
          '4.8/5',
          'Note moyenne',
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  // 📈 GRAPHIQUE DES CLIENTS
  Widget _buildClientsChart() {
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
              Icon(Icons.people_alt, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Évolution des clients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Graphique en développement',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🏆 TOP CLIENTS
  Widget _buildTopClients() {
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
                'Top clients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildClientItem('Marie K.', '4 missions', '45,000 FCFA', 1),
          _buildClientItem('Paul M.', '3 missions', '35,000 FCFA', 2),
          _buildClientItem('Ahmed T.', '2 missions', '25,000 FCFA', 3),
        ],
      ),
    );
  }

  // 👤 ÉLÉMENT DE CLIENT
  Widget _buildClientItem(
      String name, String missions, String amount, int rank) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank == 1
                  ? Colors.amber
                  : rank == 2
                      ? Colors.grey[400]
                      : Colors.orange[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  missions,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // 📈 ONGLET PERFORMANCE
  Widget _buildPerformanceTab(ProviderStatisticsState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPerformanceCards(),
          const SizedBox(height: 20),
          _buildPerformanceChart(),
          const SizedBox(height: 20),
          _buildAchievements(),
        ],
      ),
    );
  }

  // 📈 CARTES DE PERFORMANCE
  Widget _buildPerformanceCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Efficacité',
          '92%',
          '+5% ce mois',
          Icons.speed,
          Colors.blue,
        ),
        _buildStatCard(
          'Ponctualité',
          '98%',
          '+2% ce mois',
          Icons.schedule,
          Colors.green,
        ),
        _buildStatCard(
          'Qualité',
          '4.8/5',
          'Note moyenne',
          Icons.star,
          Colors.amber,
        ),
        _buildStatCard(
          'Disponibilité',
          '95%',
          'Temps de réponse',
          Icons.access_time,
          Colors.purple,
        ),
      ],
    );
  }

  // 📈 GRAPHIQUE DE PERFORMANCE
  Widget _buildPerformanceChart() {
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
              Icon(Icons.trending_up, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Évolution de la performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Graphique en développement',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
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

  // 🔧 MÉTHODES UTILITAIRES

  void _refreshStatistics() {
    if (_prestataireId != null) {
      context
          .read<ProviderStatisticsBloc>()
          .add(LoadProviderStatistics(_prestataireId!));
    }
  }

  void _loadStatisticsForPeriod(String period) {
    // TODO: Charger les statistiques pour la période sélectionnée
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chargement des statistiques pour $period')),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Exporter en PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Export PDF - En développement')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: Colors.blue),
              title: const Text('Exporter en Excel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Export Excel - En développement')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: Colors.green),
              title: const Text('Partager'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Partage - En développement')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
