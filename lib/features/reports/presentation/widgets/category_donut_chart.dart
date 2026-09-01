import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../providers/report_providers.dart';

/// Donut of the category breakdown, with an optional centre label.
///
/// Slices below 2% are folded into a single "other" slice so the ring does not
/// degrade into unreadable hairlines.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    super.key,
    required this.shares,
    required this.centerLabel,
    required this.centerSubLabel,
    this.size = 168,
    this.onTap,
  });

  final List<CategoryShare> shares;
  final String centerLabel;
  final String centerSubLabel;
  final double size;
  final VoidCallback? onTap;

  static const double _minSliceFraction = 0.02;

  @override
  Widget build(BuildContext context) {
    final List<PieChartSectionData> sections = _buildSections(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: size * 0.30,
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(enabled: false),
              ),
              duration: AppSizes.slow,
              curve: Curves.easeOutCubic,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      centerLabel,
                      maxLines: 1,
                      style: context.texts.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    centerSubLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.texts.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(BuildContext context) {
    if (shares.isEmpty) {
      return <PieChartSectionData>[
        PieChartSectionData(
          value: 1,
          color: context.colors.outlineVariant,
          radius: size * 0.16,
          showTitle: false,
        ),
      ];
    }

    final List<CategoryShare> major = shares
        .where((CategoryShare s) => s.fraction >= _minSliceFraction)
        .toList(growable: false);
    final double minorTotal = shares
        .where((CategoryShare s) => s.fraction < _minSliceFraction)
        .fold<double>(0, (double sum, CategoryShare s) => sum + s.amount);

    return <PieChartSectionData>[
      for (final CategoryShare share in major)
        PieChartSectionData(
          value: share.amount,
          color: AppColors.fromHex(share.colorHex),
          radius: size * 0.16,
          showTitle: false,
        ),
      if (minorTotal > 0)
        PieChartSectionData(
          value: minorTotal,
          color: context.colors.outlineVariant,
          radius: size * 0.16,
          showTitle: false,
        ),
    ];
  }
}

/// Legend rows shown beside or beneath the donut.
class DonutLegend extends StatelessWidget {
  const DonutLegend({
    super.key,
    required this.shares,
    required this.labelFor,
    required this.amountFor,
    required this.percentFor,
    this.maxItems = 4,
  });

  final List<CategoryShare> shares;
  final String Function(CategoryShare) labelFor;
  final String Function(CategoryShare) amountFor;
  final String Function(CategoryShare) percentFor;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final List<CategoryShare> visible = shares.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final CategoryShare share in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: Row(
              children: <Widget>[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.fromHex(share.colorHex),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                AppSizes.hGapSm,
                Expanded(
                  child: Text(
                    labelFor(share),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodyMedium,
                  ),
                ),
                AppSizes.hGapSm,
                Text(
                  percentFor(share),
                  style: context.texts.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                AppSizes.hGapSm,
                Text(
                  amountFor(share),
                  style: context.texts.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
