import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unshelf_seller/core/constants/firestore_constants.dart';
import 'package:unshelf_seller/data/repositories/user_repository.dart';
import 'package:unshelf_seller/models/user_model.dart';

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Mirrors `UserProfileService.getUserProfile` (single-doc read of
  // users/{uid}).
  @override
  Future<UserProfileModel?> getUser(String userId) async {
    final doc = await _firestore
        .collection(FirestoreConstants.users)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return UserProfileModel.fromSnapshot(doc);
  }

  @override
  Stream<UserProfileModel?> watchUser(String userId) {
    return _firestore
        .collection(FirestoreConstants.users)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserProfileModel.fromSnapshot(doc) : null);
  }

  // Set+merge upsert using the model's wire shape.
  @override
  Future<void> upsertUser(UserProfileModel user) {
    return _firestore
        .collection(FirestoreConstants.users)
        .doc(user.userId)
        .set(user.toMap(), SetOptions(merge: true));
  }

  // Mirrors `StoreService.fetchStoreFollowers`: follower documents live under
  // the `stores/{userId}/followers` subcollection, not under `users`.
  @override
  Future<int> fetchFollowersCount(String userId) async {
    final snap = await _firestore
        .collection(FirestoreConstants.stores)
        .doc(userId)
        .collection('followers')
        .get();
    return snap.size;
  }

  // Mirrors `UserProfileService.getUserDocument`: returns the raw doc data
  // map (or null when the doc does not exist).
  @override
  Future<Map<String, dynamic>?> getUserDocument(String userId) async {
    final doc = await _firestore
        .collection(FirestoreConstants.users)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // Mirrors `UserProfileService.createUserDocument`: full-document `.set()`.
  @override
  Future<void> createUserDocument(
      String userId, Map<String, dynamic> data) {
    return _firestore
        .collection(FirestoreConstants.users)
        .doc(userId)
        .set(data);
  }

  // Mirrors `UserProfileService.updateUserProfile`: `.update()` patch.
  @override
  Future<void> updateUserFields(
      String userId, Map<String, dynamic> fields) {
    return _firestore
        .collection(FirestoreConstants.users)
        .doc(userId)
        .update(fields);
  }

  // Mirrors `UserProfileService.submitReport`: appends to the top-level
  // `reports` collection.
  @override
  Future<void> submitReport(Map<String, dynamic> reportData) async {
    await _firestore
        .collection(FirestoreConstants.reports)
        .add(reportData);
  }
}
