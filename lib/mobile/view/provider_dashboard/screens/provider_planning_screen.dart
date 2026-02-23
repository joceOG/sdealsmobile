import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../bloc/planning_bloc.dart';
import '../bloc/planning_event.dart';
import '../bloc/planning_state.dart';
import '../../../../data/services/authCubit.dart';

// 🎯 ÉCRAN PLANNING PRESTATAIRE MAGNIFIQUE
class ProviderPlanningScreen extends StatefulWidget {
  const ProviderPlanningScreen({super.key});

  @override
  State<ProviderPlanningScreen> createState() => _ProviderPlanningScreenState();
}

class _ProviderPlanningScreenState extends State<ProviderPlanningScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _currentView = 'month'; // 'month', 'week', 'day'
  String? _prestataireId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDay = DateTime.now();

    // Récupérer l'ID du prestataire depuis AuthCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _prestataireId = authState.utilisateur.idutilisateur;
      // Charger les prestations du prestataire
      context
          .read<PlanningBloc>()
          .add(LoadPrestationsPlanning(_prestataireId!));
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
      body: BlocBuilder<PlanningBloc, PlanningState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildPlanningHeader(),
              _buildViewSelector(),
              Expanded(
                child: _buildPlanningContent(state),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // 🎨 HEADER DU PLANNING
  Widget _buildPlanningHeader() {
    return Container(
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planning Prestataire',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Gérez vos rendez-vous',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatsButton(),
                ],
              ),
              const SizedBox(height: 16),
              _buildDateSelector(),
            ],
          ),
        ),
      ),
    );
  }

  // 📊 BOUTON STATISTIQUES
  Widget _buildStatsButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            'Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 📅 SÉLECTEUR DE DATE
  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousPeriod,
            icon: Icon(Icons.chevron_left, color: Colors.white),
          ),
          Text(
            _getPeriodText(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: _nextPeriod,
            icon: Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 🔄 SÉLECTEUR DE VUE
  Widget _buildViewSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
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
        onTap: (index) {
          setState(() {
            _currentView = ['month', 'week', 'day'][index];
            _loadPrestationsForView();
          });
        },
        tabs: const [
          Tab(text: 'Mois', icon: Icon(Icons.calendar_view_month)),
          Tab(text: 'Semaine', icon: Icon(Icons.calendar_view_week)),
          Tab(text: 'Jour', icon: Icon(Icons.calendar_today)),
        ],
      ),
    );
  }

  // 📊 CONTENU DU PLANNING
  Widget _buildPlanningContent(PlanningState state) {
    if (state is PlanningLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is PlanningError) {
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
              onPressed: () => _loadPrestationsForView(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state is PlanningLoaded) {
      return _buildPlanningView(state);
    }

    return const Center(
      child: Text('Aucune donnée disponible'),
    );
  }

  // 📅 VUE DU PLANNING
  Widget _buildPlanningView(PlanningLoaded state) {
    switch (_currentView) {
      case 'month':
        return _buildMonthView(state);
      case 'week':
        return _buildWeekView(state);
      case 'day':
        return _buildDayView(state);
      default:
        return _buildMonthView(state);
    }
  }

  // 📅 VUE MOIS
  Widget _buildMonthView(PlanningLoaded state) {
    return Column(
      children: [
        Flexible(
          flex: 3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 300,
              maxHeight: 500,
            ),
            child: SizedBox(
              height: 400,
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  context
                      .read<PlanningBloc>()
                      .add(LoadPrestationsByDate(selectedDay));
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  context
                      .read<PlanningBloc>()
                      .add(LoadMonthlyPrestations(focusedDay));
                },
                eventLoader: (day) {
                  return state.prestations.where((prestation) {
                    final prestationDate =
                        DateTime.parse(prestation['datePrestation']);
                    return isSameDay(prestationDate, day);
                  }).toList();
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red[400]),
                  holidayTextStyle: TextStyle(color: Colors.red[400]),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.green.shade200,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.orange.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon:
                      Icon(Icons.chevron_left, color: Colors.green.shade600),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: Colors.green.shade600),
                ),
              ),
            ),
          ),
        ),
        Flexible(
          flex: 2,
          child: _buildSelectedDayEvents(state),
        ),
      ],
    );
  }

  // 📅 VUE SEMAINE
  Widget _buildWeekView(PlanningLoaded state) {
    return Column(
      children: [
        _buildWeekHeader(),
        Flexible(
          child: _buildWeekGrid(state),
        ),
      ],
    );
  }

  // 📅 VUE JOUR
  Widget _buildDayView(PlanningLoaded state) {
    return Column(
      children: [
        _buildDayHeader(),
        Flexible(
          child: _buildDayTimeline(state),
        ),
      ],
    );
  }

  // 📋 ÉVÉNEMENTS DU JOUR SÉLECTIONNÉ
  Widget _buildSelectedDayEvents(PlanningLoaded state) {
    if (_selectedDay == null) return const SizedBox.shrink();

    final dayEvents = state.prestations.where((prestation) {
      final prestationDate = DateTime.parse(prestation['datePrestation']);
      return isSameDay(prestationDate, _selectedDay!);
    }).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              Icon(Icons.event, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Text(
                'Événements du ${DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDay!)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dayEvents.isEmpty)
            Text(
              'Aucun événement ce jour',
              style: TextStyle(color: Colors.grey[600]),
            )
          else
            ...dayEvents.map((event) => _buildEventCard(event)),
        ],
      ),
    );
  }

  // 🎨 CARTE D'ÉVÉNEMENT
  Widget _buildEventCard(Map<String, dynamic> event) {
    final status = event['statut'] ?? 'EN_ATTENTE';
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event['utilisateur']['nom']} ${event['utilisateur']['prenom']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${event['heureDebut']} - ${event['heureFin']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (event['adresse'] != null)
                  Text(
                    event['adresse'],
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 COULEUR PAR STATUT
  Color _getStatusColor(String status) {
    switch (status) {
      case 'EN_ATTENTE':
        return Colors.orange;
      case 'ACCEPTEE':
        return Colors.blue;
      case 'EN_COURS':
        return Colors.green;
      case 'TERMINEE':
        return Colors.grey;
      case 'REFUSEE':
        return Colors.red;
      case 'ANNULEE':
        return Colors.red.shade300;
      default:
        return Colors.grey;
    }
  }

  // ➕ BOUTON D'ACTION FLOTTANT
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        // TODO: Ajouter une nouvelle prestation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fonctionnalité en développement'),
            backgroundColor: Colors.orange,
          ),
        );
      },
      backgroundColor: Colors.green.shade600,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Nouveau RDV',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 🔄 CHARGER LES PRESTATIONS POUR LA VUE ACTUELLE
  void _loadPrestationsForView() {
    if (_prestataireId == null) return;

    switch (_currentView) {
      case 'month':
        context.read<PlanningBloc>().add(LoadMonthlyPrestations(_focusedDay));
        break;
      case 'week':
        final weekStart =
            _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
        context.read<PlanningBloc>().add(LoadWeeklyPrestations(weekStart));
        break;
      case 'day':
        context.read<PlanningBloc>().add(LoadDailyPrestations(_focusedDay));
        break;
    }
  }

  // ⬅️ PÉRIODE PRÉCÉDENTE
  void _previousPeriod() {
    setState(() {
      switch (_currentView) {
        case 'month':
          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
          break;
        case 'week':
          _focusedDay = _focusedDay.subtract(const Duration(days: 7));
          break;
        case 'day':
          _focusedDay = _focusedDay.subtract(const Duration(days: 1));
          break;
      }
    });
    _loadPrestationsForView();
  }

  // ➡️ PÉRIODE SUIVANTE
  void _nextPeriod() {
    setState(() {
      switch (_currentView) {
        case 'month':
          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
          break;
        case 'week':
          _focusedDay = _focusedDay.add(const Duration(days: 7));
          break;
        case 'day':
          _focusedDay = _focusedDay.add(const Duration(days: 1));
          break;
      }
    });
    _loadPrestationsForView();
  }

  // 📝 TEXTE DE LA PÉRIODE
  String _getPeriodText() {
    switch (_currentView) {
      case 'month':
        return DateFormat('MMMM yyyy', 'fr_FR').format(_focusedDay);
      case 'week':
        final weekStart =
            _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('dd MMM', 'fr_FR').format(weekStart)} - ${DateFormat('dd MMM yyyy', 'fr_FR').format(weekEnd)}';
      case 'day':
        return DateFormat('dd MMMM yyyy', 'fr_FR').format(_focusedDay);
      default:
        return '';
    }
  }

  // 📅 HEADER SEMAINE
  Widget _buildWeekHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.calendar_view_week, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Text(
            'Vue Semaine',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // 📅 GRID SEMAINE
  Widget _buildWeekGrid(PlanningLoaded state) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text('Vue Semaine - En développement'),
      ),
    );
  }

  // 📅 HEADER JOUR
  Widget _buildDayHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Text(
            'Vue Jour',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // 📅 TIMELINE JOUR
  Widget _buildDayTimeline(PlanningLoaded state) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text('Vue Jour - En développement'),
      ),
    );
  }
}
