import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/data/repositories/providers.dart';
import 'package:unshelf_seller/models/product_model.dart';
import 'package:unshelf_seller/utils/colors.dart';

part 'product_viewmodel.g.dart';

/// Immutable state for the add/edit product screens.
///
/// `TextEditingController`s, `FormKey`, and the `ImagePicker` remain owned
/// by the notifier (they are imperative widget glue rather than state); see
/// [ProductViewModel].
class ProductState {
  final bool isLoading;
  final String? errorMessage;
  final ImageState mainImageState;
  final List<ImageState> additionalImages;
  final ProductModel? selectedProduct;
  final String selectedProductId;
  final String selectedCategory;
  final bool errorFound;

  const ProductState({
    required this.isLoading,
    required this.errorMessage,
    required this.mainImageState,
    required this.additionalImages,
    required this.selectedProduct,
    required this.selectedProductId,
    required this.selectedCategory,
    required this.errorFound,
  });

  factory ProductState.initial() => ProductState(
        isLoading: false,
        errorMessage: null,
        mainImageState: ImageState(),
        additionalImages: const <ImageState>[],
        selectedProduct: null,
        selectedProductId: '',
        selectedCategory: '',
        errorFound: false,
      );

  ProductState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    ImageState? mainImageState,
    List<ImageState>? additionalImages,
    Object? selectedProduct = _sentinel,
    String? selectedProductId,
    String? selectedCategory,
    bool? errorFound,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      mainImageState: mainImageState ?? this.mainImageState,
      additionalImages: additionalImages ?? this.additionalImages,
      selectedProduct: identical(selectedProduct, _sentinel)
          ? this.selectedProduct
          : selectedProduct as ProductModel?,
      selectedProductId: selectedProductId ?? this.selectedProductId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorFound: errorFound ?? this.errorFound,
    );
  }

  static const _sentinel = Object();
}

/// Product ViewModel — backs the add/edit product screens. Owns
/// `TextEditingController`s, the `FormKey`, and an `ImagePicker` on the
/// notifier instance (imperative widget glue, not state).
@riverpod
class ProductViewModel extends _$ProductViewModel {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final List<String> categories = const [
    'Grocery',
    'Fruits',
    'Vegetables',
    'Baked Goods',
  ];

  @override
  ProductState build() {
    ref.onDispose(() {
      nameController.dispose();
      descriptionController.dispose();
    });
    return ProductState.initial();
  }

  void setSelectedCategory(String value) {
    state = state.copyWith(selectedCategory: value);
  }

  void setErrorFound(bool value) {
    state = state.copyWith(errorFound: value);
  }

