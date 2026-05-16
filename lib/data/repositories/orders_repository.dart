import 'package:unshelf_seller/models/order_model.dart';

abstract class OrdersRepository {
  Stream<List<OrderModel>> watchOrders(String storeId);
  Future<OrderModel?> getOrder(String orderId);
  Future<void> updateOrderStatus(String orderId, String status);
}
