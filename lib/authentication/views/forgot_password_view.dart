import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:unshelf_seller/authentication/views/forgot_password_viewmodel.dart';
import 'package:unshelf_seller/core/interfaces/i_auth_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';

class ForgotPasswordView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordViewModel(authService: locator<IAuthService>()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Forgot Password'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<ForgotPasswordViewModel>(
            builder: (context, viewModel, child) {
              final theme = Theme.of(context);
              return Form(
                key: viewModel.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your email to receive a password reset link.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: viewModel.emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        String message = await viewModel.sendPasswordReset();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                        if (message == 'Password reset email sent') {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Send Reset Link'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
