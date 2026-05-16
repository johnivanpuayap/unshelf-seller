import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:get_it/get_it.dart';

import 'package:unshelf_seller/core/constants/app_constants.dart';
import 'package:unshelf_seller/core/current_user_provider.dart';
import 'package:unshelf_seller/core/errors/app_exceptions.dart';
import 'package:unshelf_seller/core/interfaces/i_batch_service.dart';
import 'package:unshelf_seller/core/interfaces/i_bundle_service.dart';
import 'package:unshelf_seller/core/interfaces/i_order_service.dart';
import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/data/repositories/orders_repository.dart';
import 'package:unshelf_seller/data/repositories/user_repository.dart';
import 'package:unshelf_seller/models/order_model.dart';

class OrderService implements IOrderService {
  final OrdersRepository _repo;
  final UserRepository _userRepo;
  final CurrentUserProvider _currentUser;
  final IBatchService _batchService;
  final IBundleService _bundleService;

  OrderService({
    OrdersRepository? repo,
    UserRepository? userRepo,
    CurrentUserProvider? currentUser,
    required IBatchService batchService,
    required IBundleService bundleService,
  })  : _repo = repo ?? GetIt.instance<OrdersRepository>(),
        _userRepo = userRepo ?? GetIt.instance<UserRepository>(),
        _currentUser = currentUser ?? CurrentUserProvider(),
        _batchService = batchService,
        _bundleService = bundleService;

  @override
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      // Raw fetch goes through the repository; enrichment (buyer name, bundle
      // and batch details) stays in the service per the data-layer split.
      final order = await _repo.getOrder(orderId);
      if (order == null) return null;

      final buyer = await _userRepo.getUser(order.buyerId);
      if (buyer != null) {
        order.buyerName = buyer.name;
      }

      for (var item in order.items) {
        if (item.isBundle!) {
          final bundle = await _bundleService.getBundle(item.batchId!);
          if (bundle != null) {
            order.bundles!.add(bundle);
          }
          continue;
        } else {
          final batch = await _batchService.getBatchById(item.batchId!);
          if (batch != null) {
            order.products!.add(batch);
          }
        }
      }

      return order;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch order', e, stackTrace);
      throw FirestoreException('Failed to fetch order', originalError: e);
    }
  }

  @override
  Future<List<OrderModel>> getOrders(bool forToday) async {
    try {
      // Time-window filtering stays in the service — the repository returns
      // every order for this seller; we slice it here based on the business
      // rule (today vs history window).
      final duration = forToday
          ? AppConstants.orderExpiryDuration
          : AppConstants.orderHistoryDuration;
      final cutoff = DateTime.now().subtract(duration);

      final all = await _repo.getOrdersByStore(_currentUser.uid);
      final filtered = all
          .where((o) => o.createdAt.toDate().isAfter(cutoff))
          .toList();
      AppLogger.debug('Orders fetched: ${filtered.length}');
      return filtered;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch orders', e, stackTrace);
      throw FirestoreException('Failed to fetch orders', originalError: e);
    }
  }

  @override
  Future<List<OrderModel>> getOrdersWithBatchId() async {
    try {
      final cutoff =
          DateTime.now().subtract(AppConstants.orderExpiryDuration);
      final all = await _repo.getOrdersByStore(_currentUser.uid);
      final filtered = all
          .where((o) => o.createdAt.toDate().isAfter(cutoff))
          .toList();
      AppLogger.debug('Orders containing batchId: ${filtered.length}');
      return filtered;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch orders with batch ID', e, stackTrace);
      throw FirestoreException('Failed to fetch orders with batch ID',
          originalError: e);
    }
  }

  @override
  Future<void> approveOrder(String orderId) async {
    try {
      await _repo.updateOrderStatus(orderId, StatusConstants.processing);
      AppLogger.debug('Order $orderId approved (status -> processing).');
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to approve order', e, stackTrace);
      throw FirestoreException('Failed to approve order', originalError: e);
    }
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    try {
      await _repo.cancelOrder(orderId);
      AppLogger.debug('Order $orderId cancelled.');
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to cancel order', e, stackTrace);
      throw FirestoreException('Failed to cancel order', originalError: e);
    }
  }

  @override
  Future<void> fulfillOrder(
      String orderId, List<OrderItem> items, String pickupCode) async {
    try {
      await _repo.fulfillOrder(orderId, items, pickupCode);
      AppLogger.debug(
          'Order $orderId fulfilled with pickup code $pickupCode.');
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fulfill order', e, stackTrace);
      throw FirestoreException('Failed to fulfill order', originalError: e);
    }
  }

  @override
  Future<void> completeOrder(String orderId) async {
    try {
      await _repo.completeOrder(
        orderId,
        transactionFeePercent: AppConstants.transactionFeePercent,
      );
      AppLogger.debug(
          'Order $orderId completed (status -> completed).');
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to complete order', e, stackTrace);
      throw FirestoreException('Failed to complete order', originalError: e);
    }
  }
}
