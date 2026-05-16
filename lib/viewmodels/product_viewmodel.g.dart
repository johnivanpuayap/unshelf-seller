// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productViewModelHash() => r'158843a105a19b2910b1d7230f8d0019eb97f7a3';

/// Product ViewModel — backs the add/edit product screens. Owns
/// `TextEditingController`s, the `FormKey`, and an `ImagePicker` on the
/// notifier instance (imperative widget glue, not state).
///
/// Copied from [ProductViewModel].
@ProviderFor(ProductViewModel)
final productViewModelProvider =
    AutoDisposeNotifierProvider<ProductViewModel, ProductState>.internal(
  ProductViewModel.new,
  name: r'productViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProductViewModel = AutoDisposeNotifier<ProductState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
