import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/settings_viewmodel.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Settings',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: viewModel.settings.notificationsEnabled,
            onChanged: (bool value) {
              notifier.toggleNotifications(value);
            },
          ),
          ListTile(
            leading: Icon(Icons.help,
                color: Theme.of(context).colorScheme.onSurface),
            title: const Text('Help & Feedback'),
            onTap: () {
              // Navigate to Help & Feedback
            },
          ),
        ],
      ),
    );
  }
}
