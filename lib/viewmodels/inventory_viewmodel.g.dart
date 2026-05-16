// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$inventoryViewModelHash() =>
    r'513bdd0cf48f60f01bb7104b0f0af0f3bfed9323';

/// Store-inventory ViewModel — joins products with their batches into
/// [InventoryProductModel] rows for the inventory list screen.
///
/// Copied from [InventoryViewModel].
@ProviderFor(InventoryViewModel)
final inventoryViewModelProvider =
    AutoDisposeNotifierProvider<InventoryViewModel, InventoryState>.internal(
  InventoryViewModel.new,
  name: r'inventoryViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inventoryViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$InventoryViewModel = AutoDisposeNotifier<InventoryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
