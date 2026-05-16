import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/product_model.dart';

part 'product_analytics_viewmodel.g.dart';

/// Immutable state for the product analytics screen.
class ProductAnalyticsState {
  final bool isLoading;
  final String? errorMessage;
  final List<ProductModel> products;
  final List<Map<String, dynamic>> topProducts;

  const ProductAnalyticsState({
    required this.isLoading,
    required this.errorMessage,
    required this.products,
    required this.topProducts,
  });

  factory ProductAnalyticsState.initial() => const ProductAnalyticsState(
        isLoading: false,
        errorMessage: null,
        products: <ProductModel>[],
        topProducts: <Map<String, dynamic>>[],
      );

  ProductAnalyticsState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<ProductModel>? products,
    List<Map<String, dynamic>>? topProducts,
  }) {
    return ProductAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      products: products ?? this.products,
      topProducts: topProducts ?? this.topProducts,
    );
  }

  static const _sentinel = Object();
}

/// Product analytics ViewModel — backs the product analytics screen.
@riverpod
class ProductAnalyticsViewModel extends _$ProductAnalyticsViewModel {
  @override
  ProductAnalyticsState build() => ProductAnalyticsState.initial();

  Future<void> fetchProductAnalytics() async {
    state = state.copyWith(isLoading: true);
    final products = await ref.read(productServiceProvider).getProducts();
    state = state.copyWith(products: products, isLoading: false);
  }

  Future<void> getTopProducts() async {
    state = state.copyWith(isLoading: true);

    // Fetch all completed orders from the last 14 days
    final orderDocs = await ref.read(analyticsServiceProvider).fetchOrders(
          since: DateTime.now().subtract(const Duration(days: 13)),
        );

    final Map<String, int> batchCountMap = {};

    for (var orderDoc in orderDocs) {
      final data = orderDoc.data() as Map<String, dynamic>;

      // Filter by completed status
      if (data['status'] != StatusConstants.completed) continue;

      final orderItems = data['orderItems'] as List<dynamic>? ?? [];
      AppLogger.debug('Order items: $orderItems');

      for (var item in orderItems) {
        final String batchId = item['batchId'] as String? ?? '';
        final int quantity = (item['quantity'] as num?)?.toInt() ?? 0;

        if (batchId.isNotEmpty) {
          batchCountMap[batchId] = (batchCountMap[batchId] ?? 0) + quantity;
        }
      }
    }

    final Map<String, int> productEntries = {};

    for (final entry in batchCountMap.entries) {
      final batch =
          await ref.read(batchServiceProvider).getBatchById(entry.key);
      if (batch != null) {
        final productId = batch.productId;
        productEntries[productId] =
            (productEntries[productId] ?? 0) + entry.value;
      }
    }

    final sortedEntries = productEntries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sortedEntries.take(5).toList();

    final List<Map<String, dynamic>> topProducts = [];
    for (var entry in top5) {
      final product =
          await ref.read(productServiceProvider).getProduct(entry.key);
      if (product != null) {
        topProducts.add({
          'productId': product.id,
          'name': product.name,
          'quantity': entry.value,
        });
      }
    }

    state = state.copyWith(topProducts: topProducts, isLoading: false);
  }
}
