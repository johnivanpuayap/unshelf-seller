import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unshelf_seller/core/constants/firestore_constants.dart';
import 'package:unshelf_seller/data/repositories/stores_repository.dart';
import 'package:unshelf_seller/models/store_model.dart';

class FirebaseStoresRepository implements StoresRepository {
  FirebaseStoresRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // The seller's `StoreModel.fromSnapshot` requires BOTH the user document and
  // the store document (the model joins fields from the `users` and `stores`
  // collections). We mirror the semantics of `StoreService.fetchStoreDetails`
  // (lib/services/store_service.dart) here.
  @override
  Future<StoreModel?> getStore(String storeId) async {
    final userDoc =
        await _firestore.collection(FirestoreConstants.users).doc(storeId).get();
    final storeDoc =
        await _firestore.collection(FirestoreConstants.stores).doc(storeId).get();

    if (!userDoc.exists || !storeDoc.exists) {
      return null;
    }

    return StoreModel.fromSnapshot(userDoc, storeDoc);
  }

  // Watches the user doc and re-fetches the store doc on every emission.
  // A fully reactive implementation would combine both snapshot streams
  // (e.g., via rxdart's combineLatest); kept minimal and dependency-free here.
  @override
  Stream<StoreModel?> watchStore(String storeId) {
    return _firestore
        .collection(FirestoreConstants.users)
        .doc(storeId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return null;
      final storeDoc = await _firestore
          .collection(FirestoreConstants.stores)
          .doc(storeId)
          .get();
      if (!storeDoc.exists) return null;
      return StoreModel.fromSnapshot(userDoc, storeDoc);
    });
  }

  // `upsertStore` writes only the store-doc fields exposed by `StoreModel.toMap`
  // into the `stores/{userId}` document. Mirrors `StoreService.createStore`
  // and `StoreService.updateStoreProfile` shapes.
  @override
  Future<void> upsertStore(StoreModel store) {
    return _firestore
        .collection(FirestoreConstants.stores)
        .doc(store.userId)
        .set(store.toMap(), SetOptions(merge: true));
  }

  // Mirrors `StoreService.saveStoreLocation`.
  @override
  Future<void> updateStoreLocation(String storeId, double lat, double lng) {
    return _firestore
        .collection(FirestoreConstants.stores)
        .doc(storeId)
        .set(
      {
        'latitude': lat,
        'longitude': lng,
      },
      SetOptions(merge: true),
    );
  }

  // Mirrors `StoreService.fetchStoreRatings`: reads
  // `stores/{storeId}/ratings/average` and returns the `average` field as a
  // double (defaults to 0.0 when missing or malformed).
  @override
  Future<double> fetchAverageRating(String storeId) async {
    final snap = await _firestore
        .collection(FirestoreConstants.stores)
        .doc(storeId)
        .collection('ratings')
        .doc('average')
        .get();
    final rawData = snap.data();
    final Map<String, dynamic>? data =
        rawData != null ? Map<String, dynamic>.from(rawData as Map) : null;
    return (data?['average'] ?? 0.0).toDouble();
  }

  // Mirrors `StoreService.updateStoreProfile` and
  // `StoreService.saveStoreSchedule`: applies a partial field map to
  // `stores/{storeId}`. Uses `.update` (not `.set`) to preserve the original
  // semantics — the call fails if the document does not exist.
  @override
  Future<void> updateStoreFields(
      String storeId, Map<String, dynamic> fields) {
    return _firestore
        .collection(FirestoreConstants.stores)
        .doc(storeId)
        .update(fields);
  }

  // Mirrors `StoreService.createStore`: full-document `.set()` write that
  // creates or replaces `stores/{storeId}`.
  @override
  Future<void> createStoreDocument(
      String storeId, Map<String, dynamic> data) {
    return _firestore
        .collection(FirestoreConstants.stores)
        .doc(storeId)
        .set(data);
  }
}
