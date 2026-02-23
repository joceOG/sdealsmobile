import 'dart:convert';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'soutrapay_event.dart';
import 'soutrapay_state.dart';

// 🎯 BLoC POUR GÉRER SOUTRAPAY SIMULÉ
class SoutraPayBloc extends Bloc<SoutraPayEvent, SoutraPayState> {
  final Random _random = Random();

  SoutraPayBloc() : super(SoutraPayInitial()) {
    // 💰 CHARGER LE SOLDE DU PRESTATAIRE
    on<LoadPrestataireBalance>((event, emit) async {
      emit(SoutraPayLoading());
      try {
        // Simulation d'un délai API
        await Future.delayed(const Duration(milliseconds: 800));

        // Données simulées
        final currentBalance = 15000.0 + _random.nextDouble() * 5000;
        final pendingAmount = 2500.0 + _random.nextDouble() * 1000;
        final totalEarnings = 45000.0 + _random.nextDouble() * 10000;
        final totalWithdrawals = 30000.0 + _random.nextDouble() * 5000;

        final stats = {
          'thisMonth': 8500.0 + _random.nextDouble() * 2000,
          'lastMonth': 7200.0 + _random.nextDouble() * 1500,
          'growth': 18.0 + _random.nextDouble() * 10,
          'transactionsCount': 25 + _random.nextInt(15),
        };

        emit(BalanceLoaded(
          currentBalance: currentBalance,
          pendingAmount: pendingAmount,
          totalEarnings: totalEarnings,
          totalWithdrawals: totalWithdrawals,
          stats: stats,
        ));
      } catch (e) {
        emit(SoutraPayError('Erreur lors du chargement du solde: $e'));
      }
    });

    // 💰 CHARGER L'HISTORIQUE DES TRANSACTIONS
    on<LoadTransactionHistory>((event, emit) async {
      emit(SoutraPayLoading());
      try {
        await Future.delayed(const Duration(milliseconds: 600));

        // Génération de transactions simulées
        final transactions = _generateMockTransactions(event.page);
        final hasMore = event.page < 3; // Simulation de pagination
        final totalAmount =
            transactions.fold(0.0, (sum, t) => sum + (t['amount'] as double));

        emit(TransactionHistoryLoaded(
          transactions: transactions,
          hasMore: hasMore,
          currentPage: event.page,
          totalAmount: totalAmount,
        ));
      } catch (e) {
        emit(SoutraPayError('Erreur lors du chargement de l\'historique: $e'));
      }
    });

    // 💰 CHARGER LES STATISTIQUES
    on<LoadSoutraPayStats>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        final stats = {
          'totalEarnings': 45000.0 + _random.nextDouble() * 10000,
          'thisMonth': 8500.0 + _random.nextDouble() * 2000,
          'averagePerMission': 1200.0 + _random.nextDouble() * 300,
          'completionRate': 95.0 + _random.nextDouble() * 5,
          'customerRating': 4.8 + _random.nextDouble() * 0.2,
        };

        final monthlyEarnings = _generateMonthlyEarnings();
        final topMissions = _generateTopMissions();

        emit(SoutraPayStatsLoaded(stats, monthlyEarnings, topMissions));
      } catch (e) {
        emit(SoutraPayError('Erreur lors du chargement des statistiques: $e'));
      }
    });

    // 💰 DEMANDER UN RETRAIT
    on<RequestWithdrawal>((event, emit) async {
      emit(SoutraPayLoading());
      try {
        await Future.delayed(const Duration(milliseconds: 1000));

        final requestId = 'REQ_${DateTime.now().millisecondsSinceEpoch}';

        emit(WithdrawalRequested(requestId, event.amount, event.method));

        // Recharger le solde après retrait
        add(LoadPrestataireBalance(event.prestataireId));
      } catch (e) {
        emit(SoutraPayError('Erreur lors de la demande de retrait: $e'));
      }
    });

    // 💰 SIMULER UN PAIEMENT REÇU
    on<SimulatePaymentReceived>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';

        emit(PaymentSimulated(transactionId, event.amount, event.description));

        // Recharger le solde après paiement
        add(LoadPrestataireBalance(event.prestataireId));
      } catch (e) {
        emit(SoutraPayError('Erreur lors de la simulation du paiement: $e'));
      }
    });

    // 💰 FILTRER LES TRANSACTIONS
    on<FilterTransactions>((event, emit) async {
      emit(SoutraPayLoading());
      try {
        await Future.delayed(const Duration(milliseconds: 400));

        final allTransactions = _generateMockTransactions(1);
        List<dynamic> filteredTransactions = allTransactions;

        if (event.type != null) {
          filteredTransactions =
              allTransactions.where((t) => t['type'] == event.type).toList();
        }

        if (event.startDate != null && event.endDate != null) {
          filteredTransactions = filteredTransactions.where((t) {
            final date = DateTime.parse(t['date']);
            return date.isAfter(event.startDate!) &&
                date.isBefore(event.endDate!);
          }).toList();
        }

        emit(TransactionsFiltered(filteredTransactions, event.type ?? 'all'));
      } catch (e) {
        emit(SoutraPayError('Erreur lors du filtrage: $e'));
      }
    });

    // 💰 RECHERCHER DANS LES TRANSACTIONS
    on<SearchTransactions>((event, emit) async {
      emit(SoutraPayLoading());
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        final allTransactions = _generateMockTransactions(1);
        final results = allTransactions.where((t) {
          final description = t['description'].toString().toLowerCase();
          final query = event.query.toLowerCase();
          return description.contains(query);
        }).toList();

        emit(TransactionsSearched(results, event.query));
      } catch (e) {
        emit(SoutraPayError('Erreur lors de la recherche: $e'));
      }
    });

    // 💰 ACTUALISER LE SOLDE
    on<RefreshBalance>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        final newBalance = 15000.0 + _random.nextDouble() * 5000;
        final recentTransactions =
            _generateMockTransactions(1).take(3).toList();

        emit(BalanceRefreshed(newBalance, recentTransactions));
      } catch (e) {
        emit(SoutraPayError('Erreur lors de l\'actualisation: $e'));
      }
    });

    // 💰 CHARGER LES MÉTHODES DE RETRAIT
    on<LoadWithdrawalMethods>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        final methods = [
          {
            'id': 'bank',
            'name': 'Virement bancaire',
            'icon': 'bank',
            'fee': 0.0,
            'minAmount': 1000.0,
            'maxAmount': 100000.0,
            'processingTime': '1-2 jours ouvrables',
          },
          {
            'id': 'mobile_money',
            'name': 'Mobile Money',
            'icon': 'phone',
            'fee': 50.0,
            'minAmount': 500.0,
            'maxAmount': 50000.0,
            'processingTime': 'Instantané',
          },
          {
            'id': 'cash',
            'name': 'Retrait en espèces',
            'icon': 'money',
            'fee': 100.0,
            'minAmount': 200.0,
            'maxAmount': 20000.0,
            'processingTime': '24h',
          },
        ];

        emit(WithdrawalMethodsLoaded(methods));
      } catch (e) {
        emit(SoutraPayError('Erreur lors du chargement des méthodes: $e'));
      }
    });

    // 💰 CHARGER LES FRAIS DE SERVICE
    on<LoadServiceFees>((event, emit) async {
      try {
        await Future.delayed(const Duration(milliseconds: 200));

        final fees = {
          'transactionFee': 2.5, // 2.5% par transaction
          'withdrawalFee': 50.0, // 50 FCFA par retrait
          'monthlyFee': 0.0, // Pas de frais mensuels
          'minimumBalance': 1000.0, // Solde minimum
        };

        emit(ServiceFeesLoaded(fees));
      } catch (e) {
        emit(SoutraPayError('Erreur lors du chargement des frais: $e'));
      }
    });
  }

  // 🔧 MÉTHODES UTILITAIRES POUR LA SIMULATION

  // 📊 Générer des transactions simulées
  List<dynamic> _generateMockTransactions(int page) {
    final transactions = <dynamic>[];
    final now = DateTime.now();

    for (int i = 0; i < 10; i++) {
      final daysAgo = (page - 1) * 10 + i;
      final date = now.subtract(Duration(days: daysAgo));

      final types = ['income', 'withdrawal', 'fee'];
      final type = types[_random.nextInt(types.length)];

      double amount;
      String description;
      String status;

      switch (type) {
        case 'income':
          amount = 500.0 + _random.nextDouble() * 2000;
          description = 'Paiement mission #${1000 + i}';
          status = 'completed';
          break;
        case 'withdrawal':
          amount = 1000.0 + _random.nextDouble() * 5000;
          description = 'Retrait vers compte bancaire';
          status = _random.nextBool() ? 'completed' : 'pending';
          break;
        case 'fee':
          amount = 25.0 + _random.nextDouble() * 100;
          description = 'Frais de service';
          status = 'completed';
          break;
        default:
          amount = 0;
          description = '';
          status = 'completed';
      }

      transactions.add({
        'id': 'TXN_${date.millisecondsSinceEpoch}',
        'type': type,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'status': status,
        'missionId': type == 'income' ? 'MISSION_${1000 + i}' : null,
      });
    }

    return transactions;
  }

  // 📈 Générer des revenus mensuels simulés
  List<dynamic> _generateMonthlyEarnings() {
    final months = <dynamic>[];
    final now = DateTime.now();

    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final earnings = 5000.0 + _random.nextDouble() * 3000;

      months.add({
        'month': month.month,
        'year': month.year,
        'earnings': earnings,
        'missions': 5 + _random.nextInt(10),
      });
    }

    return months;
  }

  // 🏆 Générer les meilleures missions simulées
  List<dynamic> _generateTopMissions() {
    final missions = <dynamic>[];

    for (int i = 0; i < 5; i++) {
      missions.add({
        'id': 'MISSION_${1000 + i}',
        'title': 'Mission ${i + 1}',
        'amount': 800.0 + _random.nextDouble() * 1200,
        'rating': 4.0 + _random.nextDouble(),
        'completedAt':
            DateTime.now().subtract(Duration(days: i + 1)).toIso8601String(),
      });
    }

    return missions;
  }
}
