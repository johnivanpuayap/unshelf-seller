import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/viewmodels/notification_viewmodel.dart';
import 'package:unshelf_seller/utils/colors.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Notifications',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: Consumer<NotificationViewModel>(
        builder: (context, model, child) {
          return model.notifications.isNotEmpty
              ? ListView.separated(
                  itemCount: model.notifications.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final notification = model.notifications[index];
                    return ListTile(
                      leading: Icon(
                        notification.seen
                            ? Icons.check_circle
                            : Icons.notifications,
                        color: notification.seen
                            ? AppColors.primaryColor
                            : AppColors.darkColor,
                      ),
                      title: Text(
                        notification.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: notification.seen
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        notification.text,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: notification.seen
                              ? AppColors.textHint
                              : AppColors.textSecondary,
                        ),
                      ),
                      onTap: () {
                        model.markNotificationAsReadAsync(index);
                        Navigator.pop(context);
                      },
                    );
                  },
                )
              : const EmptyState(
                  icon: Icons.notifications_off_outlined,
                  title: 'No notifications',
                  subtitle: 'You are all caught up!',
                );
        },
      ),
    );
  }
}
