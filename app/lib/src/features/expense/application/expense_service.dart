import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/validation/validators.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/expense_share.dart';
import 'expense_calculator.dart';

/// Wird geworfen, wenn der angegebene Zahler kein Mitglied der WG ist.
class ExpensePayerNotMemberException implements Exception {
  const ExpensePayerNotMemberException();
}

/// Wird geworfen, wenn ein beteiligter Nutzer kein Mitglied der WG ist.
class ExpenseParticipantNotMemberException implements Exception {
  const ExpenseParticipantNotMemberException(this.userId);

  final String userId;
}

typedef ExpensePersistence = Future<Expense> Function({
  required String wgId,
  required Expense expense,
  required Map<String, double> shares,
  required List<String> participantUserIds,
});

/// Anwendungsdienst für UC-11 – Ausgabe erfassen (siehe A05 Bausteinsicht).
///
/// Trennt fachliche Validierung, Kostenaufteilung (AF-01, siehe
/// [ExpenseCalculator]) und Firestore-Persistenz, damit die Kostenaufteilung
/// ohne Firestore-Testdouble unit-testbar bleibt. Die Mitgliedschaft von
/// Zahler und Teilnehmern wird ausschließlich serverseitig gegen die
/// Firestore-Memberships geprüft – eine vom Client übergebene Mitgliederliste
/// wird NICHT als Sicherheitsnachweis akzeptiert.
class ExpenseService {
  ExpenseService({
    FirebaseFirestore? firestore,
    Future<bool> Function(String wgId, String userId)? membershipChecker,
    ExpensePersistence? persistence,
  })  : _firestore = firestore,
        _membershipChecker = membershipChecker,
        _persistence = persistence;

  final FirebaseFirestore? _firestore;
  final Future<bool> Function(String wgId, String userId)? _membershipChecker;
  final ExpensePersistence? _persistence;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<Expense> _persistExpense({
    required String wgId,
    required Expense expense,
    required Map<String, double> shares,
    required List<String> participantUserIds,
  }) {
    if (_persistence != null) {
      return _persistence(
        wgId: wgId,
        expense: expense,
        shares: shares,
        participantUserIds: participantUserIds,
      );
    }

    return _persistExpenseWithFirestore(
      wgId: wgId,
      expense: expense,
      shares: shares,
      participantUserIds: participantUserIds,
    );
  }

