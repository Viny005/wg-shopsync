/// UC-13 - Kosten aufteilen; die fachliche Gleichverteilung stammt aus AF-01.
///
/// Reine, ohne Firestore testbare Projektion der Debt-Datensaetze, die zu
/// einer Expense gehoeren sollen. Getrennt von der Firestore-Schreiblogik in
/// ExpenseService, damit die fachliche Zuordnung (ein Debt pro Nicht-Zahler-
/// Teilnehmer) isoliert unit-testbar bleibt.
class DebtProjectionEntry {
  const DebtProjectionEntry({
    required this.creditorId,
    required this.debtorId,
    required this.amountInEuro,
  });

  final String creditorId;
  final String debtorId;
  final double amountInEuro;
}

class DebtProjection {
  const DebtProjection._();

  /// Berechnet, welche Debts fuer eine Expense mit dem gegebenen Zahler und
  /// den gegebenen Kostenanteilen existieren sollen. Ein Eintrag pro
  /// Teilnehmer, der nicht selbst der Zahler ist.
  static List<DebtProjectionEntry> forExpense({
    required String paidBy,
    required Map<String, double> shares,
  }) {
    final entries = <DebtProjectionEntry>[];
    for (final entry in shares.entries) {
      if (entry.key == paidBy) {
        continue;
      }
      entries.add(DebtProjectionEntry(
        creditorId: paidBy,
        debtorId: entry.key,
        amountInEuro: entry.value,
      ));
    }
    return entries;
  }
}
