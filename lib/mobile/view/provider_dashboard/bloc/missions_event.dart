// 🎯 ÉVÉNEMENTS POUR LE BLoC MISSIONS

// 🎯 CHARGER LES MISSIONS DISPONIBLES
class LoadAvailableMissions extends MissionsEvent {}

// 🎯 CHARGER LES MISSIONS EN COURS
class LoadOngoingMissions extends MissionsEvent {}

// 🎯 CHARGER LES MISSIONS TERMINÉES
class LoadCompletedMissions extends MissionsEvent {}

// 🎯 POSTULER À UNE MISSION
class ApplyToMission extends MissionsEvent {
  final String missionId;
  final String message;
  final double? proposedPrice;

  ApplyToMission({
    required this.missionId,
    required this.message,
    this.proposedPrice,
  });
}

// 🎯 ACCEPTER UNE MISSION
class AcceptMission extends MissionsEvent {
  final String missionId;

  AcceptMission({required this.missionId});
}

// 🎯 REFUSER UNE MISSION
class RejectMission extends MissionsEvent {
  final String missionId;
  final String reason;

  RejectMission({
    required this.missionId,
    required this.reason,
  });
}

// 🎯 TERMINER UNE MISSION
class CompleteMission extends MissionsEvent {
  final String missionId;
  final String completionNotes;
  final List<String> photos;

  CompleteMission({
    required this.missionId,
    required this.completionNotes,
    required this.photos,
  });
}

// 🎯 FILTRER LES MISSIONS
class FilterMissions extends MissionsEvent {
  final String searchQuery;
  final String location;
  final String priceRange;
  final String urgency;

  FilterMissions({
    required this.searchQuery,
    required this.location,
    required this.priceRange,
    required this.urgency,
  });
}

// 🎯 CLASSE DE BASE POUR TOUS LES ÉVÉNEMENTS
abstract class MissionsEvent {}
