// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_profile_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$storeProfileViewModelHash() =>
    r'03d3832021a2e2addea0684733f3462a564701b8';

/// Store profile ViewModel — backs the Edit Store Profile screen. Owns
/// `TextEditingController`s and an `ImagePicker` on the notifier instance
/// (imperative widget glue, not state). The view calls [loadFromStore] in
/// `initState` to seed the controllers from the current `StoreModel`.
///
/// Copied from [StoreProfileViewModel].
@ProviderFor(StoreProfileViewModel)
final storeProfileViewModelProvider = AutoDisposeNotifierProvider<
    StoreProfileViewModel, StoreProfileState>.internal(
  StoreProfileViewModel.new,
  name: r'storeProfileViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$storeProfileViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StoreProfileViewModel = AutoDisposeNotifier<StoreProfileState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
