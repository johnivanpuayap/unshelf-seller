import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/models/product_model.dart';

part 'product_summary_viewmodel.g.dart';

/// Immutable state for the product details (summary + batches) screen.
///
/// `PageController` remains owned by the notifier (imperative widget glue);
/// see [ProductSummaryViewModel].
class ProductSummaryState {
  final bool isLoading;
  final String? errorMessage;
  final ProductModel? product;
  final List<BatchModel>? batches;
  final int currentPage;

  const ProductSummaryState({
    required this.isLoading,
    required this.errorMessage,
    required this.product,
    required this.batches,
    required this.currentPage,
  });

  factory ProductSummaryState.initial() => const ProductSummaryState(
        isLoading: false,
        errorMessage: null,
        product: null,
        batches: null,
        currentPage: 0,
      );

  ProductSummaryState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? product = _sentinel,
    Object? batches = _sentinel,
    int? currentPage,
  }) {
    return ProductSummaryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      product: identical(product, _sentinel)
          ? this.product
          : product as ProductModel?,
      batches: identical(batches, _sentinel)
          ? this.batches
          : batches as List<BatchModel>?,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  static const _sentinel = Object();
}

/// Product summary ViewModel — backs the product details screen. Owns a
/// `PageController` on the notifier instance (imperative widget glue, not
/// state).
@riverpod
class ProductSummaryViewModel extends _$ProductSummaryViewModel {
  final PageController pageController = PageController();

  @override
  ProductSummaryState build() {
    ref.onDispose(() {
      pageController.dispose();
    });
    return ProductSummaryState.initial();
  }

  Future<void> fetchProductData(String productId) async {
    state = state.copyWith(isLoading: true);

    try {
      final product =
          await ref.read(productServiceProvider).getProduct(productId);
      List<BatchModel>? batches;
      if (product != null) {
        batches =
            await ref.read(productServiceProvider).getProductBatches(product);
      }
      state = state.copyWith(
        product: product,
        batches: batches,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Error fetching product data: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void onPageChanged(int index) {
    state = state.copyWith(currentPage: index);
  }

  Future<void> deleteBatch(String batchNumber) async {
    await ref.read(batchServiceProvider).deleteBatch(batchNumber);
    final batches = state.batches;
    if (batches != null) {
      final updated = batches
          .where((batch) => batch.batchNumber != batchNumber)
          .toList();
      state = state.copyWith(batches: updated);
    }
  }
}
