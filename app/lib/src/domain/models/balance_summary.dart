import 'debt.dart';

/// UC-13 (Saldenanzeige) / AF-06 Saldo berechnen.
///
/// Fasst die gerichteten Debt-Dokumente (siehe Debt) zu einem Netto-Saldo
/// pro Gegenpartei zusammen. Positiver Wert: die Gegenpartei schuldet dem
/// Nutzer Geld. Negativer Wert: der Nutzer schuldet der Gegenpartei Geld.
///
/// Zwei gerichtete Debts zwischen denselben zwei Personen koennen
/// gleichzeitig existieren (z.B. nach einem Zahlerwechsel bei UC-12, siehe
/// DebtDeltaCalculator). Fuer die Anzeige werden sie zu einem Netto-Betrag
/// verrechnet, damit ein Mitglied nicht gleichzeitig als Glaeubiger und
/// Schuldner derselben Person angezeigt wird.
class BalanceSummary {
  const BalanceSummary({required this.balances});

  /// userId der Gegenpartei -> Netto-Saldo in Euro.
  final Map<String, double> balances;

  static BalanceSummary fromDebts({
    required String userId,
    required List<Debt> debts,
  }) {
    final balances = <String, double>{};

    for (final debt in debts) {
      if (debt.status == DebtStatus.paid) {
        continue;
      }
      if (debt.creditorId == userId && debt.debtorId != userId) {
        balances.update(
          debt.debtorId,
          (value) => value + debt.amount,
          ifAbsent: () => debt.amount,
        );
      } else if (debt.debtorId == userId && debt.creditorId != userId) {
        balances.update(
          debt.creditorId,
          (value) => value - debt.amount,
          ifAbsent: () => -debt.amount,
        );
      }
    }

    balances.removeWhere((_, amount) => amount.abs() < 0.005);

    return BalanceSummary(balances: balances);
  }

  double get totalBalance =>
      balances.values.fold<double>(0, (sum, value) => sum + value);
}
