import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/authentication/views/login_view.dart';
import 'package:unshelf_seller/components/settings_tile.dart';
import 'package:unshelf_seller/viewmodels/settings_viewmodel.dart';
import 'package:unshelf_seller/views/report_view.dart';

/// Seller settings screen.
///
/// Layout: inline AppBar with back action → grouped settings tiles
/// (Account / Notifications / Support) wrapped in Quality-Bar cards, with a
/// destructive `OutlinedButton` "Sign out" at the bottom.
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _emailNotifications = true;
  bool _signingOut = false;

  void _push(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _comingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon.')),
    );
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign out failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final viewModel = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            const _SectionLabel('Account'),
            const SizedBox(height: 12),
            _SettingsCard(
              tiles: [
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit profile',
                  subtitle: 'Update your name, email, and phone',
                  onTap: () => _comingSoon('Profile editing'),
                ),
                SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change password',
                  subtitle: 'Set a new password for your account',
                  onTap: () => _comingSoon('Password change'),
                ),
                SettingsTile(
                  icon: Icons.payments_outlined,
                  title: 'Manage payment',
                  subtitle: 'Payouts and linked accounts',
                  onTap: () => _comingSoon('Payment management'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const _SectionLabel('Notifications'),
            const SizedBox(height: 12),
            _SettingsCard(
              tiles: [
                SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Push notifications',
                  subtitle: 'Order, chat, and account alerts',
                  trailing: Switch.adaptive(
                    value: viewModel.settings.notificationsEnabled,
                    onChanged: notifier.toggleNotifications,
                  ),
                ),
                SettingsTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email notifications',
                  subtitle: 'Receipts, summaries, and updates',
                  trailing: Switch.adaptive(
                    value: _emailNotifications,
                    onChanged: (v) => setState(() => _emailNotifications = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const _SectionLabel('Support'),
            const SizedBox(height: 12),
            _SettingsCard(
              tiles: [
                SettingsTile(
                  icon: Icons.flag_outlined,
                  title: 'Report a problem',
                  subtitle: 'Flag a bug, listing, or buyer issue',
                  onTap: () => _push(const ReportFormView()),
                ),
                SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & FAQ',
                  subtitle: 'Find answers to common questions',
                  onTap: () => _comingSoon('Help & FAQ'),
                ),
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  subtitle: 'Version info and credits',
                  onTap: () => _comingSoon('About'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _signingOut ? null : _signOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                ),
                icon: _signingOut
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: cs.error,
                        ),
                      )
                    : const Icon(Icons.logout_rounded, size: 20),
                label: Text(
                  'Sign out',
                  style: tt.labelLarge?.copyWith(color: cs.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Section label — small uppercase eyebrow above each settings group
// ────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: cs.onSurface.withValues(alpha: 0.55),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Settings card — Quality-Bar-shadowed surface that hosts a list of
// [SettingsTile] rows, separated by light dividers.
// ────────────────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF1F2A20).withValues(alpha: .06),
            offset: const Offset(0, 8),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              tiles[i],
              if (i < tiles.length - 1)
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: cs.onSurface.withValues(alpha: 0.06),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
