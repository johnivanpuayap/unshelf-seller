import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/data/repositories/providers.dart';
import 'package:unshelf_seller/models/bundle_model.dart';

part 'bundle_viewmodel.g.dart';

/// Immutable state for the bundle add/edit/details screens.
///
/// `TextEditingController`s, `formKey`, and the `ImagePicker` remain
/// owned by the notifier — see [BundleViewModel].
class BundleState {
  final bool isLoading;
  final String? errorMessage;
  final BundleModel? bundle;
  final Uint8List? mainImageData;
  final String selectedCategory;
  final bool errorFound;

  const BundleState({
    required this.isLoading,
    required this.errorMessage,
    required this.bundle,
    required this.mainImageData,
    required this.selectedCategory,
    required this.errorFound,
  });

  factory BundleState.initial() => const BundleState(
        isLoading: false,
        errorMessage: null,
        bundle: null,
        mainImageData: null,
        selectedCategory: '',
        errorFound: false,
      );

  BundleState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? bundle = _sentinel,
    Object? mainImageData = _sentinel,
    String? selectedCategory,
    bool? errorFound,
  }) {
    return BundleState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      bundle: identical(bundle, _sentinel)
          ? this.bundle
          : bundle as BundleModel?,
      mainImageData: identical(mainImageData, _sentinel)
          ? this.mainImageData
          : mainImageData as Uint8List?,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorFound: errorFound ?? this.errorFound,
    );
  }

  static const _sentinel = Object();
}

/// Bundle ViewModel — backs the add / edit / details bundle screens.
/// Owns the form's controllers, key, and image picker (notifier-side
/// fields, not state).
@riverpod
class BundleViewModel extends _$BundleViewModel {
  final TextEditingController bundleNameController = TextEditingController();
  final TextEditingController bundlePriceController = TextEditingController();
  final TextEditingController bundleStockController = TextEditingController();
  final TextEditingController bundleDiscountController =
      TextEditingController();
  final TextEditingController bundleDescriptionController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final List<String> categories = const [
    'Grocery',
    'Fruits',
    'Vegetables',
    'Baked Goods',
  ];

  @override
  BundleState build() {
    ref.onDispose(() {
      bundleNameController.dispose();
      bundlePriceController.dispose();
      bundleStockController.dispose();
      bundleDiscountController.dispose();
      bundleDescriptionController.dispose();
    });
    return BundleState.initial();
  }

  /// Mutable `selectedCategory` setter — kept for compatibility with
  /// views that do `viewModel.selectedCategory = newValue`.
  set selectedCategory(String value) {
    state = state.copyWith(selectedCategory: value);
  }

  String get selectedCategory => state.selectedCategory;

  void initializeControllers(BundleModel bundle) {
    bundleNameController.text = bundle.name;
    bundlePriceController.text = bundle.price.toString();
    bundleStockController.text = bundle.stock.toString();
    bundleDiscountController.text = bundle.discount.toString();
    bundleDescriptionController.text = bundle.description;
    // Force a rebuild so consumers see the updated controllers.
    state = state.copyWith();
  }

  Future<void> createBundle(
      Map<String, Map<String, dynamic>> productDetails) async {
    try {
      final bundleName = bundleNameController.text;
      final bundlePrice = double.tryParse(bundlePriceController.text) ?? 0.0;
      final bundleStock = int.tryParse(bundleStockController.text) ?? 0;
      final bundleDiscount = int.tryParse(bundleDiscountController.text) ?? 0;
      final bundleDescription = bundleDescriptionController.text;

      // Route through StorageRepository so the viewmodel stays free of
      // FirebaseStorage SDK references.
      final mainImageUrl = await ref.read(storageRepositoryProvider).uploadBytes(
            'bundle_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
            state.mainImageData!,
          );

      BundleModel bundle = BundleModel(
        id: '',
        name: bundleName,
        mainImageUrl: mainImageUrl,
        description: bundleDescription,
        category: state.selectedCategory,
        items: productDetails.entries
            .map((entry) => {
                  'batchId': entry.key,
                  'quantity': entry.value['quantity'],
                  'quantifier': entry.value['quantifier'],
                })
            .toList(),
        price: bundlePrice,
        stock: bundleStock,
        discount: bundleDiscount,
      );

      await ref.read(bundleServiceProvider).createBundle(bundle);
      AppLogger.debug('Bundle created successfully');
      // Trigger rebuild
      state = state.copyWith();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create bundle: $e', e, stackTrace);
    }
  }

  Future<void> loadImageFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        state = state.copyWith(mainImageData: response.bodyBytes);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading image: $e', e, stackTrace);
    }
  }

  Future<void> pickImage() async {
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final Uint8List imageData = await image.readAsBytes();
      state = state.copyWith(mainImageData: imageData);
    }
  }

  void deleteImage() {
    state = state.copyWith(mainImageData: null);
  }

  Future<void> getBundleDetails(String bundleId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final bundle = await ref.read(bundleServiceProvider).getBundle(bundleId);

      for (var item in bundle!.items) {
        final batch = await ref
            .read(batchServiceProvider)
            .getBatchById(item['batchId']);
        item['name'] = batch!.product!.name;
        item['imageUrl'] = batch.product!.mainImageUrl;
      }

      state = state.copyWith(bundle: bundle);

      // Load main image
      await loadImageFromUrl(bundle.mainImageUrl);
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      AppLogger.error('Error in BundleViewModel.getBundleDetails: $e', e,
          stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> initializeBundle(String bundleId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (bundleId.isNotEmpty) {
        await getBundleDetails(bundleId);
      }

      final bundle = state.bundle;
      if (bundle != null) {
        bundleNameController.text = bundle.name;
        bundleDescriptionController.text = bundle.description;
        bundlePriceController.text = bundle.price.toString();
        bundleStockController.text = bundle.stock.toString();
        bundleDiscountController.text = bundle.discount.toString();
        state = state.copyWith(selectedCategory: bundle.category);
      }

      AppLogger.debug('category: ${state.selectedCategory}');
      AppLogger.debug('Bundle initialized successfully');

      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      AppLogger.error('Error in BundleViewModel.initializeBundle: $e', e,
          stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateBundle() async {
    try {
      final bundleName = bundleNameController.text;
      final bundlePrice = double.tryParse(bundlePriceController.text) ?? 0.0;
      final bundleStock = int.tryParse(bundleStockController.text) ?? 0;
      final bundleDiscount = int.tryParse(bundleDiscountController.text) ?? 0;
      final bundleDescription = bundleDescriptionController.text;

      final mainImageUrl = await ref.read(storageRepositoryProvider).uploadBytes(
            'bundle_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
            state.mainImageData!,
          );

      BundleModel updatedBundle = BundleModel(
        id: state.bundle!.id,
        name: bundleName,
        mainImageUrl: mainImageUrl,
        description: bundleDescription,
        category: state.selectedCategory,
        items: state.bundle!.items,
        price: bundlePrice,
        stock: bundleStock,
        discount: bundleDiscount,
      );

      await ref.read(bundleServiceProvider).updateBundle(updatedBundle);
      AppLogger.debug('Bundle updated successfully');
      state = state.copyWith();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update bundle: $e', e, stackTrace);
    }
  }

  void clearSelection() {
    bundleNameController.clear();
    bundlePriceController.clear();
    bundleStockController.clear();
    bundleDiscountController.clear();
    bundleDescriptionController.clear();
    state = state.copyWith(
      mainImageData: null,
      selectedCategory: '',
    );
  }
}
