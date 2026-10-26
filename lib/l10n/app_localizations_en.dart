// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Poisa';

  @override
  String get tagline => 'Simple money tracking.';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionDone => 'Done';

  @override
  String get actionNext => 'Next';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionSeeAll => 'See all';

  @override
  String get actionYes => 'Yes';

  @override
  String get actionNo => 'No';

  @override
  String get actionOk => 'OK';

  @override
  String get labelOptional => 'Optional';

  @override
  String get labelAll => 'All';

  @override
  String get labelTotal => 'Total';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get transfer => 'Transfer';

  @override
  String get balance => 'Balance';

  @override
  String get category => 'Category';

  @override
  String get categories => 'Categories';

  @override
  String get account => 'Account';

  @override
  String get accounts => 'Accounts';

  @override
  String get budget => 'Budget';

  @override
  String get budgets => 'Budgets';

  @override
  String get report => 'Report';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get transactions => 'Transactions';

  @override
  String get home => 'Home';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get note => 'Note';

  @override
  String get net => 'Net';

  @override
  String get onboard1Title => 'Track every taka you spend.';

  @override
  String get onboard1Body =>
      'Record income and expenses in seconds, even without an internet connection.';

  @override
  String get onboard2Title => 'Set budgets, stay in control.';

  @override
  String get onboard2Body =>
      'Give every category a monthly limit and see exactly where you stand.';

  @override
  String get onboard3Title => 'Clear charts and reports.';

  @override
  String get onboard3Body =>
      'Understand your habits with simple, honest visuals.';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get chooseLanguageBody => 'You can change this any time in Settings.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'Bangla';

  @override
  String get getStarted => 'Get Started';

  @override
  String get loginHeadline => 'Welcome to Poisa';

  @override
  String get loginSubtext =>
      'Sign in to keep your records safe and synced across your devices.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueAsGuest => 'Continue without an account';

  @override
  String get guestModeCaption =>
      'Nothing is saved — your data is erased when you leave guest mode.';

  @override
  String get guestBadge => 'Guest';

  @override
  String get guestExit => 'Exit guest mode';

  @override
  String get guestExitTitle => 'Exit guest mode?';

  @override
  String get guestExitBody =>
      'Everything you added as a guest will be permanently deleted.';

  @override
  String get guestExitDone => 'Guest data cleared.';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get signInFailed => 'Sign-in failed. Please try again.';

  @override
  String get signInCancelled => 'Sign-in was cancelled.';

  @override
  String get legalPrefix => 'By continuing you agree to our';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get and => 'and';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get legalSuffix => '';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get netWorth => 'Net worth';

  @override
  String get spendingByCategory => 'Spending by category';

  @override
  String get spendingOverview => 'Spending Overview';

  @override
  String get totalExpense => 'Total Expense';

  @override
  String get othersCategory => 'Others';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get noTransactionsTitle => 'No transactions yet';

  @override
  String get noTransactionsBody =>
      'Tap the + button to record your first income or expense.';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get selectAccount => 'Select an account';

  @override
  String get fromAccount => 'From';

  @override
  String get toAccount => 'To';

  @override
  String get notePlaceholder => 'What was this for?';

  @override
  String get errorAmountRequired => 'Enter an amount greater than zero.';

  @override
  String get errorCategoryRequired => 'Please choose a category.';

  @override
  String get errorAccountRequired => 'Please choose an account.';

  @override
  String get errorSameAccount =>
      'Choose two different accounts for a transfer.';

  @override
  String get transactionSaved => 'Transaction saved';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get deleteTransactionTitle => 'Delete this transaction?';

  @override
  String get deleteTransactionBody =>
      'This cannot be undone once the snackbar disappears.';

  @override
  String get filters => 'Filters';

  @override
  String get searchHint => 'Search notes or categories';

  @override
  String get dateRange => 'Date range';

  @override
  String get amountRange => 'Amount range';

  @override
  String get minAmount => 'Min';

  @override
  String get maxAmount => 'Max';

  @override
  String get type => 'Type';

  @override
  String get noResultsTitle => 'Nothing found';

  @override
  String get noResultsBody => 'Try changing your filters or search words.';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String deleteSelectedTitle(int count) {
    return 'Delete $count transactions?';
  }

  @override
  String get deleteSelectedBody =>
      'The selected transactions will be permanently removed.';

  @override
  String filtersActive(int count) {
    return '$count filters active';
  }

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get newCategory => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryNameEn => 'Name (English)';

  @override
  String get categoryNameBn => 'Name (Bangla)';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get errorNameRequired => 'Please enter a name.';

  @override
  String get categorySaved => 'Category saved';

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String get deleteCategoryTitle => 'Delete this category?';

  @override
  String deleteCategoryBody(String name) {
    return '$name will be removed permanently. This cannot be undone.';
  }

  @override
  String get categoryInUseTitle => 'Category is in use';

  @override
  String categoryInUseBody(int count) {
    return '$count transactions use this category. Move them to another category to delete it.';
  }

  @override
  String get moveTransactionsTo => 'Move transactions to';

  @override
  String get moveAndDelete => 'Move and delete';

  @override
  String get defaultCannotDelete =>
      'Default categories can be edited but not deleted.';

  @override
  String get dragToReorder => 'Press and hold to reorder';

  @override
  String get noCategoriesTitle => 'No categories here';

  @override
  String get noCategoriesBody => 'Add one to start organising your money.';

  @override
  String get manageAccounts => 'Manage accounts';

  @override
  String get newAccount => 'New account';

  @override
  String get editAccount => 'Edit account';

  @override
  String get accountName => 'Account name';

  @override
  String get accountType => 'Account type';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeCard => 'Card';

  @override
  String get accountTypeMobileWallet => 'Mobile wallet';

  @override
  String get accountTypeSavings => 'Savings';

  @override
  String get accountSaved => 'Account saved';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get deleteAccountTitle => 'Delete this account?';

  @override
  String deleteAccountBody(String name) {
    return '$name will be removed permanently. This cannot be undone.';
  }

  @override
  String get noAccountsTitle => 'No accounts yet';

  @override
  String get noAccountsBody =>
      'Add a wallet, bank or card to start tracking balances.';

  @override
  String get accountInUseTitle => 'Account is in use';

  @override
  String accountInUseBody(int count) {
    return '$count transactions use this account. Move them to another account to delete it.';
  }

  @override
  String get moveTransactionsToAccount => 'Move transactions to';

  @override
  String get lastAccountCannotDelete => 'You need at least one account.';

  @override
  String get archived => 'Archived';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get showArchived => 'Show archived';

  @override
  String get newBudget => 'New budget';

  @override
  String get editBudget => 'Edit budget';

  @override
  String get budgetLimit => 'Monthly limit';

  @override
  String get overallBudget => 'Overall monthly budget';

  @override
  String get overallBudgetShort => 'Overall';

  @override
  String spentOfLimit(String spent, String limit) {
    return '$spent of $limit';
  }

  @override
  String remaining(String amount) {
    return '$amount left';
  }

  @override
  String overBudgetBy(String amount) {
    return '$amount over';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get copyLastMonth => 'Copy last month';

  @override
  String budgetsCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count budgets copied',
      one: '1 budget copied',
      zero: 'No budgets to copy',
    );
    return '$_temp0';
  }

  @override
  String get noBudgetsTitle => 'No budgets for this month';

  @override
  String get noBudgetsBody =>
      'Set a limit for a category and Poisa will track it for you.';

  @override
  String get budgetSaved => 'Budget saved';

  @override
  String get budgetDeleted => 'Budget deleted';

  @override
  String get deleteBudgetTitle => 'Delete this budget?';

  @override
  String get deleteBudgetBody =>
      'The limit is removed. Your transactions are not affected.';

  @override
  String get errorLimitRequired => 'Enter a limit greater than zero.';

  @override
  String get errorBudgetExists => 'A budget already exists for this category.';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get periodCustom => 'Custom';

  @override
  String get expenseBreakdown => 'Expense breakdown';

  @override
  String get incomeBreakdown => 'Income breakdown';

  @override
  String get incomeVsExpense => 'Income vs Expense';

  @override
  String get dailyTrend => 'Daily trend';

  @override
  String get categoryRanking => 'By category';

  @override
  String transactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get noDataForPeriod => 'No data for this period';

  @override
  String get noDataForPeriodBody => 'Pick another period or add a transaction.';

  @override
  String get lastSixMonths => 'Last 6 months';

  @override
  String get profile => 'Profile';

  @override
  String get preferences => 'Preferences';

  @override
  String get dataAndPrivacy => 'Data';

  @override
  String get about => 'About';

  @override
  String get language => 'Language';

  @override
  String get banglaNumerals => 'Bangla numerals';

  @override
  String get banglaNumeralsBody => 'Show numbers as ১২৩৪ instead of 1234.';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get currency => 'Currency';

  @override
  String get selectCurrency => 'Select currency';

  @override
  String get firstDayOfWeek => 'First day of week';

  @override
  String get firstDayOfMonth => 'First day of month';

  @override
  String get firstDayOfMonthBody =>
      'Useful if your salary cycle does not start on the 1st.';

  @override
  String dayOfMonth(int day) {
    return 'Day $day';
  }

  @override
  String get exportCsv => 'Export data to CSV';

  @override
  String get exportingCsv => 'Preparing your file…';

  @override
  String get exportSuccess => 'Export ready';

  @override
  String get exportFailed => 'Could not export your data.';

  @override
  String get nothingToExport => 'There is nothing to export yet.';

  @override
  String get rateApp => 'Rate this app';

  @override
  String get shareApp => 'Share Poisa';

  @override
  String get shareAppMessage =>
      'I track my money with Poisa — simple, bilingual and free.';

  @override
  String get aboutBody =>
      'Poisa is a simple, offline-friendly money tracker for everyday use.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out of Poisa?';

  @override
  String get signOutBody =>
      'Your data stays safe and will be here when you sign back in.';

  @override
  String get deleteAccountAndData => 'Delete account and all data';

  @override
  String get deleteAccountStep1Title => 'Delete your account?';

  @override
  String get deleteAccountStep1Body =>
      'Every transaction, category, account and budget will be permanently erased. This cannot be undone.';

  @override
  String get deleteAccountStep2Title => 'Are you absolutely sure?';

  @override
  String get deleteAccountStep2Body => 'Type DELETE below to confirm.';

  @override
  String get deleteConfirmationWord => 'DELETE';

  @override
  String get deleteAccountDone => 'Your account and data have been deleted.';

  @override
  String get reauthRequired =>
      'For your security, please sign in again before deleting your account.';

  @override
  String get monday => 'Monday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorBody => 'We could not load this. Please try again.';

  @override
  String get errorPermissionDenied => 'You do not have permission to do that.';

  @override
  String get offlineBanner => 'You are offline — showing saved data';

  @override
  String get loading => 'Loading…';

  @override
  String get unknownCategory => 'Uncategorised';

  @override
  String get unknownAccount => 'Unknown account';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get loans => 'Loans';

  @override
  String get loansSubtitle => 'What you are owed and what you owe';

  @override
  String get loansReceivable => 'You will receive';

  @override
  String get loansPayable => 'You will pay';

  @override
  String get loansNet => 'Net position';

  @override
  String get loansNetUp => 'Overall, more is owed to you than by you.';

  @override
  String get loansNetDown => 'Overall, you owe more than you are owed.';

  @override
  String get loansBreakdown => 'Breakdown';

  @override
  String get loanGivenTotal => 'Lent out';

  @override
  String get loanRecoveredTotal => 'Recovered';

  @override
  String get loanTakenTotal => 'Borrowed';

  @override
  String get loanRepaidTotal => 'Repaid';

  @override
  String get loanHistory => 'Loan history';

  @override
  String get noLoansTitle => 'No loans yet';

  @override
  String get noLoansBody =>
      'Record money you lend or borrow under the Loan categories and it will all be summed up here.';

  @override
  String get exportData => 'Export data';

  @override
  String get exportDataBody => 'Save or share your full transaction history';

  @override
  String get exportChooseFormat => 'Choose a format';

  @override
  String get exportFormatCsv => 'CSV spreadsheet';

  @override
  String get exportFormatCsvBody => 'Opens in Excel or Google Sheets';

  @override
  String get exportFormatPdf => 'PDF report';

  @override
  String get exportFormatPdfBody => 'A formatted statement, ready to print';

  @override
  String get exportActionShare => 'Share';

  @override
  String get exportActionShareBody => 'Send it through any app on your phone';

  @override
  String get exportActionSave => 'Save to device';

  @override
  String get exportActionSaveBody => 'Keep a copy in your Downloads folder';

  @override
  String exportSaved(String location) {
    return 'Saved to $location';
  }

  @override
  String get exportPdfTitle => 'Transaction statement';

  @override
  String exportPdfGenerated(String date) {
    return 'Generated $date';
  }

  @override
  String get exportPdfTotalIncome => 'Total income';

  @override
  String get exportPdfTotalExpense => 'Total expense';

  @override
  String get exportPdfNet => 'Net';

  @override
  String exportPdfCount(String count) {
    return '$count transactions';
  }

  @override
  String exportPdfPage(String current, String total) {
    return 'Page $current of $total';
  }

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String get dailyReminderBody => 'A nudge to log the day\'s spending';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get reminderNotificationTitle => 'Logged today\'s spending?';

  @override
  String get reminderNotificationBody =>
      'Add everything you spent today before you forget.';

  @override
  String get reminderPermissionDenied =>
      'Notifications are off for Poisa. Turn them on in system settings.';

  @override
  String get widgetTodaySpent => 'Spent today';

  @override
  String get widgetThisMonth => 'This month';

  @override
  String get displayOverlay => 'Display Overlay';

  @override
  String get displayOverlayBody =>
      'A floating bubble over other apps for quick expense entry';

  @override
  String get displayOverlayPermissionDenied =>
      'Overlay permission is required. Turn it on in system settings.';
}
