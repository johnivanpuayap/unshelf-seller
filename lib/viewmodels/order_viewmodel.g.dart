// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$orderViewModelHash() => r'24bf40c53cd7b6a19fe074e4d3910dc3cb40bfdd';

/// Order ViewModel — manages today's order list, order history, and the
/// currently-selected order's state transitions (approve / cancel /
/// fulfill / complete).
///
/// Copied from [OrderViewModel].
@ProviderFor(OrderViewModel)
final orderViewModelProvider =
    AutoDisposeNotifierProvider<OrderViewModel, OrderState>.internal(
  OrderViewModel.new,
  name: r'orderViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orderViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OrderViewModel = AutoDisposeNotifier<OrderState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
