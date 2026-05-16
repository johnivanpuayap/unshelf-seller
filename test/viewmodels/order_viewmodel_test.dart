import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/order_model.dart';
import 'package:unshelf_seller/viewmodels/order_viewmodel.dart';

import '../mocks/mock_order_service.dart';

OrderModel _makeOrder({
  required String id,
  required String status,
  bool isPaid = false,
  DateTime? createdAt,
}) {
  return OrderModel(
    id: id,
    orderId: 'ORD-$id',
    buyerId: 'buyer-1',
    items: [],
    status: status,
    createdAt: Timestamp.fromDate(createdAt ?? DateTime(2026, 4, 1)),
    isPaid: isPaid,
  );
}

/// Builds a [ProviderContainer] with the order ViewModel's service
/// dependency overridden with the given mock.
ProviderContainer _makeContainer(MockOrderService orderService) {
  final container = ProviderContainer(overrides: [
    orderServiceProvider.overrideWithValue(orderService),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockOrderService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockOrderService();
    container = _makeContainer(mockService);
  });

  group('fetchOrders', () {
    test('stores orders from service and sets loading states', () async {
      final orders = [
        _makeOrder(id: '1', status: StatusConstants.pending),
        _makeOrder(id: '2', status: StatusConstants.completed),
      ];
      mockService.ordersResult = orders;

      await container.read(orderViewModelProvider.notifier).fetchOrders();

      final state = container.read(orderViewModelProvider);
      expect(state.orders, equals(orders));
      expect(state.isLoading, isFalse);
      expect(mockService.lastForToday, isTrue);
    });

    test('fetchOrdersHistory passes forToday=false', () async {
      mockService.ordersResult = [];

      await container
          .read(orderViewModelProvider.notifier)
          .fetchOrdersHistory();

      expect(mockService.lastForToday, isFalse);
    });
  });

  group('filteredOrders', () {
    test('returns all orders when status is All', () async {
      mockService.ordersResult = [
        _makeOrder(id: '1', status: StatusConstants.pending),
        _makeOrder(id: '2', status: StatusConstants.completed),
        _makeOrder(id: '3', status: StatusConstants.cancelled),
      ];
      await container.read(orderViewModelProvider.notifier).fetchOrders();
      container.read(orderViewModelProvider.notifier).currentStatus = 'All';

      expect(container.read(orderViewModelProvider).filteredOrders.length, 3);
    });

    test('filters orders by specific status', () async {
      mockService.ordersResult = [
        _makeOrder(id: '1', status: StatusConstants.pending),
        _makeOrder(id: '2', status: StatusConstants.completed),
        _makeOrder(id: '3', status: StatusConstants.pending),
      ];
      await container.read(orderViewModelProvider.notifier).fetchOrders();
      container.read(orderViewModelProvider.notifier).currentStatus =
          StatusConstants.pending;

      final filtered = container.read(orderViewModelProvider).filteredOrders;
      expect(filtered.length, 2);
      expect(
        filtered.every((o) => o.status == StatusConstants.pending),
        isTrue,
      );
    });

    test('sorts descending by default', () async {
      mockService.ordersResult = [
        _makeOrder(
            id: '1',
            status: StatusConstants.pending,
            createdAt: DateTime(2026, 1, 1)),
        _makeOrder(
            id: '2',
            status: StatusConstants.pending,
            createdAt: DateTime(2026, 3, 1)),
        _makeOrder(
            id: '3',
            status: StatusConstants.pending,
            createdAt: DateTime(2026, 2, 1)),
      ];
      await container.read(orderViewModelProvider.notifier).fetchOrders();

      final filtered = container.read(orderViewModelProvider).filteredOrders;
      expect(filtered[0].id, '2'); // March (newest)
      expect(filtered[1].id, '3'); // February
      expect(filtered[2].id, '1'); // January (oldest)
    });

    test('sorts ascending when set', () async {
      mockService.ordersResult = [
        _makeOrder(
            id: '1',
            status: StatusConstants.pending,
            createdAt: DateTime(2026, 3, 1)),
        _makeOrder(
            id: '2',
            status: StatusConstants.pending,
            createdAt: DateTime(2026, 1, 1)),
      ];
      await container.read(orderViewModelProvider.notifier).fetchOrders();
      container.read(orderViewModelProvider.notifier).sortOrder = 'Ascending';

      final filtered = container.read(orderViewModelProvider).filteredOrders;
      expect(filtered[0].id, '2'); // January (oldest first)
      expect(filtered[1].id, '1'); // March
    });
  });

  group('selectOrder', () {
    test('sets selectedOrder from service', () async {
      final order = _makeOrder(id: '1', status: StatusConstants.pending);
      mockService.orderResult = order;

      await container.read(orderViewModelProvider.notifier).selectOrder('1');

      final state = container.read(orderViewModelProvider);
      expect(state.selectedOrder, equals(order));
      expect(state.isLoading, isFalse);
    });
  });

  group('order state transitions', () {
    late OrderModel order;

    setUp(() async {
      order = _makeOrder(id: '1', status: StatusConstants.pending);
      mockService.ordersResult = [order];
      await container.read(orderViewModelProvider.notifier).fetchOrders();
      mockService.orderResult = order;
      await container.read(orderViewModelProvider.notifier).selectOrder('1');
    });

    test('approveOrder updates status to Processing', () async {
      await container.read(orderViewModelProvider.notifier).approveOrder();

      final state = container.read(orderViewModelProvider);
      expect(state.selectedOrder!.status, StatusConstants.processing);
      expect(state.orders.first.status, StatusConstants.processing);
      expect(mockService.approveOrderCalled, 1);
    });

    test('cancelOrder updates status and sets cancelledAt', () async {
      await container.read(orderViewModelProvider.notifier).cancelOrder();

      final state = container.read(orderViewModelProvider);
      expect(state.selectedOrder!.status, StatusConstants.cancelled);
      expect(state.selectedOrder!.cancelledAt, isNotNull);
      expect(state.orders.first.status, StatusConstants.cancelled);
      expect(mockService.cancelOrderCalled, 1);
    });

    test('fulfillOrder updates status and generates pickupCode', () async {
      await container.read(orderViewModelProvider.notifier).fulfillOrder();

      final state = container.read(orderViewModelProvider);
      expect(state.selectedOrder!.status, StatusConstants.ready);
      expect(state.selectedOrder!.pickupCode, isNotEmpty);
      expect(state.selectedOrder!.pickupCode!.length, 8);
      expect(state.orders.first.status, StatusConstants.ready);
      expect(mockService.fulfillOrderCalled, 1);
    });

    test('completeOrder updates status, completedAt, and isPaid', () async {
      await container.read(orderViewModelProvider.notifier).completeOrder();

      final state = container.read(orderViewModelProvider);
      expect(state.selectedOrder!.status, StatusConstants.completed);
      expect(state.selectedOrder!.completedAt, isNotNull);
      expect(state.selectedOrder!.isPaid, isTrue);
      expect(state.orders.first.status, StatusConstants.completed);
      expect(mockService.completeOrderCalled, 1);
    });
  });

  group('error handling', () {
    test('service error sets errorMessage', () async {
      final order = _makeOrder(id: '1', status: StatusConstants.pending);
      mockService.ordersResult = [order];
      await container.read(orderViewModelProvider.notifier).fetchOrders();
      mockService.orderResult = order;
      await container.read(orderViewModelProvider.notifier).selectOrder('1');

      mockService.errorToThrow = Exception('Network error');

      await container.read(orderViewModelProvider.notifier).approveOrder();

      final state = container.read(orderViewModelProvider);
      expect(state.errorMessage, contains('Network error'));
      expect(state.isLoading, isFalse);
    });
  });

  group('clear', () {
    test('resets orders, selectedOrder, and currentStatus', () async {
      mockService.ordersResult = [
        _makeOrder(id: '1', status: StatusConstants.pending),
      ];
      await container.read(orderViewModelProvider.notifier).fetchOrders();
      container.read(orderViewModelProvider.notifier).currentStatus =
          StatusConstants.pending;

      container.read(orderViewModelProvider.notifier).clear();

      final state = container.read(orderViewModelProvider);
      expect(state.orders, isEmpty);
      expect(state.selectedOrder, isNull);
      expect(state.currentStatus, 'All');
    });

    test('clearSelectedOrder nulls only selectedOrder', () async {
      final order = _makeOrder(id: '1', status: StatusConstants.pending);
      mockService.ordersResult = [order];
      await container.read(orderViewModelProvider.notifier).fetchOrders();
      mockService.orderResult = order;
      await container.read(orderViewModelProvider.notifier).selectOrder('1');

      container.read(orderViewModelProvider.notifier).clearSelectedOrder();

      final state = container.read(orderViewModelProvider);
      expect(state.selectedOrder, isNull);
      expect(state.orders, isNotEmpty);
    });
  });
}
