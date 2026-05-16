import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/store_model.dart';

part 'store_schedule_viewmodel.g.dart';

/// Immutable state for the Edit Store Schedule screen.
///
/// `storeSchedule` is a nested map keyed by day-of-week — its inner maps
/// are mutated in-place by `selectTime`/`toggleDay` for parity with the
/// original ChangeNotifier, then a new state is emitted via `copyWith` to
/// trigger watchers.
class StoreScheduleState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, Map<String, dynamic>> storeSchedule;

  const StoreScheduleState({
    required this.isLoading,
    required this.errorMessage,
    required this.storeSchedule,
  });

  factory StoreScheduleState.initial() => const StoreScheduleState(
        isLoading: false,
        errorMessage: null,
        storeSchedule: <String, Map<String, dynamic>>{},
      );

  StoreScheduleState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Map<String, Map<String, dynamic>>? storeSchedule,
  }) {
    return StoreScheduleState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      storeSchedule: storeSchedule ?? this.storeSchedule,
    );
  }

  static const _sentinel = Object();
}

/// Store schedule ViewModel — backs the Edit Store Schedule screen. The view
/// calls [loadFromStore] in `initState` to seed the per-day schedule map from
/// the supplied `StoreModel` (mirrors original constructor-time init).
@riverpod
class StoreScheduleViewModel extends _$StoreScheduleViewModel {
  final DateFormat _timeFormatter = DateFormat('hh:mm a');

  @override
  StoreScheduleState build() => StoreScheduleState.initial();

  /// Seeds the schedule map from the supplied store model. Mirrors the
  /// original ChangeNotifier constructor: normalizes 'Closed' to '' and
  /// fills in missing `isOpen` flags before re-ordering by Mon..Sun.
  void loadFromStore(StoreModel storeDetails) {
    AppLogger.debug('Store schedule: ${storeDetails.storeSchedule}');

    for (var entry in storeDetails.storeSchedule!.entries) {
      AppLogger.debug('Day: ${entry.key}, Value: ${entry.value}');
    }

    storeDetails.storeSchedule?.forEach((key, value) {
      // Check if 'isOpen' doesn't exist or is null
      if (value['isOpen'] == null) {
        value['isOpen'] = false;
      }

      if (value['open'] == 'Closed') {
        value['open'] = '';
      }

      if (value['close'] == 'Closed') {
        value['close'] = '';
      }
    });

    const List<String> orderedDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final schedule = Map<String, Map<String, dynamic>>.fromEntries(
      orderedDays.map((day) {
        // Check if the storeSchedule has data for the day, otherwise default
        var entry = storeDetails.storeSchedule?[day] ??
            {'isOpen': false, 'open': '', 'close': ''};

        // Ensure 'isOpen' is a boolean and 'open' and 'close' are strings
        return MapEntry(
          day,
          {
            'isOpen': entry['isOpen'],
            'open': entry['open'],
            'close': entry['close'],
          },
        );
      }),
    );

    state = state.copyWith(storeSchedule: schedule);
  }

  Future<void> selectTime(String day, String type, TimeOfDay pickedTime) async {
    final timeString = _timeFormatter.format(
      DateTime(2023, 1, 1, pickedTime.hour, pickedTime.minute),
    );
    // Preserve in-place mutation, then emit new state to trigger watchers.
    state.storeSchedule[day]![type] = timeString;
    state = state.copyWith(storeSchedule: state.storeSchedule);
  }

  Future<void> toggleDay(String day) async {
    state.storeSchedule[day]!['isOpen'] =
        !(state.storeSchedule[day]!['isOpen']);
    state = state.copyWith(storeSchedule: state.storeSchedule);
  }

  Future<bool> saveProfile(BuildContext context, String userId) async {
    // Perform validation
    if (!_validateSchedule()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please set valid opening and closing times for active days.')),
      );
      return false;
    }

    AppLogger.debug('Passed validation');

    try {
      await ref
          .read(storeServiceProvider)
          .saveStoreSchedule(userId, state.storeSchedule);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }

    return true;
  }

  /// Validation Method
  bool _validateSchedule() {
    for (var entry in state.storeSchedule.entries) {
      final isOpen = entry.value['isOpen'];
      final openTime = entry.value['open']?.trim();
      final closeTime = entry.value['close']?.trim();

      if (isOpen) {
        // Ensure both times are set for open days
        if (openTime == null ||
            openTime == '' ||
            closeTime == null ||
            closeTime == '') {
          return false;
        }
      }
    }
    return true;
  }
}
