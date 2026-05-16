import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/chart.dart';
import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/section_header.dart';
import 'package:unshelf_seller/components/stat_card.dart';
import 'package:unshelf_seller/viewmodels/analytics_viewmodel.dart';

/// Store analytics screen.
///
/// Layout: inline AppBar → KPI row (lifetime revenue / orders / completed /
/// pending) → time-range chip strip (14d / 4w / 6m / 3y) → revenue chart card
/// → orders chart card → status breakdown card.
class StoreAnalyticsView extends ConsumerStatefulWidget {
  const StoreAnalyticsView({super.key});

  @override
  ConsumerState<StoreAnalyticsView> createState() => _StoreAnalyticsViewState();
}

enum _Range { day, week, month, year }

class _StoreAnalyticsViewState extends ConsumerState<StoreAnalyticsView> {
  _Range _range = _Range.day;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsViewModelProvider.notifier).fetchAnalyticsData();
    });
  }

  Future<void> _refresh() =>
      ref.read(analyticsViewModelProvider.notifier).fetchAnalyticsData();

  Map<DateTime, double> _ordersSeries(AnalyticsState s) {
    switch (_range) {
      case _Range.day:
        return s.dailyOrdersMap.map((k, v) => MapEntry(k, v.toDouble()));
      case _Range.week:
        return s.weeklyOrdersMap.map((k, v) => MapEntry(k, v.toDouble()));
      case _Range.month:
        return s.monthlyOrdersMap.map((k, v) => MapEntry(k, v.toDouble()));
      case _Range.year:
        return s.annualOrdersMap.map((k, v) => MapEntry(k, v.toDouble()));
    }
  }

  Map<DateTime, double> _salesSeries(AnalyticsState s) {
    switch (_range) {
      case _Range.day:
        return s.dailySalesMap;
      case _Range.week:
        return s.weeklySalesMap;
      case _Range.month:
        return s.monthlySalesMap;
      case _Range.year:
        return s.annualSalesMap;
    }
  }

  double _ordersMax(AnalyticsState s) {
    switch (_range) {
      case _Range.day:
        return s.dailyMaxYOrder;
      case _Range.week:
        return s.weeklyMaxYOrder;
      case _Range.month:
        return s.monthlyMaxYOrder;
      case _Range.year:
        return s.annualMaxYOrder;
    }
  }

  double _salesMax(AnalyticsState s) {
    switch (_range) {
      case _Range.day:
        return s.dailyMaxYSales;
      case _Range.week:
        return s.weeklyMaxYSales;
      case _Range.month:
        return s.monthlyMaxYSales;
      case _Range.year:
        return s.annualMaxYSales;
    }
  }

  double get _maxX {
    switch (_range) {
      case _Range.day:
        return 14;
      case _Range.week:
        return 4;
      case _Range.month:
        return 6;
      case _Range.year:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsViewModelProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Store analytics',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.totalOrders == 0) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.totalOrders == 0) {
            return EmptyState(
              icon: Icons.show_chart_rounded,
              title: "Couldn't load analytics",
              subtitle: state.errorMessage,
              actionLabel: 'Retry',
              onAction: _refresh,
            );
          }
          if (state.totalOrders == 0 && state.totalSales == 0) {
            return EmptyState(
              icon: Icons.insights_outlined,
              title: 'No analytics yet',
              subtitle:
                  'Once your store starts taking orders, analytics will appear here.',
              actionLabel: 'Refresh',
              onAction: _refresh,
            );
          }

          return RefreshIndicator(
            color: cs.primary,
            onRefresh: _refresh,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _KpiRow(state: state),
                    const SizedBox(height: 24),
                    _RangeChips(
                      selected: _range,
                      onSelected: (next) => setState(() => _range = next),
                    ),
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Revenue'),
                    const SizedBox(height: 8),
                    _ChartCard(
                      series: _salesSeries(state),
                      maxX: _maxX,
                      maxY: _salesMax(state),
                      emptyMessage: 'No revenue in this range yet.',
                    ),
                    const SizedBox(height: 32),
                    const SectionHeader(title: 'Orders'),
                    const SizedBox(height: 8),
                    _ChartCard(
                      series: _ordersSeries(state),
                      maxX: _maxX,
                      maxY: _ordersMax(state),
                      emptyMessage: 'No orders in this range yet.',
                    ),
                    const SizedBox(height: 32),
                    const SectionHeader(title: 'Order status'),
                    const SizedBox(height: 8),
                    _StatusBreakdown(state: state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// KPI row
// ────────────────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.state});

  final AnalyticsState state;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    final fulfilment = state.totalOrders == 0
        ? 0
        : ((state.totalCompletedOrders / state.totalOrders) * 100).round();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Lifetime revenue',
                value: money.format(state.totalSales),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Orders',
                value: state.totalOrders.toString(),
                icon: Icons.shopping_bag_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Completed',
                value: state.totalCompletedOrders.toString(),
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Fulfilment',
                value: '$fulfilment%',
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Time range chips
// ────────────────────────────────────────────────────────────────────────────

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.selected, required this.onSelected});

  final _Range selected;
  final ValueChanged<_Range> onSelected;

  static const _labels = <_Range, String>{
    _Range.day: '14 days',
    _Range.week: '4 weeks',
    _Range.month: '6 months',
    _Range.year: '3 years',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          for (final entry in _labels.entries) ...[
            ChoiceChip(
              label: Text(entry.value),
              selected: selected == entry.key,
              onSelected: (_) => onSelected(entry.key),
              showCheckmark: false,
              selectedColor: cs.primary.withValues(alpha: 0.14),
              backgroundColor: cs.surfaceContainerHighest,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: selected == entry.key
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: selected == entry.key
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.onSurface.withValues(alpha: 0.08),
                ),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            if (entry.key != _labels.keys.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Chart card
// ────────────────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.series,
    required this.maxX,
    required this.maxY,
    required this.emptyMessage,
  });

  final Map<DateTime, double> series;
  final double maxX;
  final double maxY;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isEmpty = series.isEmpty || series.values.every((v) => v == 0);

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
      padding: const EdgeInsets.all(16),
      child: isEmpty
          ? SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  emptyMessage,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            )
          : Chart(
              dataMap: series,
              maxXValue: maxX,
              maxYValue: maxY == 0 ? 1.0 : maxY,
            ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Order status breakdown card
// ────────────────────────────────────────────────────────────────────────────

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.state});

  final AnalyticsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _StatusRow(
            icon: Icons.hourglass_top_rounded,
            label: 'Pending',
            value: state.totalPendingOrders,
            color: cs.tertiary,
          ),
          const SizedBox(height: 16),
          _StatusRow(
            icon: Icons.local_shipping_outlined,
            label: 'Ready for pickup',
            value: state.totalReadyOrders,
            color: cs.primary,
          ),
          const SizedBox(height: 16),
          _StatusRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Completed',
            value: state.totalCompletedOrders,
            color: cs.primary,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: tt.titleSmall?.copyWith(color: cs.onSurface),
          ),
        ),
        Text(
          value.toString(),
          style: tt.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
