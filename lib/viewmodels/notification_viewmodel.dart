import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/notification_model.dart';

part 'notification_viewmodel.g.dart';

/// Immutable state for the Notifications screen.
///
/// NOTE: `NotificationModel.seen` is mutated in-place by
/// `markNotificationAsReadAsync` (preserved from the original ChangeNotifier);
/// the surrounding list reference stays the same.
class NotificationState {
  final bool isLoading;
  final String? errorMessage;
  final List<NotificationModel> notifications;
  final int unseenCount;

  const NotificationState({
    required this.isLoading,
    required this.errorMessage,
    required this.notifications,
    required this.unseenCount,
  });

  factory NotificationState.initial() => const NotificationState(
        isLoading: false,
        errorMessage: null,
        notifications: <NotificationModel>[],
        unseenCount: 0,
      );

  NotificationState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<NotificationModel>? notifications,
    int? unseenCount,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      notifications: notifications ?? this.notifications,
      unseenCount: unseenCount ?? this.unseenCount,
    );
  }

  static const _sentinel = Object();
}

/// Notification ViewModel — backs the Notifications screen.
///
/// PRESERVED BUG: `markNotificationAsReadAsync` in the original ChangeNotifier
/// never called `notifyListeners()` after mutating `seen` and decrementing
/// `_unseenCount`, so the UI didn't refresh until the next fetch. We keep
/// that behaviour here (no state emission after marking), to be fixed in a
/// later bug-fix ticket.
@Riverpod(keepAlive: true)
class NotificationViewModel extends _$NotificationViewModel {
  @override
  NotificationState build() => NotificationState.initial();

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final notifications =
          await ref.read(notificationServiceProvider).fetchNotifications();

      AppLogger.debug('Notifications fetched: ${notifications.length}');

      state = state.copyWith(
        isLoading: false,
        notifications: notifications,
        unseenCount: notifications.where((n) => !n.seen).length,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error in NotificationViewModel.fetchNotifications: $e',
          e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void markNotificationAsReadAsync(int index) async {
    final notificationId = state.notifications[index].id;

    try {
      await ref.read(notificationServiceProvider).markAsRead(notificationId);

      // Preserve in-place mutation of the seen flag (the original
      // ChangeNotifier did the same and also forgot to notify listeners).
      state.notifications[index].seen = true;
    } catch (e) {
      AppLogger.error('Error updating notification: $e');
    }
  }
}
