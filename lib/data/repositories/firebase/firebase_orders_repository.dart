import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unshelf_seller/core/constants/firestore_constants.dart';
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
}
