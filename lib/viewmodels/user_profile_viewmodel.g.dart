// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userProfileViewModelHash() =>
    r'8bdd9a938e66471b436110c05b15c96b5dcceccc';

/// User profile ViewModel — backs the Edit User Profile screen. Owns
/// `TextEditingController`s for name/email/phone/password fields on the
/// notifier instance (imperative widget glue, not state).
///
/// FirebaseAuth is held directly for reauthentication and password-change
/// operations that aren't exposed by the service layer.
///
/// Copied from [UserProfileViewModel].
@ProviderFor(UserProfileViewModel)
final userProfileViewModelProvider =
    NotifierProvider<UserProfileViewModel, UserProfileState>.internal(
  UserProfileViewModel.new,
  name: r'userProfileViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userProfileViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserProfileViewModel = Notifier<UserProfileState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
