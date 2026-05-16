import 'package:unshelf_seller/models/order_model.dart';

abstract class OrdersRepository {
  Stream<List<OrderModel>> watchOrders(String storeId);
  Future<OrderModel?> getOrder(String orderId);
  Future<void> updateOrderStatus(String orderId, String status);

  // One-shot read of orders for a seller. Mirrors the `.get()` semantics in
  // [OrderService.getOrders] / [OrderService.getOrdersWithBatchId]. The
  // service applies any time-window filtering on top of this result; the
  // repository deliberately stays a thin pass-through. Added in Task 3.5 so
  // the service can drop its direct Firestore query.
  Future<List<OrderModel>> getOrdersByStore(String storeId);

  // Atomic order cancellation: sets status to Cancelled and stamps
  // `cancelledAt`. Mirrors [OrderService.cancelOrder].
  Future<void> cancelOrder(String orderId);

  // Atomic fulfillment transaction:
  //   * for each item, decrement bundle/batch stock with insufficient-stock
  //     check
  //   * stamp `pickupCode` and set status to Ready
  // Mirrors [OrderService.fulfillOrder]. Throws on insufficient stock.
  Future<void> fulfillOrder(
    String orderId,
    List<OrderItem> items,
    String pickupCode,
  );

  // Atomic order completion transaction:
  //   * mark order Completed with completedAt and isPaid=true
  //   * credit buyer points (totalPrice / 200)
  //   * write a sale `transactions` document with seller earnings minus fee
  // Mirrors [OrderService.completeOrder]. The repo encapsulates the
  // multi-document transaction so the service stays SDK-free.
  Future<void> completeOrder(
    String orderId, {
    required double transactionFeePercent,
  });
}
