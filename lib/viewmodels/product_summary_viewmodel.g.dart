// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_summary_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productSummaryViewModelHash() =>
    r'96a57c740a3875fdff251cc584063196e25812ee';

/// Product summary ViewModel — backs the product details screen. Owns a
/// `PageController` on the notifier instance (imperative widget glue, not
/// state).
///
/// Copied from [ProductSummaryViewModel].
@ProviderFor(ProductSummaryViewModel)
final productSummaryViewModelProvider = AutoDisposeNotifierProvider<
    ProductSummaryViewModel, ProductSummaryState>.internal(
  ProductSummaryViewModel.new,
  name: r'productSummaryViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productSummaryViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProductSummaryViewModel = AutoDisposeNotifier<ProductSummaryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
