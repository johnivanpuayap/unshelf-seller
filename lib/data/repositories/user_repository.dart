// Note: this repo uses [UserProfileModel] (the seller-side user model class
// name) rather than the plan's `UserModel`. The plan was written generically;
// the seller already standardized on `UserProfileModel` in lib/models/user_model.dart.
import 'package:unshelf_seller/models/user_model.dart';

abstract class UserRepository {
  Future<UserProfileModel?> getUser(String userId);
  Stream<UserProfileModel?> watchUser(String userId);
  Future<void> upsertUser(UserProfileModel user);
  Future<int> fetchFollowersCount(String userId);
}
