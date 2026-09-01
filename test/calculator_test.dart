import 'package:flutter_test/flutter_test.dart';
import 'package:kori/core/utils/calculator.dart';

void main() {
  group('CalculatorState', () {
    test('starts empty at zero', () {
      const CalculatorState state = CalculatorState();
      expect(state.entry, '0');
      expect(state.value, 0);
      expect(state.isEmpty, isTrue);
    });

    test('typing digits replaces the leading zero', () {
      final CalculatorState state = const CalculatorState()
          .digit('2')
          .digit('5')
          .digit('0');
      expect(state.entry, '250');
      expect(state.value, 250);
    });

    test('chains an addition through equals', () {
      final CalculatorState state = const CalculatorState()
          .digit('2')
          .digit('4')
          .digit('0')
          .applyOperation(CalcOp.add)
          .digit('6')
          .digit('0')
          .equals();
      expect(state.value, 300);
      expect(state.hasPendingOperation, isFalse);
    });

    test('applies a pending operation when a second operator is pressed', () {
      final CalculatorState state = const CalculatorState()
          .digit('1')
          .digit('0')
          .applyOperation(CalcOp.add)
          .digit('5')
          .applyOperation(CalcOp.multiply);
      expect(state.value, 15);
      expect(state.operation, CalcOp.multiply);
    });

    test('keeps the left side instead of producing Infinity on ÷ 0', () {
      final CalculatorState state = const CalculatorState()
          .digit('9')
          .applyOperation(CalcOp.divide)
          .digit('0')
          .equals();
      expect(state.value, 9);
      expect(state.value.isFinite, isTrue);
    });

    test('allows only one decimal point', () {
      final CalculatorState state = const CalculatorState()
          .digit('1')
          .decimalPoint()
          .digit('5')
          .decimalPoint()
          .digit('2');
      expect(state.entry, '1.52');
    });

    test('rounds results to two decimal places', () {
      final CalculatorState state = const CalculatorState()
          .digit('1')
          .digit('0')
          .applyOperation(CalcOp.divide)
          .digit('3')
          .equals();
      expect(state.value, 3.33);
    });

    test('backspace removes one character and floors at zero', () {
      final CalculatorState state = const CalculatorState()
          .digit('4')
          .digit('2')
          .backspace()
          .backspace()
          .backspace();
      expect(state.entry, '0');
    });
  });
}
