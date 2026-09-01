import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_sizes.dart';
import '../extensions/context_x.dart';
import '../services/connectivity_provider.dart';

/// Slim banner that appears under the app bar when Firestore has no
/// connection. Data stays readable from the offline cache, so this informs
/// rather than blocks.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;

    return AnimatedSize(
      duration: AppSizes.normal,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: isOnline
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              color: context.colors.secondaryContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 16,
                    color: context.colors.onSecondaryContainer,
                  ),
                  AppSizes.hGapSm,
                  Flexible(
                    child: Text(
                      context.l10n.offlineBanner,
                      textAlign: TextAlign.center,
                      style: context.texts.labelMedium?.copyWith(
                        color: context.colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
