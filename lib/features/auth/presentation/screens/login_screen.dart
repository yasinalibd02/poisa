import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/kori_logo.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/legal_notice.dart';

/// Google-only sign-in. No email/password, no phone.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<void> signInState = ref.watch(signInControllerProvider);

    // Surfaces failures as a snackbar; a cancelled sheet is not an error and
    // never reaches here.
    ref.listen<AsyncValue<void>>(signInControllerProvider, (
      AsyncValue<void>? previous,
      AsyncValue<void> next,
    ) {
      final Object? error = next.error;
      if (error == null) return;
      AppSnack.error(context, AppFailure.from(error).localizedMessage(context.l10n));
    });

    return Scaffold(
      body: BrandBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
            child: Column(
              children: <Widget>[
                const Spacer(flex: 3),
                KoriWordmark(
                  title: context.l10n.appName,
                  subtitle: context.l10n.tagline,
                  logoSize: 104,
                ),
                const Spacer(flex: 2),
                Text(
                  context.l10n.loginHeadline,
                  textAlign: TextAlign.center,
                  style: context.texts.headlineSmall,
                ),
                AppSizes.gapMd,
                Text(
                  context.l10n.loginSubtext,
                  textAlign: TextAlign.center,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                AppSizes.gapXxl,
                GoogleSignInButton(
                  loading: signInState.isLoading,
                  onPressed: () async {
                    final bool signedIn = await ref
                        .read(signInControllerProvider.notifier)
                        .signInWithGoogle();
                    if (signedIn && context.mounted) {
                      context.go(AppRoutes.dashboard);
                    }
                  },
                ),
                const Spacer(flex: 2),
                const LegalNotice(),
                AppSizes.gapLg,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
