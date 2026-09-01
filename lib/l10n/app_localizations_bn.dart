// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppL10nBn extends AppL10n {
  AppL10nBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'কড়ি';

  @override
  String get tagline => 'সহজ হিসাব।';

  @override
  String get actionSave => 'সংরক্ষণ';

  @override
  String get actionDelete => 'মুছুন';

  @override
  String get actionEdit => 'সম্পাদনা';

  @override
  String get actionCancel => 'বাতিল';

  @override
  String get actionConfirm => 'নিশ্চিত করুন';

  @override
  String get actionAdd => 'যোগ করুন';

  @override
  String get actionClose => 'বন্ধ';

  @override
  String get actionRetry => 'আবার চেষ্টা করুন';

  @override
  String get actionDone => 'সম্পন্ন';

  @override
  String get actionNext => 'পরবর্তী';

  @override
  String get actionSkip => 'এড়িয়ে যান';

  @override
  String get actionSearch => 'খুঁজুন';

  @override
  String get actionApply => 'প্রয়োগ করুন';

  @override
  String get actionReset => 'রিসেট';

  @override
  String get actionUndo => 'ফিরিয়ে আনুন';

  @override
  String get actionRemove => 'সরান';

  @override
  String get actionSeeAll => 'সব দেখুন';

  @override
  String get actionYes => 'হ্যাঁ';

  @override
  String get actionNo => 'না';

  @override
  String get actionOk => 'ঠিক আছে';

  @override
  String get labelOptional => 'ঐচ্ছিক';

  @override
  String get labelAll => 'সব';

  @override
  String get labelTotal => 'মোট';

  @override
  String get income => 'আয়';

  @override
  String get expense => 'খরচ';

  @override
  String get transfer => 'স্থানান্তর';

  @override
  String get balance => 'ব্যালেন্স';

  @override
  String get category => 'ক্যাটাগরি';

  @override
  String get categories => 'ক্যাটাগরি';

  @override
  String get account => 'অ্যাকাউন্ট';

  @override
  String get accounts => 'অ্যাকাউন্ট';

  @override
  String get budget => 'বাজেট';

  @override
  String get budgets => 'বাজেট';

  @override
  String get report => 'রিপোর্ট';

  @override
  String get reports => 'রিপোর্ট';

  @override
  String get settings => 'সেটিংস';

  @override
  String get dashboard => 'ড্যাশবোর্ড';

  @override
  String get transactions => 'লেনদেন';

  @override
  String get home => 'হোম';

  @override
  String get amount => 'পরিমাণ';

  @override
  String get date => 'তারিখ';

  @override
  String get time => 'সময়';

  @override
  String get note => 'নোট';

  @override
  String get net => 'নিট';

  @override
  String get onboard1Title => 'খরচ করা প্রতিটি টাকার হিসাব রাখুন।';

  @override
  String get onboard1Body =>
      'ইন্টারনেট ছাড়াই কয়েক সেকেন্ডে আয় ও খরচ লিখে রাখুন।';

  @override
  String get onboard2Title => 'বাজেট ঠিক করুন, নিয়ন্ত্রণে থাকুন।';

  @override
  String get onboard2Body =>
      'প্রতিটি ক্যাটাগরির মাসিক সীমা দিন আর দেখুন আপনি কোথায় দাঁড়িয়ে আছেন।';

  @override
  String get onboard3Title => 'পরিষ্কার চার্ট ও রিপোর্ট।';

  @override
  String get onboard3Body => 'সহজ ও সৎ পরিসংখ্যানে নিজের খরচের অভ্যাস বুঝুন।';

  @override
  String get chooseLanguage => 'আপনার ভাষা বেছে নিন';

  @override
  String get chooseLanguageBody => 'সেটিংস থেকে যেকোনো সময় বদলাতে পারবেন।';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get getStarted => 'শুরু করুন';

  @override
  String get loginHeadline => 'কড়িতে স্বাগতম';

  @override
  String get loginSubtext =>
      'সাইন ইন করলে আপনার হিসাব নিরাপদ থাকবে আর সব ডিভাইসে সিঙ্ক হবে।';

  @override
  String get continueWithGoogle => 'Google দিয়ে চালিয়ে যান';

  @override
  String get signingIn => 'সাইন ইন হচ্ছে…';

  @override
  String get signInFailed => 'সাইন ইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get signInCancelled => 'সাইন ইন বাতিল করা হয়েছে।';

  @override
  String get legalPrefix => 'চালিয়ে গেলে আপনি আমাদের';

  @override
  String get termsOfService => 'শর্তাবলী';

  @override
  String get and => 'এবং';

  @override
  String get privacyPolicy => 'গোপনীয়তা নীতি';

  @override
  String get legalSuffix => 'মেনে নিচ্ছেন।';

  @override
  String greetingMorning(String name) {
    return 'শুভ সকাল, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'শুভ দুপুর, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'শুভ সন্ধ্যা, $name';
  }

  @override
  String get totalBalance => 'মোট ব্যালেন্স';

  @override
  String get netWorth => 'নিট সম্পদ';

  @override
  String get spendingByCategory => 'ক্যাটাগরি অনুযায়ী খরচ';

  @override
  String get recentTransactions => 'সাম্প্রতিক লেনদেন';

  @override
  String get noTransactionsTitle => 'এখনও কোনো লেনদেন নেই';

  @override
  String get noTransactionsBody => 'প্রথম আয় বা খরচ লিখতে + বোতামে চাপ দিন।';

  @override
  String get addTransaction => 'লেনদেন যোগ করুন';

  @override
  String get editTransaction => 'লেনদেন সম্পাদনা';

  @override
  String get selectCategory => 'ক্যাটাগরি বেছে নিন';

  @override
  String get selectAccount => 'অ্যাকাউন্ট বেছে নিন';

  @override
  String get fromAccount => 'কোথা থেকে';

  @override
  String get toAccount => 'কোথায়';

  @override
  String get notePlaceholder => 'কীসের জন্য ছিল?';

  @override
  String get errorAmountRequired => 'শূন্যের চেয়ে বড় পরিমাণ লিখুন।';

  @override
  String get errorCategoryRequired => 'একটি ক্যাটাগরি বেছে নিন।';

  @override
  String get errorAccountRequired => 'একটি অ্যাকাউন্ট বেছে নিন।';

  @override
  String get errorSameAccount =>
      'স্থানান্তরের জন্য দুটি আলাদা অ্যাকাউন্ট বেছে নিন।';

  @override
  String get transactionSaved => 'লেনদেন সংরক্ষণ হয়েছে';

  @override
  String get transactionDeleted => 'লেনদেন মুছে ফেলা হয়েছে';

  @override
  String get deleteTransactionTitle => 'এই লেনদেনটি মুছে ফেলবেন?';

  @override
  String get deleteTransactionBody =>
      'স্ন্যাকবার চলে গেলে এটি আর ফেরানো যাবে না।';

  @override
  String get filters => 'ফিল্টার';

  @override
  String get searchHint => 'নোট বা ক্যাটাগরি খুঁজুন';

  @override
  String get dateRange => 'তারিখের পরিসর';

  @override
  String get amountRange => 'পরিমাণের পরিসর';

  @override
  String get minAmount => 'সর্বনিম্ন';

  @override
  String get maxAmount => 'সর্বোচ্চ';

  @override
  String get type => 'ধরন';

  @override
  String get noResultsTitle => 'কিছু পাওয়া যায়নি';

  @override
  String get noResultsBody => 'ফিল্টার বা খোঁজার শব্দ বদলে দেখুন।';

  @override
  String selectedCount(int count) {
    return '$countটি নির্বাচিত';
  }

  @override
  String deleteSelectedTitle(int count) {
    return '$countটি লেনদেন মুছবেন?';
  }

  @override
  String get deleteSelectedBody =>
      'নির্বাচিত লেনদেনগুলো স্থায়ীভাবে মুছে যাবে।';

  @override
  String filtersActive(int count) {
    return '$countটি ফিল্টার চালু';
  }

  @override
  String get manageCategories => 'ক্যাটাগরি ব্যবস্থাপনা';

  @override
  String get newCategory => 'নতুন ক্যাটাগরি';

  @override
  String get editCategory => 'ক্যাটাগরি সম্পাদনা';

  @override
  String get categoryNameEn => 'নাম (ইংরেজি)';

  @override
  String get categoryNameBn => 'নাম (বাংলা)';

  @override
  String get icon => 'আইকন';

  @override
  String get color => 'রঙ';

  @override
  String get errorNameRequired => 'একটি নাম লিখুন।';

  @override
  String get categorySaved => 'ক্যাটাগরি সংরক্ষণ হয়েছে';

  @override
  String get categoryDeleted => 'ক্যাটাগরি মুছে ফেলা হয়েছে';

  @override
  String get deleteCategoryTitle => 'এই ক্যাটাগরিটি মুছে ফেলবেন?';

  @override
  String deleteCategoryBody(String name) {
    return '$name স্থায়ীভাবে মুছে যাবে। এটি আর ফেরানো যাবে না।';
  }

  @override
  String get categoryInUseTitle => 'ক্যাটাগরিটি ব্যবহৃত হচ্ছে';

  @override
  String categoryInUseBody(int count) {
    return '$countটি লেনদেনে এই ক্যাটাগরি ব্যবহার হয়েছে। মুছতে হলে সেগুলো অন্য ক্যাটাগরিতে সরান।';
  }

  @override
  String get moveTransactionsTo => 'লেনদেন সরান';

  @override
  String get moveAndDelete => 'সরিয়ে মুছে ফেলুন';

  @override
  String get defaultCannotDelete =>
      'ডিফল্ট ক্যাটাগরি সম্পাদনা করা যায়, তবে মোছা যায় না।';

  @override
  String get dragToReorder => 'ক্রম বদলাতে চেপে ধরে টানুন';

  @override
  String get noCategoriesTitle => 'এখানে কোনো ক্যাটাগরি নেই';

  @override
  String get noCategoriesBody => 'হিসাব গোছাতে একটি যোগ করুন।';

  @override
  String get manageAccounts => 'অ্যাকাউন্ট ব্যবস্থাপনা';

  @override
  String get newAccount => 'নতুন অ্যাকাউন্ট';

  @override
  String get editAccount => 'অ্যাকাউন্ট সম্পাদনা';

  @override
  String get accountName => 'অ্যাকাউন্টের নাম';

  @override
  String get accountType => 'অ্যাকাউন্টের ধরন';

  @override
  String get openingBalance => 'প্রারম্ভিক ব্যালেন্স';

  @override
  String get accountTypeCash => 'নগদ';

  @override
  String get accountTypeBank => 'ব্যাংক';

  @override
  String get accountTypeCard => 'কার্ড';

  @override
  String get accountTypeMobileWallet => 'মোবাইল ওয়ালেট';

  @override
  String get accountTypeSavings => 'সঞ্চয়';

  @override
  String get accountSaved => 'অ্যাকাউন্ট সংরক্ষণ হয়েছে';

  @override
  String get accountDeleted => 'অ্যাকাউন্ট মুছে ফেলা হয়েছে';

  @override
  String get deleteAccountTitle => 'এই অ্যাকাউন্টটি মুছে ফেলবেন?';

  @override
  String deleteAccountBody(String name) {
    return '$name স্থায়ীভাবে মুছে যাবে। এটি আর ফেরানো যাবে না।';
  }

  @override
  String get noAccountsTitle => 'এখনও কোনো অ্যাকাউন্ট নেই';

  @override
  String get noAccountsBody =>
      'ব্যালেন্সের হিসাব রাখতে একটি ওয়ালেট, ব্যাংক বা কার্ড যোগ করুন।';

  @override
  String get accountInUseTitle => 'অ্যাকাউন্টটি ব্যবহৃত হচ্ছে';

  @override
  String accountInUseBody(int count) {
    return '$countটি লেনদেনে এই অ্যাকাউন্ট ব্যবহার হয়েছে। মুছতে হলে সেগুলো অন্য অ্যাকাউন্টে সরান।';
  }

  @override
  String get moveTransactionsToAccount => 'লেনদেন সরান';

  @override
  String get lastAccountCannotDelete => 'কমপক্ষে একটি অ্যাকাউন্ট থাকতে হবে।';

  @override
  String get archived => 'আর্কাইভ করা';

  @override
  String get archive => 'আর্কাইভ';

  @override
  String get unarchive => 'আর্কাইভ থেকে ফেরান';

  @override
  String get showArchived => 'আর্কাইভ দেখান';

  @override
  String get newBudget => 'নতুন বাজেট';

  @override
  String get editBudget => 'বাজেট সম্পাদনা';

  @override
  String get budgetLimit => 'মাসিক সীমা';

  @override
  String get overallBudget => 'সামগ্রিক মাসিক বাজেট';

  @override
  String get overallBudgetShort => 'সামগ্রিক';

  @override
  String spentOfLimit(String spent, String limit) {
    return '$limit-এর মধ্যে $spent';
  }

  @override
  String remaining(String amount) {
    return '$amount বাকি';
  }

  @override
  String overBudgetBy(String amount) {
    return '$amount বেশি';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count দিন বাকি',
    );
    return '$_temp0';
  }

  @override
  String get copyLastMonth => 'গত মাসের বাজেট কপি করুন';

  @override
  String budgetsCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি বাজেট কপি হয়েছে',
      zero: 'কপি করার মতো বাজেট নেই',
    );
    return '$_temp0';
  }

  @override
  String get noBudgetsTitle => 'এই মাসের কোনো বাজেট নেই';

  @override
  String get noBudgetsBody =>
      'একটি ক্যাটাগরির সীমা ঠিক করুন, কড়ি হিসাব রাখবে।';

  @override
  String get budgetSaved => 'বাজেট সংরক্ষণ হয়েছে';

  @override
  String get budgetDeleted => 'বাজেট মুছে ফেলা হয়েছে';

  @override
  String get deleteBudgetTitle => 'এই বাজেটটি মুছে ফেলবেন?';

  @override
  String get deleteBudgetBody =>
      'সীমাটি মুছে যাবে। আপনার লেনদেনে কোনো প্রভাব পড়বে না।';

  @override
  String get errorLimitRequired => 'শূন্যের চেয়ে বড় সীমা লিখুন।';

  @override
  String get errorBudgetExists =>
      'এই ক্যাটাগরির জন্য আগে থেকেই একটি বাজেট আছে।';

  @override
  String get periodWeek => 'সপ্তাহ';

  @override
  String get periodMonth => 'মাস';

  @override
  String get periodYear => 'বছর';

  @override
  String get periodCustom => 'নিজের পছন্দ';

  @override
  String get expenseBreakdown => 'খরচের বিভাজন';

  @override
  String get incomeBreakdown => 'আয়ের বিভাজন';

  @override
  String get incomeVsExpense => 'আয় বনাম খরচ';

  @override
  String get dailyTrend => 'দৈনিক ধারা';

  @override
  String get categoryRanking => 'ক্যাটাগরি অনুযায়ী';

  @override
  String transactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি লেনদেন',
    );
    return '$_temp0';
  }

  @override
  String get noDataForPeriod => 'এই সময়ের কোনো তথ্য নেই';

  @override
  String get noDataForPeriodBody =>
      'অন্য সময় বেছে নিন বা একটি লেনদেন যোগ করুন।';

  @override
  String get lastSixMonths => 'গত ছয় মাস';

  @override
  String get profile => 'প্রোফাইল';

  @override
  String get preferences => 'পছন্দ';

  @override
  String get dataAndPrivacy => 'তথ্য';

  @override
  String get about => 'সম্পর্কে';

  @override
  String get language => 'ভাষা';

  @override
  String get banglaNumerals => 'বাংলা সংখ্যা';

  @override
  String get banglaNumeralsBody => '1234-এর বদলে ১২৩৪ দেখান।';

  @override
  String get theme => 'থিম';

  @override
  String get themeSystem => 'সিস্টেম';

  @override
  String get themeLight => 'উজ্জ্বল';

  @override
  String get themeDark => 'অন্ধকার';

  @override
  String get currency => 'মুদ্রা';

  @override
  String get selectCurrency => 'মুদ্রা বেছে নিন';

  @override
  String get firstDayOfWeek => 'সপ্তাহের প্রথম দিন';

  @override
  String get firstDayOfMonth => 'মাসের প্রথম দিন';

  @override
  String get firstDayOfMonthBody =>
      'আপনার বেতনের চক্র ১ তারিখে শুরু না হলে এটি কাজে লাগবে।';

  @override
  String dayOfMonth(int day) {
    return '$day তারিখ';
  }

  @override
  String get exportCsv => 'CSV ফাইলে তথ্য রপ্তানি';

  @override
  String get exportingCsv => 'ফাইল তৈরি হচ্ছে…';

  @override
  String get exportSuccess => 'রপ্তানি প্রস্তুত';

  @override
  String get exportFailed => 'তথ্য রপ্তানি করা যায়নি।';

  @override
  String get nothingToExport => 'রপ্তানি করার মতো কিছু নেই।';

  @override
  String get rateApp => 'অ্যাপটি রেট করুন';

  @override
  String get shareApp => 'কড়ি শেয়ার করুন';

  @override
  String get shareAppMessage =>
      'আমি কড়ি দিয়ে হিসাব রাখি — সহজ, দুই ভাষায় আর বিনামূল্যে।';

  @override
  String get aboutBody =>
      'কড়ি প্রতিদিনের ব্যবহারের জন্য একটি সহজ, ইন্টারনেট ছাড়াও চলে এমন হিসাব রাখার অ্যাপ।';

  @override
  String version(String version) {
    return 'সংস্করণ $version';
  }

  @override
  String get signOut => 'সাইন আউট';

  @override
  String get signOutTitle => 'কড়ি থেকে সাইন আউট করবেন?';

  @override
  String get signOutBody =>
      'আপনার তথ্য নিরাপদ থাকবে, আবার সাইন ইন করলেই ফিরে পাবেন।';

  @override
  String get deleteAccountAndData => 'অ্যাকাউন্ট ও সব তথ্য মুছে ফেলুন';

  @override
  String get deleteAccountStep1Title => 'আপনার অ্যাকাউন্ট মুছে ফেলবেন?';

  @override
  String get deleteAccountStep1Body =>
      'সব লেনদেন, ক্যাটাগরি, অ্যাকাউন্ট ও বাজেট স্থায়ীভাবে মুছে যাবে। এটি আর ফেরানো যাবে না।';

  @override
  String get deleteAccountStep2Title => 'আপনি কি একেবারে নিশ্চিত?';

  @override
  String get deleteAccountStep2Body => 'নিশ্চিত করতে নিচে DELETE লিখুন।';

  @override
  String get deleteConfirmationWord => 'DELETE';

  @override
  String get deleteAccountDone => 'আপনার অ্যাকাউন্ট ও তথ্য মুছে ফেলা হয়েছে।';

  @override
  String get reauthRequired =>
      'নিরাপত্তার জন্য অ্যাকাউন্ট মোছার আগে আবার সাইন ইন করুন।';

  @override
  String get monday => 'সোমবার';

  @override
  String get saturday => 'শনিবার';

  @override
  String get sunday => 'রবিবার';

  @override
  String get errorTitle => 'কিছু একটা ভুল হয়েছে';

  @override
  String get errorBody => 'এটি লোড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get errorPermissionDenied => 'এটি করার অনুমতি আপনার নেই।';

  @override
  String get offlineBanner => 'আপনি অফলাইনে — সংরক্ষিত তথ্য দেখানো হচ্ছে';

  @override
  String get loading => 'লোড হচ্ছে…';

  @override
  String get unknownCategory => 'ক্যাটাগরিহীন';

  @override
  String get unknownAccount => 'অজানা অ্যাকাউন্ট';

  @override
  String get thisMonth => 'এই মাস';

  @override
  String get today => 'আজ';

  @override
  String get yesterday => 'গতকাল';
}
