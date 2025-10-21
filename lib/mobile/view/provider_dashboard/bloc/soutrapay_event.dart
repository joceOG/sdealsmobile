// 🎯 ÉVÉNEMENTS POUR LE BLoC SOUTRAPAY SIMULÉ
abstract class SoutraPayEvent {}

// 💰 CHARGER LE SOLDE DU PRESTATAIRE
class LoadPrestataireBalance extends SoutraPayEvent {
  final String prestataireId;
  LoadPrestataireBalance(this.prestataireId);
}

// 💰 CHARGER L'HISTORIQUE DES TRANSACTIONS
class LoadTransactionHistory extends SoutraPayEvent {
  final String prestataireId;
  final int page;
  LoadTransactionHistory(this.prestataireId, {this.page = 1});
}

// 💰 CHARGER LES STATISTIQUES
class LoadSoutraPayStats extends SoutraPayEvent {
  final String prestataireId;
  LoadSoutraPayStats(this.prestataireId);
}

// 💰 DEMANDER UN RETRAIT
class RequestWithdrawal extends SoutraPayEvent {
  final String prestataireId;
  final double amount;
  final String method; // 'bank', 'mobile_money', 'cash'
  final String? accountDetails;
  RequestWithdrawal(this.prestataireId, this.amount, this.method,
      {this.accountDetails});
}

// 💰 SIMULER UN PAIEMENT REÇU
class SimulatePaymentReceived extends SoutraPayEvent {
  final String prestataireId;
  final double amount;
  final String missionId;
  final String description;
  SimulatePaymentReceived(
      this.prestataireId, this.amount, this.missionId, this.description);
}

// 💰 FILTRER LES TRANSACTIONS
class FilterTransactions extends SoutraPayEvent {
  final String prestataireId;
  final String? type; // 'income', 'withdrawal', 'fee'
  final DateTime? startDate;
  final DateTime? endDate;
  FilterTransactions(this.prestataireId,
      {this.type, this.startDate, this.endDate});
}

// 💰 RECHERCHER DANS LES TRANSACTIONS
class SearchTransactions extends SoutraPayEvent {
  final String prestataireId;
  final String query;
  SearchTransactions(this.prestataireId, this.query);
}

// 💰 ACTUALISER LE SOLDE
class RefreshBalance extends SoutraPayEvent {
  final String prestataireId;
  RefreshBalance(this.prestataireId);
}

// 💰 CHARGER LES MÉTHODES DE RETRAIT
class LoadWithdrawalMethods extends SoutraPayEvent {
  LoadWithdrawalMethods();
}

// 💰 CHARGER LES FRAIS DE SERVICE
class LoadServiceFees extends SoutraPayEvent {
  LoadServiceFees();
}
