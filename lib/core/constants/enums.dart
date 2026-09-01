/// Money movement kinds. Stored as the lowercase enum name.
enum TransactionType {
  income,
  expense,
  transfer;

  static TransactionType fromName(String? value) => switch (value) {
    'income' => TransactionType.income,
    'transfer' => TransactionType.transfer,
    _ => TransactionType.expense,
  };

  bool get isTransfer => this == TransactionType.transfer;
  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;
}

/// Categories exist for income or expense only — transfers move money between
/// accounts and are deliberately category-less.
enum CategoryType {
  income,
  expense;

  static CategoryType fromName(String? value) =>
      value == 'income' ? CategoryType.income : CategoryType.expense;

  TransactionType get asTransactionType =>
      this == CategoryType.income
      ? TransactionType.income
      : TransactionType.expense;
}

enum AccountType {
  cash,
  bank,
  card,
  mobileWallet,
  savings;

  static AccountType fromName(String? value) => switch (value) {
    'bank' => AccountType.bank,
    'card' => AccountType.card,
    'mobileWallet' => AccountType.mobileWallet,
    'savings' => AccountType.savings,
    _ => AccountType.cash,
  };

  /// Default icon key from `AppIcons.catalogue`.
  String get defaultIconKey => switch (this) {
    AccountType.cash => 'cash',
    AccountType.bank => 'bank',
    AccountType.card => 'card',
    AccountType.mobileWallet => 'mobile_wallet',
    AccountType.savings => 'savings',
  };
}
