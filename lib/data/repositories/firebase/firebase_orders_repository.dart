import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unshelf_seller/core/constants/firestore_constants.dart';
import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/data/repositories/orders_repository.dart';
import 'package:unshelf_seller/models/order_model.dart';

class FirebaseOrdersRepository implements OrdersRepository {
  FirebaseOrdersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Mirrors the query shape in `OrderService.getOrders` — filter on
  // `sellerId`, order by `createdAt` ascending. We deliberately omit the
  // time-window `where(createdAt > ...)` clause here so this repository stays
  // a thin pass-through; time-window filtering is business logic that belongs
  // in the service that consumes the stream.
  @override
  Stream<List<OrderModel>> watchOrders(String storeId) {
    return _firestore
        .collection(FirestoreConstants.orders)
        .where(FirestoreConstants.sellerId, isEqualTo: storeId)
        .orderBy(FirestoreConstants.createdAt, descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromFirestore(d)).toList());
  }

  // Mirrors `OrderService.getOrder` (single-doc fetch only — the service-level
  // method additionally enriches with buyer name and batch/bundle lookups;
  // that enrichment stays in the service per Task 3.5 boundary).
  @override
  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _firestore
        .collection(FirestoreConstants.orders)
        .doc(orderId)
        .get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc);
  }

  // Generic status update; replaces the per-status helpers (`approveOrder`,
  // `cancelOrder`, etc.) in `OrderService` for the data-layer concern. The
  // service-level wrappers continue to handle status-specific side effects
  // (timestamps, transactions, etc.).
  @override
  Future<void> updateOrderStatus(String orderId, String status) {
    return _firestore
        .collection(FirestoreConstants.orders)
        .doc(orderId)
        .update({FirestoreConstants.status: status});
  }

  // Mirrors the `.get()` semantics in `OrderService.getOrders` /
  // `OrderService.getOrdersWithBatchId`. Time-window filtering is handled by
  // the service.
  @override
  Future<List<OrderModel>> getOrdersByStore(String storeId) async {
    final snap = await _firestore
        .collection(FirestoreConstants.orders)
        .where(FirestoreConstants.sellerId, isEqualTo: storeId)
        .orderBy(FirestoreConstants.createdAt, descending: false)
        .get();
    return snap.docs.map((d) => OrderModel.fromFirestore(d)).toList();
  }

  // Mirrors `OrderService.cancelOrder`. Wraps the status + cancelledAt write
  // in a transaction to preserve atomic semantics.
  @override
  Future<void> cancelOrder(String orderId) async {
    final now = Timestamp.now();
    final orderRef =
        _firestore.collection(FirestoreConstants.orders).doc(orderId);
    await _firestore.runTransaction((transaction) async {
      transaction.update(orderRef, {
        FirestoreConstants.status: StatusConstants.cancelled,
        'cancelledAt': now,
      });
    });
  }

  // Mirrors `OrderService.fulfillOrder`. Each item runs its own stock-check
  // transaction (matching the original per-item transaction loop), then a
  // final transaction stamps the pickup code and Ready status.
  @override
  Future<void> fulfillOrder(
    String orderId,
    List<OrderItem> items,
    String pickupCode,
  ) async {
    for (final item in items) {
      await _firestore.runTransaction((transaction) async {
        final collection = item.isBundle!
            ? FirestoreConstants.bundles
            : FirestoreConstants.batches;
        final ref = _firestore.collection(collection).doc(item.batchId);
        final snap = await transaction.get(ref);

        if (!snap.exists) {
          throw Exception(
              '${item.isBundle! ? 'Bundle' : 'Batch'} ${item.batchId} does not exist.');
        }

        final double currentStock = snap['stock']?.toDouble() ?? 0.0;
        final double newStockValue = currentStock - item.quantity;

        if (newStockValue < 0) {
          throw Exception(
              'Insufficient stock for ${item.isBundle! ? 'bundle' : 'batch'} ${item.batchId}. Cannot fulfill order.');
        }

        transaction.update(ref, {
          FirestoreConstants.stock: newStockValue,
          FirestoreConstants.isListed: newStockValue > 0,
        });
      });
    }

    final orderRef =
        _firestore.collection(FirestoreConstants.orders).doc(orderId);
    await _firestore.runTransaction((transaction) async {
      transaction.update(orderRef, {
        'pickupCode': pickupCode,
        FirestoreConstants.status: StatusConstants.ready,
      });
    });
  }

  // Mirrors `OrderService.completeOrder`. Single transaction that:
  //   * marks the order Completed (with completedAt + isPaid)
  //   * increments buyer points (totalPrice / 200)
  //   * writes a sale `transactions` document
  // Throws if the order does not exist.
  @override
  Future<void> completeOrder(
    String orderId, {
    required double transactionFeePercent,
  }) async {
    final now = Timestamp.now();
    final orderRef =
        _firestore.collection(FirestoreConstants.orders).doc(orderId);
    final orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw Exception('Order not found');
    }

    final String buyerId = orderDoc['buyerId'];
    final double totalPrice = orderDoc['totalPrice']?.toDouble() ?? 0.0;
    final userRef =
        _firestore.collection(FirestoreConstants.users).doc(buyerId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(orderRef, {
        FirestoreConstants.status: StatusConstants.completed,
        'completedAt': now,
        'isPaid': true,
      });

      final double transactionFee = double.parse(
          (totalPrice * transactionFeePercent).toStringAsFixed(2));
      final double sellerEarnings =
          double.parse((totalPrice - transactionFee).toStringAsFixed(2));
      final int earnedPoints = (totalPrice / 200).floor();

      transaction.update(userRef, {
        'points': FieldValue.increment(earnedPoints),
      });

      final Map<String, dynamic> transactionData = {
        'date': FieldValue.serverTimestamp(),
        'isPaid': orderDoc['isPaid'],
        'orderId': orderDoc['orderId'],
        'sellerEarnings': sellerEarnings,
        'sellerId': orderDoc['sellerId'],
        'transactionFee': transactionFee,
        'type': StatusConstants.sale,
      };

      transaction.set(
        _firestore.collection(FirestoreConstants.transactions).doc(),
        transactionData,
      );
    });
  }
}
