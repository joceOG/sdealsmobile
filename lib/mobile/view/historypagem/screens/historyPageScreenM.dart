import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../historypageblocm/historyPageBlocM.dart';
import '../historypageblocm/historyPageEventM.dart';
import '../historypageblocm/historyPageStateM.dart';
import '../../../../data/models/history.dart';
import '../../../../design_system/design_system.dart';
import 'historyDetailScreenM.dart';
import '../../common/widgets/unauthenticated_banner.dart';
import '../../../../data/services/authCubit.dart';

class HistoryPageScreenM extends StatefulWidget {
  const HistoryPageScreenM({super.key});

  @override
  State<HistoryPageScreenM> createState() => _HistoryPageScreenMState();
}

class _HistoryPageScreenMState extends State<HistoryPageScreenM>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = '';
  String _selectedStatut = '';
  int _selectedPeriode = 30;
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  final List<String> _typeOptions = [
    'Tous',
    'PRESTATAIRE',
    'VENDEUR',
    'FREELANCE',
    'ARTICLE',
    'SERVICE',
    'PRESTATION',
    'COMMANDE',
    'PAGE',
    'CATEGORIE'
  ];

  final List<String> _statutOptions = ['Tous', 'ACTIVE', 'ARCHIVE', 'SUPPRIME'];

  final List<Map<String, dynamic>> _periodeOptions = [
    {'value': 7, 'label': '7 jours'},
    {'value': 30, 'label': '30 jours'},
    {'value': 90, 'label': '90 jours'},
    {'value': 365, 'label': '1 an'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    context.read<HistoryPageBlocM>().add(LoadHistoryDataM(
          objetType: _selectedType.isEmpty ? null : _selectedType,
          statut: _selectedStatut.isEmpty ? null : _selectedStatut,
          periode: _selectedPeriode,
          page: _currentPage,
          limit: _itemsPerPage,
        ));
  }

  void _searchHistory() {
    if (_searchController.text.isNotEmpty) {
      context.read<HistoryPageBlocM>().add(SearchHistoryM(
            query: _searchController.text,
            objetType: _selectedType.isEmpty ? null : _selectedType,
            periode: _selectedPeriode,
          ));
    } else {
      _loadHistory();
    }
  }

  void _loadStats() {
    context.read<HistoryPageBlocM>().add(LoadHistoryStatsM(
          periode: _selectedPeriode,
        ));
  }

  void _loadRecentHistory() {
    context.read<HistoryPageBlocM>().add(LoadRecentHistoryM(limit: 10));
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'PRESTATAIRE':
        return 'Prestataire';
      case 'VENDEUR':
        return 'Vendeur';
      case 'FREELANCE':
        return 'Freelance';
      case 'ARTICLE':
        return 'Article';
      case 'SERVICE':
        return 'Service';
      case 'PRESTATION':
        return 'Prestation';
      case 'COMMANDE':
        return 'Commande';
      case 'PAGE':
        return 'Page';
      case 'CATEGORIE':
        return 'Catégorie';
      default:
        return type;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'ACTIVE':
        return 'Active';
      case 'ARCHIVE':
        return 'Archivée';
      case 'SUPPRIME':
        return 'Supprimée';
      default:
        return statut;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'PRESTATAIRE':
        return SDColors.info500;
      case 'VENDEUR':
        return SDColors.success500;
      case 'FREELANCE':
        return SDColors.warning500;
      case 'ARTICLE':
        return Colors.purple; // TODO: Add to SDColors if missing, or use primary
      case 'SERVICE':
        return SDColors.error500;
      case 'PRESTATION':
        return Colors.teal; // TODO: Add to SDColors
      case 'COMMANDE':
        return Colors.brown; // TODO: Add to SDColors
      case 'PAGE':
        return SDColors.neutral500;
      case 'CATEGORIE':
        return Colors.pink; // TODO: Add to SDColors
      default:
        return SDColors.neutral500;
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'ACTIVE':
        return SDColors.success500;
      case 'ARCHIVE':
        return SDColors.warning500;
      case 'SUPPRIME':
        return SDColors.error500;
      default:
        return SDColors.neutral500;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const UnauthenticatedBanner(
        appBarTitle: 'Historique',
        icon: Icons.history_rounded,
        title: 'Votre historique',
        description: 'Connectez-vous pour retrouver tous vos achats, consultations de services et activités passées.',
      );
    }

    return Scaffold(
      appBar: SDWhiteAppBar.appBar(
        title: 'Historique des consultations',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadHistory();
              _loadStats();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: SDColors.primary700,
          unselectedLabelColor: SDColors.neutral500,
          indicatorColor: SDColors.primary600,
          indicatorWeight: 3,
          dividerColor: SDColors.neutral200,
          tabs: const [
            Tab(text: 'Toutes', icon: Icon(Icons.history)),
            Tab(text: 'Récentes', icon: Icon(Icons.schedule)),
            Tab(text: 'Statistiques', icon: Icon(Icons.analytics_outlined)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔍 BARRE DE RECHERCHE ET FILTRES
          Container(
            padding: EdgeInsets.all(SDSpacing.md),
            color: SDColors.neutral100,
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans l\'historique...',
                    hintStyle: SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadHistory();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    ),
                    filled: true,
                    fillColor: SDColors.white,
                  ),
                  onSubmitted: (_) => _searchHistory(),
                ),
                const SizedBox(height: 12),
                // Filtres
                Wrap(
                  spacing: SDSpacing.xxs,
                  runSpacing: SDSpacing.xs,
                  children: [
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedType.isEmpty ? null : _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: _typeOptions.map((type) {
                          return DropdownMenuItem<String>(
                            value: type == 'Tous' ? '' : type,
                            child: Text(type == 'Tous'
                                ? 'Tous les types'
                                : _getTypeLabel(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value ?? '';
                          });
                          _loadHistory();
                        },
                      ),
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatut.isEmpty ? null : _selectedStatut,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: _statutOptions.map((statut) {
                          return DropdownMenuItem<String>(
                            value: statut == 'Tous' ? '' : statut,
                            child: Text(statut == 'Tous'
                                ? 'Tous les statuts'
                                : _getStatutLabel(statut)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatut = value ?? '';
                          });
                          _loadHistory();
                        },
                      ),
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 3,
                      child: DropdownButtonFormField<int>(
                        value: _selectedPeriode,
                        decoration: const InputDecoration(
                          labelText: 'Période',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: _periodeOptions.map((periode) {
                          return DropdownMenuItem<int>(
                            value: periode['value'],
                            child: Text(periode['label']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPeriode = value ?? 30;
                          });
                          _loadHistory();
                          _loadStats();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 📋 CONTENU PRINCIPAL
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryList(),
                _buildRecentHistoryList(),
                _buildStatsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return BlocBuilder<HistoryPageBlocM, HistoryPageStateM>(
      builder: (context, state) {
        if (state is HistoryPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is HistoryPageErrorM) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: SDColors.error500.withOpacity(0.5)),
                SizedBox(height: SDSpacing.md),
                Text(
                  'Erreur: ${state.message}',
                  style: SDTypography.bodyMedium.copyWith(color: SDColors.error500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: SDSpacing.md),
                ElevatedButton(
                  onPressed: _loadHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SDColors.primary600,
                    foregroundColor: SDColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                    ),
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        } else if (state is HistoryPageLoadedM) {
          if (state.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: SDColors.neutral300),
                  SizedBox(height: SDSpacing.md),
                  Text(
                    'Aucune consultation trouvée',
                    style: SDTypography.bodyLarge.copyWith(color: SDColors.neutral500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.history.length,
            itemBuilder: (context, index) {
              final history = state.history[index];
              return _buildHistoryCard(history);
            },
          );
        } else if (state is HistorySearchedM) {
          if (state.searchResults.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun résultat trouvé',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.searchResults.length,
            itemBuilder: (context, index) {
              final history = state.searchResults[index];
              return _buildHistoryCard(history);
            },
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildRecentHistoryList() {
    return BlocBuilder<HistoryPageBlocM, HistoryPageStateM>(
      builder: (context, state) {
        if (state is HistoryPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RecentHistoryLoadedM) {
          if (state.recentHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 64, color: SDColors.neutral300),
                  SizedBox(height: SDSpacing.md),
                  Text(
                    'Aucune consultation récente',
                    style: SDTypography.bodyLarge.copyWith(color: SDColors.neutral500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.recentHistory.length,
            itemBuilder: (context, index) {
              final history = state.recentHistory[index];
              return _buildHistoryCard(history);
            },
          );
        }

        // Charger les consultations récentes si pas encore chargées
        if (state is! RecentHistoryLoadedM) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadRecentHistory();
          });
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildStatsView() {
    return BlocBuilder<HistoryPageBlocM, HistoryPageStateM>(
      builder: (context, state) {
        if (state is HistoryPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is HistoryStatsLoadedM) {
          final stats = state.stats;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistiques générales
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistiques Générales',
                          style: SDTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Consultations',
                                '${stats['totalConsultations'] ?? 0}',
                                Icons.history,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'Consultations Récentes',
                                '${stats['consultationsRecentes'] ?? 0}',
                                Icons.schedule,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Temps Total',
                                '${stats['tempsTotal'] ?? 0}s',
                                Icons.timer,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'Période',
                                '${_selectedPeriode} jours',
                                Icons.calendar_today,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                  const SizedBox(height: 16),
                // Consultations par type
                if (stats['consultationsParType'] != null)
                  Card(
                    color: SDColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
                      side: BorderSide(color: SDColors.neutral200),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(SDSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consultations par Type',
                            style: SDTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: SDSpacing.md),
                          ...((stats['consultationsParType'] as List)
                              .map((item) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: SDSpacing.xxs),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_getTypeLabel(item['type'] ?? ''), style: SDTypography.bodyMedium),
                                  Chip(
                                    label: Text('${item['count'] ?? 0}'),
                                    backgroundColor:
                                        _getTypeColor(item['type'] ?? ''),
                                    labelStyle:
                                        SDTypography.labelSmall.copyWith(color: SDColors.white),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            );
                          }).toList()),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        // Charger les statistiques si pas encore chargées
        if (state is! HistoryStatsLoadedM) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadStats();
          });
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(SDSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: SDSpacing.xs),
          Text(
            value,
            style: SDTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: SDSpacing.xxs),
          Text(
            title,
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(History history) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SDSpacing.borderRadiusMedium),
        side: BorderSide(color: SDColors.neutral200),
      ),
      margin: EdgeInsets.symmetric(horizontal: SDSpacing.md, vertical: SDSpacing.xxs),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: SDSpacing.md, vertical: SDSpacing.xs),
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(history.objetType),
          child: Text(
            history.objetType[0],
            style: SDTypography.titleSmall.copyWith(
                color: SDColors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          history.titre,
          style: SDTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTypeLabel(history.objetType),
              style: SDTypography.bodySmall.copyWith(color: _getTypeColor(history.objetType)),
            ),
            SizedBox(height: SDSpacing.xxs),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: SDColors.neutral500),
                SizedBox(width: SDSpacing.xxxs),
                Text(
                  history.dureeFormatee,
                  style: SDTypography.labelSmall.copyWith(color: SDColors.neutral500),
                ),
                SizedBox(width: SDSpacing.md),
                Icon(Icons.visibility, size: 14, color: SDColors.neutral500),
                SizedBox(width: SDSpacing.xxxs),
                Text(
                  '${history.nombreVues}',
                  style: SDTypography.labelSmall.copyWith(color: SDColors.neutral500),
                ),
              ],
            ),
            SizedBox(height: SDSpacing.xxxs),
            Text(
              _formatDate(history.dateConsultation),
              style: SDTypography.labelSmall.copyWith(color: SDColors.neutral500),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              label: Text(
                _getStatutLabel(history.statut),
                style: SDTypography.labelSmall.copyWith(fontSize: 10),
              ),
              backgroundColor: _getStatutColor(history.statut).withOpacity(0.1),
              labelStyle: SDTypography.labelSmall.copyWith(color: _getStatutColor(history.statut)),
              side: BorderSide.none,
            ),
            if (history.estRecent)
              Container(
                margin: EdgeInsets.only(top: SDSpacing.xxxs),
                padding: EdgeInsets.symmetric(horizontal: SDSpacing.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: SDColors.success500,
                  borderRadius: BorderRadius.circular(SDSpacing.borderRadiusSmall),
                ),
                child: Text(
                  'RÉCENT',
                  style: SDTypography.labelSmall.copyWith(
                    color: SDColors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => HistoryPageBlocM(),
                child: HistoryDetailScreenM(history: history),
              ),
            ),
          );
        },
      ),
    );
  }
}
