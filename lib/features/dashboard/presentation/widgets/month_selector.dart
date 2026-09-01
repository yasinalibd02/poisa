import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/dashboard_providers.dart';

/// `◀ August 2026 ▶` — steps the shared selected month. Stepping past the
/// current month is disabled, since there is nothing to show there yet.
class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime month = ref.watch(selectedMonthProvider);
    final SelectedMonthController controller = ref.read(
      selectedMonthProvider.notifier,
    );
    final DateLabels dates = ref.watch(dateLabelsProvider);
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);
    final bool atCurrentMonth = controller.isCurrentMonth;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _StepButton(
          icon: Icons.chevron_left_rounded,
          tooltip: dates.monthYear(PeriodUtils.addMonths(month, -1)),
          onPressed: controller.previous,
        ),
        Flexible(
          child: GestureDetector(
            onTap: atCurrentMonth ? null : controller.reset,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Text(
                money.localizeDigits(dates.monthYear(month)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleSmall,
              ),
            ),
          ),
        ),
        _StepButton(
          icon: Icons.chevron_right_rounded,
          tooltip: dates.monthYear(PeriodUtils.addMonths(month, 1)),
          onPressed: atCurrentMonth ? null : controller.next,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      visualDensity: VisualDensity.compact,
    );
  }
}
