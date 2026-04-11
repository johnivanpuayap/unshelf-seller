import 'package:unshelf_seller/core/interfaces/i_order_service.dart';
import 'package:unshelf_seller/models/order_model.dart';

class MockOrderService implements IOrderService {
  List<OrderModel> ordersResult = [];
  OrderModel? orderResult;
  Exception? errorToThrow;

  int getOrdersCalled = 0;
  int approveOrderCalled = 0;
  int cancelOrderCalled = 0;
  int fulfillOrderCalled = 0;
  int completeOrderCalled = 0;
  String? lastOrderId;
  bool? lastForToday;

  @override
  Future<List<OrderModel>> getOrders(bool forToday) async {
    getOrdersCalled++;
    lastForToday = forToday;
    if (errorToThrow != null) throw errorToThrow!;
    return ordersResult;
  }

  @override
  Future<OrderModel?> getOrder(String orderId) async {
    lastOrderId = orderId;
    if (errorToThrow != null) throw errorToThrow!;
    return orderResult;
  }

  @override
  Future<List<OrderModel>> getOrdersWithBatchId() async {
    if (errorToThrow != null) throw errorToThrow!;
    return ordersResult;
  }

  @override
  Future<void> approveOrder(String orderId) async {
    approveOrderCalled++;
    lastOrderId = orderId;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    cancelOrderCalled++;
    lastOrderId = orderId;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> fulfillOrder(
      String orderId, List<OrderItem> items, String pickupCode) async {
    fulfillOrderCalled++;
    lastOrderId = orderId;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> completeOrder(String orderId) async {
    completeOrderCalled++;
    lastOrderId = orderId;
    if (errorToThrow != null) throw errorToThrow!;
  }
}
