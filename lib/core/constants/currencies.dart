/// A currency the user can pick in Settings.
class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
  });

  final String code;
  final String symbol;
  final String name;
}

/// Currency list offered in Settings. BDT is the default and stays first.
abstract final class Currencies {
  static const String defaultCode = 'BDT';

  static const List<CurrencyOption> all = <CurrencyOption>[
    CurrencyOption(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    CurrencyOption(code: 'USD', symbol: r'$', name: 'US Dollar'),
    CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound'),
    CurrencyOption(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    CurrencyOption(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee'),
    CurrencyOption(code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee'),
    CurrencyOption(code: 'NPR', symbol: 'रू', name: 'Nepalese Rupee'),
    CurrencyOption(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
    CurrencyOption(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    CurrencyOption(code: 'QAR', symbol: '﷼', name: 'Qatari Riyal'),
    CurrencyOption(code: 'KWD', symbol: 'د.ك', name: 'Kuwaiti Dinar'),
    CurrencyOption(code: 'OMR', symbol: '﷼', name: 'Omani Rial'),
    CurrencyOption(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
    CurrencyOption(code: 'SGD', symbol: r'S$', name: 'Singapore Dollar'),
    CurrencyOption(code: 'AUD', symbol: r'A$', name: 'Australian Dollar'),
    CurrencyOption(code: 'CAD', symbol: r'C$', name: 'Canadian Dollar'),
    CurrencyOption(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    CurrencyOption(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    CurrencyOption(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
    CurrencyOption(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
    CurrencyOption(code: 'THB', symbol: '฿', name: 'Thai Baht'),
  ];

  static CurrencyOption byCode(String? code) {
    return all.firstWhere(
      (CurrencyOption c) => c.code == code,
      orElse: () => all.first,
    );
  }

  static String symbolFor(String? code) => byCode(code).symbol;
}
