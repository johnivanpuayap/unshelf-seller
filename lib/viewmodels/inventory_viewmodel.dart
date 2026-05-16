import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/inventory_product_model.dart';

part 'inventory_viewmodel.g.dart';

/// Immutable state for the store-inventory screen.
class InventoryState {
  final bool isLoading;
  final String? errorMessage;
  final List<InventoryProductModel> inventoryItems;

  const InventoryState({
    required this.isLoading,
    required this.errorMessage,
    required this.inventoryItems,
  });

  factory InventoryState.initial() => const InventoryState(
        isLoading: false,
        errorMessage: null,
        inventoryItems: <InventoryProductModel>[],
      );

  InventoryState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<InventoryProductModel>? inventoryItems,
  }) {
    return InventoryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      inventoryItems: inventoryItems ?? this.inventoryItems,
    );
  }

  static const _sentinel = Object();
}

/// Store-inventory ViewModel — joins products with their batches into
/// [InventoryProductModel] rows for the inventory list screen.
@riverpod
class InventoryViewModel extends _$InventoryViewModel {
  @override
  InventoryState build() => InventoryState.initial();

  Future<void> fetchInventory() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final productService = ref.read(productServiceProvider);
      final batchService = ref.read(batchServiceProvider);

      final products = await productService.getProducts();
      final items = <InventoryProductModel>[...state.inventoryItems];

      for (final product in products) {
        final batches = await batchService.getBatchesByProductId(product.id);
        items.add(InventoryProductModel(
          id: product.id,
          name: product.name,
          mainImageUrl: product.mainImageUrl,
          batches: batches,
        ));
      }

      AppLogger.debug('Inventory fetched successfully');
      state = state.copyWith(
        isLoading: false,
        inventoryItems: items,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error in InventoryViewModel: $e', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearData() {
    state = state.copyWith(inventoryItems: const <InventoryProductModel>[]);
  }
}
