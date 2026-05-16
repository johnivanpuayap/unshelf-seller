import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/chart.dart';
import 'package:unshelf_seller/components/section_header.dart';
import 'package:unshelf_seller/components/stat_card.dart';
import 'package:unshelf_seller/viewmodels/product_analytics_viewmodel.dart';

/// Product analytics screen.
///
/// Layout: AppBar + product picker + time-range chips + KPI row +
/// sales-overview section with the rethemed [Chart] component.
///
/// NOTE: the underlying viewmodel does not expose per-product time-series
/// data yet, so this screen still seeds its own mock dataset on init
/// (mirroring the pre-redesign implementation). The visual chrome is
/// what's being upgraded here; data wiring is out of scope for Phase 4.
class ProductAnalyticsView extends ConsumerStatefulWidget {
  const ProductAnalyticsView({super.key});

  @override
  ConsumerState<ProductAnalyticsView> createState() =>
      _ProductAnalyticsViewState();
}

enum _TimeRange { week, month, quarter, year }

class _ProductAnalyticsViewState extends ConsumerState<ProductAnalyticsView> {
  String _selectedProduct = 'Apples';
  _TimeRange _range = _TimeRange.week;
  Map<String, Map<String, dynamic>> _data = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(productAnalyticsViewModelProvider.notifier)
          .fetchProductAnalytics();
    });
    _data = _seedMockData();
  }

  Map<String, Map<String, dynamic>> _seedMockData() {
    final today = DateTime.now();
    List<DateTime> range(int count, Duration step) =>
        List.generate(count, (i) => today.subtract(step * i));

    Map<DateTime, double> series(int count, Duration step, double scale) {
      final rng = Random(42);
      return {
        for (final d in range(count, step)) d: rng.nextDouble() * scale,
      };
    }

    return {
      'Apples': {
        'totalOrders': 200,
        'totalSales': 36000.0,
        'completed': 180,
        'cancelled': 20,
        'weekSales': series(14, const Duration(days: 1), 100),
        'monthSales': series(4, const Duration(days: 7), 500),
        'quarterSales': series(6, const Duration(days: 30), 1000),
        'yearSales': series(3, const Duration(days: 365), 10000),
      },
      'Watermelon': {
        'totalOrders': 50,
        'totalSales': 12250.0,
        'completed': 49,
        'cancelled': 1,
        'weekSales': series(14, const Duration(days: 1), 200),
        'monthSales': series(4, const Duration(days: 7), 1000),
        'quarterSales': series(6, const Duration(days: 30), 2000),
        'yearSales': series(3, const Duration(days: 365), 10000),
      },
      'Purple Grapes': {
        'totalOrders': 100,
        'totalSales': 19000.0,
        'completed': 95,
        'cancelled': 5,
        'weekSales': series(14, const Duration(days: 1), 100),
        'monthSales': series(4, const Duration(days: 7), 500),
        'quarterSales': series(6, const Duration(days: 30), 1200),
        'yearSales': series(3, const Duration(days: 365), 2500),
      },
    };
  }

  Map<String, dynamic> get _current => _data[_selectedProduct]!;

  Map<DateTime, double> get _currentSeries {
    switch (_range) {
      case _TimeRange.week:
        return _current['weekSales'] as Map<DateTime, double>;
      case _TimeRange.month:
        return _current['monthSales'] as Map<DateTime, double>;
      case _TimeRange.quarter:
        return _current['quarterSales'] as Map<DateTime, double>;
      case _TimeRange.year:
        return _current['yearSales'] as Map<DateTime, double>;
    }
  }

  double get _maxX {
    switch (_range) {
      case _TimeRange.week:
        return 14;
      case _TimeRange.month:
        return 4;
      case _TimeRange.quarter:
        return 6;
      case _TimeRange.year:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(productAnalyticsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Product analytics',
          style: theme.textTheme.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductPicker(
                      products: _data.keys.toList(),
                      selected: _selectedProduct,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedProduct = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _KpiRow(data: _current),
                    const SizedBox(height: 32),
                    const SectionHeader(title: 'Sales overview'),
                    const SizedBox(height: 8),
                    _RangeChips(
                      selected: _range,
                      onSelected: (next) => setState(() => _range = next),
                    ),
                    const SizedBox(height: 16),
                    _ChartCard(
                      series: _currentSeries,
                      maxX: _maxX,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Product picker
// ────────────────────────────────────────────────────────────────────────────

class _ProductPicker extends StatelessWidget {
  const _ProductPicker({
    required this.products,
    required this.selected,
    required this.onChanged,
  });

  final List<String> products;
  final String selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selected,
          onChanged: onChanged,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
          style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurface),
          items: products
              .map(
                (p) => DropdownMenuItem<String>(
                  value: p,
                  child: Text(p),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// KPI row
// ────────────────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final money = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    final totalSales = (data['totalSales'] as num).toDouble();
    final completed = data['completed'] as int;
    final cancelled = data['cancelled'] as int;
    final totalOrders = data['totalOrders'] as int;
    final repeatRate = totalOrders == 0
        ? 0
        : ((completed / totalOrders) * 100).round();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Lifetime sales',
                value: money.format(totalSales),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Orders',
                value: totalOrders.toString(),
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
                value: completed.toString(),
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Cancelled',
                value: cancelled.toString(),
                icon: Icons.cancel_outlined,
                iconColor: cancelled > 0 ? cs.error : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Fulfilment rate',
                value: '$repeatRate%',
                icon: Icons.trending_up_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Time range chip strip
// ────────────────────────────────────────────────────────────────────────────

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.selected, required this.onSelected});

  final _TimeRange selected;
  final ValueChanged<_TimeRange> onSelected;

  static const _labels = <_TimeRange, String>{
    _TimeRange.week: '14 days',
    _TimeRange.month: '4 weeks',
    _TimeRange.quarter: '6 months',
    _TimeRange.year: '3 years',
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
  const _ChartCard({required this.series, required this.maxX});

  final Map<DateTime, double> series;
  final double maxX;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final values = series.values;
    final maxY = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).toDouble();

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
      child: Chart(
        dataMap: series,
        maxXValue: maxX,
        maxYValue: maxY,
      ),
    );
  }
}
