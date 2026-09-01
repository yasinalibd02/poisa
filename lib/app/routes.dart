/// Every route path and name in one place, so navigation calls never contain
/// a raw string literal.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String reports = '/reports';
  static const String settings = '/settings';

  static const String transactionNew = '/transaction/new';
  static const String transactionEdit = '/transaction/edit';
  static const String categories = '/categories';
  static const String accounts = '/accounts';
  static const String budget = '/budget';

  /// Screens the auth guard lets an unauthenticated user reach.
  static const Set<String> publicRoutes = <String>{splash, onboarding, login};
}
