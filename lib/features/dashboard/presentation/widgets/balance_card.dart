import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../reports/presentation/providers/report_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Hero card: total balance across every account, with this month's movement
/// underneath and a wallet glyph on the right.
class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);
    final double netWorth = ref.watch(netWorthProvider);
    final List<MonthlyTotals> months = ref.watch(monthlyComparisonProvider);
    final _Trend trend = _trendFor(months);

    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        borderRadius: AppSizes.brLg,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.totalBalance,
                  style: context.texts.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                AppSizes.gapSm,
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    money.format(netWorth, forceDecimals: true),
                    style: context.texts.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AppSizes.gapMd,
                _TrendPill(trend: trend, money: money),
              ],
            ),
          ),
          AppSizes.hGapMd,
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: AppSizes.brMd,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  _Trend _trendFor(List<MonthlyTotals> months) {
    if (months.length < 2) return const _Trend(label: null, up: true);
    final double current = months.last.income - months.last.expense;
    final double previous =
        months[months.length - 2].income - months[months.length - 2].expense;
    final double base = previous.abs();
    if (base < 1) return const _Trend(label: null, up: true);
    final double pct = (current - previous) / base * 100;
    return _Trend(label: pct.abs(), up: pct >= 0);
  }
}

class _Trend {
  const _Trend({required this.label, required this.up});

  /// The percentage magnitude, or `null` when there is not enough history.
  final double? label;
  final bool up;
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.trend, required this.money});

  final _Trend trend;
  final MoneyFormatter money;

  @override
  Widget build(BuildContext context) {
    final double? pct = trend.label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          context.l10n.thisMonth,
          style: context.texts.labelMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        if (pct != null) ...<Widget>[
          AppSizes.hGapSm,
          Icon(
            trend.up
                ? Icons.arrow_outward_rounded
                : Icons.south_east_rounded,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            '${money.number(pct, decimals: 1)}%',
            style: context.texts.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
