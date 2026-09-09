import '../../core/utils/firestore_converters.dart';

/// Eine Ausgabe, die von einem Mitglied für die WG getätigt wurde (siehe D1.6 / D2.5).
class Expense {
  const Expense({
    required this.id,
    required this.wgId,
    required this.amount,
    required this.description,
    required this.paidBy,
    this.shoppingItemId,
    this.receiptUrl,
    required this.createdAt,
  });

  final String id;
  final String wgId;

  /// Betrag größer als 0, mit fester Dezimalpräzision (zwei Nachkommastellen).
  final double amount;
  final String description;
  final String paidBy;
  final String? shoppingItemId;

  /// Im MVP nicht aktiv befüllt (siehe A08 8.6).
  final String? receiptUrl;
  final DateTime createdAt;

  factory Expense.fromMap(String id, Map<String, dynamic> data) {
    return Expense(
      id: id,
      wgId: data['wgId'] as String,
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] as String,
      paidBy: data['paidBy'] as String,
      shoppingItemId: data['shoppingItemId'] as String?,
      receiptUrl: data['receiptUrl'] as String?,
      createdAt: dateTimeFromFirestore(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wgId': wgId,
      'amount': amount,
      'description': description,
      'paidBy': paidBy,
      'shoppingItemId': shoppingItemId,
      'receiptUrl': receiptUrl,
      'createdAt': createdAt,
    };
  }
}
