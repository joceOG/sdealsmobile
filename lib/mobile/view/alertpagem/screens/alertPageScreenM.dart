import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../alertpageblocm/alertPageBlocM.dart';
import '../alertpageblocm/alertPageEventM.dart';
import '../alertpageblocm/alertPageStateM.dart';
import '../../../../data/models/alert.dart';
import 'alertDetailScreenM.dart';
import 'createAlertScreenM.dart';
import 'alertSettingsScreenM.dart';

class AlertPageScreenM extends StatefulWidget {
  const AlertPageScreenM({super.key});

  @override
  State<AlertPageScreenM> createState() => _AlertPageScreenMState();
}

class _AlertPageScreenMState extends State<AlertPageScreenM>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = '';
  String _selectedStatut = '';
  String _selectedPriorite = '';
  int _selectedPeriode = 30;
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  final List<String> _typeOptions = [
    'Tous',
    'COMMANDE',
    'PRESTATION',
    'PAIEMENT',
    'VERIFICATION',
    'MESSAGE',
    'SYSTEME',
    'PROMOTION',
    'RAPPEL'
  ];

  final List<String> _statutOptions = ['Tous', 'NON_LUE', 'LUE', 'ARCHIVEE'];

  final List<String> _prioriteOptions = [
    'Tous',
    'BASSE',
    'NORMALE',
    'HAUTE',
    'CRITIQUE'
  ];

  final List<Map<String, dynamic>> _periodeOptions = [
    {'value': 7, 'label': '7 jours'},
    {'value': 30, 'label': '30 jours'},
    {'value': 90, 'label': '90 jours'},
    {'value': 365, 'label': '1 an'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadAlerts() {
    context.read<AlertPageBlocM>().add(LoadAlertsDataM(
          type: _selectedType.isEmpty ? null : _selectedType,
          statut: _selectedStatut.isEmpty ? null : _selectedStatut,
          priorite: _selectedPriorite.isEmpty ? null : _selectedPriorite,
          periode: _selectedPeriode,
          page: _currentPage,
          limit: _itemsPerPage,
        ));
  }

  void _searchAlerts() {
    if (_searchController.text.isNotEmpty) {
      context.read<AlertPageBlocM>().add(SearchAlertsM(
            query: _searchController.text,
            type: _selectedType.isEmpty ? null : _selectedType,
            priorite: _selectedPriorite.isEmpty ? null : _selectedPriorite,
            periode: _selectedPeriode,
          ));
    } else {
      _loadAlerts();
    }
  }

  void _loadStats() {
    context.read<AlertPageBlocM>().add(LoadAlertStatsM(
          periode: _selectedPeriode,
        ));
  }

  void _loadUnreadAlerts() {
    context.read<AlertPageBlocM>().add(LoadUnreadAlertsM(limit: 10));
  }

  void _loadUrgentAlerts() {
    context.read<AlertPageBlocM>().add(LoadUrgentAlertsM(limit: 10));
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'COMMANDE':
        return 'Commande';
      case 'PRESTATION':
        return 'Prestation';
      case 'PAIEMENT':
        return 'Paiement';
      case 'VERIFICATION':
        return 'Vérification';
      case 'MESSAGE':
        return 'Message';
      case 'SYSTEME':
        return 'Système';
      case 'PROMOTION':
        return 'Promotion';
      case 'RAPPEL':
        return 'Rappel';
      default:
        return type;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'NON_LUE':
        return 'Non lue';
      case 'LUE':
        return 'Lue';
      case 'ARCHIVEE':
        return 'Archivée';
      default:
        return statut;
    }
  }

  String _getPrioriteLabel(String priorite) {
    switch (priorite) {
      case 'BASSE':
        return 'Basse';
      case 'NORMALE':
        return 'Normale';
      case 'HAUTE':
        return 'Haute';
      case 'CRITIQUE':
        return 'Critique';
      default:
        return priorite;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'COMMANDE':
        return Colors.blue;
      case 'PRESTATION':
        return Colors.green;
      case 'PAIEMENT':
        return Colors.orange;
      case 'VERIFICATION':
        return Colors.purple;
      case 'MESSAGE':
        return Colors.teal;
      case 'SYSTEME':
        return Colors.grey;
      case 'PROMOTION':
        return Colors.pink;
      case 'RAPPEL':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _getPrioriteColor(String priorite) {
    switch (priorite) {
      case 'BASSE':
        return Colors.green;
      case 'NORMALE':
        return Colors.blue;
      case 'HAUTE':
        return Colors.orange;
      case 'CRITIQUE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Alertes'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => AlertPageBlocM(),
                    child: const AlertSettingsScreenM(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadAlerts();
              _loadStats();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Toutes', icon: Icon(Icons.notifications)),
            Tab(text: 'Non lues', icon: Icon(Icons.mark_email_unread)),
            Tab(text: 'Urgentes', icon: Icon(Icons.priority_high)),
            Tab(text: 'Statistiques', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔍 BARRE DE RECHERCHE ET FILTRES
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans les alertes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadAlerts();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _searchAlerts(),
                ),
                const SizedBox(height: 12),
                // Filtres
                Wrap(
                  spacing: 4,
                  runSpacing: 8,
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
                          _loadAlerts();
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
                          _loadAlerts();
                        },
                      ),
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedPriorite.isEmpty
                            ? null
                            : _selectedPriorite,
                        decoration: const InputDecoration(
                          labelText: 'Priorité',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: _prioriteOptions.map((priorite) {
                          return DropdownMenuItem<String>(
                            value: priorite == 'Tous' ? '' : priorite,
                            child: Text(priorite == 'Tous'
                                ? 'Toutes les priorités'
                                : _getPrioriteLabel(priorite)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPriorite = value ?? '';
                          });
                          _loadAlerts();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
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
                          _loadAlerts();
                          _loadStats();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: _searchAlerts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Filtrer'),
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
                _buildAlertsList(),
                _buildUnreadAlertsList(),
                _buildUrgentAlertsList(),
                _buildStatsView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => AlertPageBlocM(),
                child: const CreateAlertScreenM(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAlertsList() {
    return BlocBuilder<AlertPageBlocM, AlertPageStateM>(
      builder: (context, state) {
        if (state is AlertPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AlertPageErrorM) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${state.message}',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAlerts,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        } else if (state is AlertPageLoadedM) {
          if (state.alerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune alerte trouvée',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.alerts.length,
            itemBuilder: (context, index) {
              final alert = state.alerts[index];
              return _buildAlertCard(alert);
            },
          );
        } else if (state is AlertsSearchedM) {
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
              final alert = state.searchResults[index];
              return _buildAlertCard(alert);
            },
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildUnreadAlertsList() {
    return BlocBuilder<AlertPageBlocM, AlertPageStateM>(
      builder: (context, state) {
        if (state is AlertPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is UnreadAlertsLoadedM) {
          if (state.unreadAlerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mark_email_read, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune alerte non lue',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.unreadAlerts.length,
            itemBuilder: (context, index) {
              final alert = state.unreadAlerts[index];
              return _buildAlertCard(alert);
            },
          );
        }

        // Charger les alertes non lues si pas encore chargées
        if (state is! UnreadAlertsLoadedM) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadUnreadAlerts();
          });
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildUrgentAlertsList() {
    return BlocBuilder<AlertPageBlocM, AlertPageStateM>(
      builder: (context, state) {
        if (state is AlertPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is UrgentAlertsLoadedM) {
          if (state.urgentAlerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.priority_high, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune alerte urgente',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.urgentAlerts.length,
            itemBuilder: (context, index) {
              final alert = state.urgentAlerts[index];
              return _buildAlertCard(alert);
            },
          );
        }

        // Charger les alertes urgentes si pas encore chargées
        if (state is! UrgentAlertsLoadedM) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadUrgentAlerts();
          });
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildStatsView() {
    return BlocBuilder<AlertPageBlocM, AlertPageStateM>(
      builder: (context, state) {
        if (state is AlertPageLoadingM) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AlertStatsLoadedM) {
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
                        const Text(
                          'Statistiques Générales',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Alertes',
                                '${stats['totalNotifications'] ?? 0}',
                                Icons.notifications,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'Non lues',
                                '${stats['unreadNotifications'] ?? 0}',
                                Icons.mark_email_unread,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Lues',
                                '${stats['readNotifications'] ?? 0}',
                                Icons.mark_email_read,
                                Colors.green,
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
                // Alertes par type
                if (stats['statsParType'] != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alertes par Type',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ...((stats['statsParType'] as List).map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_getTypeLabel(item['_id'] ?? '')),
                                  Chip(
                                    label: Text('${item['count'] ?? 0}'),
                                    backgroundColor:
                                        _getTypeColor(item['_id'] ?? ''),
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
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
        if (state is! AlertStatsLoadedM) {
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(alert.type),
          child: Icon(
            _getTypeIcon(alert.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          alert.titre,
          style: TextStyle(
            fontWeight: alert.estNonLue ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    alert.typeLabel,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: _getTypeColor(alert.type).withOpacity(0.2),
                  labelStyle: TextStyle(color: _getTypeColor(alert.type)),
                ),
                const SizedBox(width: 4),
                Chip(
                  label: Text(
                    alert.prioriteLabel,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor:
                      _getPrioriteColor(alert.priorite).withOpacity(0.2),
                  labelStyle:
                      TextStyle(color: _getPrioriteColor(alert.priorite)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              alert.dateFormatee,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (alert.estNonLue)
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            if (alert.estUrgente)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'URGENT',
                  style: TextStyle(
                    color: Colors.white,
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
                create: (context) => AlertPageBlocM(),
                child: AlertDetailScreenM(alert: alert),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'COMMANDE':
        return Icons.shopping_cart;
      case 'PRESTATION':
        return Icons.work;
      case 'PAIEMENT':
        return Icons.payment;
      case 'VERIFICATION':
        return Icons.verified;
      case 'MESSAGE':
        return Icons.message;
      case 'SYSTEME':
        return Icons.settings;
      case 'PROMOTION':
        return Icons.local_offer;
      case 'RAPPEL':
        return Icons.schedule;
      default:
        return Icons.notifications;
    }
  }
}
