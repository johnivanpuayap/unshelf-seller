import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/core/providers/services.dart';

part 'analytics_viewmodel.g.dart';

/// Immutable state for the store analytics screen.
///
/// The maps are emitted by-value via `copyWith` after batch population; the
/// internal helpers mutate locally-scoped maps before assigning the final
/// state object.
class AnalyticsState {
  final bool isLoading;
  final String? errorMessage;

  final int totalOrders;
  final double totalSales;
  final int totalCompletedOrders;
  final int totalReadyOrders;
  final int totalPendingOrders;

  final Map<DateTime, int> dailyOrdersMap;
  final Map<DateTime, int> weeklyOrdersMap;
  final Map<DateTime, int> monthlyOrdersMap;
  final Map<DateTime, int> annualOrdersMap;

  final double dailyMaxYOrder;
  final double weeklyMaxYOrder;
  final double monthlyMaxYOrder;
  final double annualMaxYOrder;

  final Map<DateTime, double> dailySalesMap;
  final Map<DateTime, double> weeklySalesMap;
  final Map<DateTime, double> monthlySalesMap;
  final Map<DateTime, double> annualSalesMap;

  final double dailyMaxYSales;
  final double weeklyMaxYSales;
  final double monthlyMaxYSales;
  final double annualMaxYSales;

  const AnalyticsState({
    required this.isLoading,
    required this.errorMessage,
    required this.totalOrders,
    required this.totalSales,
    required this.totalCompletedOrders,
    required this.totalReadyOrders,
    required this.totalPendingOrders,
    required this.dailyOrdersMap,
    required this.weeklyOrdersMap,
    required this.monthlyOrdersMap,
    required this.annualOrdersMap,
    required this.dailyMaxYOrder,
    required this.weeklyMaxYOrder,
    required this.monthlyMaxYOrder,
    required this.annualMaxYOrder,
    required this.dailySalesMap,
    required this.weeklySalesMap,
    required this.monthlySalesMap,
    required this.annualSalesMap,
    required this.dailyMaxYSales,
    required this.weeklyMaxYSales,
    required this.monthlyMaxYSales,
    required this.annualMaxYSales,
  });

  factory AnalyticsState.initial() => const AnalyticsState(
        isLoading: false,
        errorMessage: null,
        totalOrders: 0,
        totalSales: 0.0,
        totalCompletedOrders: 0,
        totalReadyOrders: 0,
        totalPendingOrders: 0,
        dailyOrdersMap: <DateTime, int>{},
        weeklyOrdersMap: <DateTime, int>{},
        monthlyOrdersMap: <DateTime, int>{},
        annualOrdersMap: <DateTime, int>{},
        dailyMaxYOrder: 0.0,
        weeklyMaxYOrder: 0.0,
        monthlyMaxYOrder: 0.0,
        annualMaxYOrder: 0.0,
        dailySalesMap: <DateTime, double>{},
        weeklySalesMap: <DateTime, double>{},
        monthlySalesMap: <DateTime, double>{},
        annualSalesMap: <DateTime, double>{},
        dailyMaxYSales: 0.0,
        weeklyMaxYSales: 0.0,
        monthlyMaxYSales: 0.0,
        annualMaxYSales: 0.0,
      );

