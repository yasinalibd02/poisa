import '../../features/categories/data/category_model.dart';
import 'enums.dart';

/// A category template used only for first-login seeding.
class SeedCategory {
  const SeedCategory({
    required this.key,
    required this.nameEn,
    required this.nameBn,
    required this.type,
    required this.icon,
    required this.colorHex,
  });

  /// Stable, unique-per-type id suffix used as the Firestore document id, so
  /// re-running the seed (e.g. a bootstrap race on first sign-in) overwrites
  /// the same document instead of creating a duplicate category.
  final String key;

  final String nameEn;
  final String nameBn;
  final CategoryType type;
  final String icon;
  final String colorHex;

  CategoryModel toModel({required int sortOrder, required DateTime now}) {
    return CategoryModel(
      id: '',
      nameEn: nameEn,
      nameBn: nameBn,
      type: type,
      icon: icon,
      colorHex: colorHex,
      isDefault: true,
      sortOrder: sortOrder,
      createdAt: now,
    );
  }
}

/// Seeded once, on the user's first sign-in. These are marked `isDefault`, so
/// they can be renamed and recoloured but not deleted.
abstract final class DefaultSeedData {
  /// The four lending categories, by seed key. The Loans screen recognises a
  /// transaction purely by which of these its category is, so these keys are
  /// part of the data contract and must not be renamed — the visible names
  /// are the user's to change.
  ///
  /// Money out that someone now owes back.
  static const String loanGivenKey = 'expense_loan_given';

  /// Money out that settles something *you* borrowed.
  static const String loanRepaidKey = 'expense_loan_repaid';

  /// Money in that you now owe back.
  static const String loanTakenKey = 'income_loan_taken';

  /// Money in that settles something you lent out.
  static const String loanRecoveredKey = 'income_loan_recovered';

  /// Firestore document id for a seeded category key.
  static String docIdFor(String key) => 'seed_$key';

  /// Category document ids that make up the lending ledger.
  static final String loanGivenId = docIdFor(loanGivenKey);
  static final String loanRepaidId = docIdFor(loanRepaidKey);
  static final String loanTakenId = docIdFor(loanTakenKey);
  static final String loanRecoveredId = docIdFor(loanRecoveredKey);

  static final Set<String> loanCategoryIds = <String>{
    loanGivenId,
    loanRepaidId,
    loanTakenId,
    loanRecoveredId,
  };

  /// Name of the single starter account, per UI language.
  static String cashAccountName(String languageCode) =>
      languageCode == 'bn' ? 'নগদ' : 'Cash';

  static const List<SeedCategory> expenseCategories = <SeedCategory>[
    SeedCategory(
      key: 'expense_food',
      nameEn: 'Food',
      nameBn: 'খাবার',
      type: CategoryType.expense,
      icon: 'restaurant',
      colorHex: '#E0553C',
    ),
    SeedCategory(
      key: 'expense_transport',
      nameEn: 'Transport',
      nameBn: 'যাতায়াত',
      type: CategoryType.expense,
      icon: 'directions_bus',
      colorHex: '#3D8FD9',
    ),
    SeedCategory(
      key: 'expense_shopping',
      nameEn: 'Shopping',
      nameBn: 'কেনাকাটা',
      type: CategoryType.expense,
      icon: 'shopping_bag',
      colorHex: '#B6478F',
    ),
    SeedCategory(
      key: 'expense_bills',
      nameEn: 'Bills',
      nameBn: 'বিল',
      type: CategoryType.expense,
      icon: 'receipt',
      colorHex: '#EF8B3C',
    ),
    SeedCategory(
      key: 'expense_rent',
      nameEn: 'Rent',
      nameBn: 'বাসা ভাড়া',
      type: CategoryType.expense,
      icon: 'home',
      colorHex: '#8D6E4F',
    ),
    SeedCategory(
      key: 'expense_health',
      nameEn: 'Health',
      nameBn: 'স্বাস্থ্য',
      type: CategoryType.expense,
      icon: 'health',
      colorHex: '#D94F6E',
    ),
    SeedCategory(
      key: 'expense_education',
      nameEn: 'Education',
      nameBn: 'শিক্ষা',
      type: CategoryType.expense,
      icon: 'school',
      colorHex: '#5B6CD9',
    ),
    SeedCategory(
      key: 'expense_entertainment',
      nameEn: 'Entertainment',
      nameBn: 'বিনোদন',
      type: CategoryType.expense,
      icon: 'movie',
      colorHex: '#8055C9',
    ),
    SeedCategory(
      key: 'expense_family',
      nameEn: 'Family',
      nameBn: 'পরিবার',
      type: CategoryType.expense,
      icon: 'family',
      colorHex: '#29A9BF',
    ),
    SeedCategory(
      key: 'expense_mobile_internet',
      nameEn: 'Mobile / Internet',
      nameBn: 'মোবাইল/ইন্টারনেট',
      type: CategoryType.expense,
      icon: 'wifi',
      colorHex: '#3FA98F',
    ),
    SeedCategory(
      key: 'expense_gift',
      nameEn: 'Gift',
      nameBn: 'উপহার',
      type: CategoryType.expense,
      icon: 'gift',
      colorHex: '#F2A93B',
    ),
    SeedCategory(
      key: loanGivenKey,
      nameEn: 'Loan Given',
      nameBn: 'ধার দিয়েছি',
      type: CategoryType.expense,
      icon: 'loan_given',
      colorHex: '#5B6CD9',
    ),
    SeedCategory(
      key: loanRepaidKey,
      nameEn: 'Loan Repaid',
      nameBn: 'ধার শোধ করেছি',
      type: CategoryType.expense,
      icon: 'handshake',
      colorHex: '#44514F',
    ),
    SeedCategory(
      key: 'expense_other',
      nameEn: 'Other',
      nameBn: 'অন্যান্য',
      type: CategoryType.expense,
      icon: 'more',
      colorHex: '#6B7A87',
    ),
  ];

