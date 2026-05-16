import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/models/bundle_model.dart';

part 'restock_viewmodel.g.dart';

/// Immutable state for the restock selection + details screens.
///
/// NOTE: `BatchModel` is itself mutable; selected products are mutated in
/// place by the consumer screens (e.g. `product.stock = quantity`,
/// `product.expiryDate = newDate`). `copyWith` is still used to trigger
/// watchers when list membership changes.
class RestockState {
  final bool isLoading;
  final String? errorMessage;
  final List<BatchModel> products;
  final List<BatchModel> selectedProducts;
  final List<BundleModel> bundles;
  final List<BundleModel> selectedBundles;
  final String error;

  const RestockState({
    required this.isLoading,
    required this.errorMessage,
    required this.products,
    required this.selectedProducts,
    required this.bundles,
    required this.selectedBundles,
    required this.error,
  });

  factory RestockState.initial() => const RestockState(
        isLoading: false,
        errorMessage: null,
        products: <BatchModel>[],
        selectedProducts: <BatchModel>[],
        bundles: <BundleModel>[],
        selectedBundles: <BundleModel>[],
        error: '',
      );

  RestockState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<BatchModel>? products,
    List<BatchModel>? selectedProducts,
    List<BundleModel>? bundles,
    List<BundleModel>? selectedBundles,
    String? error,
  }) {
    return RestockState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      products: products ?? this.products,
      selectedProducts: selectedProducts ?? this.selectedProducts,
      bundles: bundles ?? this.bundles,
      selectedBundles: selectedBundles ?? this.selectedBundles,
      error: error ?? this.error,
    );
  }

  static const _sentinel = Object();
}

/// Restock ViewModel — backs the restock selection + details screens.
///
/// NOTE: `batchRestock` currently has a placeholder implementation
/// (no-op apart from loading-state churn); preserved from the original
/// ChangeNotifier — Phase 4 will wire it up to a real batch update service.
@riverpod
class RestockViewModel extends _$RestockViewModel {
  @override
  RestockState build() => RestockState.initial();

  Future<void> fetchProducts() async {
    state = state.copyWith(isLoading: true);

    try {
      final allProducts =
          await ref.read(productServiceProvider).getProducts();

      final List<BatchModel> batches = [];
      for (final product in allProducts) {
        final productBatches =
            await ref.read(productServiceProvider).getProductBatches(product);
        if (productBatches != null) {
          batches.addAll(productBatches);
        }
      }

      state = state.copyWith(products: batches, isLoading: false);
    } catch (e) {
      AppLogger.error('Failed to fetch products for restock', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch products: $e',
      );
    }
  }

  void addSelectedProduct(BatchModel product) {
    if (contain(product)) {
      return;
    }
    final updated = List<BatchModel>.from(state.selectedProducts)..add(product);
    state = state.copyWith(selectedProducts: updated);
  }

  bool contain(BatchModel product) {
    for (var selected in state.selectedProducts) {
      if (product.batchNumber == selected.batchNumber) {
        return true;
      }
    }

    return false;
  }

  void removeSelectedProduct(BatchModel product) {
    final updated = state.selectedProducts
        .where((p) => p.batchNumber != product.batchNumber)
        .toList();
    state = state.copyWith(selectedProducts: updated);
  }

  Future<void> batchRestock(List<BatchModel> productsToRestock) async {
    state = state.copyWith(isLoading: true);

    try {
      // Batch restock logic placeholder - implement when batch update service
      // method is available
    } catch (e) {
      state = state.copyWith(error: 'Failed to restock products: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateExpiryDate(BatchModel product, DateTime newDate) {
    // Preserve the original mutable-model behavior: mutate the BatchModel
    // in place, then emit a state copy to trigger watchers.
    product.expiryDate = newDate;
    state = state.copyWith();
  }
}
