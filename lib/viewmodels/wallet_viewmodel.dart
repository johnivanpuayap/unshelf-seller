import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/transaction_model.dart';

part 'wallet_viewmodel.g.dart';

/// Immutable state for the wallet (balance overview + withdrawals) screen.
class WalletState {
  final bool isLoading;
  final String? errorMessage;
  final double balance;
  final List<Transaction> transactions;

  const WalletState({
    required this.isLoading,
    required this.errorMessage,
    required this.balance,
    required this.transactions,
  });

  factory WalletState.initial() => const WalletState(
        isLoading: false,
        errorMessage: null,
        balance: 0,
        transactions: <Transaction>[],
      );

  WalletState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    double? balance,
    List<Transaction>? transactions,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
    );
  }

  static const _sentinel = Object();
}

/// Wallet ViewModel — exposes the seller's running balance and transaction
/// history, derived from the wallet service's raw transaction docs.
@riverpod
class WalletViewModel extends _$WalletViewModel {
  @override
  WalletState build() => WalletState.initial();

  Future<void> withdrawRequest(double amount, String accountName,
      String bankName, String bankAccount) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final walletService = ref.read(walletServiceProvider);
      await walletService.submitWithdrawalRequest(
        amount: amount,
        accountName: accountName,
        bankName: bankName,
        bankAccount: bankAccount,
      );
      state = state.copyWith(
        isLoading: false,
        balance: state.balance - amount,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error in WalletViewModel: $e', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Refreshes [WalletState.transactions] from the wallet service and
  /// recomputes the running [WalletState.balance].
  Future<void> updateTransactions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final walletService = ref.read(walletServiceProvider);
      final docs = await walletService.fetchAllTransactions();

      final transactions = <Transaction>[];
      double newBalance = 0.0;

      for (var doc in docs) {
        final rawDate = doc['date'];
        DateTime date;
        if (rawDate is DateTime) {
          date = rawDate;
        } else {
          // Firestore Timestamp returned as a map entry; use its toDate() if available
          date = (rawDate as dynamic).toDate() as DateTime;
        }

        if (doc['type'] == StatusConstants.withdraw) {
          double amount = (doc['amount'] as num).toDouble();
          transactions.add(Transaction(
              type: StatusConstants.withdraw,
              amount: amount,
              date: date,
              orderId: 'XXXXXX-XXX'));
          newBalance -= amount;
        } else {
          String orderId = doc['orderId'] as String;

          if (doc['isPaid'] == true) {
            double sellerEarnings =
                (doc['sellerEarnings'] as num).toDouble();
            transactions.add(Transaction(
                type: StatusConstants.sale,
                amount: sellerEarnings,
                date: date,
                orderId: orderId));
            newBalance += sellerEarnings;
          } else {
            double transactionFee =
                (doc['transactionFee'] as num).toDouble();
            transactions.add(Transaction(
                type: 'Commission Fee',
                amount: transactionFee,
                date: date,
                orderId: orderId));
            newBalance -= transactionFee;
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        balance: newBalance,
        transactions: transactions,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error in WalletViewModel: $e', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