  Future<bool> addProductWithValidation(BuildContext context) async {
    state = state.copyWith(isLoading: true);

    if (state.mainImageState.data == null) {
      state = state.copyWith(errorFound: true, isLoading: false);
      _showSnackBar(context, 'Please add a main image!');
      return false;
    }

    if (!(formKey.currentState?.validate() ?? false)) {
      state = state.copyWith(isLoading: false);
      _showSnackBar(context, 'Please fill out all required fields!');
      return false;
    }

    await addProduct(context);
    if (context.mounted) {
      _showSnackBar(context, 'Product added successfully!', isSuccess: true);
    }
    return true;
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isSuccess ? AppColors.primaryColor : AppColors.error,
      ),
    );
  }

  Future<void> loadProduct(ProductModel product) async {
    state = state.copyWith(isLoading: true);
    nameController.text = product.name;
    descriptionController.text = product.description;

    // Load main image
    final mainImageState = ImageState(url: product.mainImageUrl);
    await mainImageState.loadImageData();

    List<ImageState> additionalImages;
    if (product.additionalImageUrls != null &&
        product.additionalImageUrls!.isNotEmpty) {
      additionalImages =
          await Future.wait(product.additionalImageUrls!.map((url) async {
        final imageState = ImageState(url: url);
        await imageState.loadImageData();
        return imageState;
      }).toList());
    } else {
      additionalImages = <ImageState>[];
    }

    AppLogger.debug('Product loaded: $product');
    state = state.copyWith(
      isLoading: false,
      mainImageState: mainImageState,
      additionalImages: additionalImages,
      selectedProduct: product,
      selectedCategory: product.category,
    );
  }

  // Pick and add image to the respective list
  Future<void> pickImage(bool isMainImage) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List imageData = await image.readAsBytes();

      if (isMainImage) {
        state = state.copyWith(
          mainImageState: ImageState(data: imageData, isNew: true),
          errorFound: false,
        );
      } else {
        final updated = List<ImageState>.from(state.additionalImages)
          ..add(ImageState(data: imageData, isNew: true));
        state = state.copyWith(
          additionalImages: updated,
          errorFound: false,
        );
      }
    }
  }

  // Upload image and return URL. Routes through StorageRepository so the
  // viewmodel no longer touches the FirebaseStorage SDK directly.
  Future<String> uploadImage(Uint8List imageData, int? index) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = index == null
        ? 'product_images/main_$ts.jpg'
        : 'product_images/additional_${ts}_$index.jpg';
    return ref.read(storageRepositoryProvider).uploadBytes(path, imageData);
  }

  void deleteImage(bool isMainImage, int? index) {
    if (isMainImage) {
      state = state.copyWith(mainImageState: ImageState(isNew: true));
    } else if (index != null && index < state.additionalImages.length) {
      final updated = List<ImageState>.from(state.additionalImages)
        ..removeAt(index);
      state = state.copyWith(additionalImages: updated);
    }
  }

  // Add product with the uploaded images
  Future<void> addProduct(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      state = state.copyWith(isLoading: true);

      try {
        final ProductModel product = ProductModel(
          id: '',
          name: nameController.text,
          description: descriptionController.text,
          category: state.selectedCategory,
          mainImageUrl: await uploadImage(state.mainImageState.data!, null),
          additionalImageUrls: [],
        );

        final newId =
            await ref.read(productServiceProvider).addProduct(product);
        state = state.copyWith(selectedProductId: newId);
      } catch (e) {
        AppLogger.error('Error adding product', e);
      } finally {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  // Update product with the uploaded images
  Future<bool> updateProduct(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      state = state.copyWith(isLoading: true);

      if (state.mainImageState.isNew && state.mainImageState.data == null) {
        state = state.copyWith(errorFound: true, isLoading: false);
        return false;
      }

      try {
        final productId = state.selectedProduct?.id;
        if (productId == null) {
          AppLogger.error('Error updating product: no product selected');
          return false;
        }

        String mainImageUrl = state.selectedProduct!.mainImageUrl;
        if (state.mainImageState.isNew) {
          mainImageUrl = await uploadImage(state.mainImageState.data!, null);
        }

        for (int i = 0; i < state.additionalImages.length; i++) {
          if (state.additionalImages[i].isNew) {
            state.additionalImages[i].url =
                await uploadImage(state.additionalImages[i].data!, i);
          }
        }

        final List<String?> additionalImageUrls = state.additionalImages
            .map((imageState) => imageState.url)
            .toList();

        final ProductModel updated = ProductModel(
          id: productId,
          name: nameController.text,
          description: descriptionController.text,
          category: state.selectedCategory,
          mainImageUrl: mainImageUrl,
          additionalImageUrls:
              additionalImageUrls.whereType<String>().toList(),
        );

        await ref.read(productServiceProvider).updateProduct(productId, updated);
        return true;
      } catch (e) {
        AppLogger.error('Error updating product: $e');
        return false;
      } finally {
        state = state.copyWith(isLoading: false);
      }
    }

    return false;
  }

  // Clear all data
  void clearData() {
    nameController.clear();
    descriptionController.clear();
    state = state.copyWith(
      selectedCategory: '',
      mainImageState: ImageState(),
      additionalImages: const <ImageState>[],
    );
  }
}

class ImageState {
  Uint8List? data;
  String? url;
  bool isNew;
  bool isDeleted;

  ImageState({
    this.data,
    this.url,
    this.isNew = false,
    this.isDeleted = false,
  });

  Future<void> loadImageData() async {
    if (url != null) {
      try {
        final response = await http.get(Uri.parse(url!));
        if (response.statusCode == 200) {
          data = response.bodyBytes;
        } else {
          AppLogger.warning("Failed to load image from URL.");
        }
      } catch (e) {
        AppLogger.error("Error loading image: $e");
      }
    }
  }
}
