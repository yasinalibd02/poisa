import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/utils/calculator.dart';

/// The amount keypad: digits plus the four operations, so amounts can be added
/// up ("240 + 60") without leaving the form.
///
/// Its action keys are tinted with the *secondary* colour, not the primary
/// one. `=` and Save sit one above the other, and in the same green they read
/// as the same button — people were pressing `=` expecting the row to be
/// saved. Amber keeps the only primary-coloured control on the screen the one
/// that actually commits the transaction.
///
/// The five rows divide whatever height the parent gives, rather than each key
/// standing at a fixed height. That is what lets the editor hand the keypad a
/// quarter of the screen and keep the rest for the category, account and note
/// fields, with no scrolling.
class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({
    super.key,
    required this.onDigit,
    required this.onDecimal,
    required this.onOperation,
    required this.onEquals,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDecimal;
  final ValueChanged<CalcOp> onOperation;
  final VoidCallback onEquals;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _row(<Widget>[
          _digit('7'),
          _digit('8'),
          _digit('9'),
          _op(context, CalcOp.divide),
        ]),
        _row(<Widget>[
          _digit('4'),
          _digit('5'),
          _digit('6'),
          _op(context, CalcOp.multiply),
        ]),
        _row(<Widget>[
          _digit('1'),
          _digit('2'),
          _digit('3'),
          _op(context, CalcOp.subtract),
        ]),
        _row(<Widget>[
          _KeypadKey(label: '.', onTap: onDecimal),
          _digit('0'),
          _KeypadKey(
            icon: CupertinoIcons.delete_left,
            onTap: onBackspace,
            onLongPress: onClear,
          ),
          _op(context, CalcOp.add),
        ]),
        _row(<Widget>[
          _KeypadKey(label: 'C', onTap: onClear, muted: true),
          _KeypadKey(
            label: '=',
            onTap: onEquals,
            flex: 3,
            background: context.colors.secondary,
            foreground: context.colors.onSecondary,
          ),
        ]),
      ],
    );
  }

  /// Each row takes an equal share of the available height, and `stretch`
  /// passes that share down so the keys themselves grow and shrink with it.
  Widget _row(List<Widget> keys) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: keys,
      ),
    ),
  );

  Widget _digit(String value) =>
      _KeypadKey(label: value, onTap: () => onDigit(value));

  Widget _op(BuildContext context, CalcOp op) => _KeypadKey(
    label: op.symbol,
    onTap: () => onOperation(op),
    background: context.colors.secondary.withValues(alpha: 0.14),
    foreground: context.isDark
        ? context.colors.secondary
        : AppColors.accentDark,
  );
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    this.label,
    this.icon,
    required this.onTap,
    this.onLongPress,
    this.flex = 1,
    this.background,
    this.foreground,
    this.muted = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int flex;
  final Color? background;
  final Color? foreground;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final Color fg =
        foreground ??
        (muted ? context.colors.onSurfaceVariant : context.colors.onSurface);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
        child: Material(
          color: background ??
              (context.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.035)),
          borderRadius: AppSizes.brMd,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            onLongPress: onLongPress == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    onLongPress!();
                  },
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 20, color: fg)
                  : Text(
                      label ?? '',
                      style: context.texts.titleMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
