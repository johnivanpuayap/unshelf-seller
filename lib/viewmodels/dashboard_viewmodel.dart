import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/notification_model.dart';

part 'dashboard_viewmodel.g.dart';

/// Immutable state for the dashboard screen.
///
/// All fields are copied through [copyWith]; mutate via the
/// [DashboardViewModel] notifier, never directly.
class DashboardState {
  final bool isLoading;
  final String? errorMessage;
  final DateTime today;
  final String monthYear;
  final int pendingOrders;
  final int processedOrders;
  final int completedOrders;
  final int totalOrders;
  final double totalSales;
  final int totalStockRemaining;
  final List<NotificationModel>? notifications;
  final int? unseenCount;

  const DashboardState({
    required this.isLoading,
    required this.errorMessage,
    required this.today,
    required this.monthYear,
    required this.pendingOrders,
    required this.processedOrders,
    required this.completedOrders,
    required this.totalOrders,
    required this.totalSales,
    required this.totalStockRemaining,
    required this.notifications,
    required this.unseenCount,
  });

  factory DashboardState.initial() {
    final now = DateTime.now();
    return DashboardState(
      isLoading: false,
      errorMessage: null,
      today: now,
      monthYear: DateFormat('MMMM yyyy').format(now),
      pendingOrders: 0,
      processedOrders: 0,
      completedOrders: 0,
      totalOrders: 0,
      totalSales: 0.0,
      totalStockRemaining: 40,
      notifications: null,
      unseenCount: 0,
    );
  }

  DashboardState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    DateTime? today,
    String? monthYear,
    int? pendingOrders,
    int? processedOrders,
    int? completedOrders,
    int? totalOrders,
    double? totalSales,
    int? totalStockRemaining,
    Object? notifications = _sentinel,
    Object? unseenCount = _sentinel,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      today: today ?? this.today,
      monthYear: monthYear ?? this.monthYear,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      processedOrders: processedOrders ?? this.processedOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSales: totalSales ?? this.totalSales,
      totalStockRemaining: totalStockRemaining ?? this.totalStockRemaining,
      notifications: identical(notifications, _sentinel)
          ? this.notifications
          : notifications as List<NotificationModel>?,
      unseenCount: identical(unseenCount, _sentinel)
          ? this.unseenCount
          : unseenCount as int?,
    );
  }

  static const _sentinel = Object();
}

/// Dashboard ViewModel — fetches today's order counts and monthly earnings.
///
/// Riverpod-managed; consumers read state via `ref.watch(dashboardViewModelProvider)`
/// and trigger actions via `ref.read(dashboardViewModelProvider.notifier).fetchDashboardData()`.
@riverpod
class DashboardViewModel extends _$DashboardViewModel {
  @override
  DashboardState build() => DashboardState.initial();

  Future<void> fetchDashboardData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final analyticsService = ref.read(analyticsServiceProvider);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final endOfDay = todayStart.add(const Duration(days: 1));

      final orderDocs = await analyticsService.fetchOrders(since: todayStart);

      // Filter to today only (service returns >= todayStart, trim >= endOfDay)
      final todayOrders = orderDocs.where((doc) {
        final createdAt = doc['createdAt'];
        if (createdAt == null) return true;
        final date = (createdAt as Timestamp).toDate();
        return date.isBefore(endOfDay);
      }).toList();

      final pendingOrders = todayOrders
          .where((doc) => doc['status'] == StatusConstants.pending)
          .length;
      final processedOrders = todayOrders
          .where((doc) => doc['status'] == StatusConstants.ready)
          .length;
      final completedOrders = todayOrders
          .where((doc) => doc['status'] == StatusConstants.completed)
          .length;
      final totalOrders = todayOrders.length;

      final startOfMonth = DateTime(now.year, now.month);
      final transDocs =
          await analyticsService.fetchTransactions(since: startOfMonth);

      double totalEarnings = 0.0;
      for (var trans in transDocs) {
        if (trans['type'] == StatusConstants.sale) {
          final amount = (trans['sellerEarnings'] as num).toDouble();
          totalEarnings += amount;
        }
      }

      state = state.copyWith(
        isLoading: false,
        pendingOrders: pendingOrders,
        processedOrders: processedOrders,
        completedOrders: completedOrders,
        totalOrders: totalOrders,
        totalSales: totalEarnings,
        today: now,
        monthYear: DateFormat('MMMM yyyy').format(now),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error in DashboardViewModel: $e', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
