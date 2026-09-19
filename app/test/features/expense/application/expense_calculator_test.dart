import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/features/expense/application/expense_calculator.dart';

void main() {
  group('ExpenseCalculator.euroToCents', () {
    test('konvertiert ganzen Betrag korrekt', () {
      expect(ExpenseCalculator.euroToCents(10.00), 1000);
    });

    test('konvertiert Betrag mit Nachkommastellen korrekt', () {
      expect(ExpenseCalculator.euroToCents(10.99), 1099);
    });

    test('wirft bei nicht-endlichem Betrag', () {
      expect(
        () => ExpenseCalculator.euroToCents(double.infinity),
        throwsArgumentError,
      );
    });
  });

  group('ExpenseCalculator.hasValidPrecision', () {
    test('akzeptiert zwei Nachkommastellen', () {
      expect(ExpenseCalculator.hasValidPrecision(10.99), isTrue);
      expect(ExpenseCalculator.hasValidPrecision(10.00), isTrue);
      expect(ExpenseCalculator.hasValidPrecision(10.10), isTrue);
    });

    test('lehnt mehr als zwei Nachkommastellen ab', () {
      expect(ExpenseCalculator.hasValidPrecision(10.001), isFalse);
    });
  });

  group('ExpenseCalculator.splitInCents', () {
    test('teilt gleichmaessig auf 3 Personen auf', () {
      final result = ExpenseCalculator.splitInCents(
        amountInCents: 1000,
        participantIds: ['user-a', 'user-b', 'user-c'],
      );
      expect(result.values.fold(0, (a, b) => a + b), 1000);
      expect(result['user-a'], 334);
      expect(result['user-b'], 333);
      expect(result['user-c'], 333);
    });

    test('10 Euro auf 3 Personen - Summe stimmt exakt', () {
      final result = ExpenseCalculator.splitInCents(
        amountInCents: ExpenseCalculator.euroToCents(10.00),
        participantIds: ['user-a', 'user-b', 'user-c'],
      );
      expect(result.values.fold(0, (a, b) => a + b), 1000);
    });

    test('0.02 Euro auf 3 Personen - Summe stimmt exakt', () {
      final result = ExpenseCalculator.splitInCents(
        amountInCents: ExpenseCalculator.euroToCents(0.02),
        participantIds: ['user-a', 'user-b', 'user-c'],
      );
      expect(result.values.fold(0, (a, b) => a + b), 2);
    });

    test('ist deterministisch unabhaengig von Eingabereihenfolge', () {
      final r1 = ExpenseCalculator.splitInCents(
        amountInCents: 1000,
        participantIds: ['user-c', 'user-a', 'user-b'],
      );
      final r2 = ExpenseCalculator.splitInCents(
        amountInCents: 1000,
        participantIds: ['user-a', 'user-b', 'user-c'],
      );
      expect(r1, equals(r2));
    });

    test('ein Teilnehmer bekommt den vollen Betrag', () {
      final result = ExpenseCalculator.splitInCents(
        amountInCents: 1000,
        participantIds: ['user-a'],
      );
      expect(result['user-a'], 1000);
    });

    test('wirft bei leerem Betrag', () {
      expect(
        () => ExpenseCalculator.splitInCents(
          amountInCents: 0,
          participantIds: ['user-a'],
        ),
        throwsArgumentError,
      );
    });

    test('wirft bei negativem Betrag', () {
      expect(
        () => ExpenseCalculator.splitInCents(
          amountInCents: -100,
          participantIds: ['user-a'],
        ),
        throwsArgumentError,
      );
    });

    test('wirft bei leerer Teilnehmerliste', () {
      expect(
        () => ExpenseCalculator.splitInCents(
          amountInCents: 1000,
          participantIds: [],
        ),
        throwsArgumentError,
      );
    });

    test('wirft bei doppelten Teilnehmer-IDs', () {
      expect(
        () => ExpenseCalculator.splitInCents(
          amountInCents: 1000,
          participantIds: ['user-a', 'user-a'],
        ),
        throwsArgumentError,
      );
    });
  });
}