  AnalyticsState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    int? totalOrders,
    double? totalSales,
    int? totalCompletedOrders,
    int? totalReadyOrders,
    int? totalPendingOrders,
    Map<DateTime, int>? dailyOrdersMap,
    Map<DateTime, int>? weeklyOrdersMap,
    Map<DateTime, int>? monthlyOrdersMap,
    Map<DateTime, int>? annualOrdersMap,
    double? dailyMaxYOrder,
    double? weeklyMaxYOrder,
    double? monthlyMaxYOrder,
    double? annualMaxYOrder,
    Map<DateTime, double>? dailySalesMap,
    Map<DateTime, double>? weeklySalesMap,
    Map<DateTime, double>? monthlySalesMap,
    Map<DateTime, double>? annualSalesMap,
    double? dailyMaxYSales,
    double? weeklyMaxYSales,
    double? monthlyMaxYSales,
    double? annualMaxYSales,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSales: totalSales ?? this.totalSales,
      totalCompletedOrders: totalCompletedOrders ?? this.totalCompletedOrders,
      totalReadyOrders: totalReadyOrders ?? this.totalReadyOrders,
      totalPendingOrders: totalPendingOrders ?? this.totalPendingOrders,
      dailyOrdersMap: dailyOrdersMap ?? this.dailyOrdersMap,
      weeklyOrdersMap: weeklyOrdersMap ?? this.weeklyOrdersMap,
      monthlyOrdersMap: monthlyOrdersMap ?? this.monthlyOrdersMap,
      annualOrdersMap: annualOrdersMap ?? this.annualOrdersMap,
      dailyMaxYOrder: dailyMaxYOrder ?? this.dailyMaxYOrder,
      weeklyMaxYOrder: weeklyMaxYOrder ?? this.weeklyMaxYOrder,
      monthlyMaxYOrder: monthlyMaxYOrder ?? this.monthlyMaxYOrder,
      annualMaxYOrder: annualMaxYOrder ?? this.annualMaxYOrder,
      dailySalesMap: dailySalesMap ?? this.dailySalesMap,
      weeklySalesMap: weeklySalesMap ?? this.weeklySalesMap,
      monthlySalesMap: monthlySalesMap ?? this.monthlySalesMap,
      annualSalesMap: annualSalesMap ?? this.annualSalesMap,
      dailyMaxYSales: dailyMaxYSales ?? this.dailyMaxYSales,
      weeklyMaxYSales: weeklyMaxYSales ?? this.weeklyMaxYSales,
      monthlyMaxYSales: monthlyMaxYSales ?? this.monthlyMaxYSales,
      annualMaxYSales: annualMaxYSales ?? this.annualMaxYSales,
    );
  }

  static const _sentinel = Object();
}

/// Store analytics ViewModel — fetches lifetime totals plus per-period
/// (Daily / Weekly / Monthly / Annual) maps of orders and sales for chart
/// rendering.
@riverpod
class AnalyticsViewModel extends _$AnalyticsViewModel {
  @override
  AnalyticsState build() => AnalyticsState.initial();

