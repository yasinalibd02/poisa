import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../providers/report_providers.dart';

/// Spending (or income) over time for the selected period.
class DailyTrendChart extends StatelessWidget {
  const DailyTrendChart({
    super.key,
    required this.points,
    required this.color,
    required this.compactAmount,
    required this.pointLabel,
  });

  final List<DailyPoint> points;
  final Color color;
  final String Function(double) compactAmount;
  final String Function(DailyPoint) pointLabel;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            context.l10n.noDataForPeriod,
            style: context.texts.bodySmall,
          ),
        ),
      );
    }

    final double maxValue = points.fold<double>(
      0,
      (double max, DailyPoint p) => p.amount > max ? p.amount : max,
    );
    final double maxY = maxValue <= 0 ? 100 : maxValue * 1.25;

    // Label every Nth point so the axis stays readable at any range length.
    final int labelStep = (points.length / 5).ceil().clamp(1, points.length);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (double value) => FlLine(
              color: context.colors.outlineVariant,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                interval: maxY / 3,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value <= 0) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      compactAmount(value),
                      style: context.texts.labelSmall,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: labelStep.toDouble(),
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      pointLabel(points[index]),
                      style: context.texts.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: <FlSpot>[
                for (int i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].amount),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(show: points.length <= 14),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    color.withValues(alpha: 0.28),
                    color.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: AppSizes.slow,
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