  Future<Expense> _persistExpenseWithFirestore({
    required String wgId,
    required Expense expense,
    required Map<String, double> shares,
    required List<String> participantUserIds,
  }) async {
    final activeFirestore = firestore;
    final expenseRef = activeFirestore
        .collection('wgs')
        .doc(wgId)
        .collection('expenses')
        .doc();

    return activeFirestore.runTransaction<Expense>((transaction) async {
      final payerMembershipRef = activeFirestore
          .collection('wgs')
          .doc(wgId)
          .collection('memberships')
          .doc(expense.paidBy);
      final payerMembershipSnapshot = await transaction.get(payerMembershipRef);
      if (!payerMembershipSnapshot.exists) {
        throw const ExpensePayerNotMemberException();
      }

      for (final participantId in participantUserIds) {
        final participantMembershipRef = activeFirestore
            .collection('wgs')
            .doc(wgId)
            .collection('memberships')
            .doc(participantId);
        final participantMembershipSnapshot =
            await transaction.get(participantMembershipRef);
        if (!participantMembershipSnapshot.exists) {
          throw ExpenseParticipantNotMemberException(participantId);
        }
      }

      transaction.set(expenseRef, {
        ...expense.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (final participantId in participantUserIds) {
        final shareRef = expenseRef.collection('expenseShares').doc();
        final share = ExpenseShare(
          id: shareRef.id,
          expenseId: expenseRef.id,
          userId: participantId,
          shareAmount: shares[participantId]!,
        );
        transaction.set(shareRef, share.toMap());
      }

      return expense;
    });
  }

  Future<bool> _isWgMember(String wgId, String userId) {
    if (_membershipChecker != null) {
      return _membershipChecker(wgId, userId);
    }
    return firestore
        .collection('wgs')
        .doc(wgId)
        .collection('memberships')
        .doc(userId)
        .get()
        .then((snapshot) => snapshot.exists);
  }

  /// Erzeugt eine lokale ID ohne Firestore-Zugriff (nur für den Testpfad mit
  /// injiziertem Persistence-Callback; der echte Firestore-Pfad vergibt die
  /// ID weiterhin über ein Firestore-Dokument).
  String _generateFallbackExpenseId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  Future<List<Expense>> getExpenses({required String wgId}) async {
    final trimmedWgId = wgId.trim();
    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }

    final snapshot = await firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('expenses')
        .get();

    final expenses = snapshot.docs
        .map((doc) => Expense.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return expenses;
  }

  /// Erfasst eine neue Ausgabe (UC-11) inklusive cent-genauer Kostenaufteilung
  /// (AF-01, siehe [ExpenseCalculator]) und der dafür erforderlichen
  /// ExpenseShares.
  ///
  /// Keine Debt-Entitäten werden im Rahmen von UC-11 erstellt; die Operation
  /// bleibt atomar innerhalb derselben Firestore-Transaktion und speichert nur
  /// Expense + ExpenseShares.
  Future<Expense> createExpense({
    required String wgId,
    required double amount,
    required String description,
    required String paidBy,
    required List<String> participantUserIds,
    String? shoppingItemId,
    String? receiptUrl,
  }) async {
    final trimmedWgId = wgId.trim();
    final trimmedDescription = description.trim();
    final trimmedPaidBy = paidBy.trim();
    final trimmedParticipants =
        participantUserIds.map((id) => id.trim()).toList(growable: false);

    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }
    if (trimmedPaidBy.isEmpty) {
      throw ArgumentError('Die Zahler-ID darf nicht leer sein.');
    }

    final amountError = Validators.expenseAmount(amount);
    if (amountError != null) {
      throw ArgumentError(amountError);
    }

    if (trimmedDescription.isEmpty) {
      throw ArgumentError('Die Beschreibung darf nicht leer sein.');
    }

    if (trimmedParticipants.isEmpty) {
      throw ArgumentError(
        'Es muss mindestens ein beteiligtes Mitglied ausgewaehlt werden.',
      );
    }
    if (trimmedParticipants.any((id) => id.isEmpty)) {
      throw ArgumentError('Teilnehmer-IDs duerfen nicht leer sein.');
    }
    if (trimmedParticipants.toSet().length != trimmedParticipants.length) {
      throw ArgumentError(
        'Teilnehmer duerfen nicht doppelt ausgewaehlt werden.',
      );
    }

    if (!await _isWgMember(trimmedWgId, trimmedPaidBy)) {
      throw const ExpensePayerNotMemberException();
    }
    for (final participantId in trimmedParticipants) {
      if (!await _isWgMember(trimmedWgId, participantId)) {
        throw ExpenseParticipantNotMemberException(participantId);
      }
    }

    final amountInCents = ExpenseCalculator.euroToCents(amount);
    final sharesInCents = ExpenseCalculator.splitInCents(
      amountInCents: amountInCents,
      participantIds: trimmedParticipants,
    );
    final shares = {
      for (final entry in sharesInCents.entries) entry.key: entry.value / 100,
    };

    // Firestore darf nur ausgewertet werden, wenn kein Persistence-Callback
    // injiziert wurde (siehe DI-Vertrag von ExpenseService).
    final expenseId = _persistence != null
        ? _generateFallbackExpenseId()
        : firestore
            .collection('wgs')
            .doc(trimmedWgId)
            .collection('expenses')
            .doc()
            .id;

    final createdAt = DateTime.now();
    final expense = Expense(
      id: expenseId,
      wgId: trimmedWgId,
      amount: amount,
      description: trimmedDescription,
      paidBy: trimmedPaidBy,
      shoppingItemId: shoppingItemId,
      receiptUrl: receiptUrl,
      createdAt: createdAt,
    );

    return _persistExpense(
      wgId: trimmedWgId,
      expense: expense,
      shares: shares,
      participantUserIds: trimmedParticipants,
    );
  }
}
