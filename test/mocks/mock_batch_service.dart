import 'package:unshelf_seller/core/interfaces/i_batch_service.dart';
import 'package:unshelf_seller/models/batch_model.dart';

class MockBatchService implements IBatchService {
  List<BatchModel> batchesResult = [];
  BatchModel? batchResult;
  Exception? errorToThrow;

  /// Keyed by productId so tests can return different batches per product.
  Map<String, List<BatchModel>> batchesByProductId = {};

  @override
  Future<BatchModel?> getBatchById(String batchId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return batchResult;
  }

  @override
  Future<List<BatchModel>> getBatches(List<String> batchIds) async {
    if (errorToThrow != null) throw errorToThrow!;
    return batchesResult;
  }

  @override
  Future<List<BatchModel>> getBatchesByProductId(String productId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return batchesByProductId[productId] ?? batchesResult;
  }

  @override
  Future<List<BatchModel>> getAllBatches() async {
    if (errorToThrow != null) throw errorToThrow!;
    return batchesResult;
  }

  @override
  Future<void> addBatch({
    required String productId,
    String? batchNumber,
    required double price,
    required int stock,
    required String quantifier,
    required DateTime expiryDate,
    required int discount,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> updateBatch(String batchNumber, double price, int stock,
      String quantifier, DateTime expiryDate, int discount) async {
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<void> deleteBatch(String batchNumber) async {
    if (errorToThrow != null) throw errorToThrow!;
  }
}
