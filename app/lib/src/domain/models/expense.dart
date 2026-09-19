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
    this.updatedAt,
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

  /// Zeitpunkt der letzten fachlichen Änderung.
  ///
  /// Das Feld ist optional, damit bereits vor UC-12 gespeicherte Ausgaben
  /// weiterhin gelesen werden können.
  final DateTime? updatedAt;

  /// Versionszeitpunkt für die Konflikterkennung in UC-12.
  /// Alte Ausgaben ohne updatedAt verwenden createdAt als Ausgangsversion.
  DateTime get effectiveUpdatedAt => updatedAt ?? createdAt;

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
      updatedAt: dateTimeFromFirestoreOrNull(data['updatedAt']),
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
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  Expense copyWith({
    double? amount,
    String? description,
    String? paidBy,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id,
      wgId: wgId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paidBy: paidBy ?? this.paidBy,
      shoppingItemId: shoppingItemId,
      receiptUrl: receiptUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
