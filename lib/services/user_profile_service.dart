import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:get_it/get_it.dart';

import 'package:unshelf_seller/core/current_user_provider.dart';
import 'package:unshelf_seller/core/errors/app_exceptions.dart';
import 'package:unshelf_seller/core/interfaces/i_user_profile_service.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/data/repositories/user_repository.dart';
import 'package:unshelf_seller/models/report_model.dart';
import 'package:unshelf_seller/models/user_model.dart';

class UserProfileService implements IUserProfileService {
  final UserRepository _repo;
  final CurrentUserProvider _currentUser;

  UserProfileService({
    UserRepository? repo,
    CurrentUserProvider? currentUser,
  })  : _repo = repo ?? GetIt.instance<UserRepository>(),
        _currentUser = currentUser ?? CurrentUserProvider();

  @override
  Future<UserProfileModel?> getUserProfile() async {
    try {
      final uid = _currentUser.uid;
      final user = await _repo.getUser(uid);
      if (user == null) {
        AppLogger.debug('No user profile found for uid: $uid');
      } else {
        AppLogger.debug('User profile fetched for uid: $uid');
      }
      return user;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch user profile', e, stackTrace);
      throw FirestoreException('Failed to fetch user profile',
          originalError: e);
    }
  }

  @override
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final uid = _currentUser.uid;
      await _repo.updateUserFields(uid, data);
      AppLogger.debug('User profile updated for uid: $uid');
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to update user profile', e, stackTrace);
      throw FirestoreException('Failed to update user profile',
          originalError: e);
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    try {
      final data = await _repo.getUserDocument(uid);
      if (data == null) {
        AppLogger.debug('No user document found for uid: $uid');
      } else {
        AppLogger.debug('User document fetched for uid: $uid');
      }
      return data;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch user document', e, stackTrace);
      throw FirestoreException('Failed to fetch user document',
          originalError: e);
    }
  }

  @override
  Future<void> createUserDocument(
      String uid, Map<String, dynamic> data) async {
    try {
      await _repo.createUserDocument(uid, data);
      AppLogger.debug('User document created for uid: $uid');
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to create user document', e, stackTrace);
      throw FirestoreException('Failed to create user document',
          originalError: e);
    }
  }

  @override
  Future<void> submitReport(ReportModel report) async {
    try {
      // The service handles report -> map conversion (toJson) and logging;
      // the repository handles the raw collection write.
      await _repo.submitReport(report.toJson());
      AppLogger.debug('Report submitted by uid: ${report.userId}');
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to submit report', e, stackTrace);
      throw FirestoreException('Failed to submit report', originalError: e);
    }
  }
}
