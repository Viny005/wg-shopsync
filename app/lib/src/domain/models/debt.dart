import '../../core/utils/firestore_converters.dart';

/// Zahlungsstatus einer Schuld zwischen zwei Mitgliedern (siehe D2.8 Kostenstatus).
enum DebtStatus {
  open,
  paid;

  static DebtStatus fromValue(String value) {
    return DebtStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw ArgumentError('Unbekannte DebtStatus: $value'),
    );
  }
}

/// Eine offene oder bereits beglichene Forderung zwischen zwei Mitgliedern (siehe D1.8 / D2.7).
class Debt {
  const Debt({
    required this.id,
    required this.wgId,
    required this.creditorId,
    required this.debtorId,
    required this.amount,
    required this.status,
    this.paidAt,
    required this.createdAt,
  });

  final String id;
  final String wgId;
  final String creditorId;
  final String debtorId;
  final double amount;
  final DebtStatus status;

  /// Wird gesetzt, sobald [status] auf [DebtStatus.paid] wechselt.
  final DateTime? paidAt;
  final DateTime createdAt;

  factory Debt.fromMap(String id, Map<String, dynamic> data) {
    return Debt(
      id: id,
      wgId: data['wgId'] as String,
      creditorId: data['creditorId'] as String,
      debtorId: data['debtorId'] as String,
      amount: (data['amount'] as num).toDouble(),
      status: DebtStatus.fromValue(data['status'] as String),
      paidAt: dateTimeFromFirestoreOrNull(data['paidAt']),
      createdAt: dateTimeFromFirestore(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wgId': wgId,
      'creditorId': creditorId,
      'debtorId': debtorId,
      'amount': amount,
      'status': status.name,
      'paidAt': paidAt,
      'createdAt': createdAt,
    };
  }
}
