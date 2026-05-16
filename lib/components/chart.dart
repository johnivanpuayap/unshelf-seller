import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A line chart for time-series analytics screens.
///
/// Rendering uses `Theme.of(context).colorScheme.primary` for the line stroke
/// and a soft alpha-blended fill underneath. Tick labels and grid lines pull
/// from `Theme.of(context)` so the chart stays on-brand in both light and
/// dark themes.
class Chart extends StatelessWidget {
  const Chart({
    super.key,
    required this.dataMap,
    required this.maxXValue,
    required this.maxYValue,
  });

  final Map<DateTime, dynamic> dataMap;
  final double maxXValue;
  final double maxYValue;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.28,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LineChart(_chartData(context)),
      ),
    );
  }

  LineChartData _chartData(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final keys = dataMap.keys.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < keys.length; i++) {
      final value = (dataMap[keys[i]] ?? 0.0).toDouble();
      spots.add(FlSpot(i.toDouble(), value));
    }

    final digits = maxYValue.toStringAsFixed(0).length;
    final reservedSize = 16.0 + (digits * 6.0);

    final gridColor = cs.onSurface.withValues(alpha: 0.08);
    final tickColor = cs.onSurface.withValues(alpha: 0.55);
    final tickStyle = theme.textTheme.labelSmall?.copyWith(
      color: tickColor,
      fontWeight: FontWeight.w600,
    );

    return LineChartData(
      gridData: FlGridData(
        show: true,
        horizontalInterval: maxYValue > 0 ? maxYValue / 4 : 1.0,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: gridColor, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= keys.length) {
                return const SizedBox.shrink();
              }
              final date = keys[index];
              final label = _xLabel(date);
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 6,
                child: Text(label, style: tickStyle),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxYValue > 0 ? maxYValue / 4 : 1.0,
            reservedSize: reservedSize,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(0),
                style: tickStyle,
                textAlign: TextAlign.left,
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: gridColor),
          left: BorderSide(color: gridColor),
        ),
      ),
      minX: 0,
      maxX: maxXValue - 1,
      minY: 0,
      maxY: maxYValue == 0 ? 1.0 : maxYValue,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: cs.primary,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) =>
                FlDotCirclePainter(
              radius: 3,
              color: cs.primary,
              strokeColor: cs.surface,
              strokeWidth: 2,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                cs.primary.withValues(alpha: 0.24),
                cs.primary.withValues(alpha: 0.04),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _xLabel(DateTime date) {
    if (maxXValue == 14) return DateFormat('MM/dd').format(date);
    if (maxXValue == 6) return DateFormat('MMM yy').format(date);
    if (maxXValue == 4) return DateFormat('MM/dd').format(date);
    return DateFormat('yyyy').format(date);
  }
}
