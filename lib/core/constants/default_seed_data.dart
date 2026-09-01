import '../../features/categories/data/category_model.dart';
import 'enums.dart';

/// A category template used only for first-login seeding.
class SeedCategory {
  const SeedCategory({
    required this.nameEn,
    required this.nameBn,
    required this.type,
    required this.icon,
    required this.colorHex,
  });

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
  /// Name of the single starter account, per UI language.
  static String cashAccountName(String languageCode) =>
      languageCode == 'bn' ? 'নগদ' : 'Cash';

  static const List<SeedCategory> expenseCategories = <SeedCategory>[
    SeedCategory(
      nameEn: 'Food',
      nameBn: 'খাবার',
      type: CategoryType.expense,
      icon: 'restaurant',
      colorHex: '#E0553C',
    ),
    SeedCategory(
      nameEn: 'Transport',
      nameBn: 'যাতায়াত',
      type: CategoryType.expense,
      icon: 'directions_bus',
      colorHex: '#3D8FD9',
    ),
    SeedCategory(
      nameEn: 'Shopping',
      nameBn: 'কেনাকাটা',
      type: CategoryType.expense,
      icon: 'shopping_bag',
      colorHex: '#B6478F',
    ),
    SeedCategory(
      nameEn: 'Bills',
      nameBn: 'বিল',
      type: CategoryType.expense,
      icon: 'receipt',
      colorHex: '#EF8B3C',
    ),
    SeedCategory(
      nameEn: 'Rent',
      nameBn: 'বাসা ভাড়া',
      type: CategoryType.expense,
      icon: 'home',
      colorHex: '#8D6E4F',
    ),
    SeedCategory(
      nameEn: 'Health',
      nameBn: 'স্বাস্থ্য',
      type: CategoryType.expense,
      icon: 'health',
      colorHex: '#D94F6E',
    ),
    SeedCategory(
      nameEn: 'Education',
      nameBn: 'শিক্ষা',
      type: CategoryType.expense,
      icon: 'school',
      colorHex: '#5B6CD9',
    ),
    SeedCategory(
      nameEn: 'Entertainment',
      nameBn: 'বিনোদন',
      type: CategoryType.expense,
      icon: 'movie',
      colorHex: '#8055C9',
    ),
    SeedCategory(
      nameEn: 'Family',
      nameBn: 'পরিবার',
      type: CategoryType.expense,
      icon: 'family',
      colorHex: '#29A9BF',
    ),
    SeedCategory(
      nameEn: 'Mobile / Internet',
      nameBn: 'মোবাইল/ইন্টারনেট',
      type: CategoryType.expense,
      icon: 'wifi',
      colorHex: '#3FA98F',
    ),
    SeedCategory(
      nameEn: 'Gift',
      nameBn: 'উপহার',
      type: CategoryType.expense,
      icon: 'gift',
      colorHex: '#F2A93B',
    ),
    SeedCategory(
      nameEn: 'Other',
      nameBn: 'অন্যান্য',
      type: CategoryType.expense,
      icon: 'more',
      colorHex: '#6B7A87',
    ),
  ];

  static const List<SeedCategory> incomeCategories = <SeedCategory>[
    SeedCategory(
      nameEn: 'Salary',
      nameBn: 'বেতন',
      type: CategoryType.income,
      icon: 'salary',
      colorHex: '#2E9E5B',
    ),
    SeedCategory(
      nameEn: 'Business',
      nameBn: 'ব্যবসা',
      type: CategoryType.income,
      icon: 'business',
      colorHex: '#1B7F6B',
    ),
    SeedCategory(
      nameEn: 'Freelance',
      nameBn: 'ফ্রিল্যান্স',
      type: CategoryType.income,
      icon: 'freelance',
      colorHex: '#6FBF4B',
    ),
    SeedCategory(
      nameEn: 'Bonus',
      nameBn: 'বোনাস',
      type: CategoryType.income,
      icon: 'bonus',
      colorHex: '#F2A93B',
    ),
    SeedCategory(
      nameEn: 'Investment',
      nameBn: 'বিনিয়োগ',
      type: CategoryType.income,
      icon: 'investment',
      colorHex: '#3D8FD9',
    ),
    SeedCategory(
      nameEn: 'Gift',
      nameBn: 'উপহার',
      type: CategoryType.income,
      icon: 'gift',
      colorHex: '#B6478F',
    ),
    SeedCategory(
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
}
