import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../providers/report_providers.dart';

/// Grouped income/expense bars for the last six months.
class IncomeExpenseBars extends StatelessWidget {
  const IncomeExpenseBars({
    super.key,
    required this.months,
    required this.monthLabel,
    required this.compactAmount,
  });

  final List<MonthlyTotals> months;
  final String Function(MonthlyTotals) monthLabel;
  final String Function(double) compactAmount;

  @override
  Widget build(BuildContext context) {
    final double maxValue = months.fold<double>(
      0,
      (double max, MonthlyTotals m) => m.maxSide > max ? m.maxSide : max,
    );
    // A flat zero axis would collapse the chart; give it a nominal ceiling.
    final double maxY = maxValue <= 0 ? 100 : maxValue * 1.2;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: const BarTouchData(enabled: false),
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
                reservedSize: 28,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= months.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      monthLabel(months[index]),
                      style: context.texts.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: <BarChartGroupData>[
            for (int i = 0; i < months.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: months[i].income,
                    width: 9,
                    color: AppColors.income,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  BarChartRodData(
                    toY: months[i].expense,
                    width: 9,
                    color: AppColors.expense,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: AppSizes.slow,
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

/// Colour key shared by the bar and line charts.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.entries});

  final List<({Color color, String label})> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.lg,
      runSpacing: AppSizes.sm,
      children: <Widget>[
        for (final ({Color color, String label}) entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: entry.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AppSizes.hGapSm,
              Text(entry.label, style: context.texts.bodySmall),
            ],
          ),
      ],
    );
  }
}
