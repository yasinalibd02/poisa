import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/account_model.dart';
import '../providers/account_providers.dart';

/// Bottom-sheet list of accounts with live balances.
/// Returns the chosen account id, or `null` if dismissed.
Future<String?> showAccountPicker(
  BuildContext context, {
  required String title,
  String? selectedId,
  String? excludeId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AccountPickerSheet(
      title: title,
      selectedId: selectedId,
      excludeId: excludeId,
    ),
  );
}

class _AccountPickerSheet extends ConsumerWidget {
  const _AccountPickerSheet({
    required this.title,
    required this.selectedId,
    required this.excludeId,
  });

  final String title;
  final String? selectedId;

  /// Hidden so a transfer cannot pick the same account on both sides.
  final String? excludeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<AccountModel> accounts = ref
        .watch(activeAccountsProvider)
        .where((AccountModel a) => a.id != excludeId)
        .toList(growable: false);
    final Map<String, double> balances = ref.watch(accountBalancesProvider);
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.sm,
              AppSizes.lg,
              AppSizes.md,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(title, style: context.texts.titleMedium),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: AppSizes.lg),
              itemCount: accounts.length,
              itemBuilder: (BuildContext context, int index) {
                final AccountModel account = accounts[index];
                final bool selected = account.id == selectedId;
                return ListTile(
                  leading: IconBadge(
                    iconKey: account.icon,
                    colorHex: account.colorHex,
                    size: 40,
                    selected: selected,
                  ),
                  title: Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    money.format(
                      balances[account.id] ?? account.openingBalance,
                    ),
                  ),
                  trailing: selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: context.colors.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(account.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
