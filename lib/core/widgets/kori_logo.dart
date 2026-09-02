import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The Poisa app mark, rendered from `assets/images/logo.png` so every screen
/// shows exactly the same artwork as the launcher icon.
class KoriLogo extends StatelessWidget {
  const KoriLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Logo plus tagline, used on the splash and login screens. The "poisa"
/// wordmark is already part of the logo art, so only the tagline is drawn
/// underneath.
class KoriWordmark extends StatelessWidget {
  const KoriWordmark({
    super.key,
    this.subtitle,
    this.logoSize = 96,
  });

  final String? subtitle;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        KoriLogo(size: logoSize),
        if (subtitle != null) ...<Widget>[
          SizedBox(height: logoSize * 0.14),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Decorative background blobs used behind onboarding and login.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color tint = Theme.of(context).colorScheme.primary;
    return Stack(
      children: <Widget>[
        Positioned(
          top: -120,
          right: -80,
          child: _Blob(color: tint.withValues(alpha: 0.10), size: 260),
        ),
        Positioned(
          bottom: -140,
          left: -100,
          child: _Blob(
            color: AppColors.accent.withValues(alpha: 0.10),
            size: 300,
          ),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 6,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.42),
        ),
      ),
    );
  }
}
