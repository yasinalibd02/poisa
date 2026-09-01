import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/widgets/kori_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Plays the logo animation while the session and onboarding flag are
/// resolved, then routes on. It owns its own exit — the router's redirect
/// deliberately leaves `/splash` alone.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppSizes.splash,
  );

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
  );
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.45, curve: Curves.easeOut),
  );
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Waits for both the animation and the first auth event, so the app never
  /// flashes the login screen at a user who is already signed in.
  Future<void> _resolveDestination() async {
    final Future<void> animation = _controller.forward().orCancel.catchError(
      (_) {},
    );
    final Future<Object?> session = ref
        .read(authStateProvider.future)
        .catchError((_) => null);

    await Future.wait<void>(<Future<void>>[
      animation,
      session.then((_) {}),
    ]);

    if (!mounted) return;

    final bool onboardingDone = ref.read(settingsProvider).onboardingDone;
    final bool signedIn = ref.read(currentUserProvider) != null;

    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
    } else if (!signedIn) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackdrop(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: 0.7 + (_logoScale.value * 0.3),
                      child: const KoriLogo(size: 112),
                    ),
                  ),
                  AppSizes.gapXl,
                  Opacity(
                    opacity: _textFade.value,
                    child: Column(
                      children: <Widget>[
                        Text(
                          context.l10n.appName,
                          style: context.texts.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        AppSizes.gapXs,
                        Text(
                          context.l10n.tagline,
                          style: context.texts.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
