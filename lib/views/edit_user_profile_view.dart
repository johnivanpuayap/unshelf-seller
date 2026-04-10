import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/models/user_model.dart';
import 'package:unshelf_seller/viewmodels/user_profile_viewmodel.dart';
import 'package:unshelf_seller/utils/theme.dart';

class EditUserProfileView extends StatelessWidget {
  final UserProfileModel userProfile;

  EditUserProfileView({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<UserProfileViewModel>(context);

    viewModel.initializeControllers(userProfile);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Edit User Profile',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.errorMessage != null
              ? Center(child: Text(viewModel.errorMessage!))
              : Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppTheme.spacing8),
                      TextFormField(
                        controller: viewModel.nameController,
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
                        controller: viewModel.emailController,
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
                        controller: viewModel.phoneController,
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
                        controller: viewModel.passwordController,
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
                        controller: viewModel.confirmPasswordController,
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
                            viewModel.updateUserProfile();

                            if (viewModel.errorMessage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully'),
                                ),
                              );
                            }

                            AppLogger.debug('Passing ${viewModel.userProfile}');

                            Navigator.pop(context, viewModel.userProfile);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
