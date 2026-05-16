// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dashboardViewModelHash() =>
    r'4591394ace847894fcebf3b0a9a5278fc43bbdb6';

/// Dashboard ViewModel — fetches today's order counts and monthly earnings.
///
/// Riverpod-managed; consumers read state via `ref.watch(dashboardViewModelProvider)`
/// and trigger actions via `ref.read(dashboardViewModelProvider.notifier).fetchDashboardData()`.
///
/// Copied from [DashboardViewModel].
@ProviderFor(DashboardViewModel)
final dashboardViewModelProvider =
    AutoDisposeNotifierProvider<DashboardViewModel, DashboardState>.internal(
  DashboardViewModel.new,
  name: r'dashboardViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DashboardViewModel = AutoDisposeNotifier<DashboardState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
