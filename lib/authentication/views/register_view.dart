import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_seller/authentication/views/login_view.dart';
import 'package:unshelf_seller/core/interfaces/i_store_service.dart';
import 'package:unshelf_seller/core/interfaces/i_user_profile_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _sellerNameController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> saveUserData(
      User user, String name, String phoneNumber, String storeName) async {
    await locator<IUserProfileService>().createUserDocument(user.uid, {
      'name': name,
      'email': user.email,
      'phoneNumber': phoneNumber,
      'type': 'seller',
      'isBanned': false,
    });

    await locator<IStoreService>().createStore(user.uid, {
      'storeSchedule': {
        'Monday': {'open': '', 'close': '', 'isOpen': 'false'},
        'Tuesday': {'open': '', 'close': '', 'isOpen': 'false'},
        'Wednesday': {'open': '', 'close': '', 'isOpen': 'false'},
        'Thursday': {'open': '', 'close': '', 'isOpen': 'false'},
        'Friday': {'open': '', 'close': '', 'isOpen': 'false'},
        'Saturday': {'open': '', 'close': '', 'isOpen': 'false'},
        'Sunday': {'open': '', 'close': '', 'isOpen': 'false'},
      },
      'storeName': "",
      'storeImageUrl': "",
      'isApproved': false,
      'isNew': true,
      'latitude': 10.3157,
      'longitude': 123.8854,
      'storeAddress': "",
      'storePhoneNumber': "",
      'storeFollowers': 0,
      'storeRating': 0,
    });
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      User user = userCredential.user!;
      await saveUserData(user, _sellerNameController.text.trim(),
          _phoneNumberController.text.trim(), _storeNameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please sign in.'),
          ),
        );

        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginView()));
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message =
            'Password is too weak. Use at least 6 characters with letters and numbers.';
      } else if (e.code == 'email-already-in-use') {
        message =
            'An account with this email already exists. Try signing in instead.';
      } else {
        message = 'Registration failed. Please check your details and try again.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Registration failed. Please check your details and try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacing32),

                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 96,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Heading
                Text(
                  'Create your account',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'Start selling near-expiry food today',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing32),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name field
                      TextFormField(
                        controller: _sellerNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email address';
                          }
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      // Confirm password field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword =
                                  !_obscureConfirmPassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),

                      // Phone number field
                      TextFormField(
                        controller: _phoneNumberController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '09XX XXX XXXX',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your phone number';
                          }
                          if (value.trim().length < 11) {
                            return 'Phone number must be at least 11 digits';
                          }
                          if (!value.trim().startsWith('09')) {
                            return 'Phone number must start with 09';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing24),

                      // Sign Up button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacing16),

                // Terms text
                Text(
                  "By signing up, you agree to Unshelf's Terms of Use and Privacy Policy.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),

                const SizedBox(height: AppTheme.spacing24),

                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginView()),
                        );
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    _sellerNameController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }
}
