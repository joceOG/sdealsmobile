import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../bloc/planning_bloc.dart';
import '../bloc/planning_event.dart';
import '../bloc/planning_state.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/authCubit.dart';
import '../../../../data/utils/display_text.dart';
import '../../../../design_system/design_system.dart';
import '../models/provider_mission.dart';

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

  /// AppBar parent — revenir à aujourd’hui (conserve la vue Jour / Semaine / Mois).
  void goToToday() {
    setState(() {
      final now = DateTime.now();
      _focusedDay = now;
      _selectedDay = now;
    });
    _reloadPlanning();
  }

  DateTime _weekStartFor(DateTime anchor) =>
      anchor.subtract(Duration(days: anchor.weekday - 1));

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
        return _MesDisponibilitesSheet(
          initialDate: _selectedDay,
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

  bool _isPlannedStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'ACCEPTEE':
      case 'CONFIRMEE':
      case 'EN_COURS':
        return true;
      default:
        return false;
    }
  }

  List<Map<String, dynamic>> _plannedForDay(List<dynamic> all, DateTime day) {
    return all
        .where((p) {
          if (p is! Map) return false;
          final map = Map<String, dynamic>.from(p);
          final statut = (map['statut'] ?? map['status'] ?? '').toString();
          if (!_isPlannedStatus(statut)) return false;
          final raw = map['datePrestation'] ?? map['date'];
          final d = DateTime.tryParse('$raw');
          if (d == null) return false;
          return isSameDay(d.toLocal(), day);
        })
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();
  }

  List<dynamic> _prestationsForDay(List<dynamic> all, DateTime day) {
    return _plannedForDay(all, day);
  }

  List<dynamic> _prestationsForWeek(List<dynamic> all, DateTime day) {
    final start = day.subtract(Duration(days: day.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return all.where((p) {
      if (p is! Map) return false;
      final map = Map<String, dynamic>.from(p);
      final statut = (map['statut'] ?? map['status'] ?? '').toString();
      if (!_isPlannedStatus(statut)) return false;
      final raw = map['datePrestation'] ?? map['date'];
      final d = DateTime.tryParse('$raw');
      if (d == null) return false;
      final local = d.toLocal();
      return !local.isBefore(start) && local.isBefore(end);
    }).toList();
  }

  Duration? _missionDurationIfKnown(Map<String, dynamic> p) {
    final start = _parseTime(p['heureDebut']);
    final end = _parseTime(p['heureFin']);
    if (start == null || end == null) return null;
    final mins = end.difference(start).inMinutes;
    if (mins <= 0) return null;
    return Duration(minutes: mins);
  }

  Duration _missionDuration(Map<String, dynamic> p) {
    return _missionDurationIfKnown(p) ?? const Duration(hours: 1);
  }

  DateTime? _parseTimeOnDay(dynamic raw, DateTime day) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final base = DateTime(day.year, day.month, day.day);
    return base.add(Duration(hours: h, minutes: m));
  }

  DateTime? _parseTime(dynamic raw) => _parseTimeOnDay(raw, _selectedDay);

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

  String _titleOf(Map<String, dynamic> p) => prestationServiceTitle(p);

  String _locationOf(Map<String, dynamic> p) => prestationLocationLabel(p);

  String? _timeRangeLabel(Map<String, dynamic> p) {
    final start = _parseTime(p['heureDebut']);
    final end = _parseTime(p['heureFin']);
    if (start == null) return null;
    final startStr = DateFormat('HH:mm').format(start);
    if (end == null) return startStr;
    return '$startStr — ${DateFormat('HH:mm').format(end)}';
  }

  Future<void> _openMissionDetail(Map<String, dynamic> mission) async {
    final id = prestationIdOf(mission);
    if (id == null) return;
    final changed = await context.push<bool>(
      '/mission-details/$id',
      extra: _prestataireId == null
          ? null
          : {'prestataireDocId': _prestataireId},
    );
    if (changed == true && mounted) _reloadPlanning();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
      locale: const Locale('fr', 'FR'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDay = picked;
      _focusedDay = picked;
    });
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
                        if (_currentView == 'day') ...[
                          _buildDayPlanningChrome(prestations),
                        ] else if (_currentView == 'week') ...[
                          _buildWeekPlanningChrome(prestations),
                        ] else if (_currentView == 'month') ...[
                          _buildMonthPlanningChrome(),
                        ] else ...[
                          _buildDateRow(),
                          const SizedBox(height: 16),
                          _buildKpiRow(prestations),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (state is PlanningLoading && _currentView != 'day')
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (state is PlanningLoading && _currentView == 'day')
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
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
      'Vos interventions planifiées',
      style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
    );
  }

  Widget _buildDayPlanningChrome(List<dynamic> all) {
    final weekStart =
        _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
    final dayPlanned = _plannedForDay(all, _selectedDay);
    var totalDuration = Duration.zero;
    var hasTotalDuration = false;
    for (final p in dayPlanned) {
      final d = _missionDurationIfKnown(p);
      if (d != null) {
        totalDuration += d;
        hasTotalDuration = true;
      }
    }

    final dayTitle = DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDay);
    final capDay = dayTitle.isNotEmpty
        ? '${dayTitle[0].toUpperCase()}${dayTitle.substring(1)}'
        : dayTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: _pickMonth,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy', 'fr_FR').format(_selectedDay),
                      style: SDTypography.bodyMedium.copyWith(
                        color: SDColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: SDColors.neutral900, size: 20),
                  ],
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: goToToday,
              style: TextButton.styleFrom(
                foregroundColor: SDColors.primary700,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Aujourd\'hui',
                style: SDTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: Row(
            children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              final selected = isSameDay(day, _selectedDay);
              final hasEvents = _plannedForDay(all, day).isNotEmpty;
              final weekday =
                  DateFormat('EEE', 'fr_FR').format(day).replaceAll('.', '');
              final weekdayCap = weekday.isNotEmpty
                  ? '${weekday[0].toUpperCase()}${weekday.substring(1)}'
                  : weekday;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                  child: Material(
                    color: selected ? SDColors.primary700 : SDColors.neutral50,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDay = day;
                          _focusedDay = day;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? SDColors.primary700
                                : SDColors.neutral200,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              weekdayCap,
                              style: SDTypography.labelSmall.copyWith(
                                color: selected
                                    ? SDColors.white
                                    : SDColors.neutral600,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('d').format(day),
                              style: SDTypography.titleSmall.copyWith(
                                color: selected
                                    ? SDColors.white
                                    : SDColors.neutral900,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (hasEvents) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? SDColors.white
                                      : SDColors.primary600,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          capDay,
          style: SDTypography.titleSmall.copyWith(
            color: SDColors.neutral900,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _daySummaryLine(dayPlanned.length, totalDuration, hasTotalDuration),
          style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
        ),
      ],
    );
  }

  String _daySummaryLine(int count, Duration total, bool hasTotal) {
    if (count == 0) return 'Aucune intervention ce jour';
    final base =
        '$count intervention${count > 1 ? 's' : ''}';
    if (!hasTotal) return base;
    return '$base • ${_formatDuration(total)} planifiées';
  }

  Widget _buildWeekPlanningChrome(List<dynamic> all) {
    final weekStart = _weekStartFor(_focusedDay);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekInterventions = _prestationsForWeek(all, weekStart);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _circleNav(Icons.chevron_left_rounded, _previousPeriod),
            Expanded(
              child: Text(
                '${DateFormat('d', 'fr_FR').format(weekStart)} – ${DateFormat('d MMMM yyyy', 'fr_FR').format(weekEnd)}',
                textAlign: TextAlign.center,
                style: SDTypography.bodyMedium.copyWith(
                  color: SDColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _circleNav(Icons.chevron_right_rounded, _nextPeriod),
            const SizedBox(width: 8),
            TextButton(
              onPressed: goToToday,
              style: TextButton.styleFrom(
                foregroundColor: SDColors.primary700,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Aujourd\'hui',
                style: SDTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: SDColors.primary700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: Row(
            children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              final selected = isSameDay(day, _selectedDay);
              final hasEvents = _plannedForDay(all, day).isNotEmpty;
              final weekday =
                  DateFormat('EEE', 'fr_FR').format(day).replaceAll('.', '');
              final weekdayCap = weekday.isNotEmpty
                  ? '${weekday[0].toUpperCase()}${weekday.substring(1)}'
                  : weekday;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                  child: Material(
                    color: selected ? SDColors.primary700 : SDColors.neutral50,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDay = day;
                          _focusedDay = day;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? SDColors.primary700
                                : SDColors.neutral200,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              weekdayCap,
                              style: SDTypography.labelSmall.copyWith(
                                color: selected
                                    ? SDColors.white
                                    : SDColors.neutral600,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('d').format(day),
                              style: SDTypography.titleSmall.copyWith(
                                color: selected
                                    ? SDColors.white
                                    : SDColors.neutral900,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (hasEvents) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? SDColors.white
                                      : SDColors.primary600,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${weekInterventions.length} intervention${weekInterventions.length > 1 ? 's' : ''} cette semaine',
          style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
        ),
      ],
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _buildMonthDayAgenda(state),
            ),
          ),
          SliverToBoxAdapter(child: _buildMonthLegend()),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ];
      case 'week':
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(child: _buildWeekAgenda(state)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ];
      case 'day':
      default:
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _buildDayTimeline(
                _plannedForDay(state.prestations, _selectedDay),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ];
    }
  }

  Widget _buildMonthPlanningChrome() {
    return Row(
      children: [
        _circleNav(Icons.chevron_left_rounded, _previousPeriod),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy', 'fr_FR').format(_focusedDay),
            textAlign: TextAlign.center,
            style: SDTypography.bodyMedium.copyWith(
              color: SDColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _circleNav(Icons.chevron_right_rounded, _nextPeriod),
        const SizedBox(width: 8),
        TextButton(
          onPressed: goToToday,
          style: TextButton.styleFrom(
            foregroundColor: SDColors.primary700,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            'Aujourd\'hui',
            style: SDTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: SDColors.primary700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthDayAgenda(PlanningLoaded state) {
    final events = List<Map<String, dynamic>>.from(
      _plannedForDay(state.prestations, _selectedDay),
    );
    events.sort((a, b) {
      final ta =
          _parseTimeOnDay(a['heureDebut'], _selectedDay) ?? DateTime(0);
      final tb =
          _parseTimeOnDay(b['heureDebut'], _selectedDay) ?? DateTime(0);
      return ta.compareTo(tb);
    });

    final dayTitle = DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDay);
    final capDay = dayTitle.isNotEmpty
        ? '${dayTitle[0].toUpperCase()}${dayTitle.substring(1)}'
        : dayTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                capDay,
                style: SDTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SDColors.neutral900,
                ),
              ),
            ),
            if (events.isNotEmpty)
              Text(
                '${events.length} intervention${events.length > 1 ? 's' : ''}',
                style:
                    SDTypography.caption.copyWith(color: SDColors.neutral500),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Text(
            'Aucune intervention prévue',
            style:
                SDTypography.bodyMedium.copyWith(color: SDColors.neutral500),
          )
        else
          ...events.map(
            (mission) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _WeekInterventionCard(
                title: _titleOf(mission),
                location: _locationOf(mission),
                visual: _visualForStatus('${mission['statut'] ?? ''}'),
                timeStart: _parseTimeOnDay(mission['heureDebut'], _selectedDay),
                timeEnd: _parseTimeOnDay(mission['heureFin'], _selectedDay),
                onOpen: () => _openMissionDetail(mission),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: SDColors.primary600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Intervention prévue',
            style: SDTypography.labelSmall.copyWith(color: SDColors.neutral600),
          ),
        ],
      ),
    );
  }

  Widget _monthCalendarDayCell({
    required DateTime day,
    required DateTime focusedMonth,
    required bool selected,
    required bool todayOutline,
    required bool hasEvents,
  }) {
    final outside = day.month != focusedMonth.month;
    final textColor = selected
        ? SDColors.white
        : (outside ? SDColors.neutral400 : SDColors.neutral900);

    BoxDecoration decoration;
    if (selected) {
      decoration = const BoxDecoration(
        color: SDColors.primary700,
        shape: BoxShape.circle,
      );
    } else if (todayOutline) {
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: SDColors.primary600, width: 2),
      );
    } else {
      decoration = const BoxDecoration(shape: BoxShape.circle);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: decoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: SDTypography.labelLarge.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hasEvents)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: selected ? SDColors.white : SDColors.primary600,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(PlanningLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final calHeight = 320.0;
        final calendar = TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
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
          eventLoader: (day) => _plannedForDay(state.prestations, day),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final selected = isSameDay(day, _selectedDay);
              final today = isSameDay(day, DateTime.now());
              if (selected || today) return null;
              final hasEvents =
                  _plannedForDay(state.prestations, day).isNotEmpty;
              return _monthCalendarDayCell(
                day: day,
                focusedMonth: focusedDay,
                selected: false,
                todayOutline: false,
                hasEvents: hasEvents,
              );
            },
            todayBuilder: (context, day, focusedDay) {
              final selected = isSameDay(day, _selectedDay);
              final hasEvents =
                  _plannedForDay(state.prestations, day).isNotEmpty;
              return _monthCalendarDayCell(
                day: day,
                focusedMonth: focusedDay,
                selected: selected,
                todayOutline: !selected,
                hasEvents: hasEvents,
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              final hasEvents =
                  _plannedForDay(state.prestations, day).isNotEmpty;
              return _monthCalendarDayCell(
                day: day,
                focusedMonth: focusedDay,
                selected: true,
                todayOutline: false,
                hasEvents: hasEvents,
              );
            },
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: true,
            cellMargin: const EdgeInsets.all(2),
            outsideTextStyle: SDTypography.labelLarge.copyWith(
              color: SDColors.neutral400,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            todayDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            markerDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            markersMaxCount: 0,
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

  Widget _buildWeekAgenda(PlanningLoaded state) {
    final weekStart = _weekStartFor(_focusedDay);
    final sections = <Widget>[];

    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final events = List<Map<String, dynamic>>.from(
        _plannedForDay(state.prestations, day),
      );
      events.sort((a, b) {
        final ta = _parseTimeOnDay(a['heureDebut'], day) ?? DateTime(0);
        final tb = _parseTimeOnDay(b['heureDebut'], day) ?? DateTime(0);
        return ta.compareTo(tb);
      });

      final dayTitle = DateFormat('EEEE d MMMM', 'fr_FR').format(day);
      final capDay = dayTitle.isNotEmpty
          ? '${dayTitle[0].toUpperCase()}${dayTitle.substring(1)}'
          : dayTitle;

      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      capDay,
                      style: SDTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                      ),
                    ),
                  ),
                  if (events.isNotEmpty)
                    Text(
                      '${events.length} intervention${events.length > 1 ? 's' : ''}',
                      style: SDTypography.caption
                          .copyWith(color: SDColors.neutral500),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (events.isEmpty)
                Text(
                  'Aucune intervention prévue',
                  style: SDTypography.bodyMedium
                      .copyWith(color: SDColors.neutral500),
                )
              else
                ...events.map(
                  (mission) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _WeekInterventionCard(
                      title: _titleOf(mission),
                      location: _locationOf(mission),
                      visual: _visualForStatus('${mission['statut'] ?? ''}'),
                      timeStart:
                          _parseTimeOnDay(mission['heureDebut'], day),
                      timeEnd: _parseTimeOnDay(mission['heureFin'], day),
                      onOpen: () => _openMissionDetail(mission),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Column(children: sections);
  }

  Widget _buildDayTimeline(List<Map<String, dynamic>> events) {
    final sorted = List<Map<String, dynamic>>.from(events)
      ..sort((a, b) {
        final ta = _parseTime(a['heureDebut']) ?? DateTime(0);
        final tb = _parseTime(b['heureDebut']) ?? DateTime(0);
        return ta.compareTo(tb);
      });

    if (sorted.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.event_available_outlined,
                size: 44,
                color: SDColors.neutral900.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(
              'Aucune intervention ce jour',
              style: SDTypography.titleSmall.copyWith(
                color: SDColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sélectionnez une autre date ou consultez vos missions à venir.',
              textAlign: TextAlign.center,
              style: SDTypography.bodySmall.copyWith(color: SDColors.neutral500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < sorted.length; i++)
          _DayInterventionRow(
            isLast: i == sorted.length - 1,
            timeStart: _parseTime(sorted[i]['heureDebut']),
            timeEnd: _parseTime(sorted[i]['heureFin']),
            title: _titleOf(sorted[i]),
            client: prestationClientName(sorted[i]),
            location: _locationOf(sorted[i]),
            timeRange: _timeRangeLabel(sorted[i]),
            visual: _visualForStatus('${sorted[i]['statut'] ?? ''}'),
            onOpen: () => _openMissionDetail(sorted[i]),
          ),
        if (sorted.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.event_busy_outlined,
                    size: 18, color: SDColors.neutral400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aucune autre intervention prévue ce jour.',
                    style: SDTypography.bodySmall
                        .copyWith(color: SDColors.neutral500),
                  ),
                ),
              ],
            ),
          ),
      ],
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
        ],
      ),
    );
  }
}

class _WeekInterventionCard extends StatelessWidget {
  const _WeekInterventionCard({
    required this.title,
    required this.location,
    required this.visual,
    required this.timeStart,
    required this.timeEnd,
    required this.onOpen,
  });

  final String title;
  final String location;
  final _MissionVisual visual;
  final DateTime? timeStart;
  final DateTime? timeEnd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final startLabel = timeStart != null
        ? DateFormat('HH:mm').format(timeStart!)
        : '—';
    final endLabel =
        timeEnd != null ? DateFormat('HH:mm').format(timeEnd!) : null;

    return Material(
      color: SDColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SDColors.neutral200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startLabel,
                      style: SDTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SDColors.neutral900,
                      ),
                    ),
                    if (endLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        endLabel,
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.neutral500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: SDTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: SDColors.neutral900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: SDColors.primary50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            visual.label,
                            style: SDTypography.labelSmall.copyWith(
                              color: SDColors.primary700,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 14, color: SDColors.neutral500),
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
              const Icon(Icons.chevron_right_rounded,
                  color: SDColors.neutral900, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayInterventionRow extends StatelessWidget {
  const _DayInterventionRow({
    required this.isLast,
    required this.timeStart,
    required this.timeEnd,
    required this.title,
    required this.client,
    required this.location,
    required this.timeRange,
    required this.visual,
    required this.onOpen,
  });

  final bool isLast;
  final DateTime? timeStart;
  final DateTime? timeEnd;
  final String title;
  final String client;
  final String location;
  final String? timeRange;
  final _MissionVisual visual;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final startLabel = timeStart != null
        ? DateFormat('HH:mm').format(timeStart!)
        : '—';
    final endLabel =
        timeEnd != null ? DateFormat('HH:mm').format(timeEnd!) : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  startLabel,
                  style: SDTypography.labelMedium.copyWith(
                    color: SDColors.neutral900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (endLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    endLabel,
                    style: SDTypography.labelSmall.copyWith(
                      color: SDColors.neutral500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: SDColors.primary600,
                    shape: BoxShape.circle,
                    border: Border.all(color: SDColors.white, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: SDColors.neutral200,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Material(
                color: SDColors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onOpen,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SDColors.neutral200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: SDTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: SDColors.neutral900,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: SDColors.primary50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: SDColors.primary600.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Text(
                                visual.label,
                                style: SDTypography.labelSmall.copyWith(
                                  color: SDColors.primary700,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _infoRow(Icons.person_outline_rounded, client),
                        const SizedBox(height: 4),
                        _infoRow(Icons.place_outlined, location),
                        if (timeRange != null) ...[
                          const SizedBox(height: 4),
                          _infoRow(Icons.schedule_outlined, timeRange!),
                        ],
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: SDColors.neutral200),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Voir la mission',
                              style: SDTypography.labelMedium.copyWith(
                                color: SDColors.primary700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 18, color: SDColors.primary700),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: SDColors.neutral500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: SDTypography.bodySmall.copyWith(color: SDColors.neutral600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

/// Panneau « Mes disponibilités » — créneaux récurrents `prestataire.creneaux` (jour + heures).
class _MesDisponibilitesSheet extends StatefulWidget {
  final DateTime initialDate;
  final List<Map<String, dynamic>> initialCreneaux;
  final List<String> jourLabels;
  final Future<bool> Function(List<Map<String, dynamic>>) onSave;

  const _MesDisponibilitesSheet({
    required this.initialDate,
    required this.initialCreneaux,
    required this.jourLabels,
    required this.onSave,
  });

  @override
  State<_MesDisponibilitesSheet> createState() =>
      _MesDisponibilitesSheetState();
}

class _MesDisponibilitesSheetState extends State<_MesDisponibilitesSheet> {
  late List<Map<String, dynamic>> _creneaux;
  late DateTime _date;
  String _heureDebut = '08:00';
  String _heureFin = '12:00';
  bool _saving = false;

  int _jourFromDate(DateTime d) => d.weekday % 7;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _creneaux = widget.initialCreneaux
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _prefillFromExistingCreneau();
  }

  void _prefillFromExistingCreneau() {
    final jour = _jourFromDate(_date);
    final match = _creneaux.where((c) {
      if (c['actif'] == false) return false;
      final j = c['jour'] is int
          ? c['jour'] as int
          : int.tryParse('${c['jour']}') ?? -1;
      return j == jour;
    }).toList();
    if (match.isEmpty) return;
    final c = match.first;
    final debut = c['heureDebut']?.toString();
    final fin = c['heureFin']?.toString();
    if (debut != null && debut.isNotEmpty) _heureDebut = debut;
    if (fin != null && fin.isNotEmpty) _heureFin = fin;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
      locale: const Locale('fr', 'FR'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      _prefillFromExistingCreneau();
    });
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

  String _dateLabelLong() {
    final raw = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_date);
    return raw.isNotEmpty
        ? '${raw[0].toUpperCase()}${raw.substring(1)}'
        : raw;
  }

  String _dateLabelShort() {
    final raw = DateFormat('EEEE d MMMM', 'fr_FR').format(_date);
    return raw.isNotEmpty
        ? '${raw[0].toUpperCase()}${raw.substring(1)}'
        : raw;
  }

  String _weekdayRecurrenceHint() {
    final jour = _jourFromDate(_date);
    if (jour >= 0 && jour < widget.jourLabels.length) {
      return widget.jourLabels[jour];
    }
    return '';
  }

  Future<void> _saveSlot() async {
    final jour = _jourFromDate(_date);
    final updated = List<Map<String, dynamic>>.from(
      _creneaux.map((e) => Map<String, dynamic>.from(e)),
    );
    final index = updated.indexWhere((c) {
      final j = c['jour'] is int
          ? c['jour'] as int
          : int.tryParse('${c['jour']}') ?? -1;
      return j == jour;
    });
    final slot = {
      'jour': jour,
      'heureDebut': _heureDebut,
      'heureFin': _heureFin,
      'actif': true,
    };
    if (index >= 0) {
      updated[index] = slot;
    } else {
      updated.add(slot);
    }

    setState(() => _saving = true);
    final success = await widget.onSave(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = SDResponsive.occupiedBottomInset(context);
    final recurrence = _weekdayRecurrenceHint();

    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              Text(
                'Mes disponibilités',
                style: SDTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: SDColors.neutral900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Indiquez quand vous pouvez intervenir.',
                style: SDTypography.bodyMedium
                    .copyWith(color: SDColors.neutral500),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SDColors.primary50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.event_available_outlined,
                        color: SDColors.primary700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Un créneau disponible ne réserve aucune intervention.',
                        style: SDTypography.bodySmall
                            .copyWith(color: SDColors.neutral700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Créneau disponible',
                style: SDTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (recurrence.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Enregistré pour chaque $recurrence (modèle actuel).',
                  style: SDTypography.caption.copyWith(
                    color: SDColors.neutral500,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SDColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 20, color: SDColors.neutral700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _dateLabelLong(),
                          style: SDTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: SDColors.neutral400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _timeField(
                      label: 'Début',
                      value: _heureDebut,
                      onTap: () => _pickTime(
                        label: 'Début',
                        initial: _heureDebut,
                        onPicked: (v) => setState(() => _heureDebut = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeField(
                      label: 'Fin',
                      value: _heureFin,
                      onTap: () => _pickTime(
                        label: 'Fin',
                        initial: _heureFin,
                        onPicked: (v) => setState(() => _heureFin = v),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Aperçu',
                style: SDTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SDColors.neutral50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SDColors.neutral200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_outlined,
                        color: SDColors.primary700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dateLabelShort(),
                            style: SDTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Disponible de $_heureDebut à $_heureFin',
                            style: SDTypography.bodySmall
                                .copyWith(color: SDColors.neutral600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: SDColors.primary50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SDColors.primary200),
                      ),
                      child: Text(
                        'Disponibilité',
                        style: SDTypography.labelSmall.copyWith(
                          color: SDColors.primary700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Vos interventions déjà planifiées restent inchangées.',
                style: SDTypography.caption.copyWith(color: SDColors.neutral500),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _saveSlot,
                  style: FilledButton.styleFrom(
                    backgroundColor: SDColors.primary700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SDColors.white,
                          ),
                        )
                      : const Text('Enregistrer le créneau'),
                ),
              ),
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SDTypography.caption.copyWith(color: SDColors.neutral600),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SDColors.neutral200),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_outlined,
                    size: 18, color: SDColors.neutral600),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: SDTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
