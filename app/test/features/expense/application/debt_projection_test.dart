import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/features/expense/application/debt_projection.dart';

void main() {
  group('DebtProjection.forExpense', () {
    test('erzeugt einen Eintrag pro Nicht-Zahler-Teilnehmer', () {
      final entries = DebtProjection.forExpense(
        paidBy: 'user-a',
        shares: {'user-a': 5.0, 'user-b': 5.0},
      );

      expect(entries.length, 1);
      expect(entries.first.creditorId, 'user-a');
      expect(entries.first.debtorId, 'user-b');
      expect(entries.first.amountInEuro, 5.0);
    });

    test('erzeugt keinen Eintrag wenn nur der Zahler beteiligt ist', () {
      final entries = DebtProjection.forExpense(
        paidBy: 'user-a',
        shares: {'user-a': 10.0},
      );

      expect(entries, isEmpty);
    });

    test('erzeugt je einen Eintrag pro Nicht-Zahler bei drei Beteiligten', () {
      final entries = DebtProjection.forExpense(
        paidBy: 'user-a',
        shares: {'user-a': 3.34, 'user-b': 3.33, 'user-c': 3.33},
      );

      expect(entries.length, 2);
      expect(
        entries.map((e) => e.debtorId).toSet(),
        {'user-b', 'user-c'},
      );
      for (final e in entries) {
        expect(e.creditorId, 'user-a');
      }
    });

    test('kein Eintrag hat creditorId gleich debtorId', () {
      final entries = DebtProjection.forExpense(
        paidBy: 'user-a',
        shares: {'user-a': 5.0, 'user-b': 5.0, 'user-c': 5.0},
      );

      for (final e in entries) {
        expect(e.creditorId, isNot(e.debtorId));
      }
    });

    test('leere shares ergeben leere Projektion', () {
      final entries = DebtProjection.forExpense(
        paidBy: 'user-a',
        shares: const {},
      );

      expect(entries, isEmpty);
    });
  });
}