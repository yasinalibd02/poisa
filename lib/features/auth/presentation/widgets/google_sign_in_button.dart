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
                  const GoogleGlyph(),
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

/// Google's four-colour "G", on the white plate its brand guidelines require.
///
/// Drawn rather than shipped as an asset: the mark is four flat-filled shapes,
/// which `Path` states exactly, and that avoids both an image dependency and a
/// bitmap that would soften on high-density screens.
class GoogleGlyph extends StatelessWidget {
  const GoogleGlyph({super.key, this.size = 22});

  /// Diameter of the white plate. The mark is inset inside it.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(size * 0.66),
        painter: const _GoogleGPainter(),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  /// Google's official brand colours for the mark.
  static const Color _blue = Color(0xFF4285F4);
  static const Color _green = Color(0xFF34A853);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _red = Color(0xFFEA4335);

  /// The mark's own coordinate space; every path below is authored in it and
  /// scaled to the widget at paint time.
  static const double _viewBox = 48;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / _viewBox, size.height / _viewBox);

    final Paint paint = Paint()..isAntiAlias = true;

    // Right arm and crossbar.
    canvas.drawPath(
      _path((Path p) {
        p.moveTo(45.12, 24.5);
        p.cubicTo(45.12, 22.94, 44.98, 21.44, 44.72, 20);
        p.lineTo(24, 20);
        p.lineTo(24, 28.51);
        p.lineTo(35.84, 28.51);
        p.cubicTo(35.33, 31.26, 33.78, 33.59, 31.45, 35.15);
        p.lineTo(31.45, 40.67);
        p.lineTo(38.56, 40.67);
        p.cubicTo(42.72, 36.84, 45.12, 31.2, 45.12, 24.5);
      }),
      paint..color = _blue,
    );

    // Lower sweep.
    canvas.drawPath(
      _path((Path p) {
        p.moveTo(24, 46);
        p.cubicTo(29.94, 46, 34.92, 44.03, 38.56, 40.67);
        p.lineTo(31.45, 35.15);
        p.cubicTo(29.48, 36.47, 26.96, 37.25, 24, 37.25);
        p.cubicTo(18.27, 37.25, 13.42, 33.38, 11.69, 28.18);
        p.lineTo(4.34, 28.18);
        p.lineTo(4.34, 33.88);
        p.cubicTo(7.96, 41.07, 15.4, 46, 24, 46);
      }),
      paint..color = _green,
    );

    // Left edge.
    canvas.drawPath(
      _path((Path p) {
        p.moveTo(11.69, 28.18);
        p.cubicTo(11.25, 26.86, 11, 25.45, 11, 24);
        p.cubicTo(11, 22.55, 11.25, 21.14, 11.69, 19.82);
        p.lineTo(11.69, 14.12);
        p.lineTo(4.34, 14.12);
        p.cubicTo(2.85, 17.09, 2, 20.45, 2, 24);
        p.cubicTo(2, 27.55, 2.85, 30.91, 4.34, 33.88);
        p.close();
      }),
      paint..color = _yellow,
    );

    // Upper sweep.
    canvas.drawPath(
      _path((Path p) {
        p.moveTo(24, 10.75);
        p.cubicTo(27.23, 10.75, 30.13, 11.86, 32.41, 14.04);
        p.lineTo(38.72, 7.73);
        p.cubicTo(34.91, 4.18, 29.93, 2, 24, 2);
        p.cubicTo(15.4, 2, 7.96, 6.93, 4.34, 14.12);
        p.lineTo(11.69, 19.82);
        p.cubicTo(13.42, 14.62, 18.27, 10.75, 24, 10.75);
      }),
      paint..color = _red,
    );

    canvas.restore();
  }

  static Path _path(void Function(Path) build) {
    final Path path = Path();
    build(path);
    return path..close();
  }

  @override
  bool shouldRepaint(_GoogleGPainter oldDelegate) => false;
}
