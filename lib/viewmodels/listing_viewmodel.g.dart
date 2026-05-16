// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$listingViewModelHash() => r'20ff727c0f6e4f492d9257624f07ee311378c8c9';

/// Listing ViewModel — fetches both products and bundles, merges them
/// into a single list, and supports search + filter (All / Products /
/// Bundles).
///
/// The original ChangeNotifier called `fetchItems()` from its constructor;
/// that side-effect has been moved to the view's `initState` (see
/// [ListingsView]).
///
/// Copied from [ListingViewModel].
@ProviderFor(ListingViewModel)
final listingViewModelProvider =
    AutoDisposeNotifierProvider<ListingViewModel, ListingState>.internal(
  ListingViewModel.new,
  name: r'listingViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$listingViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ListingViewModel = AutoDisposeNotifier<ListingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
