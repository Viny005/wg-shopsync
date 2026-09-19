/// UC-13 - Kosten aufteilen (AF-06 Saldo berechnen).
///
/// Reine, ohne Firestore testbare Berechnung der Debt-Deltas, die bei
/// createExpense/updateExpense angewendet werden muessen. Getrennt von der
/// eigentlichen Firestore-Schreiblogik in ExpenseService, damit die
/// fachliche Regel (Payer-Wechsel vs. reine Betragsaenderung) isoliert
/// unit-testbar bleibt.
class DebtDelta {
  const DebtDelta({
    required this.creditorId,
    required this.debtorId,
    required this.amountInEuro,
  });

  final String creditorId;
  final String debtorId;

  /// Positiver Wert erhoeht die Schuld debtorId -> creditorId,
  /// negativer Wert reduziert sie.
  final double amountInEuro;
}

class DebtDeltaCalculator {
  const DebtDeltaCalculator._();

  /// Berechnet die Debt-Deltas fuer eine neu erstellte Ausgabe: jeder
  /// Teilnehmer ausser dem Zahler erhaelt eine positive Schuld gegenueber
  /// dem Zahler in Hoehe seines Anteils.
  static List<DebtDelta> forCreate({
    required String paidBy,
    required Map<String, double> shares,
  }) {
    final deltas = <DebtDelta>[];
    for (final entry in shares.entries) {
      if (entry.key == paidBy) {
        continue;
      }
      deltas.add(DebtDelta(
        creditorId: paidBy,
        debtorId: entry.key,
        amountInEuro: entry.value,
      ));
    }
    return deltas;
  }

  /// Berechnet die Debt-Deltas fuer eine bearbeitete Ausgabe.
  ///
  /// Bleibt der Zahler gleich, wird pro betroffenem User (alte und neue
  /// Teilnehmer zusammen) nur die Differenz zwischen neuem und altem Anteil
  /// angewendet. Aendert sich der Zahler, wird die alte Zuordnung
  /// vollstaendig storniert (negative Deltas gegenueber dem alten Zahler)
  /// und die neue Zuordnung vollstaendig aufgebaut (positive Deltas
  /// gegenueber dem neuen Zahler), da die beiden Schuldrichtungen
  /// unterschiedliche Glaeubiger betreffen und nicht miteinander verrechnet
  /// werden koennen.
  static List<DebtDelta> forUpdate({
    required String oldPaidBy,
    required Map<String, double> oldShares,
    required String newPaidBy,
    required Map<String, double> newShares,
  }) {
    final deltas = <DebtDelta>[];

    if (oldPaidBy != newPaidBy) {
      for (final entry in oldShares.entries) {
        if (entry.key == oldPaidBy) {
          continue;
        }
        deltas.add(DebtDelta(
          creditorId: oldPaidBy,
          debtorId: entry.key,
          amountInEuro: -entry.value,
        ));
      }
      for (final entry in newShares.entries) {
        if (entry.key == newPaidBy) {
          continue;
        }
        deltas.add(DebtDelta(
          creditorId: newPaidBy,
          debtorId: entry.key,
          amountInEuro: entry.value,
        ));
      }
      return deltas;
    }

    final allUserIds = {...oldShares.keys, ...newShares.keys};
    for (final userId in allUserIds) {
      if (userId == newPaidBy) {
        continue;
      }
      final oldAmount = oldShares[userId] ?? 0;
      final newAmount = newShares[userId] ?? 0;
      final delta = newAmount - oldAmount;
      if (delta == 0) {
        continue;
      }
      deltas.add(DebtDelta(
        creditorId: newPaidBy,
        debtorId: userId,
        amountInEuro: delta,
      ));
    }
    return deltas;
  }
}
