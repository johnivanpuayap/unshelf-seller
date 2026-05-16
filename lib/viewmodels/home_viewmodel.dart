import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/notification_model.dart';

part 'home_viewmodel.g.dart';

/// Immutable state for the home shell (notification bell badge).
class HomeState {
  final bool isLoading;
  final String? errorMessage;
  final List<NotificationModel> notifications;
  final int unseenCount;

  const HomeState({
    required this.isLoading,
    required this.errorMessage,
    required this.notifications,
    required this.unseenCount,
  });

  factory HomeState.initial() => const HomeState(
        isLoading: false,
        errorMessage: null,
        notifications: <NotificationModel>[],
        unseenCount: 0,
      );

  HomeState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<NotificationModel>? notifications,
    int? unseenCount,
  }) {
    return HomeState(
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

/// Home shell ViewModel — fetches the seller's notifications to drive the
/// notification bell badge.
@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  HomeState build() => HomeState.initial();

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final notifications =
          await ref.read(notificationServiceProvider).fetchNotifications();
      final unseenCount = notifications.where((n) => !n.seen).length;

      state = state.copyWith(
        isLoading: false,
        notifications: notifications,
        unseenCount: unseenCount,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error in HomeViewModel: $e', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
