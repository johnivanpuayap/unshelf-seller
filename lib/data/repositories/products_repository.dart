import 'package:unshelf_seller/models/product_model.dart';

abstract class ProductsRepository {
  Stream<List<ProductModel>> watchProductsByStore(String storeId);
  Future<ProductModel?> getProduct(String productId);
  Future<String> createProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String productId);
}
