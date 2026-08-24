import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../bloc/planning_bloc.dart';
import '../bloc/planning_event.dart';
import '../bloc/planning_state.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';

/// Écran Planning prestataire — layout type Figma (KPI + timeline + légende).
class ProviderPlanningScreen extends StatefulWidget {
  final String? prestataireDocId;

  const ProviderPlanningScreen({super.key, this.prestataireDocId});

  @override
  ProviderPlanningScreenState createState() => ProviderPlanningScreenState();
}

class ProviderPlanningScreenState extends State<ProviderPlanningScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  /// day | week | month — défaut = jour (Figma)
  String _currentView = 'day';
  String? _prestataireId;
  final ApiClient _apiClient = ApiClient();

  static const double _calendarLayoutHeight = 400.0;
  static const List<String> _jourLabels = [
    'Dimanche',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
  ];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<PlanningBloc>().setToken(authState.token);
      _prestataireId = widget.prestataireDocId;
      // Attendre le vrai docId prestataire (pas l’userId) — sinon 404 API.
      if (_prestataireId != null && _prestataireId!.isNotEmpty) {
        context.read<PlanningBloc>().setPrestataireId(_prestataireId!);
        context
            .read<PlanningBloc>()
            .add(LoadPrestationsPlanning(_prestataireId!));
      }
    }
  }

  @override
  void didUpdateWidget(covariant ProviderPlanningScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextId = widget.prestataireDocId;
    if (nextId != null &&
        nextId.isNotEmpty &&
        nextId != oldWidget.prestataireDocId) {
      _prestataireId = nextId;
      context.read<PlanningBloc>().setPrestataireId(nextId);
      context.read<PlanningBloc>().add(LoadPrestationsPlanning(nextId));
    }
  }

  /// AppBar parent — revenir à aujourd’hui.
  void goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
      _currentView = 'day';
    });
    _reloadPlanning();
  }

  /// AppBar parent — disponibilités.
  void openDisponibilites() => _showDisponibilitesSheet();

  Future<void> _showDisponibilitesSheet() async {
    final id = _prestataireId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil prestataire introuvable')),
      );
      return;
    }

    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expirée — reconnectez-vous')),
      );
      return;
    }

    List<Map<String, dynamic>> creneaux = [];
    try {
      final response =
          await _apiClient.get('/prestataire/$id', token: auth.token);
      if (response.statusCode == 200) {
        final data = ApiClient.decodeJson(response);
        if (data is Map && data['creneaux'] is List) {
          creneaux = (data['creneaux'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SDColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _CreneauxEditorSheet(
          initialCreneaux: creneaux,
          jourLabels: _jourLabels,
          onSave: (updated) => _saveCreneaux(updated),
        );
      },
    );
  }

  Future<bool> _saveCreneaux(List<Map<String, dynamic>> creneaux) async {
    final id = _prestataireId;
    final auth = context.read<AuthCubit>().state;
    if (id == null || id.isEmpty || auth is! AuthAuthenticated) return false;

    try {
      final response = await _apiClient.put(
        '/prestataire/$id',
        body: {
          'creneaux': creneaux
              .map((c) => {
                    'jour': c['jour'],
                    'heureDebut': c['heureDebut'],
                    'heureFin': c['heureFin'],
                    'actif': c['actif'] != false,
                  })
              .toList(),
        },
        token: auth.token,
      );
      if (!mounted) return false;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Créneaux enregistrés')),
        );
        return true;
      }
      String message = 'Impossible d\'enregistrer les créneaux';
      try {
        final data = ApiClient.decodeJson(response);
        if (data is Map && (data['error'] != null || data['message'] != null)) {
          message = (data['error'] ?? data['message']).toString();
        }
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    }
  }

  void _reloadPlanning() {
    if (_prestataireId == null || _prestataireId!.isEmpty) return;
    context
        .read<PlanningBloc>()
        .add(LoadPrestationsPlanning(_prestataireId!));
  }

  void _loadPrestationsForView() {
    // Toujours le endpoint prestataire authentifié ; le filtre jour/semaine/mois
    // est appliqué côté UI (évite /prestations?date… sans filtre prestataire).
    _reloadPlanning();
  }

  void _previousPeriod() {
    setState(() {
      switch (_currentView) {
        case 'month':
          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
          break;
        case 'week':
          _focusedDay = _focusedDay.subtract(const Duration(days: 7));
          _selectedDay = _focusedDay;
          break;
        case 'day':
        default:
          _selectedDay = _selectedDay.subtract(const Duration(days: 1));
          _focusedDay = _selectedDay;
          break;
      }
    });
    _loadPrestationsForView();
  }

  void _nextPeriod() {
    setState(() {
      switch (_currentView) {
        case 'month':
          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
          break;
        case 'week':
          _focusedDay = _focusedDay.add(const Duration(days: 7));
          _selectedDay = _focusedDay;
          break;
        case 'day':
        default:
          _selectedDay = _selectedDay.add(const Duration(days: 1));
          _focusedDay = _selectedDay;
          break;
      }
    });
    _loadPrestationsForView();
  }

  String _periodLabel() {
    switch (_currentView) {
      case 'month':
        return DateFormat('MMMM yyyy', 'fr_FR').format(_focusedDay);
      case 'week':
        final weekStart =
            _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('dd MMM', 'fr_FR').format(weekStart)} – ${DateFormat('dd MMM yyyy', 'fr_FR').format(weekEnd)}';
      case 'day':
      default:
        return DateFormat('EEEE d MMM. yyyy', 'fr_FR').format(_selectedDay);
    }
  }

  List<dynamic> _prestationsForDay(List<dynamic> all, DateTime day) {
    return all.where((p) {
      final raw = p['datePrestation'] ?? p['createdAt'];
      final d = DateTime.tryParse('$raw');
      if (d == null) return false;
      return isSameDay(d.toLocal(), day);
    }).toList();
  }

  List<dynamic> _prestationsForWeek(List<dynamic> all, DateTime day) {
    final start = day.subtract(Duration(days: day.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return all.where((p) {
      final raw = p['datePrestation'] ?? p['createdAt'];
      final d = DateTime.tryParse('$raw');
      if (d == null) return false;
      final local = d.toLocal();
      return !local.isBefore(start) && local.isBefore(end);
    }).toList();
  }

  Duration _missionDuration(Map<String, dynamic> p) {
    final start = _parseTime(p['heureDebut']);
    final end = _parseTime(p['heureFin']);
    if (start == null || end == null) return const Duration(hours: 1);
    var mins = end.difference(start).inMinutes;
    if (mins <= 0) mins = 60;
    return Duration(minutes: mins);
  }

  DateTime? _parseTime(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final base = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    return base.add(Duration(hours: h, minutes: m));
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m.toString().padLeft(2, '0')}';
  }

  _MissionVisual _visualForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'EN_COURS':
        return _MissionVisual(
          accent: const Color(0xFF3B82F6),
          bg: const Color(0xFFEFF6FF),
          label: 'En cours',
        );
      case 'ACCEPTEE':
      case 'CONFIRMEE':
        return _MissionVisual(
          accent: SDColors.primary600,
          bg: const Color(0xFFECFDF5),
          label: 'Confirmée',
        );
      case 'EN_ATTENTE':
        return _MissionVisual(
          accent: const Color(0xFF8B5CF6),
          bg: const Color(0xFFF5F3FF),
          label: 'À confirmer',
        );
      case 'TERMINEE':
        return _MissionVisual(
          accent: SDColors.neutral500,
          bg: SDColors.neutral100,
          label: 'Terminée',
        );
      case 'PAUSE':
        return _MissionVisual(
          accent: SDColors.neutral400,
          bg: SDColors.neutral100,
          label: 'Pause',
        );
      default:
        return _MissionVisual(
          accent: SDColors.neutral500,
          bg: SDColors.neutral100,
          label: status,
        );
    }
  }

  String _titleOf(Map<String, dynamic> p) {
    final t = (p['titre'] ?? p['notesClient'] ?? '').toString().trim();
    if (t.isNotEmpty) return t;
    final u = p['utilisateur'];
    if (u is Map) {
      final name = personNameFromMap(
        Map<String, dynamic>.from(u),
        fallback: 'Client',
      );
      if (name.isNotEmpty) return name;
    }
    return 'Mission';
  }

  String _locationOf(Map<String, dynamic> p) {
    final parts = <String>[
      if ((p['adresse'] ?? '').toString().trim().isNotEmpty)
        p['adresse'].toString(),
      if ((p['ville'] ?? '').toString().trim().isNotEmpty) p['ville'].toString(),
    ];
    return parts.isEmpty ? 'Lieu non précisé' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SDColors.white,
      child: BlocBuilder<PlanningBloc, PlanningState>(
        builder: (context, state) {
          final prestations = state is PlanningLoaded
              ? state.prestations
              : <dynamic>[];

          return RefreshIndicator(
            onRefresh: () async {
              if (_prestataireId != null) {
                context
                    .read<PlanningBloc>()
                    .add(LoadPrestationsPlanning(_prestataireId!));
              }
            },
            color: SDColors.primary600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIntroSubtitle(),
                        const SizedBox(height: 16),
                        _buildViewSelector(),
                        const SizedBox(height: 12),
                        _buildDateRow(),
                        const SizedBox(height: 16),
                        _buildKpiRow(prestations),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (state is PlanningLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (state is PlanningError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildError(state.message),
                  )
                else if (state is PlanningLoaded)
                  ..._buildContentSlivers(state)
                else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: (_prestataireId == null || _prestataireId!.isEmpty)
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Text(
                              'Aucune donnée',
                              style: SDTypography.bodyMedium
                                  .copyWith(color: SDColors.neutral500),
                            ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntroSubtitle() {
    return Text(
      'Gérez vos disponibilités et vos missions',
      style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
    );
  }

  Widget _buildViewSelector() {
    final items = const [
      ('day', 'Jour'),
      ('week', 'Semaine'),
      ('month', 'Mois'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SDColors.neutral100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: items.map((e) {
          final selected = _currentView == e.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _currentView = e.$1);
                _loadPrestationsForView();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? SDColors.primary700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(
                  e.$2,
                  style: SDTypography.labelMedium.copyWith(
                    color: selected ? SDColors.white : SDColors.neutral600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: SDColors.neutral100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _periodLabel(),
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: SDColors.neutral900, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _circleNav(Icons.chevron_left_rounded, _previousPeriod),
        const SizedBox(width: 6),
        _circleNav(Icons.chevron_right_rounded, _nextPeriod),
      ],
    );
  }

  Widget _circleNav(IconData icon, VoidCallback onTap) {
    return Material(
      color: SDColors.neutral100,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: SDColors.neutral900, size: 22),
        ),
      ),
    );
  }

  Widget _buildKpiRow(List<dynamic> all) {
    final dayList = _prestationsForDay(all, _selectedDay);
    final weekList = _prestationsForWeek(all, _selectedDay);
    var planned = Duration.zero;
    for (final p in dayList) {
      if (p is Map<String, dynamic>) {
        planned += _missionDuration(p);
      } else if (p is Map) {
        planned += _missionDuration(Map<String, dynamic>.from(p));
      }
    }
    final reminders = dayList.where((p) {
      final s = '${p['statut'] ?? ''}'.toUpperCase();
      return s == 'EN_ATTENTE';
    }).length;

    return Row(
      children: [
        Expanded(
          child: _KpiChip(
            icon: Icons.work_outline_rounded,
            value: '${dayList.length}',
            label: 'Missions\nprogrammées',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiChip(
            icon: Icons.schedule_outlined,
            value: _formatDuration(planned),
            label: 'Heures\nplanifiées',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiChip(
            icon: Icons.notifications_none_rounded,
            value: '$reminders',
            label: 'Rappels\naujourd\'hui',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiChip(
            icon: Icons.check_circle_outline_rounded,
            value: '${weekList.length}',
            label: 'Missions\ncette semaine',
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: SDColors.neutral900),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  SDTypography.bodyMedium.copyWith(color: SDColors.neutral600),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadPrestationsForView,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContentSlivers(PlanningLoaded state) {
    switch (_currentView) {
      case 'month':
        return [
          SliverToBoxAdapter(child: _buildMonthCalendar(state)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _buildDayEventsList(
                _prestationsForDay(state.prestations, _selectedDay),
                heading:
                    'Événements du ${DateFormat('d MMMM', 'fr_FR').format(_selectedDay)}',
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildLegend()),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ];
      case 'week':
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(child: _buildWeekList(state)),
          ),
          SliverToBoxAdapter(child: _buildLegend()),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ];
      case 'day':
      default:
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _buildDayTimeline(
                _prestationsForDay(state.prestations, _selectedDay),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildLegend()),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ];
    }
  }

  Widget _buildMonthCalendar(PlanningLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final calHeight = 280.0;
        final calendar = TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          sixWeekMonthsEnforced: false,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() => _focusedDay = focusedDay);
            context
                .read<PlanningBloc>()
                .add(LoadMonthlyPrestations(focusedDay));
          },
          eventLoader: (day) => _prestationsForDay(state.prestations, day),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: const EdgeInsets.all(4),
            selectedDecoration: const BoxDecoration(
              color: SDColors.primary600,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: SDColors.primary200,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: SDColors.neutral900,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            headerPadding: EdgeInsets.symmetric(vertical: 6),
            leftChevronIcon:
                Icon(Icons.chevron_left_rounded, color: SDColors.neutral900),
            rightChevronIcon:
                Icon(Icons.chevron_right_rounded, color: SDColors.neutral900),
          ),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SizedBox(
            height: calHeight,
            width: maxW,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: maxW,
                height: _calendarLayoutHeight,
                child: calendar,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekList(PlanningLoaded state) {
    final weekStart =
        _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    return Column(
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final events = _prestationsForDay(state.prestations, day);
        final isSelected = isSameDay(day, _selectedDay);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: isSelected ? SDColors.neutral50 : SDColors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _selectedDay = day;
                  _focusedDay = day;
                  _currentView = 'day';
                });
                _loadPrestationsForView();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? SDColors.neutral900
                        : SDColors.neutral200,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEE', 'fr_FR').format(day),
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.neutral500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${day.day}',
                            style: SDTypography.titleMedium.copyWith(
                              color: SDColors.neutral900,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        events.isEmpty
                            ? 'Aucune mission'
                            : '${events.length} mission${events.length > 1 ? 's' : ''}',
                        style: SDTypography.bodyMedium.copyWith(
                          color: SDColors.neutral700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: SDColors.neutral900),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayTimeline(List<dynamic> events) {
    final now = DateTime.now();
    final showNowLine = isSameDay(now, _selectedDay);

    final sorted = List<Map<String, dynamic>>.from(
      events.map((e) => Map<String, dynamic>.from(e as Map)),
    )..sort((a, b) {
        final ta = _parseTime(a['heureDebut']) ?? DateTime(0);
        final tb = _parseTime(b['heureDebut']) ?? DateTime(0);
        return ta.compareTo(tb);
      });

    return Column(
      children: [
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.event_available_outlined,
                    size: 44,
                    color: SDColors.neutral900.withValues(alpha: 0.35)),
                const SizedBox(height: 12),
                Text(
                  'Aucuneune mission ce jour',
                  style: SDTypography.titleSmall.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aucune prestation planifiée pour ce jour. Changez de jour ou revenez plus tard.',
                  textAlign: TextAlign.center,
                  style: SDTypography.bodySmall
                      .copyWith(color: SDColors.neutral500),
                ),
              ],
            ),
          )
        else
          ...sorted.map((event) {
            final start = _parseTime(event['heureDebut']);
            final end = _parseTime(event['heureFin']);
            final timeLabel = [
              if (start != null) DateFormat('HH:mm').format(start),
              if (end != null) DateFormat('HH:mm').format(end),
            ].join(' – ');

            final afterNow = showNowLine &&
                start != null &&
                start.isAfter(now) &&
                sorted.indexOf(event) ==
                    sorted.indexWhere((e) {
                      final s = _parseTime(e['heureDebut']);
                      return s != null && s.isAfter(now);
                    });

            return Column(
              children: [
                if (afterNow) _buildNowLine(now),
                _TimelineMissionCard(
                  timeLabel: timeLabel.isEmpty ? '—' : timeLabel,
                  title: _titleOf(event),
                  location: _locationOf(event),
                  visual: _visualForStatus('${event['statut'] ?? 'EN_ATTENTE'}'),
                ),
              ],
            );
          }),
        if (showNowLine &&
            sorted.every((e) {
              final s = _parseTime(e['heureDebut']);
              return s == null || !s.isAfter(now);
            }))
          _buildNowLine(now),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNowLine(DateTime now) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            DateFormat('HH:mm').format(now),
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.primary600,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 2, color: SDColors.primary600),
          ),
        ],
      ),
    );
  }

  Widget _buildDayEventsList(List<dynamic> events, {required String heading}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: SDTypography.titleSmall.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Text(
            'Aucun événement ce jour',
            style:
                SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
          )
        else
          ...events.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            final start = _parseTime(map['heureDebut']);
            final end = _parseTime(map['heureFin']);
            final timeLabel = [
              if (start != null) DateFormat('HH:mm').format(start),
              if (end != null) DateFormat('HH:mm').format(end),
            ].join(' – ');
            return _TimelineMissionCard(
              timeLabel: timeLabel.isEmpty ? '—' : timeLabel,
              title: _titleOf(map),
              location: _locationOf(map),
              visual: _visualForStatus('${map['statut'] ?? 'EN_ATTENTE'}'),
            );
          }),
      ],
    );
  }

  Widget _buildLegend() {
    final items = const [
      (SDColors.primary600, 'Confirmée'),
      (Color(0xFF3B82F6), 'En cours'),
      (Color(0xFF8B5CF6), 'À confirmer'),
      (SDColors.neutral400, 'Pause'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: [
          ...items.map(
            (e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: e.$1,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  e.$2,
                  style: SDTypography.labelSmall
                      .copyWith(color: SDColors.neutral600),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(14, 10),
                painter: _DashedBorderPainter(
                  color: SDColors.primary600,
                  radius: 2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Disponible',
                style: SDTypography.labelSmall
                    .copyWith(color: SDColors.neutral600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionVisual {
  final Color accent;
  final Color bg;
  final String label;

  const _MissionVisual({
    required this.accent,
    required this.bg,
    required this.label,
  });
}

class _KpiChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _KpiChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: SDColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SDColors.neutral200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: SDColors.neutral900),
          const SizedBox(height: 6),
          Text(
            value,
            style: SDTypography.titleSmall.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: SDTypography.labelSmall.copyWith(
              color: SDColors.neutral500,
              height: 1.15,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineMissionCard extends StatelessWidget {
  final String timeLabel;
  final String title;
  final String location;
  final _MissionVisual visual;

  const _TimelineMissionCard({
    required this.timeLabel,
    required this.title,
    required this.location,
    required this.visual,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              timeLabel.split(' – ').first,
              style: SDTypography.labelSmall.copyWith(
                color: SDColors.neutral500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: visual.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: visual.accent.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (timeLabel.contains('–'))
                        Expanded(
                          child: Text(
                            timeLabel,
                            style: SDTypography.labelSmall.copyWith(
                              color: visual.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: visual.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          visual.label,
                          style: SDTypography.labelSmall.copyWith(
                            color: SDColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: SDTypography.bodyMedium.copyWith(
                      color: SDColors.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: SDColors.neutral900),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: SDTypography.bodySmall
                              .copyWith(color: SDColors.neutral600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Éditeur de créneaux récurrents (jour + heures) — sync PUT prestataire.
class _CreneauxEditorSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialCreneaux;
  final List<String> jourLabels;
  final Future<bool> Function(List<Map<String, dynamic>>) onSave;

  const _CreneauxEditorSheet({
    required this.initialCreneaux,
    required this.jourLabels,
    required this.onSave,
  });

  @override
  State<_CreneauxEditorSheet> createState() => _CreneauxEditorSheetState();
}

class _CreneauxEditorSheetState extends State<_CreneauxEditorSheet> {
  late List<Map<String, dynamic>> _creneaux;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _creneaux = widget.initialCreneaux
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _pickTime({
    required String label,
    required String initial,
    required ValueChanged<String> onPicked,
  }) async {
    final parts = initial.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '8') ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: label,
    );
    if (picked != null) {
      onPicked(
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _addCreneau() async {
    int jour = DateTime.now().weekday % 7; // Dim=0
    String debut = '08:00';
    String fin = '18:00';

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialog) {
            return AlertDialog(
              title: const Text('Ajouter un créneau'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: jour,
                    decoration: const InputDecoration(labelText: 'Jour'),
                    items: [
                      for (var i = 0; i < widget.jourLabels.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(widget.jourLabels[i]),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialog(() => jour = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Heure début'),
                    trailing: Text(debut),
                    onTap: () => _pickTime(
                      label: 'Début',
                      initial: debut,
                      onPicked: (v) => setDialog(() => debut = v),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Heure fin'),
                    trailing: Text(fin),
                    onTap: () => _pickTime(
                      label: 'Fin',
                      initial: fin,
                      onPicked: (v) => setDialog(() => fin = v),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true && mounted) {
      setState(() {
        _creneaux.add({
          'jour': jour,
          'heureDebut': debut,
          'heureFin': fin,
          'actif': true,
        });
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final success = await widget.onSave(_creneaux);
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SDColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Disponibilités',
                    style: SDTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SDColors.neutral900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : _addCreneau,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Ajouter',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Créneaux récurrents (jour de la semaine).',
              style: SDTypography.bodySmall
                  .copyWith(color: SDColors.neutral500),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: _creneaux.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Aucun créneau. Appuyez sur + pour en ajouter.',
                        style: SDTypography.bodySmall
                            .copyWith(color: SDColors.neutral500),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _creneaux.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = _creneaux[index];
                        final jour = (c['jour'] is int)
                            ? c['jour'] as int
                            : int.tryParse('${c['jour']}') ?? 0;
                        final label = (jour >= 0 && jour < widget.jourLabels.length)
                            ? widget.jourLabels[jour]
                            : 'Jour $jour';
                        final actif = c['actif'] != false;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '$label · ${c['heureDebut']} – ${c['heureFin']}',
                            style: SDTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: actif
                                  ? SDColors.neutral900
                                  : SDColors.neutral400,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch.adaptive(
                                value: actif,
                                onChanged: (v) {
                                  setState(() => _creneaux[index]['actif'] = v);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red.shade400),
                                onPressed: () {
                                  setState(() => _creneaux.removeAt(index));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SDColors.primary600,
                      foregroundColor: Colors.white,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, this.radius = 14});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.7, 0.7, size.width - 1.4, size.height - 1.4),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 5.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
