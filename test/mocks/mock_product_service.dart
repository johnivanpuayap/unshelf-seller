import 'package:unshelf_seller/core/interfaces/i_product_service.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/models/product_model.dart';

class MockProductService implements IProductService {
  List<ProductModel> productsResult = [];
  ProductModel? productResult;
  List<BatchModel>? batchesResult;
  Exception? errorToThrow;

  @override
  Future<ProductModel?> getProduct(String productId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return productResult;
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    if (errorToThrow != null) throw errorToThrow!;
    return productsResult;
  }

  @override
  Future<List<BatchModel>?> getProductBatches(ProductModel product) async {
    if (errorToThrow != null) throw errorToThrow!;
    return batchesResult;
  }

  @override
  Future<String> addProduct(ProductModel product) async {
    if (errorToThrow != null) throw errorToThrow!;
    return 'mock-product-id';
  }

  @override
  Future<void> updateProduct(String productId, ProductModel product) async {
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    if (errorToThrow != null) throw errorToThrow!;
  }
}