  Future<void> fetchAnalyticsData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _getTotals();
      await _getOrdersAndSalesData();
    } catch (e, stackTrace) {
      AppLogger.error('Error in AnalyticsViewModel: $e', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _getOrdersAndSalesData() async {
    await _getOrdersMap('Daily');
    await _getOrdersMap('Weekly');
    await _getOrdersMap('Monthly');
    await _getOrdersMap('Annual');

    await _getSalesMap('Daily');
    await _getSalesMap('Weekly');
    await _getSalesMap('Monthly');
    await _getSalesMap('Annual');

    AppLogger.debug('Weekly Orders: ${state.weeklyOrdersMap}');
    AppLogger.debug('Weekly Sales: ${state.weeklySalesMap}');
  }

  Future<void> _getTotals() async {
    int totalOrders = 0;
    double totalSales = 0.0;
    int totalCompletedOrders = 0;
    int totalReadyOrders = 0;
    int totalPendingOrders = 0;

    final orderDocs = await ref.read(analyticsServiceProvider).fetchOrders();

    for (var doc in orderDocs) {
      totalOrders++;

      final String status = doc['status'] as String;
      if (status == StatusConstants.completed) {
        totalCompletedOrders++;
      } else if (status == StatusConstants.ready) {
        totalReadyOrders++;
      } else if (status == StatusConstants.pending) {
        totalPendingOrders++;
      }
    }

    final transDocs =
        await ref.read(analyticsServiceProvider).fetchTransactions();

    for (var transDoc in transDocs) {
      if (transDoc['type'] == StatusConstants.sale) {
        double transAmount = (transDoc['sellerEarnings'] ?? 0).toDouble();
        totalSales += transAmount;
      }
    }

    state = state.copyWith(
      totalOrders: totalOrders,
      totalSales: totalSales,
      totalCompletedOrders: totalCompletedOrders,
      totalReadyOrders: totalReadyOrders,
      totalPendingOrders: totalPendingOrders,
    );
  }

  Future<void> _getOrdersMap(String period) async {
    final DateTime today = DateTime.now();
    final Map<DateTime, int> ordersMap = _initializeOrdersMap(period, today);

    final startDate = _getStartDate(period, today);
    final orderDocs = await ref
        .read(analyticsServiceProvider)
        .fetchOrders(since: startDate);

    for (var orderDoc in orderDocs) {
      final DateTime orderDate = (orderDoc['createdAt'] as Timestamp).toDate();
      _updateOrdersMap(period, orderDate, ordersMap);
    }

    final double maxY = _calculateMaxYOrder(ordersMap);

    switch (period) {
      case 'Daily':
        state =
            state.copyWith(dailyOrdersMap: ordersMap, dailyMaxYOrder: maxY);
        break;
      case 'Weekly':
        state =
            state.copyWith(weeklyOrdersMap: ordersMap, weeklyMaxYOrder: maxY);
        break;
      case 'Monthly':
        state = state.copyWith(
            monthlyOrdersMap: ordersMap, monthlyMaxYOrder: maxY);
        break;
      case 'Annual':
        state =
            state.copyWith(annualOrdersMap: ordersMap, annualMaxYOrder: maxY);
        break;
    }
  }

  Future<void> _getSalesMap(String period) async {
    final DateTime today = DateTime.now();
    final Map<DateTime, double> salesMap = _initializeSalesMap(period, today);

    final startDate = _getStartDate(period, today);
    final transDocs = await ref
        .read(analyticsServiceProvider)
        .fetchTransactions(since: startDate);

    for (var transDoc in transDocs) {
      if (transDoc['type'] == StatusConstants.sale) {
        final DateTime transDate = (transDoc['date'] as Timestamp).toDate();
        final double transAmount = (transDoc['sellerEarnings'] ?? 0).toDouble();
        _updateSalesMap(period, transDate, transAmount, salesMap);
      }
    }

    final double maxY = _calculateMaxYSales(salesMap);

    switch (period) {
      case 'Daily':
        state =
            state.copyWith(dailySalesMap: salesMap, dailyMaxYSales: maxY);
        break;
      case 'Weekly':
        state =
            state.copyWith(weeklySalesMap: salesMap, weeklyMaxYSales: maxY);
        break;
      case 'Monthly':
        state =
            state.copyWith(monthlySalesMap: salesMap, monthlyMaxYSales: maxY);
        break;
      case 'Annual':
        state =
            state.copyWith(annualSalesMap: salesMap, annualMaxYSales: maxY);
        break;
    }
  }

  Map<DateTime, int> _initializeOrdersMap(String period, DateTime today) {
    final Map<DateTime, int> map = {};
    switch (period) {
      case 'Daily':
        for (int i = 0; i < 14; i++) {
          DateTime date = today.subtract(Duration(days: i));
          DateTime saveDate = DateTime(date.year, date.month, date.day);
          map[saveDate] = 0;
        }
        break;
      case 'Weekly':
        DateTime lastMonday = today.subtract(Duration(days: today.weekday - 1));
        for (int i = 0; i < 4; i++) {
          DateTime weekStartDate =
              lastMonday.subtract(Duration(days: 21 - (i * 7)));

          weekStartDate = DateTime(
              weekStartDate.year, weekStartDate.month, weekStartDate.day);

          map[weekStartDate] = 0;
        }
        break;
      case 'Monthly':
        for (int i = 5; i >= 0; i--) {
          int year = today.year;
          int month = today.month - i;

          if (month <= 0) {
            month += 12;
            year--;
          }

          DateTime monthDate = DateTime(year, month, 1);
          map[monthDate] = 0;
        }
        break;
      case 'Annual':
        for (int i = 2; i >= 0; i--) {
          DateTime yearDate = DateTime(today.year - i, 1, 1);
          map[yearDate] = 0;
        }
        break;

      default:
        AppLogger.warning('Invalid time period');
        break;
    }
    return map;
  }

  Map<DateTime, double> _initializeSalesMap(String period, DateTime today) {
    final Map<DateTime, double> map = {};
    switch (period) {
      case 'Daily':
        for (int i = 0; i < 14; i++) {
          DateTime date = today.subtract(Duration(days: i));
          DateTime saveDate = DateTime(date.year, date.month, date.day);
          map[saveDate] = 0.0;
        }
        break;
      case 'Weekly':
        DateTime lastMonday = today.subtract(Duration(days: today.weekday - 1));
        for (int i = 0; i < 4; i++) {
          DateTime weekStartDate =
              lastMonday.subtract(Duration(days: 21 - (i * 7)));

          weekStartDate = DateTime(
              weekStartDate.year, weekStartDate.month, weekStartDate.day);
          map[weekStartDate] = 0;
        }
        break;
      case 'Monthly':
        for (int i = 5; i >= 0; i--) {
          int year = today.year;
          int month = today.month - i;

          if (month <= 0) {
            month += 12;
            year--;
          }

          DateTime monthDate = DateTime(year, month, 1);
          map[monthDate] = 0.0;
        }
        break;
      case 'Annual':
        for (int i = 2; i >= 0; i--) {
          // Start from the oldest year and move forward
          DateTime yearDate = DateTime(today.year - i, 1, 1);
          map[yearDate] = 0.0;
        }
        break;
      default:
        break;
    }
    return map;
  }

  void _updateOrdersMap(
      String period, DateTime orderDate, Map<DateTime, int> map) {
    DateTime key;

    switch (period) {
      case 'Daily':
        key = DateTime(orderDate.year, orderDate.month, orderDate.day);

        if (map.containsKey(key)) {
          map[key] = (map[key] ?? 0) + 1;
        }

        break;
      case 'Weekly':
        key = DateTime(
          orderDate.year,
          orderDate.month,
          orderDate.day,
        ).subtract(Duration(days: orderDate.weekday - 1));

        key = DateTime(key.year, key.month, key.day);

        map[key] = (map[key] ?? 0) + 1;

        break;
      case 'Monthly':
        key = DateTime(orderDate.year, orderDate.month, 1);

        if (map.containsKey(key)) {
          map[key] = (map[key] ?? 0) + 1;
        }

        break;
      case 'Annual':
        key = DateTime(orderDate.year, 1, 1);

        if (map.containsKey(key)) {
          map[key] = (map[key] ?? 0) + 1;
        }

        break;
      default:
        return;
    }
  }

  void _updateSalesMap(String period, DateTime saleDate, double saleAmount,
      Map<DateTime, double> map) {
    DateTime key;

    switch (period) {
      case 'Daily':
        key = DateTime(saleDate.year, saleDate.month, saleDate.day);

        if (map.containsKey(key)) {
          map[key] = (map[key] ?? 0.0) + saleAmount;
        }

        break;
      case 'Weekly':
        key = DateTime(
          saleDate.year,
          saleDate.month,
          saleDate.day,
        ).subtract(Duration(days: saleDate.weekday - 1));

        key = DateTime(key.year, key.month, key.day);

        map[key] = (map[key] ?? 0.0) + saleAmount;

        break;
      case 'Monthly':
        key = DateTime(saleDate.year, saleDate.month, 1);

        if (map.containsKey(key)) {
          map[key] = (map[key] ?? 0.0) + saleAmount;
        }

        break;
      case 'Annual':
        key = DateTime(saleDate.year, 1, 1);

        if (map.containsKey(key)) {
          map[key] = (map[key] ?? 0.0) + saleAmount;
        }

        break;
      default:
        return;
    }
  }

  double _calculateMaxYOrder(Map<DateTime, int> map) {
    if (map.isEmpty) return 0.0;
    final int maxOrderCount =
        map.values.reduce((a, b) => a > b ? a : b);
    return maxOrderCount.toDouble();
  }

  double _calculateMaxYSales(Map<DateTime, double> map) {
    if (map.isEmpty) return 0.0;
    final double maxSalesAmount =
        map.values.reduce((a, b) => a > b ? a : b);
    return maxSalesAmount.ceil().toDouble();
  }

  DateTime _getStartDate(String period, DateTime today) {
    switch (period) {
      case 'Daily':
        return today.subtract(const Duration(days: 15));
      case 'Weekly':
        DateTime lastMonday = today.subtract(Duration(days: today.weekday - 1));
        return lastMonday.subtract(const Duration(days: 21));
      case 'Monthly':
        return DateTime(today.year, today.month - 11, 1);
      case 'Annual':
        return DateTime(today.year - 2, 1, 1);
      default:
        throw Exception('Invalid period');
    }
  }
}
