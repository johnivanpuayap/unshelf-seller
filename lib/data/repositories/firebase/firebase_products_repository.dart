import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unshelf_seller/core/constants/firestore_constants.dart';
import 'package:unshelf_seller/data/repositories/products_repository.dart';
import 'package:unshelf_seller/models/product_model.dart';

class FirebaseProductsRepository implements ProductsRepository {
  FirebaseProductsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Mirrors the query shape in `ProductService.getProducts` (filter by
  // sellerId) but returns a live stream instead of a single .get(). The
  // service currently does .get(); switching to .snapshots() here is a
  // capability upgrade for downstream consumers (e.g., reactive lists).
  @override
  Stream<List<ProductModel>> watchProductsByStore(String storeId) {
    return _firestore
        .collection(FirestoreConstants.products)
        .where(FirestoreConstants.sellerId, isEqualTo: storeId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ProductModel.fromSnapshot(d)).toList());
  }

  // Mirrors `ProductService.getProduct`.
  @override
  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _firestore
        .collection(FirestoreConstants.products)
        .doc(productId)
        .get();
    if (!doc.exists) return null;
    return ProductModel.fromSnapshot(doc);
  }

  // Mirrors `ProductService.addProduct`. Note: the existing service stamps
  // `sellerId` from the current user; the repository signature does not
  // include sellerId, so callers (Task 3.5 service refactor) are responsible
  // for ensuring `product.toMap()` contains all required fields OR for using a
  // service-level method that injects sellerId before delegating here.
  @override
  Future<String> createProduct(ProductModel product) async {
    final docRef = await _firestore
        .collection(FirestoreConstants.products)
        .add(product.toMap());
    return docRef.id;
  }

  // Mirrors `ProductService.updateProduct`. Uses the product's `id` field as
  // the document id (the existing service takes productId + product
  // separately; we use product.id to keep the interface uniform).
  @override
  Future<void> updateProduct(ProductModel product) {
    return _firestore
        .collection(FirestoreConstants.products)
        .doc(product.id)
        .update(product.toMap());
  }

  // Mirrors `ProductService.deleteProduct`.
  @override
  Future<void> deleteProduct(String productId) {
    return _firestore
        .collection(FirestoreConstants.products)
        .doc(productId)
        .delete();
  }
}
