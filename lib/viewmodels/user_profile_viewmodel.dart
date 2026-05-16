import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/user_model.dart';

part 'user_profile_viewmodel.g.dart';

/// Immutable state for the Edit User Profile screen.
///
/// `userProfile` mirrors the original ChangeNotifier field — it remains
/// `null` in the current code paths (no caller invokes `setUserProfile`),
/// but a setter is preserved here so future auth integrations can supply
/// it via `ref.read(userProfileViewModelProvider.notifier).setUserProfile(...)`.
class UserProfileState {
  final bool isLoading;
  final String? errorMessage;
  final UserProfileModel? userProfile;

  const UserProfileState({
    required this.isLoading,
    required this.errorMessage,
    required this.userProfile,
  });

  factory UserProfileState.initial() => const UserProfileState(
        isLoading: false,
        errorMessage: null,
        userProfile: null,
      );

  UserProfileState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? userProfile = _sentinel,
  }) {
    return UserProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      userProfile: identical(userProfile, _sentinel)
          ? this.userProfile
          : userProfile as UserProfileModel?,
    );
  }

  static const _sentinel = Object();
}

/// User profile ViewModel — backs the Edit User Profile screen. Owns
/// `TextEditingController`s for name/email/phone/password fields on the
/// notifier instance (imperative widget glue, not state).
///
/// FirebaseAuth is held directly for reauthentication and password-change
/// operations that aren't exposed by the service layer.
@Riverpod(keepAlive: true)
class UserProfileViewModel extends _$UserProfileViewModel {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  UserProfileState build() {
    ref.onDispose(() {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
    });
    return UserProfileState.initial();
  }

  void setUserProfile(UserProfileModel? profile) {
    state = state.copyWith(userProfile: profile);
  }

  void initializeControllers(UserProfileModel userProfile) {
    nameController.text = userProfile.name;
    emailController.text = userProfile.email;
    phoneController.text = userProfile.phoneNumber;
  }

  Future<void> updateUserProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _auth.currentUser!;

      if (passwordController.text.isNotEmpty &&
          confirmPasswordController.text.isEmpty) {
        state = state.copyWith(
            isLoading: false, errorMessage: 'Please confirm your password');
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        state = state.copyWith(
            isLoading: false, errorMessage: 'Passwords do not match');
        return;
      }

      if (emailController.text != user.email) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: passwordController.text,
        );

        await user.reauthenticateWithCredential(credential);
      }

      if (passwordController.text.isNotEmpty &&
          confirmPasswordController.text.isNotEmpty) {
        await _auth.currentUser!.updatePassword(passwordController.text);
      }

      await ref.read(userProfileServiceProvider).updateUserProfile({
        'name': nameController.text,
        'email': emailController.text,
        'phoneNumber': phoneController.text,
      });

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
