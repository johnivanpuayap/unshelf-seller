// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restock_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$restockViewModelHash() => r'c43ad6b43037116d218ea505922620e3c0d9e53f';

/// Restock ViewModel — backs the restock selection + details screens.
///
/// NOTE: `batchRestock` currently has a placeholder implementation
/// (no-op apart from loading-state churn); preserved from the original
/// ChangeNotifier — Phase 4 will wire it up to a real batch update service.
///
/// Copied from [RestockViewModel].
@ProviderFor(RestockViewModel)
final restockViewModelProvider =
    AutoDisposeNotifierProvider<RestockViewModel, RestockState>.internal(
  RestockViewModel.new,
  name: r'restockViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$restockViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RestockViewModel = AutoDisposeNotifier<RestockState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
