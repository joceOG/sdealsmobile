// 🎯 ÉTATS POUR LE BLoC SOUTRAPAY SIMULÉ
abstract class SoutraPayState {}

// 💰 ÉTAT INITIAL
class SoutraPayInitial extends SoutraPayState {}

// 💰 CHARGEMENT EN COURS
class SoutraPayLoading extends SoutraPayState {}

// 💰 SOLDE CHARGÉ
class BalanceLoaded extends SoutraPayState {
  final double currentBalance;
  final double pendingAmount;
  final double totalEarnings;
  final double totalWithdrawals;
  final Map<String, dynamic>? stats;

  BalanceLoaded({
    required this.currentBalance,
    required this.pendingAmount,
    required this.totalEarnings,
    required this.totalWithdrawals,
    this.stats,
  });

  BalanceLoaded copyWith({
    double? currentBalance,
    double? pendingAmount,
    double? totalEarnings,
    double? totalWithdrawals,
    Map<String, dynamic>? stats,
  }) {
    return BalanceLoaded(
      currentBalance: currentBalance ?? this.currentBalance,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      stats: stats ?? this.stats,
    );
  }
}

// 💰 HISTORIQUE CHARGÉ
class TransactionHistoryLoaded extends SoutraPayState {
  final List<dynamic> transactions;
  final bool hasMore;
  final int currentPage;
  final double totalAmount;

  TransactionHistoryLoaded({
    required this.transactions,
    required this.hasMore,
    required this.currentPage,
    required this.totalAmount,
  });

  TransactionHistoryLoaded copyWith({
    List<dynamic>? transactions,
    bool? hasMore,
    int? currentPage,
    double? totalAmount,
  }) {
    return TransactionHistoryLoaded(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}

// 💰 STATISTIQUES CHARGÉES
class SoutraPayStatsLoaded extends SoutraPayState {
  final Map<String, dynamic> stats;
  final List<dynamic> monthlyEarnings;
  final List<dynamic> topMissions;
  SoutraPayStatsLoaded(this.stats, this.monthlyEarnings, this.topMissions);
}

// 💰 RETRAIT DEMANDÉ
class WithdrawalRequested extends SoutraPayState {
  final String requestId;
  final double amount;
  final String method;
  WithdrawalRequested(this.requestId, this.amount, this.method);
}

// 💰 PAIEMENT SIMULÉ
class PaymentSimulated extends SoutraPayState {
  final String transactionId;
  final double amount;
  final String description;
  PaymentSimulated(this.transactionId, this.amount, this.description);
}

// 💰 TRANSACTIONS FILTRÉES
class TransactionsFiltered extends SoutraPayState {
  final List<dynamic> transactions;
  final String filterType;
  TransactionsFiltered(this.transactions, this.filterType);
}

// 💰 RECHERCHE EFFECTUÉE
class TransactionsSearched extends SoutraPayState {
  final List<dynamic> results;
  final String query;
  TransactionsSearched(this.results, this.query);
}

// 💰 MÉTHODES DE RETRAIT CHARGÉES
class WithdrawalMethodsLoaded extends SoutraPayState {
  final List<dynamic> methods;
  WithdrawalMethodsLoaded(this.methods);
}

// 💰 FRAIS DE SERVICE CHARGÉS
class ServiceFeesLoaded extends SoutraPayState {
  final Map<String, dynamic> fees;
  ServiceFeesLoaded(this.fees);
}

// 💰 SOLDE ACTUALISÉ
class BalanceRefreshed extends SoutraPayState {
  final double newBalance;
  final List<dynamic> recentTransactions;
  BalanceRefreshed(this.newBalance, this.recentTransactions);
}

// 💰 ERREUR
class SoutraPayError extends SoutraPayState {
  final String message;
  SoutraPayError(this.message);
}
