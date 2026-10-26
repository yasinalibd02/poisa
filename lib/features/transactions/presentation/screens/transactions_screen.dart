import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/period_utils.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/transaction_model.dart';
import '../providers/transaction_actions.dart';
import '../providers/transaction_list_provider.dart';
import '../providers/transaction_providers.dart';
import '../widgets/day_header.dart';
import '../widgets/dismissible_transaction.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/summary_bar.dart';

/// The full ledger: searchable, filterable, grouped by day, with multi-select
/// for bulk deletes.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Grows the render window as the end of the list comes into view.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final double remaining =
        _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    if (remaining < 400 && ref.read(hasMoreTransactionsProvider)) {
      ref.read(transactionPageProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Another screen can set the filters and then send the user here — the
    // dashboard's wallet shortcut does exactly that. The search box is the one
    // filter with its own copy of the state, so it is pulled back into line
    // rather than left showing a query that is no longer being applied.
    ref.listen<String>(
      transactionFiltersProvider.select((TransactionFilters f) => f.query),
      (String? previous, String next) {
        if (_searchController.text != next) _searchController.text = next;
      },
    );

    final AsyncValue<List<TransactionModel>> ledger = ref.watch(
      allTransactionsProvider,
    );
    final Set<String> selection = ref.watch(transactionSelectionProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: selection.isEmpty
          ? _searchAppBar(context)
          : _selectionAppBar(context, selection),
      body: ledger.when(
        loading: () => const ListSkeleton(rows: 8),
        error: (Object error, _) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(allTransactionsProvider),
        ),
        data: (_) => _body(context, selection),
      ),
    );
  }

  PreferredSizeWidget _searchAppBar(BuildContext context) {
    final int activeFilters = ref
        .watch(transactionFiltersProvider)
        .activeCount;
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);

    return AppBar(
      title: Text(context.l10n.transactions),
      actions: <Widget>[
        IconButton(
          tooltip: context.l10n.filters,
          onPressed: () => showFiltersSheet(context),
          icon: Badge(
            isLabelVisible: activeFilters > 0,
            label: Text(money.number(activeFilters)),
            child: const Icon(CupertinoIcons.line_horizontal_3_decrease),
          ),
        ),
        AppSizes.hGapXs,
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            0,
            AppSizes.screenPadding,
            AppSizes.md,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: ref.read(transactionFiltersProvider.notifier).setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.l10n.searchHint,
              prefixIcon: const Icon(CupertinoIcons.search),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.md,
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(CupertinoIcons.xmark, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(transactionFiltersProvider.notifier)
                            .setQuery('');
                        setState(() {});
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _selectionAppBar(
    BuildContext context,
    Set<String> selection,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(CupertinoIcons.xmark),
        onPressed: ref.read(transactionSelectionProvider.notifier).clear,
      ),
      title: Text(context.l10n.selectedCount(selection.length)),
      actions: <Widget>[
        IconButton(
          tooltip: context.l10n.actionDelete,
          icon: Icon(CupertinoIcons.trash, color: context.colors.error),
          onPressed: () => _deleteSelected(selection),
        ),
        AppSizes.hGapXs,
      ],
    );
  }

  Widget _body(BuildContext context, Set<String> selection) {
    final List<DayGroup> groups = ref.watch(transactionDayGroupsProvider);
    final List<TransactionModel> filtered = ref.watch(
      filteredTransactionsProvider,
    );
    final MoneyFormatter money = ref.watch(moneyFormatterProvider);
    final DateLabels dates = ref.watch(dateLabelsProvider);
    final bool hasMore = ref.watch(hasMoreTransactionsProvider);
    final bool filtersActive = !ref.watch(transactionFiltersProvider).isEmpty;

    if (groups.isEmpty) {
      return filtersActive
          ? EmptyStateView(
              icon: CupertinoIcons.doc_text_search,
              title: context.l10n.noResultsTitle,
              message: context.l10n.noResultsBody,
              actionLabel: context.l10n.actionReset,
              onAction: ref.read(transactionFiltersProvider.notifier).clearAll,
            )
          : EmptyStateView(
              icon: CupertinoIcons.doc_text_fill,
              title: context.l10n.noTransactionsTitle,
              message: context.l10n.noTransactionsBody,
              actionLabel: context.l10n.addTransaction,
              onAction: () => context.push(AppRoutes.transactionNew),
            );
    }

    final MoneySummary summary = MoneySummary.from(filtered);

    return CustomScrollView(
      controller: _scrollController,
      slivers: <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: PinnedSummaryBar(
            child: SummaryBar(
              income: money.format(summary.income),
              expense: money.format(summary.expense),
              net: money.formatSigned(summary.net),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          sliver: SliverList.builder(
            itemCount: groups.length,
            itemBuilder: (BuildContext context, int index) {
              final DayGroup group = groups[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  DayHeader(
                    label: money.localizeDigits(_dayLabel(group.day, dates)),
                    subtotal: money.formatSigned(group.subtotal),
                    subtotalColor: group.subtotal == 0
                        ? context.colors.onSurfaceVariant
                        : (group.subtotal > 0
                              ? AppColors.income
                              : AppColors.expense),
                  ),
                  for (final TransactionModel transaction
                      in group.transactions)
                    DismissibleTransaction(
                      key: ValueKey<String>(transaction.id),
                      transaction: transaction,
                      showTime: true,
                      selectionMode: selection.isNotEmpty,
                      selected: selection.contains(transaction.id),
                      onTap: () {
                        if (selection.isNotEmpty) {
                          ref
                              .read(transactionSelectionProvider.notifier)
                              .toggle(transaction.id);
                        } else {
                          context.push(
                            AppRoutes.transactionEdit,
                            extra: transaction,
                          );
                        }
                      },
                      onLongPress: () => ref
                          .read(transactionSelectionProvider.notifier)
                          .toggle(transaction.id),
                    ),
                ],
              );
            },
          ),
        ),
        if (hasMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.xl),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  String _dayLabel(DateTime day, DateLabels dates) {
    final DateTime today = PeriodUtils.dayStart(DateTime.now());
    if (day == today) return context.l10n.today;
    if (day == today.subtract(const Duration(days: 1))) {
      return context.l10n.yesterday;
    }
    return dates.dayWithWeekday(day);
  }

  Future<void> _deleteSelected(Set<String> selection) async {
    final List<TransactionModel> chosen = ref
        .read(filteredTransactionsProvider)
        .where((TransactionModel t) => selection.contains(t.id))
        .toList(growable: false);
    if (chosen.isEmpty) return;

    final bool confirmed = await showConfirmDialog(
      context,
      title: context.l10n.deleteSelectedTitle(chosen.length),
      message: context.l10n.deleteSelectedBody,
      confirmLabel: context.l10n.actionDelete,
    );
    if (!confirmed || !mounted) return;

    await ref
        .read(transactionActionsProvider)
        .deleteManyWithUndo(context, transactions: chosen);
    ref.read(transactionSelectionProvider.notifier).clear();
  }
}
