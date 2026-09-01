import 'package:flutter_test/flutter_test.dart';
import 'package:kori/core/utils/money_formatter.dart';
import 'package:kori/core/utils/number_localizer.dart';
import 'package:kori/core/utils/validators.dart';

void main() {
  group('NumberLocalizer', () {
    test('converts between Western and Bengali digits', () {
      expect(NumberLocalizer.toBengali('1,234.50'), '১,২৩৪.৫০');
      expect(NumberLocalizer.toWestern('১২৩৪'), '1234');
    });

    test('leaves non-digit characters untouched', () {
      expect(NumberLocalizer.toBengali('৳ 1,200'), '৳ ১,২০০');
    });
  });

  group('MoneyFormatter', () {
    final MoneyFormatter english = MoneyFormatter(
      localeName: 'en',
      currencySymbol: '৳',
      useBanglaNumerals: false,
    );

    test('omits decimals for whole amounts', () {
      expect(english.format(1200), '৳1,200');
    });

    test('shows two decimals when the amount has a fraction', () {
      expect(english.format(1234.5), '৳1,234.50');
    });

    test('signs amounts for transaction rows', () {
      expect(english.formatSigned(1200), '+৳1,200');
      expect(english.formatSigned(-350), '−৳350');
    });

    test('honours the Bangla numeral preference', () {
      final MoneyFormatter bangla = MoneyFormatter(
        localeName: 'en',
        currencySymbol: '৳',
        useBanglaNumerals: true,
      );
      expect(bangla.format(1200), '৳১,২০০');
    });
  });

  group('Validators', () {
    test('parses amounts containing Bengali digits and separators', () {
      expect(Validators.parseAmount('১,২০০'), 1200);
      expect(Validators.parseAmount('1,234.5'), 1234.5);
    });

    test('rejects blank and malformed input', () {
      expect(Validators.parseAmount(''), isNull);
      expect(Validators.parseAmount('abc'), isNull);
      expect(Validators.isPositiveAmount('0'), isFalse);
    });

    test('rounds money to two decimals', () {
      expect(Validators.roundMoney(0.1 + 0.2), 0.3);
    });
  });
}
