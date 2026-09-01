import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';

/// "Continue with Google" with an inline loading state, so the button itself
/// reports progress instead of a blocking overlay.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: AppSizes.fast,
        child: loading
            ? Row(
                key: const ValueKey<String>('loading'),
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.onPrimary,
                    ),
                  ),
                  AppSizes.hGapMd,
                  Flexible(
                    child: Text(
                      context.l10n.signingIn,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Row(
                key: const ValueKey<String>('idle'),
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const _GoogleGlyph(),
                  AppSizes.hGapMd,
                  Flexible(
                    child: Text(
                      context.l10n.continueWithGoogle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The Google "G" drawn as four arcs, so no image asset is needed.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
          height: 1.1,
        ),
      ),
    );
  }
}
