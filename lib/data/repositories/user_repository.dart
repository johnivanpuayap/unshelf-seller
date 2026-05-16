// Note: this repo uses [UserProfileModel] (the seller-side user model class
// name) rather than the plan's `UserModel`. The plan was written generically;
// the seller already standardized on `UserProfileModel` in lib/models/user_model.dart.
import 'package:unshelf_seller/models/user_model.dart';

abstract class UserRepository {
  Future<UserProfileModel?> getUser(String userId);
  Stream<UserProfileModel?> watchUser(String userId);
  Future<void> upsertUser(UserProfileModel user);
  Future<int> fetchFollowersCount(String userId);

  // Raw-map read of the `users/{uid}` doc. Mirrors
  // [UserProfileService.getUserDocument]. Some callers need fields not
  // exposed by [UserProfileModel] (e.g., `type`, `isBanned`).
  Future<Map<String, dynamic>?> getUserDocument(String userId);

  // Full-document write to `users/{uid}` (`.set()` semantics — replaces).
  // Mirrors [UserProfileService.createUserDocument], used during seller
  // onboarding.
  Future<void> createUserDocument(String userId, Map<String, dynamic> data);

  // Patch-update of `users/{uid}` (`.update()` semantics — fails if absent).
  // Mirrors [UserProfileService.updateUserProfile].
  Future<void> updateUserFields(String userId, Map<String, dynamic> fields);

  // Append a report document to the top-level `reports` collection. Reports
  // are user-authored but are not stored under `users/{uid}`; they live in
  // their own collection. Mirrors [UserProfileService.submitReport]. The
  // [reportData] map is passed through verbatim (the service has already
  // called `report.toJson()`).
  Future<void> submitReport(Map<String, dynamic> reportData);
}
