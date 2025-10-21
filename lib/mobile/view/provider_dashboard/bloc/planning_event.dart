// 🎯 ÉVÉNEMENTS POUR LE BLoC PLANNING
abstract class PlanningEvent {}

// 📅 CHARGER LES PRESTATIONS DU PRESTATAIRE
class LoadPrestationsPlanning extends PlanningEvent {
  final String prestataireId;
  LoadPrestationsPlanning(this.prestataireId);
}

// 📅 CHARGER LES PRESTATIONS PAR DATE
class LoadPrestationsByDate extends PlanningEvent {
  final DateTime date;
  LoadPrestationsByDate(this.date);
}

// 📅 CHARGER LES PRESTATIONS PAR STATUT
class LoadPrestationsByStatus extends PlanningEvent {
  final String status;
  LoadPrestationsByStatus(this.status);
}

// 📅 FILTRER LES PRESTATIONS
class FilterPrestations extends PlanningEvent {
  final Map<String, dynamic> filters;
  FilterPrestations(this.filters);
}

// 📅 METTRE À JOUR LE STATUT D'UNE PRESTATION
class UpdatePrestationStatus extends PlanningEvent {
  final String prestationId;
  final String newStatus;
  final String? notes;
  UpdatePrestationStatus(this.prestationId, this.newStatus, {this.notes});
}

// 📅 AJOUTER DES NOTES À UNE PRESTATION
class AddPrestationNotes extends PlanningEvent {
  final String prestationId;
  final String notes;
  AddPrestationNotes(this.prestationId, this.notes);
}

// 📅 CHARGER LES STATISTIQUES DU PLANNING
class LoadPlanningStats extends PlanningEvent {
  final String prestataireId;
  LoadPlanningStats(this.prestataireId);
}

// 📅 CHARGER LES PRESTATIONS DU MOIS
class LoadMonthlyPrestations extends PlanningEvent {
  final DateTime month;
  LoadMonthlyPrestations(this.month);
}

// 📅 CHARGER LES PRESTATIONS DE LA SEMAINE
class LoadWeeklyPrestations extends PlanningEvent {
  final DateTime weekStart;
  LoadWeeklyPrestations(this.weekStart);
}

// 📅 CHARGER LES PRESTATIONS DU JOUR
class LoadDailyPrestations extends PlanningEvent {
  final DateTime day;
  LoadDailyPrestations(this.day);
}
