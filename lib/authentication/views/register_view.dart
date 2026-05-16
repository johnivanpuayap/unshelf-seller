import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unshelf_seller/authentication/views/login_view.dart';
import 'package:unshelf_seller/core/interfaces/i_store_service.dart';
import 'package:unshelf_seller/core/interfaces/i_user_profile_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';

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

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _submitting = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveUserData(
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
      'storeName': storeName,
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      User user = userCredential.user!;
      await _saveUserData(
        user,
        _sellerNameController.text.trim(),
        _phoneNumberController.text.trim(),
        _storeNameController.text.trim(),
      );

      _snack('Registration successful');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'weak-password' => 'Password is too weak.',
        'email-already-in-use' =>
          'An account already exists for that email.',
        _ => 'An error occurred. Please try again.',
      };
      _snack(msg);
    } catch (_) {
      _snack('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/logos/logo-icon.svg',
                        height: 88,
                        semanticsLabel: 'Unshelf',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Create your account',
                      style: tt.headlineMedium?.copyWith(color: cs.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Turn your unsold stock into revenue.',
                      style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Full name
                    _FieldLabel('Full name', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _sellerNameController,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(hintText: 'e.g. Maria Santos'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email
                    _FieldLabel('Email', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(hintText: 'you@example.com'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Store name (seller delta — between Email and Phone)
                    _FieldLabel('Store name', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _storeNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          hintText: 'Your store or brand name'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Store name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Phone number
                    _FieldLabel('Phone number', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [
                        AutofillHints.telephoneNumberNational
                      ],
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(hintText: '09XX XXX XXXX'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 11) {
                          return 'Phone number must be at least 11 digits';
                        }
                        if (!digits.startsWith('09')) {
                          return 'Phone number must start with 09';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password
                    _FieldLabel('Password', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'At least 6 characters',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                          onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Confirm password
                    _FieldLabel('Confirm password', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_confirmPasswordVisible,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      decoration: InputDecoration(
                        hintText: 'Type it again',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                          onPressed: () => setState(() =>
                              _confirmPasswordVisible =
                                  !_confirmPasswordVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Primary CTA
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _register,
                        child: _submitting
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Text(
                                'Create account',
                                style: tt.labelLarge
                                    ?.copyWith(color: cs.onPrimary),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Terms
                    Text(
                      "By signing up, you agree to Unshelf's Terms and Privacy Policy.",
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Secondary action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already a member?',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (_) => const LoginView()),
                                  ),
                          child: Text(
                            'Sign in',
                            style:
                                tt.labelLarge?.copyWith(color: cs.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
      );
}
