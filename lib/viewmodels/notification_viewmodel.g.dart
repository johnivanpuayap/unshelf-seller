// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationViewModelHash() =>
    r'780117d398c5c5215f99f5615f1fe133f43a2a4e';

/// Notification ViewModel — backs the Notifications screen.
///
/// PRESERVED BUG: `markNotificationAsReadAsync` in the original ChangeNotifier
/// never called `notifyListeners()` after mutating `seen` and decrementing
/// `_unseenCount`, so the UI didn't refresh until the next fetch. We keep
/// that behaviour here (no state emission after marking), to be fixed in a
/// later bug-fix ticket.
///
/// Copied from [NotificationViewModel].
@ProviderFor(NotificationViewModel)
final notificationViewModelProvider =
    NotifierProvider<NotificationViewModel, NotificationState>.internal(
  NotificationViewModel.new,
  name: r'notificationViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationViewModel = Notifier<NotificationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
