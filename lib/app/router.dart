import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/budget/presentation/screens/budget_screen.dart';
import '../features/categories/presentation/screens/categories_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/loans/presentation/screens/loans_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/settings/data/app_settings.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/transactions/data/transaction_model.dart';
import '../features/transactions/presentation/screens/transaction_editor_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';
import 'app_shell.dart';
import 'routes.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

/// Re-runs `redirect` whenever the session or the onboarding flag changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen<AsyncValue<Object?>>(
      authStateProvider,
      (AsyncValue<Object?>? previous, AsyncValue<Object?> next) =>
          notifyListeners(),
    );
    ref.listen<bool>(
      settingsProvider.select((AppSettings s) => s.onboardingDone),
      (bool? previous, bool next) => notifyListeners(),
    );
  }
}

final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final _RouterRefresh refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: false,

    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.matchedLocation;

      // The splash screen owns its own exit: it plays the logo animation and
      // then routes using exactly the rules below.
      if (location == AppRoutes.splash) return null;

      final bool onboardingDone = ref.read(settingsProvider).onboardingDone;
      final bool signedIn = ref.read(currentUserProvider) != null;

      if (!onboardingDone) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }
      if (!signedIn) {
        return location == AppRoutes.login ? null : AppRoutes.login;
      }
      if (AppRoutes.publicRoutes.contains(location)) {
        return AppRoutes.dashboard;
      }
      return null;
    },

    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _fade(state, const DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _fade(state, const TransactionsScreen()),
          ),
          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _fade(state, const ReportsScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _fade(state, const SettingsScreen()),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.transactionNew,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) =>
            TransactionEditorScreen(
          initialType: state.extra is TransactionModel
              ? null
              : state.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.transactionEdit,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) =>
            TransactionEditorScreen(existing: state.extra as TransactionModel?),
      ),
      GoRoute(
        path: AppRoutes.categories,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) =>
            const CategoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.accounts,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) =>
            const AccountsScreen(),
      ),
      GoRoute(
        path: AppRoutes.budget,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) =>
            const BudgetScreen(),
      ),
      GoRoute(
        path: AppRoutes.loans,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) =>
            const LoansScreen(),
      ),
    ],
  );
});

/// Tab switches cross-fade rather than slide, which would fight the bottom
/// navigation bar's own motion.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) => FadeTransition(opacity: animation, child: child),
  );
}
