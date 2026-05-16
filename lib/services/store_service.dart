import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:get_it/get_it.dart';

import 'package:unshelf_seller/core/current_user_provider.dart';
import 'package:unshelf_seller/core/errors/app_exceptions.dart';
import 'package:unshelf_seller/core/interfaces/i_store_service.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/data/repositories/stores_repository.dart';
import 'package:unshelf_seller/data/repositories/user_repository.dart';
import 'package:unshelf_seller/models/store_model.dart';
import 'package:unshelf_seller/models/user_model.dart';

// A "store" is split across two Firestore documents:
//   * users/{uid}    — name, email, phoneNumber  (handled by UserRepository)
//   * stores/{uid}   — storeName, location, schedule (handled by StoresRepository)
// StoreService coordinates the two repositories so callers see a single
// StoreModel surface.
class StoreService implements IStoreService {
  final StoresRepository _storesRepo;
  final UserRepository _userRepo;
  final CurrentUserProvider _currentUser;

  StoreService({
    StoresRepository? storesRepo,
    UserRepository? userRepo,
    CurrentUserProvider? currentUser,
  })  : _storesRepo = storesRepo ?? GetIt.instance<StoresRepository>(),
        _userRepo = userRepo ?? GetIt.instance<UserRepository>(),
        _currentUser = currentUser ?? CurrentUserProvider();

  @override
  Future<UserProfileModel?> fetchUserProfile() async {
    try {
      final uid = _currentUser.uid;
      final user = await _userRepo.getUser(uid);
      if (user == null) {
        AppLogger.warning('User profile not found for uid: $uid');
      }
      return user;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch user profile', e, stackTrace);
      throw FirestoreException('Failed to fetch user profile',
          originalError: e);
    }
  }

  @override
  Future<StoreModel?> fetchStoreDetails() async {
    try {
      final uid = _currentUser.uid;
      // StoresRepository.getStore joins users/{uid} + stores/{uid}; mirrors
      // the original service-level join.
      final store = await _storesRepo.getStore(uid);
      if (store == null) {
        AppLogger.warning('User profile or store not found for uid: $uid');
      } else {
        AppLogger.debug('Store details fetched for uid: $uid');
      }
      return store;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch store details', e, stackTrace);
      throw FirestoreException('Failed to fetch store details',
          originalError: e);
    }
  }

  @override
  Future<int> fetchStoreFollowers() async {
    try {
      final uid = _currentUser.uid;
      // UserRepository.fetchFollowersCount already reads from
      // `stores/{uid}/followers` — the subcollection lives under stores, not
      // users (see the repo doc comment for the rationale).
      final count = await _userRepo.fetchFollowersCount(uid);
      AppLogger.debug('Store followers fetched: $count');
      return count;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch store followers', e, stackTrace);
      throw FirestoreException('Failed to fetch store followers',
          originalError: e);
    }
  }

  @override
  Future<double> fetchStoreRatings() async {
    try {
      final uid = _currentUser.uid;
      final average = await _storesRepo.fetchAverageRating(uid);
      AppLogger.debug('Store rating fetched: $average');
      return average;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch store ratings', e, stackTrace);
      throw FirestoreException('Failed to fetch store ratings',
          originalError: e);
    }
  }

  @override
  Future<void> updateStoreProfile(Map<String, dynamic> fields) async {
    try {
      final uid = _currentUser.uid;
      await _storesRepo.updateStoreFields(uid, fields);
      AppLogger.debug('Store profile updated for uid: $uid');
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to update store profile', e, stackTrace);
      throw FirestoreException('Failed to update store profile',
          originalError: e);
    }
  }

  @override
  Future<void> saveStoreLocation(double latitude, double longitude) async {
    try {
      final uid = _currentUser.uid;
      await _storesRepo.updateStoreLocation(uid, latitude, longitude);
      AppLogger.debug('Store location saved for uid: $uid');
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to save store location', e, stackTrace);
      throw FirestoreException('Failed to save store location',
          originalError: e);
    }
  }

  @override
  Future<void> saveStoreSchedule(
      String userId, Map<String, Map<String, dynamic>> schedule) async {
    try {
      await _storesRepo.updateStoreFields(userId, {
        'storeSchedule': schedule,
      });
      AppLogger.debug('Store schedule saved for uid: $userId');
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to save store schedule', e, stackTrace);
      throw FirestoreException('Failed to save store schedule',
          originalError: e);
    }
  }

  @override
  Future<void> createStore(String uid, Map<String, dynamic> data) async {
    try {
      await _storesRepo.createStoreDocument(uid, data);
      AppLogger.debug('Store document created for uid: $uid');
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to create store document', e, stackTrace);
      throw FirestoreException('Failed to create store document',
          originalError: e);
    }
  }
}
