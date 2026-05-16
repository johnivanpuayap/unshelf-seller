// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_schedule_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$storeScheduleViewModelHash() =>
    r'264bb04870261d91256b466fafb42ca612601ffa';

/// Store schedule ViewModel — backs the Edit Store Schedule screen. The view
/// calls [loadFromStore] in `initState` to seed the per-day schedule map from
/// the supplied `StoreModel` (mirrors original constructor-time init).
///
/// Copied from [StoreScheduleViewModel].
@ProviderFor(StoreScheduleViewModel)
final storeScheduleViewModelProvider = AutoDisposeNotifierProvider<
    StoreScheduleViewModel, StoreScheduleState>.internal(
  StoreScheduleViewModel.new,
  name: r'storeScheduleViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$storeScheduleViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StoreScheduleViewModel = AutoDisposeNotifier<StoreScheduleState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
