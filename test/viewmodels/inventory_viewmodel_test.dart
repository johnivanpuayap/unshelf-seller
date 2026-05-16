import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/models/product_model.dart';
import 'package:unshelf_seller/viewmodels/inventory_viewmodel.dart';

import '../mocks/mock_batch_service.dart';
import '../mocks/mock_product_service.dart';

ProductModel _makeProduct(String id, String name) {
  return ProductModel(
    id: id,
    name: name,
    mainImageUrl: 'https://example.com/$id.jpg',
    category: 'Food',
    description: 'A $name product',
  );
}

BatchModel _makeBatch(String batchNumber, String productId) {
  return BatchModel(
    batchNumber: batchNumber,
    productId: productId,
    product: null,
    price: 10.0,
    stock: 5,
    quantifier: 'piece',
    expiryDate: DateTime(2026, 12, 31),
    discount: 0,
  );
}

/// Builds a [ProviderContainer] with the inventory ViewModel's service
/// dependencies overridden with the given mocks.
ProviderContainer _makeContainer({
  required MockProductService productService,
  required MockBatchService batchService,
}) {
  final container = ProviderContainer(overrides: [
    productServiceProvider.overrideWithValue(productService),
    batchServiceProvider.overrideWithValue(batchService),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockProductService mockProductService;
  late MockBatchService mockBatchService;

  setUp(() {
    mockProductService = MockProductService();
    mockBatchService = MockBatchService();
  });

  group('fetchInventory', () {
    test('builds inventory items from products and their batches', () async {
      final product1 = _makeProduct('p1', 'Rice');
      final product2 = _makeProduct('p2', 'Bread');

      mockProductService.productsResult = [product1, product2];
      mockBatchService.batchesByProductId = {
        'p1': [_makeBatch('b1', 'p1'), _makeBatch('b2', 'p1')],
        'p2': [_makeBatch('b3', 'p2')],
      };

      final container = _makeContainer(
        productService: mockProductService,
        batchService: mockBatchService,
      );

      await container
          .read(inventoryViewModelProvider.notifier)
          .fetchInventory();

      final state = container.read(inventoryViewModelProvider);
      expect(state.inventoryItems.length, 2);
      expect(state.inventoryItems[0].name, 'Rice');
      expect(state.inventoryItems[0].batches.length, 2);
      expect(state.inventoryItems[1].name, 'Bread');
      expect(state.inventoryItems[1].batches.length, 1);
      expect(state.isLoading, isFalse);
    });

    test('populates id and mainImageUrl from product', () async {
      mockProductService.productsResult = [_makeProduct('p1', 'Rice')];
      mockBatchService.batchesByProductId = {
        'p1': [_makeBatch('b1', 'p1')],
      };

      final container = _makeContainer(
        productService: mockProductService,
        batchService: mockBatchService,
      );

      await container
          .read(inventoryViewModelProvider.notifier)
          .fetchInventory();

      final state = container.read(inventoryViewModelProvider);
      expect(state.inventoryItems[0].id, 'p1');
      expect(state.inventoryItems[0].mainImageUrl,
          'https://example.com/p1.jpg');
    });

    test('handles empty products list', () async {
      mockProductService.productsResult = [];

      final container = _makeContainer(
        productService: mockProductService,
        batchService: mockBatchService,
      );

      await container
          .read(inventoryViewModelProvider.notifier)
          .fetchInventory();

      final state = container.read(inventoryViewModelProvider);
      expect(state.inventoryItems, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('handles products with no batches', () async {
      mockProductService.productsResult = [_makeProduct('p1', 'Rice')];
      mockBatchService.batchesByProductId = {'p1': []};

      final container = _makeContainer(
        productService: mockProductService,
        batchService: mockBatchService,
      );

      await container
          .read(inventoryViewModelProvider.notifier)
          .fetchInventory();

      final state = container.read(inventoryViewModelProvider);
      expect(state.inventoryItems.length, 1);
      expect(state.inventoryItems[0].batches, isEmpty);
    });

    test('uses fallback batchesResult when productId not in map', () async {
      final fallbackBatch = _makeBatch('bf', 'p1');
      mockProductService.productsResult = [_makeProduct('p1', 'Rice')];
      mockBatchService.batchesByProductId = {};
      mockBatchService.batchesResult = [fallbackBatch];

      final container = _makeContainer(
        productService: mockProductService,
        batchService: mockBatchService,
      );

      await container
          .read(inventoryViewModelProvider.notifier)
          .fetchInventory();

      final state = container.read(inventoryViewModelProvider);
      expect(state.inventoryItems[0].batches.length, 1);
      expect(state.inventoryItems[0].batches[0].batchNumber, 'bf');
    });
  });

  group('error handling', () {
    test('product service error sets errorMessage', () async {
      mockProductService.errorToThrow = Exception('Firestore unavailable');

      final container = _makeContainer(
        productService: mockProductService,
        batchService: mockBatchService,
      );

      await container
          .read(inventoryViewModelProvider.notifier)
          .fetchInventory();

      final state = container.read(inventoryViewModelProvider);
      expect(state.errorMessage, contains('Firestore unavailable'));
      expect(state.isLoading, isFalse);
    });

    test('batch service error sets errorMessage', () async {
      mockProductService.productsResult = [_makeProduct('p1', 'Rice')];
      mockBatchService.errorToThrow = Exception('Batch fetch failed');

      final container = _makeContainer(
        productService: mockProductService,
        batchService: mockBatchService,
      );

      await container
          .read(inventoryViewModelProvider.notifier)
          .fetchInventory();

      final state = container.read(inventoryViewModelProvider);
      expect(state.errorMessage, contains('Batch fetch failed'));
      expect(state.isLoading, isFalse);
    });
  });

  group('clearData', () {
    test('empties inventoryItems list', () async {
      mockProductService.productsResult = [_makeProduct('p1', 'Rice')];
      mockBatchService.batchesByProductId = {
        'p1': [_makeBatch('b1', 'p1')],
      };

      final container = _makeContainer(
        productService: mockProductService,
        batchService: mockBatchService,
      );

      await container
          .read(inventoryViewModelProvider.notifier)
          .fetchInventory();
      expect(container.read(inventoryViewModelProvider).inventoryItems,
          isNotEmpty);

      container.read(inventoryViewModelProvider.notifier).clearData();

      expect(
          container.read(inventoryViewModelProvider).inventoryItems, isEmpty);
    });

    test('clearData on already empty list stays empty', () {
      final container = _makeContainer(
        productService: mockProductService,
        batchService: mockBatchService,
      );

      container.read(inventoryViewModelProvider.notifier).clearData();

      expect(
          container.read(inventoryViewModelProvider).inventoryItems, isEmpty);
    });
  });
}
