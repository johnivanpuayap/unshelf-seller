// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$analyticsViewModelHash() =>
    r'38008e94fc71ecf6ffe3a0911d2210889b092646';

/// Store analytics ViewModel — fetches lifetime totals plus per-period
/// (Daily / Weekly / Monthly / Annual) maps of orders and sales for chart
/// rendering.
///
/// Copied from [AnalyticsViewModel].
@ProviderFor(AnalyticsViewModel)
final analyticsViewModelProvider =
    AutoDisposeNotifierProvider<AnalyticsViewModel, AnalyticsState>.internal(
  AnalyticsViewModel.new,
  name: r'analyticsViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AnalyticsViewModel = AutoDisposeNotifier<AnalyticsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
