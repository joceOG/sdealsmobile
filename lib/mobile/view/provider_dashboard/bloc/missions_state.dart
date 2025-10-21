// 🎯 ÉTATS POUR LE BLoC MISSIONS

// 🎯 ÉTAT INITIAL
class MissionsInitial extends MissionsState {}

// 🎯 ÉTAT DE CHARGEMENT
class MissionsLoading extends MissionsState {}

// 🎯 ÉTAT DE SUCCÈS - MISSIONS CHARGÉES
class MissionsLoaded extends MissionsState {
  final List<dynamic>? availableMissions;
  final List<dynamic>? ongoingMissions;
  final List<dynamic>? completedMissions;
  final List<dynamic>? rejectedMissions;

  MissionsLoaded({
    this.availableMissions,
    this.ongoingMissions,
    this.completedMissions,
    this.rejectedMissions,
  });
}

// 🎯 ÉTAT D'ERREUR
class MissionsError extends MissionsState {
  final String message;

  MissionsError(this.message);
}

// 🎯 ÉTATS DE SUCCÈS POUR ACTIONS SPÉCIFIQUES
class MissionAppliedSuccessfully extends MissionsState {}

class MissionAcceptedSuccessfully extends MissionsState {}

class MissionRejectedSuccessfully extends MissionsState {}

class MissionCompletedSuccessfully extends MissionsState {}

// 🎯 CLASSE DE BASE POUR TOUS LES ÉTATS
abstract class MissionsState {}
