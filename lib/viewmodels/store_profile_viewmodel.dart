import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/current_user_provider.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/core/service_locator.dart';
import 'package:unshelf_seller/models/store_model.dart';

part 'store_profile_viewmodel.g.dart';

/// Immutable state for the Edit Store Profile screen.
///
/// `profileImage` is the freshly-picked image bytes (null until the user
/// taps the avatar). Form text lives on `TextEditingController`s held by
/// the notifier (imperative widget glue, not state).
class StoreProfileState {
  final bool isLoading;
  final String? errorMessage;
  final Uint8List? profileImage;

  const StoreProfileState({
    required this.isLoading,
    required this.errorMessage,
    required this.profileImage,
  });

  factory StoreProfileState.initial() => const StoreProfileState(
        isLoading: false,
        errorMessage: null,
        profileImage: null,
      );

  StoreProfileState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? profileImage = _sentinel,
  }) {
    return StoreProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      profileImage: identical(profileImage, _sentinel)
          ? this.profileImage
          : profileImage as Uint8List?,
    );
  }

  static const _sentinel = Object();
}

/// Store profile ViewModel — backs the Edit Store Profile screen. Owns
/// `TextEditingController`s and an `ImagePicker` on the notifier instance
/// (imperative widget glue, not state). The view calls [loadFromStore] in
/// `initState` to seed the controllers from the current `StoreModel`.
@riverpod
class StoreProfileViewModel extends _$StoreProfileViewModel {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  late CurrentUserProvider _currentUser;

  @override
  StoreProfileState build() {
    _currentUser = locator<CurrentUserProvider>();
    ref.onDispose(() {
      nameController.dispose();
      addressController.dispose();
      phoneNumberController.dispose();
    });
    return StoreProfileState.initial();
  }

  /// Seeds the text controllers from the supplied store model. Called once
  /// from the view's `initState` to mirror the original constructor-time
  /// initialization.
  void loadFromStore(StoreModel storeDetails) {
    nameController.text = storeDetails.storeName;
    addressController.text = storeDetails.storeAddress ?? '';
    phoneNumberController.text = storeDetails.storePhoneNumber ?? '';
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List imageData = await image.readAsBytes();
      state = state.copyWith(profileImage: imageData);
    }
  }

  Future<void> updateStoreProfile() async {
    if (nameController.text.isEmpty) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updateData = <String, dynamic>{
        'storeName': nameController.text,
      };

      if (addressController.text.isNotEmpty) {
        updateData['storeAddress'] = addressController.text;
      }

      if (phoneNumberController.text.isNotEmpty) {
        updateData['storePhoneNumber'] = phoneNumberController.text;
      }

      if (state.profileImage != null) {
        final imageUrl = await uploadImage(state.profileImage!);
        updateData['storeImageUrl'] = imageUrl;
      }

      await ref.read(storeServiceProvider).updateStoreProfile(updateData);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<String> uploadImage(Uint8List? image) async {
    final userId = _currentUser.uid;
    final mainImageRef =
        FirebaseStorage.instance.ref().child('user_avatars/$userId.jpg');
    await mainImageRef.putData(image!);
    final mainImageUrl = await mainImageRef.getDownloadURL();
    return mainImageUrl;
  }
}