  static const List<SeedCategory> incomeCategories = <SeedCategory>[
    SeedCategory(
      key: 'income_salary',
      nameEn: 'Salary',
      nameBn: 'বেতন',
      type: CategoryType.income,
      icon: 'salary',
      colorHex: '#2E9E5B',
    ),
    SeedCategory(
      key: 'income_business',
      nameEn: 'Business',
      nameBn: 'ব্যবসা',
      type: CategoryType.income,
      icon: 'business',
      colorHex: '#1B7F6B',
    ),
    SeedCategory(
      key: 'income_freelance',
      nameEn: 'Freelance',
      nameBn: 'ফ্রিল্যান্স',
      type: CategoryType.income,
      icon: 'freelance',
      colorHex: '#6FBF4B',
    ),
    SeedCategory(
      key: 'income_bonus',
      nameEn: 'Bonus',
      nameBn: 'বোনাস',
      type: CategoryType.income,
      icon: 'bonus',
      colorHex: '#F2A93B',
    ),
    SeedCategory(
      key: 'income_investment',
      nameEn: 'Investment',
      nameBn: 'বিনিয়োগ',
      type: CategoryType.income,
      icon: 'investment',
      colorHex: '#3D8FD9',
    ),
    SeedCategory(
      key: 'income_gift',
      nameEn: 'Gift',
      nameBn: 'উপহার',
      type: CategoryType.income,
      icon: 'gift',
      colorHex: '#B6478F',
    ),
    SeedCategory(
      key: loanTakenKey,
      nameEn: 'Loan Taken',
      nameBn: 'ধার নিয়েছি',
      type: CategoryType.income,
      icon: 'loan_taken',
      colorHex: '#EF8B3C',
    ),
    SeedCategory(
      key: loanRecoveredKey,
      nameEn: 'Loan Recovered',
      nameBn: 'ধার ফেরত পেয়েছি',
      type: CategoryType.income,
      icon: 'handshake',
      colorHex: '#29A9BF',
    ),
    SeedCategory(
      key: 'income_other',
      nameEn: 'Other',
      nameBn: 'অন্যান্য',
      type: CategoryType.income,
      icon: 'more',
      colorHex: '#6B7A87',
    ),
  ];

  static List<SeedCategory> get all => <SeedCategory>[
    ...expenseCategories,
    ...incomeCategories,
  ];

  /// Defaults introduced after the first release, which accounts seeded before
  /// it will not have. `UserRepository.reconcileDefaultCategories` backfills
  /// exactly these and nothing else — an older default is left alone even if
  /// its name no longer matches this file, because the user is free to rename
  /// their categories and a "missing" one is far more likely to be a renamed
  /// one than a genuinely absent one.
  ///
  /// Append to this list when adding a default in a future release.
  static List<SeedCategory> get lateAdditions => all
      .where(
        (SeedCategory seed) => <String>{
          loanGivenKey,
          loanRepaidKey,
          loanTakenKey,
          loanRecoveredKey,
        }.contains(seed.key),
      )
      .toList(growable: false);
}
