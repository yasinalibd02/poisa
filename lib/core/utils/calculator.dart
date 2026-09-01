import 'package:flutter/foundation.dart';

/// The four operations offered by the amount keypad.
enum CalcOp {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const CalcOp(this.symbol);

  final String symbol;
}

/// An immutable chain calculator — the "type 250 + 40 =" behaviour people
/// expect from a phone keypad, not a full expression parser.
///
/// Pure and side-effect free, so the editor screen holds one of these in
/// state and the whole thing is unit-testable without a widget tree.
@immutable
class CalculatorState {
  const CalculatorState({
    this.entry = '0',
    this.accumulator,
    this.operation,
    this.startNewEntry = true,
  });

  /// The digits currently being typed.
  final String entry;

  /// The left-hand side of a pending operation.
  final double? accumulator;

  final CalcOp? operation;

  /// True when the next digit should replace [entry] rather than append.
  final bool startNewEntry;

  static const int _maxDigits = 12;

  double get value => double.tryParse(entry) ?? 0;

  bool get hasPendingOperation => operation != null;

  /// `250 +` — shown above the amount so the pending step stays visible.
  String get pendingLabel =>
      operation == null ? '' : '${_trim(accumulator ?? 0)} ${operation!.symbol}';

  bool get isEmpty => entry == '0' && accumulator == null && operation == null;

  CalculatorState digit(String d) {
    if (startNewEntry) {
      return _copy(entry: d == '.' ? '0.' : d, startNewEntry: false);
    }
    final String digitsOnly = entry.replaceAll('.', '').replaceAll('-', '');
    if (digitsOnly.length >= _maxDigits) return this;
    if (entry == '0' && d != '.') return _copy(entry: d);
    return _copy(entry: entry + d);
  }

  CalculatorState decimalPoint() {
    if (startNewEntry) return _copy(entry: '0.', startNewEntry: false);
    if (entry.contains('.')) return this;
    return _copy(entry: '$entry.');
  }

  /// Applies a pending operation (if any) and queues [op].
  CalculatorState applyOperation(CalcOp op) {
    if (operation != null && !startNewEntry) {
      final double result = _evaluate(accumulator ?? 0, value, operation!);
      return CalculatorState(
        entry: _trim(result),
        accumulator: result,
        operation: op,
        startNewEntry: true,
      );
    }
    return CalculatorState(
      entry: entry,
      accumulator: value,
      operation: op,
      startNewEntry: true,
    );
  }

  CalculatorState equals() {
    if (operation == null) return _copy(startNewEntry: true);
    final double result = _evaluate(accumulator ?? 0, value, operation!);
    return CalculatorState(entry: _trim(result), startNewEntry: true);
  }

  CalculatorState backspace() {
    if (startNewEntry) return _copy(entry: '0');
    if (entry.length <= 1) return _copy(entry: '0', startNewEntry: true);
    final String next = entry.substring(0, entry.length - 1);
    return _copy(entry: next.isEmpty || next == '-' ? '0' : next);
  }

  CalculatorState clear() => const CalculatorState();

  /// Replaces the entry wholesale — used when opening the editor on an
  /// existing transaction.
  static CalculatorState fromAmount(double amount) =>
      CalculatorState(entry: _trim(amount));

  static double _evaluate(double left, double right, CalcOp op) {
    final double result = switch (op) {
      CalcOp.add => left + right,
      CalcOp.subtract => left - right,
      CalcOp.multiply => left * right,
      // Dividing by zero would poison the field with Infinity/NaN, so the
      // left-hand side is simply kept.
      CalcOp.divide => right == 0 ? left : left / right,
    };
    if (result.isNaN || result.isInfinite) return left;
    return (result * 100).roundToDouble() / 100;
  }

  /// Renders a double without a pointless `.0`.
  static String _trim(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  CalculatorState _copy({
    String? entry,
    double? accumulator,
    CalcOp? operation,
    bool? startNewEntry,
  }) {
    return CalculatorState(
      entry: entry ?? this.entry,
      accumulator: accumulator ?? this.accumulator,
      operation: operation ?? this.operation,
      startNewEntry: startNewEntry ?? this.startNewEntry,
    );
  }
}
