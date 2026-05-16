import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/viewmodels/wallet_viewmodel.dart';

import '../mocks/mock_wallet_service.dart';

/// Builds a [ProviderContainer] with the wallet ViewModel's service
/// dependency overridden with the given mock.
ProviderContainer _makeContainer(MockWalletService walletService) {
  final container = ProviderContainer(overrides: [
    walletServiceProvider.overrideWithValue(walletService),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockWalletService mockService;

  setUp(() {
    mockService = MockWalletService();
  });

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

      final container = _makeContainer(mockService);
      await container
          .read(walletViewModelProvider.notifier)
          .updateTransactions();

      final state = container.read(walletViewModelProvider);
      expect(state.balance, 150.0);
      expect(state.transactions.length, 1);
      expect(state.transactions.first.type, StatusConstants.sale);
      expect(state.transactions.first.amount, 150.0);
    });

    test('withdrawal transaction subtracts amount from balance', () async {
      mockService.transactionsResult = [
        {
          'type': StatusConstants.withdraw,
          'amount': 50.0,
          'date': DateTime(2026, 4, 1),
        },
      ];

      final container = _makeContainer(mockService);
      await container
          .read(walletViewModelProvider.notifier)
          .updateTransactions();

      final state = container.read(walletViewModelProvider);
      expect(state.balance, -50.0);
      expect(state.transactions.length, 1);
      expect(state.transactions.first.type, StatusConstants.withdraw);
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

      final container = _makeContainer(mockService);
      await container
          .read(walletViewModelProvider.notifier)
          .updateTransactions();

      final state = container.read(walletViewModelProvider);
      expect(state.balance, -10.0);
      expect(state.transactions.first.type, 'Commission Fee');
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

      final container = _makeContainer(mockService);
      await container
          .read(walletViewModelProvider.notifier)
          .updateTransactions();

      // 200 + 100 - 75 - 15 = 210
      final state = container.read(walletViewModelProvider);
      expect(state.balance, 210.0);
      expect(state.transactions.length, 4);
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

      final container = _makeContainer(mockService);
      await container
          .read(walletViewModelProvider.notifier)
          .updateTransactions();
      expect(container.read(walletViewModelProvider).balance, 500.0);

      await container
          .read(walletViewModelProvider.notifier)
          .withdrawRequest(100.0, 'John', 'BDO', '1234567890');

      expect(container.read(walletViewModelProvider).balance, 400.0);
      expect(mockService.submitWithdrawalCalled, 1);
      expect(mockService.lastWithdrawalAmount, 100.0);
    });
  });

  group('error handling', () {
    test('service error sets errorMessage', () async {
      mockService.transactionsResult = [];
      final container = _makeContainer(mockService);
      await container
          .read(walletViewModelProvider.notifier)
          .updateTransactions();

      mockService.errorToThrow = Exception('Server down');

      await container
          .read(walletViewModelProvider.notifier)
          .withdrawRequest(50.0, 'John', 'BDO', '123');

      final state = container.read(walletViewModelProvider);
      expect(state.errorMessage, contains('Server down'));
    });
  });
}
