import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/models/user_model.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/user_profile_viewmodel.dart';

class EditUserProfileView extends ConsumerStatefulWidget {
  final UserProfileModel userProfile;

  const EditUserProfileView({super.key, required this.userProfile});

  @override
  ConsumerState<EditUserProfileView> createState() =>
      _EditUserProfileViewState();
}

class _EditUserProfileViewState extends ConsumerState<EditUserProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(userProfileViewModelProvider.notifier)
          .initializeControllers(widget.userProfile);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProfileViewModelProvider);
    final notifier = ref.read(userProfileViewModelProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Edit User Profile',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(child: Text(state.errorMessage!))
              : Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppTheme.spacing8),
                      TextFormField(
                        controller: notifier.nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      TextFormField(
                        controller: notifier.emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      TextFormField(
                        controller: notifier.phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      TextFormField(
                        controller: notifier.passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          } else if (value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      TextFormField(
                        controller: notifier.confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Align(
                        alignment: Alignment.center,
                        child: CustomButton(
                          text: 'Save Changes',
                          onPressed: () {
                            notifier.updateUserProfile();

                            final updatedState =
                                ref.read(userProfileViewModelProvider);
                            if (updatedState.errorMessage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Profile updated successfully'),
                                ),
                              );
                            }

                            AppLogger.debug(
                                'Passing ${updatedState.userProfile}');

                            Navigator.pop(context, updatedState.userProfile);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
