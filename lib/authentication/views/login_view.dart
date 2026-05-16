import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:unshelf_seller/authentication/views/forgot_password_view.dart';
import 'package:unshelf_seller/authentication/views/register_view.dart';
import 'package:unshelf_seller/core/interfaces/i_user_profile_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';
import 'package:unshelf_seller/views/home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _submitting = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['GOOGLE_CLIENT_ID']!,
    scopes: <String>[
      'email',
      'profile',
    ],
  );

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;
      if (user == null) {
        await FirebaseAuth.instance.signOut();
        _snack('Sign in failed. Please try again.');
        return;
      }

      final passed = await _gateUser(user);
      if (!passed) return;

      _snack('Signed in');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'No user found for that email.',
        'wrong-password' => 'Wrong password.',
        'invalid-credential' => 'Email or password is incorrect.',
        _ => 'Sign in failed. Please try again.',
      };
      _snack(msg);
    } catch (_) {
      _snack('Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _submitting = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        await FirebaseAuth.instance.signOut();
        _snack('Google sign-in failed. Please try again.');
        return;
      }

      final passed = await _gateUser(user);
      if (!passed) return;

      _snack('Signed in');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    } catch (_) {
      _snack('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Returns true if the user passes all seller-side gates (account exists,
  /// not banned, approved, role is seller); otherwise signs the user out,
  /// shows the appropriate snack, and returns false.
  Future<bool> _gateUser(User user) async {
    final userDoc =
        await locator<IUserProfileService>().getUserDocument(user.uid);

    if (userDoc == null) {
      await FirebaseAuth.instance.signOut();
      _snack('Account not found. Check your email or sign up first.');
      return false;
    }

    final banned = userDoc['isBanned'] as bool? ?? false;
    if (banned) {
      await FirebaseAuth.instance.signOut();
      _snack('Your account is banned. Please contact support.');
      return false;
    }

    final isApproved = userDoc['isApproved'] as bool? ?? false;
    if (!isApproved) {
      await FirebaseAuth.instance.signOut();
      _snack(
          'Your account is pending approval. You will be notified once approved.');
      return false;
    }

    final role = userDoc['type'] as String? ?? '';
    if (role != 'seller') {
      await FirebaseAuth.instance.signOut();
      _snack('User has a different role');
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                        height: 112,
                        semanticsLabel: 'Unshelf',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome back',
                      style: tt.headlineMedium?.copyWith(color: cs.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Eat well. Waste less.',
                      style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
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
                    _FieldLabel('Password', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        hintText: 'Your password',
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
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Password is required' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordView(),
                                )),
                        child: Text(
                          'Forgot password?',
                          style: tt.labelLarge?.copyWith(color: cs.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _login,
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
                                'Sign in',
                                style: tt.labelLarge
                                    ?.copyWith(color: cs.onPrimary),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _loginWithGoogle,
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                        label: Text(
                          'Continue with Google',
                          style: tt.labelLarge?.copyWith(color: cs.onSurface),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New here?',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (_) => const RegisterView()),
                                  ),
                          child: Text(
                            'Create a seller account',
                            style: tt.labelLarge?.copyWith(color: cs.primary),
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
