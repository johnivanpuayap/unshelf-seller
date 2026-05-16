import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/batch_model.dart';

part 'select_products_viewmodel.g.dart';

/// Immutable state for the bundle product-selection screen.
///
/// NOTE: `BatchModel.product` is set by-mutation in `fetchAllBatches`
/// (preserved from the original ChangeNotifier). `sortItems` mutates
/// `filteredItems` in place before reassigning state to trigger watchers.
class SelectProductsState {
  final bool isLoading;
  final String? errorMessage;
  final List<BatchModel> items;
  final List<BatchModel> filteredItems;
  final Map<String, BatchModel> selectedItems;
  final String sortBy;
  final String searchQuery;

  const SelectProductsState({
    required this.isLoading,
    required this.errorMessage,
    required this.items,
    required this.filteredItems,
    required this.selectedItems,
    required this.sortBy,
    required this.searchQuery,
  });

  factory SelectProductsState.initial() => const SelectProductsState(
        isLoading: false,
        errorMessage: null,
        items: <BatchModel>[],
        filteredItems: <BatchModel>[],
        selectedItems: <String, BatchModel>{},
        sortBy: 'expiryDate',
        searchQuery: '',
      );

  SelectProductsState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<BatchModel>? items,
    List<BatchModel>? filteredItems,
    Map<String, BatchModel>? selectedItems,
    String? sortBy,
    String? searchQuery,
  }) {
    return SelectProductsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      selectedItems: selectedItems ?? this.selectedItems,
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  static const _sentinel = Object();
}

/// Select-products ViewModel — backs the bundle product-selection screen.
@riverpod
class SelectProductsViewModel extends _$SelectProductsViewModel {
  @override
  SelectProductsState build() => SelectProductsState.initial();

  Future<void> fetchAllBatches() async {
    state = state.copyWith(isLoading: true);

    final items = await ref.read(batchServiceProvider).getAllBatches();

    final List<Future<void>> productFutures = items.map((item) async {
      item.product =
          await ref.read(productServiceProvider).getProduct(item.productId);
    }).toList();

    await Future.wait(productFutures);

    items.removeWhere((item) => item.product == null);

    state = state.copyWith(
      isLoading: false,
      items: items,
      filteredItems: items,
    );
  }

  // Method to add a product to the bundle
  void addProductToBundle(String batchNumber) {
    if (!state.selectedItems.keys.contains(batchNumber)) {
      final updated = Map<String, BatchModel>.from(state.selectedItems);
      updated[batchNumber] = state.items
          .firstWhere((product) => product.batchNumber == batchNumber);
      state = state.copyWith(selectedItems: updated);
    }
  }

  // Method to remove a product from the bundle
  void removeProductFromBundle(String batchNumber) {
    final updated = Map<String, BatchModel>.from(state.selectedItems);
    updated.remove(batchNumber);
    state = state.copyWith(selectedItems: updated);
  }

  void updateSearchQuery(String query) {
    final filtered = _filterItems(query);
    state = state.copyWith(searchQuery: query, filteredItems: filtered);
  }

  void sortItems(String sortBy) {
    // Preserve in-place sort behavior, then emit a new state.
    final sorted = List<BatchModel>.from(state.filteredItems);
    String nextSortBy = state.sortBy;
    if (sortBy == 'name') {
      nextSortBy = 'name';
      sorted.sort((a, b) => a.product!.name.compareTo(b.product!.name));
    } else if (sortBy == 'expiryDate') {
      nextSortBy = 'expiryDate';
      sorted.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    }
    state = state.copyWith(sortBy: nextSortBy, filteredItems: sorted);
  }

  List<BatchModel> _filterItems(String query) {
    if (query.isEmpty) {
      return state.items;
    }
    AppLogger.debug('Filtering items');
    final result = state.items.where((item) {
      final name = item.product?.name.toLowerCase();
      final q = query.toLowerCase();
      return name!.contains(q);
    }).toList();
    AppLogger.debug('Filtered items: $result');
    return result;
  }

  void clearSelection() {
    state = state.copyWith(selectedItems: <String, BatchModel>{});
  }
}
