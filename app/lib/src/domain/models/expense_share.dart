/// Der Anteil eines Mitglieds an einer Ausgabe (siehe D1.7 / D2.6).
///
/// Wird als eigenständige Sub-Collection unter der zugehörigen Expense
/// gespeichert: wgs/{wgId}/expenses/{expenseId}/expenseShares/{shareId}.
class ExpenseShare {
  const ExpenseShare({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.shareAmount,
  });

  final String id;
  final String expenseId;
  final String userId;

  /// Summe aller Anteile entspricht exakt dem Gesamtbetrag der Ausgabe.
  final double shareAmount;

  factory ExpenseShare.fromMap(String id, Map<String, dynamic> data) {
    return ExpenseShare(
      id: id,
      expenseId: data['expenseId'] as String,
      userId: data['userId'] as String,
      shareAmount: (data['shareAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expenseId': expenseId,
      'userId': userId,
      'shareAmount': shareAmount,
    };
  }
}
