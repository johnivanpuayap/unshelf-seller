import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:get_it/get_it.dart';

import 'package:unshelf_seller/core/constants/firestore_constants.dart';
import 'package:unshelf_seller/core/current_user_provider.dart';
import 'package:unshelf_seller/core/errors/app_exceptions.dart';
import 'package:unshelf_seller/core/interfaces/i_product_service.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/data/repositories/products_repository.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/models/product_model.dart';

class ProductService implements IProductService {
  final ProductsRepository _repo;
  final CurrentUserProvider _currentUser;

  ProductService({
    ProductsRepository? repo,
    CurrentUserProvider? currentUser,
  })  : _repo = repo ?? GetIt.instance<ProductsRepository>(),
        _currentUser = currentUser ?? CurrentUserProvider();

  @override
  Future<ProductModel?> getProduct(String productId) async {
    try {
      return await _repo.getProduct(productId);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch product', e, stackTrace);
      throw FirestoreException('Failed to fetch product', originalError: e);
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      // sellerId scoping is a service-level concern: the repo accepts a
      // storeId and we inject the current user's uid from the auth-aware
      // CurrentUserProvider.
      return await _repo.getProductsByStore(_currentUser.uid);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch products', e, stackTrace);
      throw FirestoreException('Failed to fetch products', originalError: e);
    }
  }

  @override
  Future<List<BatchModel>?> getProductBatches(ProductModel product) async {
    try {
      // The repository returns batches with `product = null`; the service
      // attaches the product reference so the model carries the
      // cross-collection join. Returns null when no batches exist (matches
      // the original service contract, where an empty result -> null).
      final batches = await _repo.getBatchesByProductId(product.id);
      if (batches.isEmpty) return null;
      for (final batch in batches) {
        batch.product = product;
      }
      return batches;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch product batches', e, stackTrace);
      throw FirestoreException('Failed to fetch product batches',
          originalError: e);
    }
  }

  @override
  Future<String> addProduct(ProductModel product) async {
    try {
      // ProductModel does not carry a sellerId field, so we stamp it via the
      // repository's `extraFields` sidecar map. This keeps business-logic
      // injection (current user -> sellerId) in the service while leaving
      // the raw write to the repo.
      return await _repo.createProduct(
        product,
        extraFields: {
          FirestoreConstants.sellerId: _currentUser.uid,
        },
      );
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to add product', e, stackTrace);
      throw FirestoreException('Failed to add product', originalError: e);
    }
  }

  @override
  Future<void> updateProduct(String productId, ProductModel product) async {
    try {
      await _repo.updateProduct(productId, product);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to update product', e, stackTrace);
      throw FirestoreException('Failed to update product', originalError: e);
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _repo.deleteProduct(productId);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to delete product', e, stackTrace);
      throw FirestoreException('Failed to delete product', originalError: e);
    }
  }
}
