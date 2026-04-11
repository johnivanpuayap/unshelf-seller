import 'package:unshelf_seller/core/interfaces/i_wallet_service.dart';

class MockWalletService implements IWalletService {
  List<Map<String, dynamic>> transactionsResult = [];
  Exception? errorToThrow;

  int submitWithdrawalCalled = 0;
  int fetchTransactionsCalled = 0;
  double? lastWithdrawalAmount;

  @override
  Future<void> submitWithdrawalRequest({
    required double amount,
    required String accountName,
    required String bankName,
    required String bankAccount,
  }) async {
    submitWithdrawalCalled++;
    lastWithdrawalAmount = amount;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllTransactions() async {
    fetchTransactionsCalled++;
    if (errorToThrow != null) throw errorToThrow!;
    return transactionsResult;
  }
}
