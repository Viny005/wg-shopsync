import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/features/expense/application/debt_delta_calculator.dart';

void main() {
  group('DebtDeltaCalculator.forCreate', () {
    test('erzeugt positive Deltas fuer alle Teilnehmer ausser dem Zahler', () {
      final deltas = DebtDeltaCalculator.forCreate(
        paidBy: 'user-a',
        shares: {'user-a': 5.0, 'user-b': 5.0},
      );

      expect(deltas.length, 1);
      expect(deltas.first.creditorId, 'user-a');
      expect(deltas.first.debtorId, 'user-b');
      expect(deltas.first.amountInEuro, 5.0);
    });

    test('erzeugt keine Deltas wenn nur der Zahler beteiligt ist', () {
      final deltas = DebtDeltaCalculator.forCreate(
        paidBy: 'user-a',
        shares: {'user-a': 10.0},
      );

      expect(deltas, isEmpty);
    });

    test('erzeugt je ein Delta pro Nicht-Zahler bei drei Beteiligten', () {
      final deltas = DebtDeltaCalculator.forCreate(
        paidBy: 'user-a',
        shares: {'user-a': 3.34, 'user-b': 3.33, 'user-c': 3.33},
      );

      expect(deltas.length, 2);
      expect(
        deltas.map((d) => d.debtorId).toSet(),
        {'user-b', 'user-c'},
      );
      for (final d in deltas) {
        expect(d.creditorId, 'user-a');
      }
    });
  });

  group('DebtDeltaCalculator.forUpdate - gleichbleibender Zahler', () {
    test('erzeugt Delta gleich der Differenz bei Betragsaenderung', () {
      final deltas = DebtDeltaCalculator.forUpdate(
        oldPaidBy: 'user-a',
        oldShares: {'user-a': 5.0, 'user-b': 5.0},
        newPaidBy: 'user-a',
        newShares: {'user-a': 7.5, 'user-b': 7.5},
      );

      expect(deltas.length, 1);
      expect(deltas.first.creditorId, 'user-a');
      expect(deltas.first.debtorId, 'user-b');
      expect(deltas.first.amountInEuro, closeTo(2.5, 0.001));
    });

    test('erzeugt negatives Delta wenn Anteil sinkt', () {
      final deltas = DebtDeltaCalculator.forUpdate(
        oldPaidBy: 'user-a',
        oldShares: {'user-a': 5.0, 'user-b': 5.0},
        newPaidBy: 'user-a',
        newShares: {'user-a': 8.0, 'user-b': 2.0},
      );

      expect(deltas.length, 1);
      expect(deltas.first.amountInEuro, closeTo(-3.0, 0.001));
    });

    test('erzeugt kein Delta wenn Betrag unveraendert bleibt', () {
      final deltas = DebtDeltaCalculator.forUpdate(
        oldPaidBy: 'user-a',
        oldShares: {'user-a': 5.0, 'user-b': 5.0},
        newPaidBy: 'user-a',
        newShares: {'user-a': 5.0, 'user-b': 5.0},
      );

      expect(deltas, isEmpty);
    });

    test('erzeugt positives Delta wenn neuer Teilnehmer hinzukommt', () {
      final deltas = DebtDeltaCalculator.forUpdate(
        oldPaidBy: 'user-a',
        oldShares: {'user-a': 10.0},
        newPaidBy: 'user-a',
        newShares: {'user-a': 5.0, 'user-b': 5.0},
      );

      expect(deltas.length, 1);
      expect(deltas.first.debtorId, 'user-b');
      expect(deltas.first.amountInEuro, closeTo(5.0, 0.001));
    });

    test(
        'erzeugt negatives Delta gleich dem vollen alten Anteil wenn Teilnehmer entfernt wird',
        () {
      final deltas = DebtDeltaCalculator.forUpdate(
        oldPaidBy: 'user-a',
        oldShares: {'user-a': 5.0, 'user-b': 5.0},
        newPaidBy: 'user-a',
        newShares: {'user-a': 10.0},
      );

      expect(deltas.length, 1);
      expect(deltas.first.debtorId, 'user-b');
      expect(deltas.first.amountInEuro, closeTo(-5.0, 0.001));
    });
  });

  group('DebtDeltaCalculator.forUpdate - Zahlerwechsel', () {
    test('storniert alte Schuld vollstaendig und baut neue vollstaendig auf',
        () {
      final deltas = DebtDeltaCalculator.forUpdate(
        oldPaidBy: 'user-a',
        oldShares: {'user-a': 5.0, 'user-b': 5.0},
        newPaidBy: 'user-b',
        newShares: {'user-b': 5.0, 'user-a': 5.0},
      );

      expect(deltas.length, 2);

      final reversal = deltas.firstWhere((d) => d.amountInEuro < 0);
      expect(reversal.creditorId, 'user-a');
      expect(reversal.debtorId, 'user-b');
      expect(reversal.amountInEuro, closeTo(-5.0, 0.001));

      final rebuild = deltas.firstWhere((d) => d.amountInEuro > 0);
      expect(rebuild.creditorId, 'user-b');
      expect(rebuild.debtorId, 'user-a');
      expect(rebuild.amountInEuro, closeTo(5.0, 0.001));
    });

    test('beruecksichtigt bei Zahlerwechsel auch dritte Teilnehmer', () {
      final deltas = DebtDeltaCalculator.forUpdate(
        oldPaidBy: 'user-a',
        oldShares: {'user-a': 3.34, 'user-b': 3.33, 'user-c': 3.33},
        newPaidBy: 'user-b',
        newShares: {'user-b': 3.34, 'user-a': 3.33, 'user-c': 3.33},
      );

      // 2 Stornierungen (b, c gegenueber altem Zahler a) + 2 Aufbauten
      // (a, c gegenueber neuem Zahler b) = 4 Deltas.
      expect(deltas.length, 4);

      final reversals = deltas.where((d) => d.creditorId == 'user-a');
      expect(reversals.length, 2);
      expect(
        reversals.map((d) => d.debtorId).toSet(),
        {'user-b', 'user-c'},
      );
      for (final d in reversals) {
        expect(d.amountInEuro, lessThan(0));
      }

      final rebuilds = deltas.where((d) => d.creditorId == 'user-b');
      expect(rebuilds.length, 2);
      expect(
        rebuilds.map((d) => d.debtorId).toSet(),
        {'user-a', 'user-c'},
      );
      for (final d in rebuilds) {
        expect(d.amountInEuro, greaterThan(0));
      }
    });

    test('neuer Zahler hat in der Aufbau-Richtung kein Delta gegen sich selbst',
        () {
      final deltas = DebtDeltaCalculator.forUpdate(
        oldPaidBy: 'user-a',
        oldShares: {'user-a': 5.0, 'user-b': 5.0},
        newPaidBy: 'user-b',
        newShares: {'user-b': 10.0},
      );

      // Storno-Delta (alter Zahler user-a als creditorId) darf user-b als
      // Schuldner enthalten - das ist korrekt, die alte Schuld wird
      // zurueckgenommen. Kein Delta mit creditorId user-b (Aufbauphase)
      // darf jedoch user-b selbst als Schuldner haben.
      final rebuildDeltas = deltas.where((d) => d.creditorId == 'user-b');
      for (final d in rebuildDeltas) {
        expect(d.debtorId, isNot('user-b'));
      }

      // Da newShares nur den Zahler selbst enthaelt, entsteht in der
      // Aufbauphase gar kein Delta.
      expect(rebuildDeltas, isEmpty);
    });
  });
}
