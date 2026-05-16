import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/bundle_model.dart';
import 'package:unshelf_seller/models/item_model.dart';
import 'package:unshelf_seller/models/product_model.dart';

part 'listing_viewmodel.g.dart';

/// Immutable state for the listings (products + bundles) screen.
class ListingState {
  final bool isLoading;
  final String? errorMessage;
  final List<ItemModel> items;
  final List<dynamic> filteredItems;
  final bool showingProducts;
  final String searchQuery;
  final String filter;

  const ListingState({
    required this.isLoading,
    required this.errorMessage,
    required this.items,
    required this.filteredItems,
    required this.showingProducts,
    required this.searchQuery,
    required this.filter,
  });

  factory ListingState.initial() => const ListingState(
        isLoading: false,
        errorMessage: null,
        items: <ItemModel>[],
        filteredItems: <dynamic>[],
        showingProducts: true,
        searchQuery: '',
        filter: 'All',
      );

  ListingState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<ItemModel>? items,
    List<dynamic>? filteredItems,
    bool? showingProducts,
    String? searchQuery,
    String? filter,
  }) {
    return ListingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      showingProducts: showingProducts ?? this.showingProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }

  static const _sentinel = Object();
}

/// Listing ViewModel — fetches both products and bundles, merges them
/// into a single list, and supports search + filter (All / Products /
/// Bundles).
///
/// The original ChangeNotifier called `fetchItems()` from its constructor;
/// that side-effect has been moved to the view's `initState` (see
/// [ListingsView]).
@riverpod
class ListingViewModel extends _$ListingViewModel {
  @override
  ListingState build() => ListingState.initial();

  void updateSearchQuery(String query) {
    final next = state.copyWith(searchQuery: query);
    state = next.copyWith(filteredItems: _computeFilter(next));
  }

  void setFilter(String filter) {
    final next = state.copyWith(filter: filter);
    state = next.copyWith(filteredItems: _computeFilter(next));
  }

  Future<void> refreshItems() async {
    state = state.copyWith(filteredItems: _computeFilter(state));
  }

  Future<void> fetchItems() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final products = await ref.read(productServiceProvider).getProducts();
      final bundles = await ref.read(bundleServiceProvider).getBundles();

      final items = <ItemModel>[
        ...products.cast<ItemModel>(),
        ...bundles.cast<ItemModel>(),
      ];

      final next = state.copyWith(isLoading: false, items: items);
      state = next.copyWith(filteredItems: _computeFilter(next));
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching items: $e', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        items: const <ItemModel>[],
        filteredItems: const <dynamic>[],
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> addProduct(ProductModel product) async {
    await ref.read(productServiceProvider).addProduct(product);
    await fetchItems();
  }

  Future<void> addBundle(BundleModel bundle) async {
    await ref.read(bundleServiceProvider).createBundle(bundle);
    await fetchItems();
  }

  Future<void> deleteItem(String itemId, bool isProduct) async {
    if (isProduct) {
      await ref.read(productServiceProvider).deleteProduct(itemId);
    } else {
      await ref.read(bundleServiceProvider).deleteBundle(itemId);
    }

    final remaining = state.items.where((i) => i.id != itemId).toList();
    final next = state.copyWith(items: remaining);
    state = next.copyWith(filteredItems: _computeFilter(next));
  }

  void toggleView() {
    state = state.copyWith(showingProducts: !state.showingProducts);
    fetchItems();
  }

  void clear() {
    state = ListingState.initial().copyWith(isLoading: true);
  }

  List<dynamic> _computeFilter(ListingState s) {
    List<dynamic> result;
    if (s.searchQuery.isEmpty) {
      result = List<dynamic>.from(s.items);
    } else {
      final q = s.searchQuery.toLowerCase();
      result = s.items.where((item) {
        return item.name.toLowerCase().contains(q);
      }).toList();
    }

    if (s.filter == 'Bundles') {
      result = result.whereType<BundleModel>().toList();
    } else if (s.filter == 'Products') {
      result = result.whereType<ProductModel>().toList();
    }

    return result;
  }
}
