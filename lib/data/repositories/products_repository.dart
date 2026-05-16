import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/models/product_model.dart';

abstract class ProductsRepository {
  Stream<List<ProductModel>> watchProductsByStore(String storeId);
  Future<ProductModel?> getProduct(String productId);
  // One-shot read of products for a seller. Mirrors `.get()` semantics in
  // [ProductService.getProducts]. Service-layer callers use this for
  // request/response interactions where a stream is unnecessary.
  Future<List<ProductModel>> getProductsByStore(String storeId);
  // Mirrors [ProductService.addProduct]'s wire shape: the service stamps
  // `sellerId` BEFORE calling `createProduct`, so the implementation reads
  // it out of the `extraFields` map and writes it alongside the product
  // fields. ProductModel does not carry a sellerId field, so we pass it
  // through as a sidecar map.
  Future<String> createProduct(
    ProductModel product, {
    Map<String, dynamic> extraFields = const {},
  });
  // Update by explicit product id (mirrors the service's
  // `updateProduct(productId, product)` shape).
  Future<void> updateProduct(String productId, ProductModel product);
  Future<void> deleteProduct(String productId);

  // Batches scoped to a product id. Mirrors the query in
  // [ProductService.getProductBatches]; the model's `product` reference is
  // attached by the service after this raw fetch returns.
  Future<List<BatchModel>> getBatchesByProductId(String productId);
}
