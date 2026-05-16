import 'package:unshelf_seller/models/store_model.dart';

abstract class StoresRepository {
  Future<StoreModel?> getStore(String storeId);
  Stream<StoreModel?> watchStore(String storeId);
  Future<void> upsertStore(StoreModel store);
  Future<void> updateStoreLocation(String storeId, double lat, double lng);
}
