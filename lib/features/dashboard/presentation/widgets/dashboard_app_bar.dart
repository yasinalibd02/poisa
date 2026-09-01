import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../auth/data/user_model.dart';
import '../../../auth/presentation/providers/user_providers.dart';

/// Greeting plus the user's Google avatar, which opens Settings.
class DashboardAppBar extends ConsumerWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserModel? user = ref.watch(userDocProvider).valueOrNull;
    final String name = user?.firstName ?? '';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.md,
          AppSizes.screenPadding,
          AppSizes.sm,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _greeting(context, name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(context.l10n.tagline, style: context.texts.bodySmall),
                ],
              ),
            ),
            AppSizes.hGapMd,
            _Avatar(user: user, onTap: () => context.go(AppRoutes.settings)),
          ],
        ),
      ),
    );
  }

  String _greeting(BuildContext context, String name) {
    final int hour = DateTime.now().hour;
    if (hour < 12) return context.l10n.greetingMorning(name);
    if (hour < 17) return context.l10n.greetingAfternoon(name);
    return context.l10n.greetingEvening(name);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.onTap});

  final UserModel? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? photo = user?.photoUrl;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: context.colors.primary.withValues(alpha: 0.14),
        foregroundImage: (photo != null && photo.isNotEmpty)
            ? NetworkImage(photo)
            : null,
        // Initials show while the photo loads, and stay if it never does.
        child: Text(
          user?.initials ?? '',
          style: context.texts.titleSmall?.copyWith(
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }
}
