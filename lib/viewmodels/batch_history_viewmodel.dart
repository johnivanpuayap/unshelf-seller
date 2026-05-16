import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nanoid/nanoid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/order_model.dart';

part 'batch_history_viewmodel.g.dart';

/// Immutable state for the batch-history screen.
///
/// [OrderModel] itself is still mutable; mutations to its fields are
/// preserved from the original ViewModel.
class BatchHistoryState {
  final bool isLoading;
  final String? errorMessage;
  final List<OrderModel> orders;
  final OrderModel? selectedOrder;
  final String currentStatus;
  final String sortOrder;

  const BatchHistoryState({
    required this.isLoading,
    required this.errorMessage,
    required this.orders,
    required this.selectedOrder,
    required this.currentStatus,
    required this.sortOrder,
  });

  factory BatchHistoryState.initial() => const BatchHistoryState(
        isLoading: false,
        errorMessage: null,
        orders: <OrderModel>[],
        selectedOrder: null,
        currentStatus: 'All',
        sortOrder: 'Descending',
      );

  List<OrderModel> get filteredOrders {
    final List<OrderModel> ordersToReturn = currentStatus == 'All'
        ? List<OrderModel>.from(orders)
        : orders.where((order) => order.status == currentStatus).toList();

    if (sortOrder == 'Ascending') {
      ordersToReturn.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (sortOrder == 'Descending') {
      ordersToReturn.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return ordersToReturn;
  }

  BatchHistoryState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<OrderModel>? orders,
    Object? selectedOrder = _sentinel,
    String? currentStatus,
    String? sortOrder,
  }) {
    return BatchHistoryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      orders: orders ?? this.orders,
      selectedOrder: identical(selectedOrder, _sentinel)
          ? this.selectedOrder
          : selectedOrder as OrderModel?,
      currentStatus: currentStatus ?? this.currentStatus,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static const _sentinel = Object();
}

/// Batch History ViewModel — fetches order history for a specific batch
/// and maintains a hard-coded demo [batchHistory] map alongside the live
/// orders list.
///
/// Preserves the original (pre-migration) behavior of computing
/// totalSaleSize / totalProductsSold inside [fetchBatchHistory] but never
/// surfacing them on state — they're written into [batchHistory] and the
/// view reads only the seeded map keys. The notifier keeps this mutable
/// map as a notifier-side field (it's not in state because it's
/// effectively static demo data plus per-fetch writes).
@riverpod
class BatchHistoryViewModel extends _$BatchHistoryViewModel {
  /// Hard-coded demo data. Preserved from the pre-Riverpod ViewModel —
  /// the view (`batch_history_view.dart`) reads this map directly to
  /// render the screen.
  final Map<String, Map<String, dynamic>> batchHistory = {
    // Existing Batches
    'LZOQUrGi4EhT5yV4jyA0': {
      'totalSaleSize': 13041.39 * 2,
      'totalProductsSold': 2,
      'orderHistory': [
        {
          'orderId': '20241216-003',
          'soldWithBundle': true,
          'soldQuantity': 1,
          'soldPrice': 13041.39,
        },
        {
          'orderId': '20241217-001',
          'soldWithBundle': false,
          'soldQuantity': 1,
          'soldPrice': 13041.39,
        },
      ],
    },

    '20241031-0': {
      'totalSaleSize': 1500.00 * 5,
      'totalProductsSold': 5,
      'orderHistory': [
        {
          'orderId': '20241031-001',
          'soldWithBundle': false,
          'soldQuantity': 5,
          'soldPrice': 1500.00,
        },
      ],
    },
    '20241031-1': {
      'totalSaleSize': 1200.00 * 8,
      'totalProductsSold': 8,
      'orderHistory': [
        {
          'orderId': '20241031-002',
          'soldWithBundle': true,
          'soldQuantity': 8,
          'soldPrice': 1200.00,
        },
      ],
    },
    '20241031-2': {
      'totalSaleSize': 800.00 * 3,
      'totalProductsSold': 3,
      'orderHistory': [
        {
          'orderId': '20241031-003',
          'soldWithBundle': false,
          'soldQuantity': 3,
          'soldPrice': 800.00,
        },
      ],
    },
    '20241205-0': {
      'totalSaleSize': 30 * 4,
      'totalProductsSold': 4,
      'orderHistory': [
        {
          'orderId': '20241205-001',
          'soldWithBundle': true,
          'soldQuantity': 4,
          'soldPrice': 30.00,
        },
      ],
    },
    '20241205-1': {
      'totalSaleSize': 33 * 2,
      'totalProductsSold': 2,
      'orderHistory': [
        {
          'orderId': '20241205-002',
          'soldWithBundle': false,
          'soldQuantity': 2,
          'soldPrice': 33.00,
        },
      ],
    },
    '20241214-0': {
      'totalSaleSize': 1000.00 * 10,
      'totalProductsSold': 10,
      'orderHistory': [
        {
          'orderId': '20241214-001',
          'soldWithBundle': true,
          'soldQuantity': 10,
          'soldPrice': 1000.00,
        },
      ],
    },
    '20241215-0': {
      'totalSaleSize': 750.00 * 6,
      'totalProductsSold': 6,
      'orderHistory': [
        {
          'orderId': '20241215-001',
          'soldWithBundle': false,
          'soldQuantity': 6,
          'soldPrice': 750.00,
        },
      ],
    },
  };

