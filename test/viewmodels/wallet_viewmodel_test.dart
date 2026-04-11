import 'package:flutter_test/flutter_test.dart';

import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/viewmodels/wallet_viewmodel.dart';

import '../mocks/mock_wallet_service.dart';

void main() {
  late MockWalletService mockService;

  setUp(() {
    mockService = MockWalletService();
  });

  /// Helper: constructs WalletViewModel and waits for the constructor's
  /// async `updateTransactions()` to settle.
  Future<WalletViewModel> buildVm() async {
    final vm = WalletViewModel(walletService: mockService);
    // Constructor fires updateTransactions() but doesn't await it.
    // Pump the microtask queue so the Future completes.
    await Future<void>.delayed(Duration.zero);
    return vm;
  }

  group('updateTransactions', () {
    test('sale transaction adds sellerEarnings to balance', () async {
      mockService.transactionsResult = [
        {
          'type': StatusConstants.sale,
          'sellerEarnings': 150.0,
          'isPaid': true,
          'orderId': 'ORD-1',
          'date': DateTime(2026, 4, 1),
        },
      ];

      final vm = await buildVm();

      expect(vm.balance, 150.0);
      expect(vm.transactions.length, 1);
      expect(vm.transactions.first.type, StatusConstants.sale);
      expect(vm.transactions.first.amount, 150.0);
    });

    test('withdrawal transaction subtracts amount from balance', () async {
      mockService.transactionsResult = [
        {
          'type': StatusConstants.withdraw,
          'amount': 50.0,
          'date': DateTime(2026, 4, 1),
        },
      ];

      final vm = await buildVm();

      expect(vm.balance, -50.0);
      expect(vm.transactions.length, 1);
      expect(vm.transactions.first.type, StatusConstants.withdraw);
    });

    test('commission fee transaction subtracts transactionFee', () async {
      mockService.transactionsResult = [
        {
          'type': StatusConstants.sale,
          'isPaid': false,
          'transactionFee': 10.0,
          'orderId': 'ORD-2',
          'date': DateTime(2026, 4, 1),
        },
      ];

      final vm = await buildVm();

      expect(vm.balance, -10.0);
      expect(vm.transactions.first.type, 'Commission Fee');
    });

    test('multiple transactions compute correct balance', () async {
      mockService.transactionsResult = [
        {
          'type': StatusConstants.sale,
          'sellerEarnings': 200.0,
          'isPaid': true,
          'orderId': 'ORD-1',
          'date': DateTime(2026, 4, 1),
        },
        {
          'type': StatusConstants.sale,
          'sellerEarnings': 100.0,
          'isPaid': true,
          'orderId': 'ORD-2',
          'date': DateTime(2026, 4, 2),
        },
        {
          'type': StatusConstants.withdraw,
          'amount': 75.0,
          'date': DateTime(2026, 4, 3),
        },
        {
          'type': StatusConstants.sale,
          'isPaid': false,
          'transactionFee': 15.0,
          'orderId': 'ORD-3',
          'date': DateTime(2026, 4, 3),
        },
      ];

      final vm = await buildVm();

      // 200 + 100 - 75 - 15 = 210
      expect(vm.balance, 210.0);
      expect(vm.transactions.length, 4);
    });
  });

  group('withdrawRequest', () {
    test('calls service and subtracts from balance', () async {
      mockService.transactionsResult = [
        {
          'type': StatusConstants.sale,
          'sellerEarnings': 500.0,
          'isPaid': true,
          'orderId': 'ORD-1',
          'date': DateTime(2026, 4, 1),
        },
      ];

      final vm = await buildVm();
      expect(vm.balance, 500.0);

      await vm.withdrawRequest(100.0, 'John', 'BDO', '1234567890');

      expect(vm.balance, 400.0);
      expect(mockService.submitWithdrawalCalled, 1);
      expect(mockService.lastWithdrawalAmount, 100.0);
    });
  });

  group('error handling', () {
    test('service error sets errorMessage', () async {
      mockService.transactionsResult = [];
      final vm = await buildVm();

      mockService.errorToThrow = Exception('Server down');

      await vm.withdrawRequest(50.0, 'John', 'BDO', '123');

      expect(vm.errorMessage, contains('Server down'));
    });
  });
}
