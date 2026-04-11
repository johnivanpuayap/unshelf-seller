import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unshelf_seller/core/constants/status_constants.dart';
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

void main() {
  late MockOrderService mockService;
  late OrderViewModel vm;

  setUp(() {
    mockService = MockOrderService();
    vm = OrderViewModel(orderService: mockService);
  });

  group('fetchOrders', () {
    test('stores orders from service and sets loading states', () async {
      final orders = [
        _makeOrder(id: '1', status: StatusConstants.pending),
        _makeOrder(id: '2', status: StatusConstants.completed),
      ];
      mockService.ordersResult = orders;

      await vm.fetchOrders();

      expect(vm.orders, equals(orders));
      expect(vm.isLoading, isFalse);
      expect(mockService.lastForToday, isTrue);
    });

    test('fetchOrdersHistory passes forToday=false', () async {
      mockService.ordersResult = [];

      await vm.fetchOrdersHistory();

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
      await vm.fetchOrders();

      vm.currentStatus = 'All';

      expect(vm.filteredOrders.length, 3);
    });

    test('filters orders by specific status', () async {
      mockService.ordersResult = [
        _makeOrder(id: '1', status: StatusConstants.pending),
        _makeOrder(id: '2', status: StatusConstants.completed),
        _makeOrder(id: '3', status: StatusConstants.pending),
      ];
      await vm.fetchOrders();

      vm.currentStatus = StatusConstants.pending;

      expect(vm.filteredOrders.length, 2);
      expect(
        vm.filteredOrders.every((o) => o.status == StatusConstants.pending),
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
      await vm.fetchOrders();

      final filtered = vm.filteredOrders;

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
      await vm.fetchOrders();

      vm.sortOrder = 'Ascending';
      final filtered = vm.filteredOrders;

      expect(filtered[0].id, '2'); // January (oldest first)
      expect(filtered[1].id, '1'); // March
    });
  });

  group('selectOrder', () {
    test('sets selectedOrder from service', () async {
      final order = _makeOrder(id: '1', status: StatusConstants.pending);
      mockService.orderResult = order;

      await vm.selectOrder('1');

      expect(vm.selectedOrder, equals(order));
      expect(vm.isLoading, isFalse);
    });
  });

  group('order state transitions', () {
    late OrderModel order;

    setUp(() async {
      order = _makeOrder(id: '1', status: StatusConstants.pending);
      mockService.ordersResult = [order];
      await vm.fetchOrders();
      mockService.orderResult = order;
      await vm.selectOrder('1');
    });

    test('approveOrder updates status to Processing', () async {
      await vm.approveOrder();

      expect(vm.selectedOrder!.status, StatusConstants.processing);
      expect(vm.orders.first.status, StatusConstants.processing);
      expect(mockService.approveOrderCalled, 1);
    });

    test('cancelOrder updates status and sets cancelledAt', () async {
      await vm.cancelOrder();

      expect(vm.selectedOrder!.status, StatusConstants.cancelled);
      expect(vm.selectedOrder!.cancelledAt, isNotNull);
      expect(vm.orders.first.status, StatusConstants.cancelled);
      expect(mockService.cancelOrderCalled, 1);
    });

    test('fulfillOrder updates status and generates pickupCode', () async {
      await vm.fulfillOrder();

      expect(vm.selectedOrder!.status, StatusConstants.ready);
      expect(vm.selectedOrder!.pickupCode, isNotEmpty);
      expect(vm.selectedOrder!.pickupCode!.length, 8);
      expect(vm.orders.first.status, StatusConstants.ready);
      expect(mockService.fulfillOrderCalled, 1);
    });

    test('completeOrder updates status, completedAt, and isPaid', () async {
      await vm.completeOrder();

      expect(vm.selectedOrder!.status, StatusConstants.completed);
      expect(vm.selectedOrder!.completedAt, isNotNull);
      expect(vm.selectedOrder!.isPaid, isTrue);
      expect(vm.orders.first.status, StatusConstants.completed);
      expect(mockService.completeOrderCalled, 1);
    });
  });

  group('error handling', () {
    test('service error sets errorMessage via runBusyFuture', () async {
      final order = _makeOrder(id: '1', status: StatusConstants.pending);
      mockService.ordersResult = [order];
      await vm.fetchOrders();
      mockService.orderResult = order;
      await vm.selectOrder('1');

      mockService.errorToThrow = Exception('Network error');

      await vm.approveOrder();

      expect(vm.errorMessage, contains('Network error'));
      expect(vm.isLoading, isFalse);
    });
  });

  group('clear', () {
    test('resets orders, selectedOrder, and currentStatus', () async {
      mockService.ordersResult = [
        _makeOrder(id: '1', status: StatusConstants.pending),
      ];
      await vm.fetchOrders();
      vm.currentStatus = StatusConstants.pending;

      vm.clear();

      expect(vm.orders, isEmpty);
      expect(vm.selectedOrder, isNull);
      expect(vm.currentStatus, 'All');
    });

    test('clearSelectedOrder nulls only selectedOrder', () async {
      final order = _makeOrder(id: '1', status: StatusConstants.pending);
      mockService.ordersResult = [order];
      await vm.fetchOrders();
      mockService.orderResult = order;
      await vm.selectOrder('1');

      vm.clearSelectedOrder();

      expect(vm.selectedOrder, isNull);
      expect(vm.orders, isNotEmpty);
    });
  });
}
