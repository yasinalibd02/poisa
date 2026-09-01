import 'package:flutter/widgets.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/context_x.dart';

/// Localised name for an account type. Kept in one place so the five labels
/// never drift between the editor, the list and the pickers.
String accountTypeLabel(BuildContext context, AccountType type) =>
    switch (type) {
      AccountType.cash => context.l10n.accountTypeCash,
      AccountType.bank => context.l10n.accountTypeBank,
      AccountType.card => context.l10n.accountTypeCard,
      AccountType.mobileWallet => context.l10n.accountTypeMobileWallet,
      AccountType.savings => context.l10n.accountTypeSavings,
    };
