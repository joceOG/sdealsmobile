import 'package:equatable/equatable.dart';
import '../../../../data/models/history.dart';

abstract class HistoryPageStateM extends Equatable {
  const HistoryPageStateM();

  @override
  List<Object?> get props => [];
}

// 🔄 ÉTAT INITIAL
class HistoryPageInitialM extends HistoryPageStateM {
  const HistoryPageInitialM();
}

// ⏳ ÉTAT DE CHARGEMENT
class HistoryPageLoadingM extends HistoryPageStateM {
  const HistoryPageLoadingM();
}

// ✅ ÉTAT DE SUCCÈS - DONNÉES CHARGÉES
class HistoryPageLoadedM extends HistoryPageStateM {
  final List<History> history;
  final Map<String, dynamic>? pagination;
  final Map<String, dynamic>? stats;
  final List<History>? recentHistory;
  final List<History>? historyByType;

  const HistoryPageLoadedM({
    required this.history,
    this.pagination,
    this.stats,
    this.recentHistory,
    this.historyByType,
  });

  @override
  List<Object?> get props => [
        history,
        pagination,
        stats,
        recentHistory,
        historyByType,
      ];
}

// ❌ ÉTAT D'ERREUR
class HistoryPageErrorM extends HistoryPageStateM {
  final String message;
  final String? code;

  const HistoryPageErrorM({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

// ➕ ÉTAT DE SUCCÈS - CONSULTATION AJOUTÉE
class HistoryAddedM extends HistoryPageStateM {
  final History history;

  const HistoryAddedM({
    required this.history,
  });

  @override
  List<Object?> get props => [history];
}

// ✏️ ÉTAT DE SUCCÈS - CONSULTATION MODIFIÉE
class HistoryUpdatedM extends HistoryPageStateM {
  final History history;

  const HistoryUpdatedM({
    required this.history,
  });

  @override
  List<Object?> get props => [history];
}

// 🗑️ ÉTAT DE SUCCÈS - CONSULTATION SUPPRIMÉE
class HistoryDeletedM extends HistoryPageStateM {
  final String historyId;

  const HistoryDeletedM({
    required this.historyId,
  });

  @override
  List<Object?> get props => [historyId];
}

// 📊 ÉTAT DE SUCCÈS - STATISTIQUES CHARGÉES
class HistoryStatsLoadedM extends HistoryPageStateM {
  final Map<String, dynamic> stats;

  const HistoryStatsLoadedM({
    required this.stats,
  });

  @override
  List<Object?> get props => [stats];
}

// 📱 ÉTAT DE SUCCÈS - CONSULTATIONS RÉCENTES CHARGÉES
class RecentHistoryLoadedM extends HistoryPageStateM {
  final List<History> recentHistory;

  const RecentHistoryLoadedM({
    required this.recentHistory,
  });

  @override
  List<Object?> get props => [recentHistory];
}

// 🏷️ ÉTAT DE SUCCÈS - CONSULTATIONS PAR TYPE CHARGÉES
class HistoryByTypeLoadedM extends HistoryPageStateM {
  final List<History> historyByType;
  final String objetType;

  const HistoryByTypeLoadedM({
    required this.historyByType,
    required this.objetType,
  });

  @override
  List<Object?> get props => [historyByType, objetType];
}

// 🔄 ÉTAT DE SUCCÈS - CONSULTATION ARCHIVÉE
class HistoryArchivedM extends HistoryPageStateM {
  final String historyId;

  const HistoryArchivedM({
    required this.historyId,
  });

  @override
  List<Object?> get props => [historyId];
}

// 🧹 ÉTAT DE SUCCÈS - HISTORIQUE NETTOYÉ
class HistoryCleanedM extends HistoryPageStateM {
  final int deletedCount;

  const HistoryCleanedM({
    required this.deletedCount,
  });

  @override
  List<Object?> get props => [deletedCount];
}

// 🔍 ÉTAT DE SUCCÈS - RECHERCHE EFFECTUÉE
class HistorySearchedM extends HistoryPageStateM {
  final List<History> searchResults;
  final String query;

  const HistorySearchedM({
    required this.searchResults,
    required this.query,
  });

  @override
  List<Object?> get props => [searchResults, query];
}



