// 🎯 ÉTATS POUR LE BLoC PLANNING
abstract class PlanningState {}

// 📅 ÉTAT INITIAL
class PlanningInitial extends PlanningState {}

// 📅 CHARGEMENT EN COURS
class PlanningLoading extends PlanningState {}

// 📅 PRESTATIONS CHARGÉES
class PlanningLoaded extends PlanningState {
  final List<dynamic> prestations;
  final List<dynamic>? monthlyPrestations;
  final List<dynamic>? weeklyPrestations;
  final List<dynamic>? dailyPrestations;
  final Map<String, dynamic>? stats;
  final DateTime? selectedDate;
  final String? selectedView; // 'month', 'week', 'day'

  PlanningLoaded({
    required this.prestations,
    this.monthlyPrestations,
    this.weeklyPrestations,
    this.dailyPrestations,
    this.stats,
    this.selectedDate,
    this.selectedView,
  });

  PlanningLoaded copyWith({
    List<dynamic>? prestations,
    List<dynamic>? monthlyPrestations,
    List<dynamic>? weeklyPrestations,
    List<dynamic>? dailyPrestations,
    Map<String, dynamic>? stats,
    DateTime? selectedDate,
    String? selectedView,
  }) {
    return PlanningLoaded(
      prestations: prestations ?? this.prestations,
      monthlyPrestations: monthlyPrestations ?? this.monthlyPrestations,
      weeklyPrestations: weeklyPrestations ?? this.weeklyPrestations,
      dailyPrestations: dailyPrestations ?? this.dailyPrestations,
      stats: stats ?? this.stats,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedView: selectedView ?? this.selectedView,
    );
  }
}

// 📅 ERREUR
class PlanningError extends PlanningState {
  final String message;
  PlanningError(this.message);
}

// 📅 PRESTATION MISE À JOUR
class PrestationUpdated extends PlanningState {
  final Map<String, dynamic> prestation;
  PrestationUpdated(this.prestation);
}

// 📅 NOTES AJOUTÉES
class NotesAdded extends PlanningState {
  final String prestationId;
  final String notes;
  NotesAdded(this.prestationId, this.notes);
}

// 📅 STATISTIQUES CHARGÉES
class PlanningStatsLoaded extends PlanningState {
  final Map<String, dynamic> stats;
  PlanningStatsLoaded(this.stats);
}
