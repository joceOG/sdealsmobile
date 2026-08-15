import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/provider_statistics_bloc.dart';
import '../bloc/provider_statistics_event.dart';
import '../bloc/provider_statistics_state.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../design_system/design_system.dart';

/// Statistiques prestataire — données réelles `/prestations/stats`.
class ProviderStatisticsScreen extends StatefulWidget {
  final String? prestataireDocId;
  const ProviderStatisticsScreen({super.key, this.prestataireDocId});

  @override
  State<ProviderStatisticsScreen> createState() =>
      _ProviderStatisticsScreenState();
}

class _ProviderStatisticsScreenState extends State<ProviderStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _prestataireId;
  final _money = NumberFormat('#,###', 'fr_FR');
  static const _monthsFr = [
    '',
    'Jan',
    'Fév',
    'Mar',
    'Avr',
    'Mai',
    'Juin',
    'Juil',
    'Aoû',
    'Sep',
    'Oct',
    'Nov',
    'Déc',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _prestataireId =
          widget.prestataireDocId ?? authState.utilisateur.idutilisateur;
      context.read<ProviderStatisticsBloc>().setToken(authState.token);
      if (_prestataireId != null) {
        context
            .read<ProviderStatisticsBloc>()
            .add(LoadProviderStatistics(_prestataireId!));
      }
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
      appBar: AppBar(
        backgroundColor: SDColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: SDColors.neutral900,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: SDColors.neutral900),
        ),
        title: Text(
          'Mes Statistiques',
          style: SDTypography.displayMedium.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showExportOptions,
            icon: const Icon(Icons.download_outlined,
                color: SDColors.neutral900),
          ),
          IconButton(
            onPressed: _refreshStatistics,
            icon: const Icon(Icons.refresh, color: SDColors.neutral900),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: SDColors.neutral200),
        ),
      ),
      body: BlocBuilder<ProviderStatisticsBloc, ProviderStatisticsState>(
        builder: (context, state) {
          if (state is ProviderStatisticsLoading ||
              state is ProviderStatisticsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProviderStatisticsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshStatistics,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! ProviderStatisticsLoaded) {
            return const Center(child: Text('Aucune donnée'));
          }

          return Column(
            children: [
              _buildHeader(state),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                labelColor: SDColors.primary700,
                unselectedLabelColor: SDColors.neutral500,
                indicatorColor: SDColors.primary600,
                tabs: const [
                  Tab(text: 'Revenus'),
                  Tab(text: 'Missions'),
                  Tab(text: 'Villes'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRevenusTab(state),
                    _buildMissionsTab(state),
                    _buildVillesTab(state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ProviderStatisticsLoaded state) {
    final revenue = _asDouble(state.revenus['total']);
    final total = _asInt(state.missions['total'] ??
        state.charts['totalPrestations']);
    final note = _asDouble(state.missions['satisfaction']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SDColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vue d\'ensemble',
            style: SDTypography.titleSmall.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Données serveur (toutes périodes disponibles)',
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerStat(
                'Revenus',
                '${_money.format(revenue.round())} FCFA',
                Icons.monetization_on_outlined,
              ),
              _headerStat(
                'Prestations',
                '$total',
                Icons.assignment_outlined,
              ),
              _headerStat(
                'Note',
                note > 0 ? '${note.toStringAsFixed(1)}/5' : '—',
                Icons.star_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: SDColors.neutral700, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: SDTypography.labelLarge.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style:
                SDTypography.labelSmall.copyWith(color: SDColors.neutral500),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenusTab(ProviderStatisticsLoaded state) {
    final revenue = _asDouble(state.revenus['total']);
    final avg = _asDouble(state.revenus['averagePerMission']);
    final mois = _listOf(state.charts['prestationsParMois']);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Revenus totaux',
                '${_money.format(revenue.round())} FCFA',
                Icons.account_balance_wallet,
                SDColors.primary600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                'Moyenne / mission',
                '${_money.format(avg.round())} FCFA',
                Icons.trending_up,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Prestations par mois',
          child: mois.isEmpty
              ? _emptyChart('Aucune donnée mensuelle')
              : _barList(
                  mois.reversed.map((raw) {
                    final m = Map<String, dynamic>.from(raw as Map);
                    final id = m['_id'];
                    final year = id is Map ? id['year'] : null;
                    final month = id is Map ? _asInt(id['month']) : 0;
                    final label = month >= 1 && month <= 12
                        ? '${_monthsFr[month]} $year'
                        : '$year-$month';
                    return _BarItem(
                      label: label,
                      value: _asDouble(m['totalRevenu']),
                      count: _asInt(m['count']),
                      valueLabel:
                          '${_money.format(_asDouble(m['totalRevenu']).round())} FCFA',
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildMissionsTab(ProviderStatisticsLoaded state) {
    final total = _asInt(state.missions['total']);
    final completed = _asInt(state.missions['completed']);
    final ongoing = _asInt(state.missions['ongoing']);
    final rate = _asDouble(state.missions['successRate']);
    final parStatut = _listOf(state.charts['statsParStatut']);
    final mois = _listOf(state.charts['prestationsParMois']);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Total',
                '$total',
                Icons.assignment,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                'Terminées',
                '$completed',
                Icons.check_circle,
                SDColors.primary600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'En cours / acceptées',
                '$ongoing',
                Icons.timelapse,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                'Taux terminées',
                '${(rate * 100).toStringAsFixed(0)}%',
                Icons.pie_chart,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Répartition par statut',
          child: parStatut.isEmpty
              ? _emptyChart('Aucun statut disponible')
              : _barList(
                  parStatut.map((raw) {
                    final m = Map<String, dynamic>.from(raw as Map);
                    final count = _asInt(m['count']);
                    return _BarItem(
                      label: '${m['_id'] ?? '—'}',
                      value: count.toDouble(),
                      count: count,
                      valueLabel: '$count',
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Volume par mois',
          child: mois.isEmpty
              ? _emptyChart('Aucune donnée mensuelle')
              : _barList(
                  mois.reversed.map((raw) {
                    final m = Map<String, dynamic>.from(raw as Map);
                    final id = m['_id'];
                    final year = id is Map ? id['year'] : null;
                    final month = id is Map ? _asInt(id['month']) : 0;
                    final label = month >= 1 && month <= 12
                        ? '${_monthsFr[month]} $year'
                        : '$year-$month';
                    final count = _asInt(m['count']);
                    return _BarItem(
                      label: label,
                      value: count.toDouble(),
                      count: count,
                      valueLabel: '$count',
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildVillesTab(ProviderStatisticsLoaded state) {
    final villes = _listOf(state.charts['statsParVille']);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Prestations par ville',
          child: villes.isEmpty
              ? _emptyChart('Aucune donnée par ville')
              : _barList(
                  villes.map((raw) {
                    final m = Map<String, dynamic>.from(raw as Map);
                    final count = _asInt(m['count']);
                    final revenu = _asDouble(m['totalRevenu']);
                    return _BarItem(
                      label: (m['_id']?.toString().isNotEmpty == true)
                          ? m['_id'].toString()
                          : 'Non renseignée',
                      value: count.toDouble(),
                      count: count,
                      valueLabel:
                          '$count · ${_money.format(revenu.round())} FCFA',
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _emptyChart(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _barList(List<_BarItem> items) {
    final maxV = items.fold<double>(
      1,
      (a, b) => a > b.value ? a : (b.value > 0 ? b.value : a),
    );
    return Column(
      children: items.map((item) {
        final ratio = (item.value / maxV).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    item.valueLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(SDColors.primary600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _refreshStatistics() {
    if (_prestataireId == null) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) {
      context.read<ProviderStatisticsBloc>().setToken(auth.token);
    }
    context
        .read<ProviderStatisticsBloc>()
        .add(LoadProviderStatistics(_prestataireId!));
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Exporter en PDF'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Export PDF — non disponible'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.blue),
                title: const Text('Exporter en Excel'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Export Excel — non disponible'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<dynamic> _listOf(dynamic v) {
    if (v is List) return v;
    return const [];
  }

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  double _asDouble(dynamic v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }
}

class _BarItem {
  final String label;
  final double value;
  final int count;
  final String valueLabel;

  _BarItem({
    required this.label,
    required this.value,
    required this.count,
    required this.valueLabel,
  });
}
