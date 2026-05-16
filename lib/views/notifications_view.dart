import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/models/notification_model.dart';
import 'package:unshelf_seller/viewmodels/notification_viewmodel.dart';

/// Notifications screen.
///
/// Time-grouped sections (Today / This week / Earlier) per the buyer +
/// seller spec. Each notification is a card on the honey-paper raised
/// surface; unread items show a primary-tinted dot.
class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});

  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationViewModelProvider.notifier).fetchNotifications();
    });
  }

  Future<void> _refresh() =>
      ref.read(notificationViewModelProvider.notifier).fetchNotifications();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(notificationViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(color: cs.onSurface),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _NotificationsBody(state: state, onRefresh: _refresh),
    );
  }
}

class _NotificationsBody extends ConsumerWidget {
  const _NotificationsBody({required this.state, required this.onRefresh});

  final NotificationState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.notifications.isEmpty) {
      return _NotificationsError(
        message: state.errorMessage!,
        onRetry: onRefresh,
      );
    }

    if (state.notifications.isEmpty) {
      return SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            EmptyState(
              icon: Icons.notifications_none_outlined,
              title: "You're all caught up",
              subtitle: "You'll see new alerts here as they come in.",
            ),
          ],
        ),
      );
    }

    final groups = _groupByTime(state.notifications);

    return SafeArea(
      child: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: onRefresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          itemCount: groups.length,
          itemBuilder: (context, i) {
            final group = groups[i];
            return _TimeGroup(
              label: group.label,
              entries: group.entries,
              isFirst: i == 0,
            );
          },
        ),
      ),
    );
  }
}

class _TimeGroup extends ConsumerWidget {
  const _TimeGroup({
    required this.label,
    required this.entries,
    required this.isFirst,
  });

  final String label;
  final List<_IndexedNotification> entries;
  final bool isFirst;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 16),
          for (final entry in entries) ...[
            _NotificationCard(
              notification: entry.notification,
              onTap: () async {
                if (!entry.notification.seen) {
                  ref
                      .read(notificationViewModelProvider.notifier)
                      .markNotificationAsReadAsync(entry.index);
                }
                // Preserve existing behaviour: popping back to the parent so
                // the bell badge state can reconcile on next fetch.
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
            if (entry != entries.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final timeLabel = notification.createdAt != null
        ? _shortTime(notification.createdAt!)
        : null;

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
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UnreadDot(seen: notification.seen, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title.isEmpty
                                  ? 'Notification'
                                  : notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeLabel != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              timeLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (notification.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.75),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.seen, required this.color});

  final bool seen;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 22,
      child: seen
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
    );
  }
}

class _NotificationsError extends StatelessWidget {
  const _NotificationsError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: cs.error.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              "Couldn't load notifications",
              style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => onRetry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────

class _IndexedNotification {
  const _IndexedNotification({required this.index, required this.notification});
  final int index;
  final NotificationModel notification;
}

class _NotificationGroup {
  const _NotificationGroup({required this.label, required this.entries});
  final String label;
  final List<_IndexedNotification> entries;
}

List<_NotificationGroup> _groupByTime(List<NotificationModel> notifications) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekAgo = today.subtract(const Duration(days: 7));

  final todayItems = <_IndexedNotification>[];
  final weekItems = <_IndexedNotification>[];
  final earlierItems = <_IndexedNotification>[];
  final undatedItems = <_IndexedNotification>[];

  for (var i = 0; i < notifications.length; i++) {
    final n = notifications[i];
    final entry = _IndexedNotification(index: i, notification: n);
    final created = n.createdAt;
    if (created == null) {
      undatedItems.add(entry);
    } else if (!created.isBefore(today)) {
      todayItems.add(entry);
    } else if (!created.isBefore(weekAgo)) {
      weekItems.add(entry);
    } else {
      earlierItems.add(entry);
    }
  }

  final groups = <_NotificationGroup>[];
  if (todayItems.isNotEmpty) {
    groups.add(_NotificationGroup(label: 'Today', entries: todayItems));
  }
  if (weekItems.isNotEmpty) {
    groups.add(_NotificationGroup(label: 'This week', entries: weekItems));
  }
  if (earlierItems.isNotEmpty) {
    groups.add(_NotificationGroup(label: 'Earlier', entries: earlierItems));
  }
  if (undatedItems.isNotEmpty) {
    groups.add(_NotificationGroup(label: 'Earlier', entries: undatedItems));
  }
  return groups;
}

String _shortTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('MMM d').format(time);
}
