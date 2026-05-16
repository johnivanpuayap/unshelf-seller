import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nanoid/nanoid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/order_model.dart';

part 'order_viewmodel.g.dart';

/// Immutable state for the orders screens (today + history + details).
///
/// [OrderModel] itself is still a mutable class — we preserve those
/// in-place mutations (status/timestamps) so existing widgets and tests
/// continue to work — and re-emit a new [OrderState] after each mutation
/// so Riverpod watchers rebuild.
class OrderState {
  final bool isLoading;
  final String? errorMessage;
  final List<OrderModel> orders;
  final OrderModel? selectedOrder;
  final String currentStatus;
  final String sortOrder;

  const OrderState({
    required this.isLoading,
    required this.errorMessage,
    required this.orders,
    required this.selectedOrder,
    required this.currentStatus,
    required this.sortOrder,
  });

  factory OrderState.initial() => const OrderState(
        isLoading: false,
        errorMessage: null,
        orders: <OrderModel>[],
        selectedOrder: null,
        currentStatus: 'All',
        sortOrder: 'Descending',
      );

  /// Computed: orders filtered by [currentStatus], then sorted by
  /// [createdAt] in [sortOrder] direction. Matches the original
  /// `OrderViewModel.filteredOrders` getter behavior — mutates the
  /// underlying list in-place via `sort` when there is a copy
  /// (we copy here to avoid mutating [orders]).
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

  OrderState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<OrderModel>? orders,
    Object? selectedOrder = _sentinel,
    String? currentStatus,
    String? sortOrder,
  }) {
    return OrderState(
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

/// Order ViewModel — manages today's order list, order history, and the
/// currently-selected order's state transitions (approve / cancel /
/// fulfill / complete).
@riverpod
class OrderViewModel extends _$OrderViewModel {
  @override
  OrderState build() => OrderState.initial();

  set currentStatus(String status) {
    state = state.copyWith(currentStatus: status);
  }

  set sortOrder(String order) {
    state = state.copyWith(sortOrder: order);
  }

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    AppLogger.debug('Fetching orders for today...');
    try {
      final orders = await ref.read(orderServiceProvider).getOrders(true);
      state = state.copyWith(isLoading: false, orders: orders);
    } catch (e, stackTrace) {
      AppLogger.error('Error in OrderViewModel: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchOrdersHistory() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final orders = await ref.read(orderServiceProvider).getOrders(false);
      state = state.copyWith(isLoading: false, orders: orders);
    } catch (e, stackTrace) {
      AppLogger.error('Error in OrderViewModel: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> selectOrder(String orderId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final order = await ref.read(orderServiceProvider).getOrder(orderId);
      state = state.copyWith(isLoading: false, selectedOrder: order);
    } catch (e, stackTrace) {
      AppLogger.error('Error in OrderViewModel: $e', e, stackTrace);
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
      AppLogger.error('Error in OrderViewModel: $e', e, stackTrace);
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
      AppLogger.error('Error in OrderViewModel: $e', e, stackTrace);
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
      AppLogger.error('Error in OrderViewModel: $e', e, stackTrace);
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
      AppLogger.error('Error in OrderViewModel: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clear() {
    state = state.copyWith(
      orders: const <OrderModel>[],
      selectedOrder: null,
      currentStatus: 'All',
    );
  }

  void clearSelectedOrder() {
    state = state.copyWith(selectedOrder: null);
  }
}
