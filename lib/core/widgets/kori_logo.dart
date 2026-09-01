import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The Kori mark: a rounded-square coin with a leaf notch and a "K" cut clean
/// through it, filled with the teal brand gradient.
///
/// Painted rather than shipped as a raster so it stays crisp at every size and
/// costs no asset decode on the splash screen.
class KoriLogo extends StatelessWidget {
  const KoriLogo({super.key, this.size = 96, this.showShadow = true});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: showShadow
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: size * 0.22,
                    offset: Offset(0, size * 0.08),
                  ),
                ]
              : null,
        ),
        child: CustomPaint(painter: _KoriLogoPainter(), size: Size.square(size)),
      ),
    );
  }
}

class _KoriLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Rect bounds = Offset.zero & size;
    final RRect body = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(s * 0.28),
    );

    // Everything is drawn into one layer so the "K" can be punched out of the
    // gradient with dstOut rather than faked with a background-coloured glyph.
    canvas.saveLayer(bounds, Paint());

    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primaryLight, AppColors.primaryDark],
        ).createShader(bounds),
    );

    // Leaf notch: a soft crescent lifted out of the top-right corner, which is
    // what makes the coin read as a leaf as well.
    canvas.drawCircle(
      Offset(s * 1.02, s * -0.02),
      s * 0.34,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    // Leaf vein.
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.74, s * 0.26)
        ..quadraticBezierTo(s * 0.88, s * 0.16, s * 0.96, s * 0.04),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34)
        ..strokeWidth = s * 0.035
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    _punchOutK(canvas, s);

    canvas.restore();
  }

  /// The "K", drawn as three strokes and removed from the layer.
  void _punchOutK(Canvas canvas, double s) {
    final Paint cut = Paint()
      ..blendMode = BlendMode.dstOut
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.105
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double top = s * 0.28;
    final double bottom = s * 0.72;
    final double left = s * 0.34;
    final double right = s * 0.70;
    final double waist = s * 0.505;

    canvas
      ..drawLine(Offset(left, top), Offset(left, bottom), cut)
      ..drawLine(Offset(right, top), Offset(left + s * 0.02, waist), cut)
      ..drawLine(Offset(left + s * 0.02, waist), Offset(right, bottom), cut);
  }

  @override
  bool shouldRepaint(covariant _KoriLogoPainter oldDelegate) => false;
}

/// Logo plus wordmark, used on the splash and login screens.
class KoriWordmark extends StatelessWidget {
  const KoriWordmark({
    super.key,
    required this.title,
    this.subtitle,
    this.logoSize = 96,
  });

  final String title;
  final String? subtitle;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        KoriLogo(size: logoSize),
        SizedBox(height: logoSize * 0.22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 6),
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
