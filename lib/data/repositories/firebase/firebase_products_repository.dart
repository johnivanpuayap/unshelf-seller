import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unshelf_seller/core/constants/firestore_constants.dart';
import 'package:unshelf_seller/data/repositories/products_repository.dart';
import 'package:unshelf_seller/models/batch_model.dart';
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

  // Mirrors `ProductService.getProducts` (.get() form).
  @override
  Future<List<ProductModel>> getProductsByStore(String storeId) async {
    final snap = await _firestore
        .collection(FirestoreConstants.products)
        .where(FirestoreConstants.sellerId, isEqualTo: storeId)
        .get();
    return snap.docs.map((d) => ProductModel.fromSnapshot(d)).toList();
  }

  // Mirrors `ProductService.addProduct`. The service is expected to stamp
  // `sellerId` in [extraFields] before calling this method. ProductModel does
  // not carry a sellerId field, so the sidecar map is the cleanest way to
  // pass the field without changing the shared model.
  @override
  Future<String> createProduct(
    ProductModel product, {
    Map<String, dynamic> extraFields = const {},
  }) async {
    final docRef =
        await _firestore.collection(FirestoreConstants.products).add({
      ...product.toMap(),
      ...extraFields,
    });
    return docRef.id;
  }

  // Mirrors `ProductService.updateProduct(productId, product)`. The product
  // id is taken explicitly (not from `product.id`) to preserve the original
  // service signature, which lets callers update a doc with a different id
  // than the model's `id` field (defensive, matches the existing service).
  @override
  Future<void> updateProduct(String productId, ProductModel product) {
    return _firestore
        .collection(FirestoreConstants.products)
        .doc(productId)
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

  // Mirrors `ProductService.getProductBatches` raw fetch. Returns batches
  // with `product = null`; the service attaches the product reference after
  // this call to keep cross-collection joins in the business layer.
  @override
  Future<List<BatchModel>> getBatchesByProductId(String productId) async {
    final snap = await _firestore
        .collection(FirestoreConstants.batches)
        .where(FirestoreConstants.productId, isEqualTo: productId)
        .get();
    return snap.docs.map((d) => BatchModel.fromSnapshot(d, null)).toList();
  }
}
