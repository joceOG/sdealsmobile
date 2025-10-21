import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/soutrapay_bloc.dart';
import '../bloc/soutrapay_event.dart';
import '../bloc/soutrapay_state.dart';
import '../../../../data/services/authCubit.dart';

// 🎯 ÉCRAN SOUTRAPAY PRESTATAIRE MAGNIFIQUE
class ProviderSoutraPayScreen extends StatefulWidget {
  const ProviderSoutraPayScreen({super.key});

  @override
  State<ProviderSoutraPayScreen> createState() =>
      _ProviderSoutraPayScreenState();
}

class _ProviderSoutraPayScreenState extends State<ProviderSoutraPayScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _prestataireId;
  final TextEditingController _withdrawalController = TextEditingController();
  String _selectedWithdrawalMethod = 'bank';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Récupérer l'ID du prestataire depuis AuthCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _prestataireId = authState.utilisateur.idutilisateur;
      // Charger les données SoutraPay
      context
          .read<SoutraPayBloc>()
          .add(LoadPrestataireBalance(_prestataireId!));
      context.read<SoutraPayBloc>().add(LoadSoutraPayStats(_prestataireId!));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _withdrawalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildSoutraPayAppBar(),
      body: BlocBuilder<SoutraPayBloc, SoutraPayState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildBalanceCard(state),
              _buildTabSelector(),
              Expanded(
                child: _buildSoutraPayContent(state),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // 🎨 APP BAR SOUTRAPAY
  PreferredSizeWidget _buildSoutraPayAppBar() {
    return AppBar(
      backgroundColor: Colors.green.shade600,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'SoutraPay',
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
          onPressed: () => _refreshBalance(),
          icon: Icon(Icons.refresh, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 💰 CARTE DE SOLDE
  Widget _buildBalanceCard(SoutraPayState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade600,
            Colors.green.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Solde SoutraPay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Actif',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (state is BalanceLoaded) ...[
              Text(
                '${NumberFormat('#,##0', 'fr_FR').format(state.currentBalance)} FCFA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Solde disponible',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildBalanceInfo(
                      'En attente',
                      '${NumberFormat('#,##0', 'fr_FR').format(state.pendingAmount)} FCFA',
                      Icons.schedule,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBalanceInfo(
                      'Total gagné',
                      '${NumberFormat('#,##0', 'fr_FR').format(state.totalEarnings)} FCFA',
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),
            ] else if (state is SoutraPayLoading) ...[
              const SizedBox(height: 20),
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ] else ...[
              Text(
                '0 FCFA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 📊 INFORMATIONS DE SOLDE
  Widget _buildBalanceInfo(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Portefeuille', icon: Icon(Icons.account_balance_wallet)),
          Tab(text: 'Historique', icon: Icon(Icons.history)),
          Tab(text: 'Statistiques', icon: Icon(Icons.analytics)),
        ],
      ),
    );
  }

  // 📊 CONTENU SOUTRAPAY
  Widget _buildSoutraPayContent(SoutraPayState state) {
    if (state is SoutraPayLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is SoutraPayError) {
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
              onPressed: () => _refreshBalance(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildWalletTab(state),
        _buildHistoryTab(state),
        _buildStatsTab(state),
      ],
    );
  }

  // 💰 ONGLET PORTEFEUILLE
  Widget _buildWalletTab(SoutraPayState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuickActions(),
          const SizedBox(height: 20),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  // 📈 ONGLET HISTORIQUE
  Widget _buildHistoryTab(SoutraPayState state) {
    if (state is TransactionHistoryLoaded) {
      if (state.transactions.isEmpty) {
        return _buildEmptyState(
          icon: Icons.history,
          title: 'Aucune transaction',
          subtitle: 'Vous n\'avez pas encore de transactions',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.transactions.length,
        itemBuilder: (context, index) {
          final transaction = state.transactions[index];
          return _buildTransactionCard(transaction);
        },
      );
    }

    return const Center(child: Text('Chargement...'));
  }

  // 📊 ONGLET STATISTIQUES
  Widget _buildStatsTab(SoutraPayState state) {
    if (state is SoutraPayStatsLoaded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatsCards(state.stats),
            const SizedBox(height: 20),
            _buildMonthlyChart(state.monthlyEarnings),
            const SizedBox(height: 20),
            _buildTopMissions(state.topMissions),
          ],
        ),
      );
    }

    return const Center(child: Text('Chargement...'));
  }

  // ⚡ ACTIONS RAPIDES
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Retirer',
                  Icons.money_off,
                  Colors.orange,
                  () => _showWithdrawalDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Historique',
                  Icons.history,
                  Colors.blue,
                  () => _tabController.animateTo(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Statistiques',
                  Icons.analytics,
                  Colors.purple,
                  () => _tabController.animateTo(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Actualiser',
                  Icons.refresh,
                  Colors.green,
                  () => _refreshBalance(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🎯 BOUTON D'ACTION
  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📋 TRANSACTIONS RÉCENTES
  Widget _buildRecentTransactions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Transactions récentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Simulation de transactions récentes
          ...List.generate(
              3,
              (index) => _buildTransactionItem(
                    'Paiement mission #${1000 + index}',
                    '${NumberFormat('#,##0', 'fr_FR').format(800 + index * 200)} FCFA',
                    Icons.arrow_downward,
                    Colors.green,
                    DateTime.now().subtract(Duration(hours: index + 1)),
                  )),
        ],
      ),
    );
  }

  // 📄 ÉLÉMENT DE TRANSACTION
  Widget _buildTransactionItem(
      String title, String amount, IconData icon, Color color, DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(date),
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
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 💳 CARTE DE TRANSACTION
  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? 'income';
    final amount = transaction['amount'] as double;
    final description = transaction['description'] ?? '';
    final date = DateTime.parse(transaction['date']);
    final status = transaction['status'] ?? 'completed';

    Color color;
    IconData icon;

    switch (type) {
      case 'income':
        color = Colors.green;
        icon = Icons.arrow_downward;
        break;
      case 'withdrawal':
        color = Colors.orange;
        icon = Icons.arrow_upward;
        break;
      case 'fee':
        color = Colors.red;
        icon = Icons.remove;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'completed'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status == 'completed' ? 'Terminé' : 'En attente',
                        style: TextStyle(
                          fontSize: 10,
                          color: status == 'completed'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${type == 'income' ? '+' : '-'}${NumberFormat('#,##0', 'fr_FR').format(amount)} FCFA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 📊 CARTES DE STATISTIQUES
  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Ce mois',
          '${NumberFormat('#,##0', 'fr_FR').format(stats['thisMonth'])} FCFA',
          Icons.calendar_month,
          Colors.blue,
        ),
        _buildStatCard(
          'Total gagné',
          '${NumberFormat('#,##0', 'fr_FR').format(stats['totalEarnings'])} FCFA',
          Icons.trending_up,
          Colors.green,
        ),
        _buildStatCard(
          'Moyenne/mission',
          '${NumberFormat('#,##0', 'fr_FR').format(stats['averagePerMission'])} FCFA',
          Icons.analytics,
          Colors.orange,
        ),
        _buildStatCard(
          'Taux de réussite',
          '${stats['completionRate'].toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.purple,
        ),
      ],
    );
  }

  // 📊 CARTE DE STATISTIQUE
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // 📈 GRAPHIQUE MENSUEL
  Widget _buildMonthlyChart(List<dynamic> monthlyEarnings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenus mensuels',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          // Simulation d'un graphique simple
          Container(
            height: 200,
            child: Center(
              child: Text(
                'Graphique en développement',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🏆 MEILLEURES MISSIONS
  Widget _buildTopMissions(List<dynamic> topMissions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meilleures missions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ...topMissions.map((mission) => _buildTopMissionItem(mission)),
        ],
      ),
    );
  }

  // 🏆 ÉLÉMENT DE MEILLEURE MISSION
  Widget _buildTopMissionItem(Map<String, dynamic> mission) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.work, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission['title'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      mission['rating'].toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${NumberFormat('#,##0', 'fr_FR').format(mission['amount'])} FCFA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // 📭 ÉTAT VIDE
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ➕ BOUTON D'ACTION FLOTTANT
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showWithdrawalDialog(),
      backgroundColor: Colors.green.shade600,
      icon: const Icon(Icons.money_off, color: Colors.white),
      label: const Text(
        'Retirer des fonds',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 🔧 MÉTHODES UTILITAIRES

  // 🔄 ACTUALISER LE SOLDE
  void _refreshBalance() {
    if (_prestataireId != null) {
      context.read<SoutraPayBloc>().add(RefreshBalance(_prestataireId!));
    }
  }

  // 💰 DIALOGUE DE RETRAIT
  void _showWithdrawalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demander un retrait'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _withdrawalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedWithdrawalMethod,
              decoration: const InputDecoration(
                labelText: 'Méthode de retrait',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'bank', child: Text('Virement bancaire')),
                DropdownMenuItem(
                    value: 'mobile_money', child: Text('Mobile Money')),
                DropdownMenuItem(
                    value: 'cash', child: Text('Retrait en espèces')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedWithdrawalMethod = value!;
                });
              },
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
              final amount = double.tryParse(_withdrawalController.text);
              if (amount != null && amount > 0 && _prestataireId != null) {
                context.read<SoutraPayBloc>().add(
                      RequestWithdrawal(
                          _prestataireId!, amount, _selectedWithdrawalMethod),
                    );
                Navigator.pop(context);
                _withdrawalController.clear();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demande de retrait envoyée'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
