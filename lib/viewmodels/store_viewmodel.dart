import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/store_model.dart';
import 'package:unshelf_seller/models/user_model.dart';

part 'store_viewmodel.g.dart';

/// Immutable state for the Store screen.
///
/// NOTE: `storeDetails` (a `StoreModel`) is a mutable model — `EditStoreLocationView`
/// reaches in and assigns `storeLatitude`/`storeLongitude` directly. Preserve that
/// in-place mutation pattern; we just emit `state = state.copyWith(...)` to trigger
/// watchers when fetching fresh values from the service.
class StoreState {
  final bool isLoading;
  final String? errorMessage;
  final StoreModel? storeDetails;
  final UserProfileModel? userProfile;

  const StoreState({
    required this.isLoading,
    required this.errorMessage,
    required this.storeDetails,
    required this.userProfile,
  });

  factory StoreState.initial() => const StoreState(
        isLoading: false,
        errorMessage: null,
        storeDetails: null,
        userProfile: null,
      );

  StoreState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? storeDetails = _sentinel,
    Object? userProfile = _sentinel,
  }) {
    return StoreState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      storeDetails: identical(storeDetails, _sentinel)
          ? this.storeDetails
          : storeDetails as StoreModel?,
      userProfile: identical(userProfile, _sentinel)
          ? this.userProfile
          : userProfile as UserProfileModel?,
    );
  }

  static const _sentinel = Object();
}

/// Store ViewModel — backs the store profile screen and supplies header data
/// to the dashboard.
@Riverpod(keepAlive: true)
class StoreViewModel extends _$StoreViewModel {
  @override
  StoreState build() => StoreState.initial();

  Future<void> fetchUserProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await ref.read(storeServiceProvider).fetchUserProfile();
      if (profile == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User profile not found',
        );
      } else {
        state = state.copyWith(isLoading: false, userProfile: profile);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error in StoreViewModel.fetchUserProfile: $e',
          e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchStoreDetails() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final store = await ref.read(storeServiceProvider).fetchStoreDetails();
      if (store == null) {
        AppLogger.warning('User profile or store not found');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User profile or store not found',
        );
      } else {
        AppLogger.debug('Getting Store Details Here');
        state = state.copyWith(isLoading: false, storeDetails: store);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error in StoreViewModel.fetchStoreDetails: $e',
          e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<int> fetchStoreFollowers() async {
    try {
      return await ref.read(storeServiceProvider).fetchStoreFollowers();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error fetching store followers');
      return 0;
    }
  }

  Future<double> fetchStoreRatings() async {
    try {
      return await ref.read(storeServiceProvider).fetchStoreRatings();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error fetching store ratings');
      return 0.0;
    }
  }

  String formatStoreSchedule(Map<String, Map<String, String>> schedule) {
    const List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return daysOfWeek.map((day) {
      Map<String, String> times =
          schedule[day] ?? {'open': 'Closed', 'close': 'Closed'};
      String open = times['open'] ?? 'Closed';
      String close = times['close'] ?? 'Closed';
      return open == 'Closed' && close == 'Closed'
          ? '$day: Closed'
          : '$day: $open - $close';
    }).join('\n');
  }

  void clear() {
    state = state.copyWith(storeDetails: null, errorMessage: null);
  }
}
