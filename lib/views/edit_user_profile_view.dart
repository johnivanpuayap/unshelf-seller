import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/components/field_label.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/models/user_model.dart';
import 'package:unshelf_seller/viewmodels/user_profile_viewmodel.dart';

/// Edit User Profile screen.
///
/// Quality-Bar form shell (maxWidth 420). Visual-only circular avatar with a
/// camera badge sits at the top — the underlying user model has no
/// `avatarUrl` field yet, so tapping the badge surfaces a "coming soon"
/// snackbar until the avatar pipeline exists.
///
/// Fields: Name, Email (read-only), Phone, plus optional password change rows.
/// The bottom 52px pill saves via the viewmodel and pops with the latest
/// `userProfile`.
class EditUserProfileView extends ConsumerStatefulWidget {
  final UserProfileModel userProfile;

  const EditUserProfileView({super.key, required this.userProfile});

  @override
  ConsumerState<EditUserProfileView> createState() =>
      _EditUserProfileViewState();
}

class _EditUserProfileViewState extends ConsumerState<EditUserProfileView> {
  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _changePasswordExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(userProfileViewModelProvider.notifier)
          .initializeControllers(widget.userProfile);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(userProfileViewModelProvider.notifier);
    await notifier.updateUserProfile();

    final updatedState = ref.read(userProfileViewModelProvider);
    if (!mounted) return;

    if (updatedState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(updatedState.errorMessage!)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );

    AppLogger.debug('Passing ${updatedState.userProfile}');
    Navigator.pop(context, updatedState.userProfile);
  }

  void _onAvatarTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo upload is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProfileViewModelProvider);
    final notifier = ref.read(userProfileViewModelProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final saving = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit profile',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AvatarEditor(
                      name: widget.userProfile.name,
                      onTap: saving ? () {} : _onAvatarTap,
                    ),
                    const SizedBox(height: 32),
                    FieldLabel('Name', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Maria Santos',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    FieldLabel('Email', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.emailController,
                      readOnly: true,
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'you@example.com',
                        suffixIcon: Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email is tied to your account and cannot be changed here.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FieldLabel('Phone number', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.telephoneNumberNational
                      ],
                      decoration:
                          const InputDecoration(hintText: '09XX XXX XXXX'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 10) {
                          return 'Phone number is too short';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    _ChangePasswordSection(
                      expanded: _changePasswordExpanded,
                      passwordController: notifier.passwordController,
                      confirmPasswordController:
                          notifier.confirmPasswordController,
                      passwordVisible: _passwordVisible,
                      confirmPasswordVisible: _confirmPasswordVisible,
                      onToggleExpanded: () => setState(() {
                        _changePasswordExpanded = !_changePasswordExpanded;
                        if (!_changePasswordExpanded) {
                          notifier.passwordController.clear();
                          notifier.confirmPasswordController.clear();
                        }
                      }),
                      onTogglePasswordVisible: () => setState(
                          () => _passwordVisible = !_passwordVisible),
                      onToggleConfirmPasswordVisible: () => setState(() =>
                          _confirmPasswordVisible = !_confirmPasswordVisible),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: saving ? null : _save,
                        child: saving
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Text(
                                'Save changes',
                                style: tt.labelLarge
                                    ?.copyWith(color: cs.onPrimary),
                              ),
                      ),
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

// ────────────────────────────────────────────────────────────────────────────
// Avatar editor — circular avatar with initials + camera badge overlay
// ────────────────────────────────────────────────────────────────────────────

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.characters.firstOrNull ?? '';
    final last = parts.length > 1
        ? (parts.last.characters.firstOrNull ?? '')
        : '';
    return ('$first$last').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final initials = _initials(name);

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1F2A20).withValues(alpha: .10),
                        offset: const Offset(0, 8),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: cs.surfaceContainerHighest,
                    child: initials.isNotEmpty
                        ? Text(
                            initials,
                            style: tt.headlineSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : Icon(
                            Icons.person_outline_rounded,
                            size: 40,
                            color: cs.primary,
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                      border: Border.all(color: cs.surface, width: 3),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: cs.onPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to change photo',
            style: tt.labelMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Change-password section — collapsed by default. Expands into matched
// password + confirm fields; values are routed through the viewmodel's
// controllers, which already drive the FirebaseAuth password update.
// ────────────────────────────────────────────────────────────────────────────

class _ChangePasswordSection extends StatelessWidget {
  const _ChangePasswordSection({
    required this.expanded,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.onToggleExpanded,
    required this.onTogglePasswordVisible,
    required this.onToggleConfirmPasswordVisible,
  });

  final bool expanded;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool passwordVisible;
  final bool confirmPasswordVisible;
  final VoidCallback onToggleExpanded;
  final VoidCallback onTogglePasswordVisible;
  final VoidCallback onToggleConfirmPasswordVisible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggleExpanded,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Change password',
                    style: tt.labelLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 16),
          FieldLabel('New password', color: cs.onSurface),
          const SizedBox(height: 8),
          TextFormField(
            controller: passwordController,
            obscureText: !passwordVisible,
            autocorrect: false,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'At least 6 characters',
              suffixIcon: IconButton(
                icon: Icon(
                  passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
                onPressed: onTogglePasswordVisible,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              if (v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          FieldLabel('Confirm password', color: cs.onSurface),
          const SizedBox(height: 8),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: !confirmPasswordVisible,
            autocorrect: false,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Type it again',
              suffixIcon: IconButton(
                icon: Icon(
                  confirmPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
                onPressed: onToggleConfirmPasswordVisible,
              ),
            ),
            validator: (v) {
              if (passwordController.text.isEmpty) return null;
              if (v == null || v.isEmpty) {
                return 'Please confirm your password';
              }
              if (v != passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Field label — Phase 1 Quality Bar form pattern
// ────────────────────────────────────────────────────────────────────────────

