import 'package:unshelf_seller/models/store_model.dart';

abstract class StoresRepository {
  Future<StoreModel?> getStore(String storeId);
  Stream<StoreModel?> watchStore(String storeId);
  Future<void> upsertStore(StoreModel store);
  Future<void> updateStoreLocation(String storeId, double lat, double lng);

  // Average rating for a store, stored in the `stores/{storeId}/ratings/average`
  // document under the `average` field. Returns 0.0 when the doc is missing or
  // malformed. Added in Task 3.5 to remove the last direct Firestore call from
  // [StoreService.fetchStoreRatings].
  Future<double> fetchAverageRating(String storeId);

  // Map-shaped patch update applied to the `stores/{storeId}` document.
  // [StoreService.updateStoreProfile] and [StoreService.saveStoreSchedule]
  // both pass field maps that are wider than [StoreModel.toMap], so we keep a
  // raw map update to preserve their original semantics. Added in Task 3.5.
  Future<void> updateStoreFields(String storeId, Map<String, dynamic> fields);

  // Full-document write to `stores/{storeId}`. Mirrors
  // [StoreService.createStore]: replaces the document entirely. Used for the
  // initial seller onboarding flow where the document does not yet exist.
  Future<void> createStoreDocument(String storeId, Map<String, dynamic> data);
}
