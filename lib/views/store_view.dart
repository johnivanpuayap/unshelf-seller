import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ViewModels
import 'package:unshelf_seller/viewmodels/store_viewmodel.dart';

// Views
import 'package:unshelf_seller/views/balance_overview_view.dart';
import 'package:unshelf_seller/views/edit_store_schedule_view.dart';
import 'package:unshelf_seller/views/edit_store_location_view.dart';
import 'package:unshelf_seller/views/edit_store_profile_view.dart';
import 'package:unshelf_seller/authentication/views/login_view.dart';
import 'package:unshelf_seller/views/order_history_view.dart';
import 'package:unshelf_seller/views/product_analytics_view.dart';
import 'package:unshelf_seller/views/settings_view.dart';
import 'package:unshelf_seller/views/edit_user_profile_view.dart';
import 'package:unshelf_seller/views/store_analytics_view.dart';
import 'package:unshelf_seller/views/inventory_view.dart';
import 'package:unshelf_seller/views/report_view.dart';

// Components
import 'package:unshelf_seller/components/section_header.dart';

// Utils
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

class StoreView extends StatefulWidget {
  const StoreView({super.key});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<StoreViewModel>(context, listen: false);
      viewModel.fetchStoreDetails();
      viewModel.fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<StoreViewModel>(context);

    if (viewModel.isLoading ||
        viewModel.storeDetails == null ||
        viewModel.userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Header
            _buildStoreHeader(context, viewModel),

            const Divider(),

            // Store Management Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTheme.spacing8),
                  const SectionHeader(title: 'Store Management'),
                  _buildManagementCard(context, viewModel),

                  const SizedBox(height: AppTheme.spacing24),

                  // Account Section
                  const SectionHeader(title: 'Account'),
                  _buildAccountCard(context, viewModel),

                  const SizedBox(height: AppTheme.spacing32),

                  // Logout Button
                  _buildLogoutButton(context),

                  const SizedBox(height: AppTheme.spacing32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader(BuildContext context, StoreViewModel viewModel) {
    final theme = Theme.of(context);
    final store = viewModel.storeDetails!;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Store Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.lightColor,
                backgroundImage:
                    (store.storeImageUrl != null && store.storeImageUrl!.isNotEmpty)
                        ? NetworkImage(store.storeImageUrl!)
                        : null,
                child:
                    (store.storeImageUrl == null || store.storeImageUrl!.isEmpty)
                        ? Icon(
                            Icons.store,
                            size: 32,
                            color: theme.colorScheme.primary,
                          )
                        : null,
              ),

              const SizedBox(width: AppTheme.spacing16),

              // Store Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.storeName.isNotEmpty ? store.storeName : 'My Store',
                      style: theme.textTheme.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppTheme.spacing4),
                        Text(
                          store.storeRating?.toStringAsFixed(1) ?? '0.0',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Text(
                          '\u2022',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Text(
                          '${store.storeFollowers ?? 0} followers',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () => _navigateTo(
                EditStoreProfileView(storeDetails: viewModel.storeDetails!),
              ),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(BuildContext context, StoreViewModel viewModel) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuTile(
            context,
            icon: Icons.analytics_outlined,
            iconColor: AppColors.info,
            title: 'Store Analytics',
            onTap: () => _navigateTo(const StoreAnalyticsView()),
          ),
          Divider(height: 1, indent: AppTheme.spacing16, endIndent: AppTheme.spacing16, color: theme.dividerColor),
          _buildMenuTile(
            context,
            icon: Icons.bar_chart_outlined,
            iconColor: AppColors.success,
            title: 'Product Analytics',
            onTap: () => _navigateTo(const ProductAnalyticsView()),
          ),
          Divider(height: 1, indent: AppTheme.spacing16, endIndent: AppTheme.spacing16, color: theme.dividerColor),
          _buildMenuTile(
            context,
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.statusPendingText,
            title: 'Order History',
            onTap: () => _navigateTo(const OrderHistoryView()),
          ),
          Divider(height: 1, indent: AppTheme.spacing16, endIndent: AppTheme.spacing16, color: theme.dividerColor),
          _buildMenuTile(
            context,
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.darkColor,
            title: 'Store Inventory',
            onTap: () => _navigateTo(InventoryView()),
          ),
          Divider(height: 1, indent: AppTheme.spacing16, endIndent: AppTheme.spacing16, color: theme.dividerColor),
          _buildMenuTile(
            context,
            icon: Icons.access_time_outlined,
            iconColor: AppColors.warning,
            title: 'Business Hours',
            onTap: () => _navigateTo(
              EditStoreScheduleView(storeDetails: viewModel.storeDetails!),
            ),
          ),
          Divider(height: 1, indent: AppTheme.spacing16, endIndent: AppTheme.spacing16, color: theme.dividerColor),
          _buildMenuTile(
            context,
            icon: Icons.location_on_outlined,
            iconColor: AppColors.error,
            title: 'Store Location',
            onTap: () => _navigateTo(
              EditStoreLocationView(storeDetails: viewModel.storeDetails!),
            ),
          ),
          Divider(height: 1, indent: AppTheme.spacing16, endIndent: AppTheme.spacing16, color: theme.dividerColor),
          _buildMenuTile(
            context,
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.primaryColor,
            title: 'Wallet',
            onTap: () => _navigateTo(const BalanceOverviewView()),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, StoreViewModel viewModel) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuTile(
            context,
            icon: Icons.person_outlined,
            iconColor: AppColors.info,
            title: 'Edit Profile',
            onTap: () => _navigateTo(
              EditUserProfileView(userProfile: viewModel.userProfile!),
            ),
          ),
          Divider(height: 1, indent: AppTheme.spacing16, endIndent: AppTheme.spacing16, color: theme.dividerColor),
          _buildMenuTile(
            context,
            icon: Icons.settings_outlined,
            iconColor: AppColors.textSecondary,
            title: 'Settings',
            onTap: () => _navigateTo(const SettingsView()),
          ),
          Divider(height: 1, indent: AppTheme.spacing16, endIndent: AppTheme.spacing16, color: theme.dividerColor),
          _buildMenuTile(
            context,
            icon: Icons.flag_outlined,
            iconColor: AppColors.warning,
            title: 'Report Issue',
            onTap: () => _navigateTo(ReportFormView()),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textHint,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: OutlinedButton.icon(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            _navigateTo(const LoginView(), clearStack: true);
          }
        },
        icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
        label: Text(
          'Log Out',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
          minimumSize: const Size(200, AppTheme.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing24,
            vertical: AppTheme.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
        ),
      ),
    );
  }

  void _navigateTo(Widget page, {bool clearStack = false}) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => page),
      (route) => !clearStack,
    );
  }
}