  @override
  BatchHistoryState build() => BatchHistoryState.initial();

  set currentStatus(String status) {
    state = state.copyWith(currentStatus: status);
  }

  set sortOrder(String order) {
    state = state.copyWith(sortOrder: order);
  }

  Future<void> fetchBatchHistory(dynamic batchId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // ignore: unused_local_variable
      final batch =
          await ref.read(batchServiceProvider).getBatchById(batchId);
      final orders =
          await ref.read(orderServiceProvider).getOrdersWithBatchId();

      double totalSaleSize = 0;
      int totalProductsSold = 0;
      int totalBatchStock = 0;

      for (var order in orders) {
        for (var item in order.items) {
          if (item.batchId == batchId) {
            totalSaleSize += (item.price ?? 0) * item.quantity;
            totalProductsSold += item.quantity;
          }
        }
      }

      batchHistory[batchId] = {
        'totalSaleSize': totalSaleSize,
        'totalProductsSold': totalProductsSold,
        'totalBatchStock': totalBatchStock,
        'orderHistory': orders,
      };

      state = state.copyWith(isLoading: false, orders: orders);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Error in BatchHistoryViewModel.fetchBatchHistory: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchOrdersHistory() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final orders = await ref.read(orderServiceProvider).getOrders(false);
      state = state.copyWith(isLoading: false, orders: orders);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Error in BatchHistoryViewModel.fetchOrdersHistory: $e',
          e,
          stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> selectOrder(String orderId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final order = await ref.read(orderServiceProvider).getOrder(orderId);
      state = state.copyWith(isLoading: false, selectedOrder: order);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Error in BatchHistoryViewModel.selectOrder: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void filterOrdersByStatus(String? status) {
    state = state.copyWith(currentStatus: status!);
  }

  Future<void> approveOrder() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final selected = state.selectedOrder!;
      await ref.read(orderServiceProvider).approveOrder(selected.id);
      selected.status = StatusConstants.processing;
      state.orders
          .firstWhere((o) => o.id == selected.id)
          .status = StatusConstants.processing;
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Error in BatchHistoryViewModel.approveOrder: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> cancelOrder() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final selected = state.selectedOrder!;
      await ref.read(orderServiceProvider).cancelOrder(selected.id);
      final now = Timestamp.now();
      selected.status = StatusConstants.cancelled;
      selected.cancelledAt = now;
      final updateOrder = state.orders.firstWhere((o) => o.id == selected.id);
      updateOrder.status = StatusConstants.cancelled;
      updateOrder.cancelledAt = now;
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Error in BatchHistoryViewModel.cancelOrder: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fulfillOrder() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final selected = state.selectedOrder!;
      final pickupCode = generatePickUpCode();
      await ref
          .read(orderServiceProvider)
          .fulfillOrder(selected.id, selected.items, pickupCode);
      selected.status = StatusConstants.ready;
      selected.pickupCode = pickupCode;
      final updateOrder = state.orders.firstWhere((o) => o.id == selected.id);
      updateOrder.status = StatusConstants.ready;
      updateOrder.pickupCode = pickupCode;
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Error in BatchHistoryViewModel.fulfillOrder: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  String generatePickUpCode() {
    return customAlphabet('1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ', 8);
  }

  Future<void> completeOrder() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final selected = state.selectedOrder!;
      await ref.read(orderServiceProvider).completeOrder(selected.id);
      final now = Timestamp.now();
      selected.status = StatusConstants.completed;
      selected.completedAt = now;
      selected.isPaid = true;
      final updateOrder = state.orders.firstWhere((o) => o.id == selected.id);
      updateOrder.status = StatusConstants.completed;
      updateOrder.completedAt = now;
      updateOrder.isPaid = true;
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Error in BatchHistoryViewModel.completeOrder: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
