import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/network/network_connectivity.dart';
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

/// Wird geworfen, wenn die zu bearbeitende Ausgabe nicht mehr existiert.
class ExpenseNotFoundException implements Exception {
  const ExpenseNotFoundException();
}

/// Wird geworfen, wenn die Ausgabe seit dem Öffnen des Formulars
/// zwischenzeitlich von einem anderen Mitglied geändert wurde.
class ExpenseConflictException implements Exception {
  const ExpenseConflictException({
    required this.serverExpense,
  });

  final Expense serverExpense;
}

enum _ExpenseTransactionOutcome {
  success,
  notFound,
  conflict,
  payerNotMember,
  participantNotMember,
}

class _ExpenseTransactionResult {
  const _ExpenseTransactionResult.success(this.expense)
      : kind = _ExpenseTransactionOutcome.success,
        serverExpense = null,
        conflictingParticipantId = null;

  const _ExpenseTransactionResult.notFound()
      : kind = _ExpenseTransactionOutcome.notFound,
        expense = null,
        serverExpense = null,
        conflictingParticipantId = null;

  const _ExpenseTransactionResult.conflict(this.serverExpense)
      : kind = _ExpenseTransactionOutcome.conflict,
        expense = null,
        conflictingParticipantId = null;

  const _ExpenseTransactionResult.payerNotMember()
      : kind = _ExpenseTransactionOutcome.payerNotMember,
        expense = null,
        serverExpense = null,
        conflictingParticipantId = null;

  const _ExpenseTransactionResult.participantNotMember(
    this.conflictingParticipantId,
  )   : kind = _ExpenseTransactionOutcome.participantNotMember,
        expense = null,
        serverExpense = null;

  final _ExpenseTransactionOutcome kind;
  final Expense? expense;
  final Expense? serverExpense;
  final String? conflictingParticipantId;
}

/// Wird geworfen, wenn UC-12 ohne erforderliche Internetverbindung
/// ausgeführt werden soll.
class ExpenseRequiresConnectionException implements Exception {
  const ExpenseRequiresConnectionException();
}

typedef ExpensePersistence = Future<Expense> Function({
  required String wgId,
  required Expense expense,
  required Map<String, double> shares,
  required List<String> participantUserIds,
});


typedef ExpenseUpdatePersistence = Future<Expense> Function({
  required Expense originalExpense,
  required double amount,
  required String description,
  required String paidBy,
  required List<String> participantUserIds,
  required Map<String, double> shares,
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
    ExpenseUpdatePersistence? updatePersistence,
    bool Function()? isOfflineChecker,
  })  : _firestore = firestore,
        _membershipChecker = membershipChecker,
        _persistence = persistence,
        _updatePersistence = updatePersistence,
        _isOfflineChecker = isOfflineChecker ?? isDeviceOffline;
  final FirebaseFirestore? _firestore;
  final Future<bool> Function(String wgId, String userId)? _membershipChecker;
  final ExpensePersistence? _persistence;
  final ExpenseUpdatePersistence? _updatePersistence;
  final bool Function() _isOfflineChecker;

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
        .doc(expense.id);

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
        'updatedAt': FieldValue.serverTimestamp(),
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

  /// Lädt die gespeicherten Kostenanteile einer Ausgabe.
  /// Wird für das Vorbelegen des Bearbeitungsformulars in UC-12 verwendet.
  Future<List<ExpenseShare>> getExpenseShares({
    required String wgId,
    required String expenseId,
  }) async {
    final trimmedWgId = wgId.trim();
    final trimmedExpenseId = expenseId.trim();

    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }

    if (trimmedExpenseId.isEmpty) {
      throw ArgumentError('Die Ausgabe-ID darf nicht leer sein.');
    }

    final snapshot = await firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('expenses')
        .doc(trimmedExpenseId)
        .collection('expenseShares')
        .get();

    final shares = snapshot.docs
        .map((doc) => ExpenseShare.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => a.userId.compareTo(b.userId));

    return shares;
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
      updatedAt: createdAt,
    );

    return _persistExpense(
      wgId: trimmedWgId,
      expense: expense,
      shares: shares,
      participantUserIds: trimmedParticipants,
    );
  }

  /// Bearbeitet eine bestehende Ausgabe (UC-12).
  ///
  /// Betrag, Beschreibung, Zahler und Beteiligte können geändert werden.
  /// Die ExpenseShares werden anschließend gemäß AF-01 neu berechnet.
  Future<Expense> updateExpense({
    required Expense originalExpense,
    required double amount,
    required String description,
    required String paidBy,
    required List<String> participantUserIds,
  }) async {
    final trimmedWgId = originalExpense.wgId.trim();
    final trimmedExpenseId = originalExpense.id.trim();
    final trimmedDescription = description.trim();
    final trimmedPaidBy = paidBy.trim();
    final trimmedParticipants =
        participantUserIds.map((id) => id.trim()).toList(growable: false);

    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }

    if (trimmedExpenseId.isEmpty) {
      throw ArgumentError('Die Ausgabe-ID darf nicht leer sein.');
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

    if (_isOfflineChecker()) {
      throw const ExpenseRequiresConnectionException();
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

        return _persistUpdatedExpense(
      originalExpense: originalExpense,
      amount: amount,
      description: trimmedDescription,
      paidBy: trimmedPaidBy,
      participantUserIds: trimmedParticipants,
      shares: shares,
    );
  }

  Future<Expense> _persistUpdatedExpense({
    required Expense originalExpense,
    required double amount,
    required String description,
    required String paidBy,
    required List<String> participantUserIds,
    required Map<String, double> shares,
  }) {
    if (_updatePersistence != null) {
      return _updatePersistence(
        originalExpense: originalExpense,
        amount: amount,
        description: description,
        paidBy: paidBy,
        participantUserIds: participantUserIds,
        shares: shares,
      );
    }

    return _updateExpenseWithFirestore(
      originalExpense: originalExpense,
      amount: amount,
      description: description,
      paidBy: paidBy,
      participantUserIds: participantUserIds,
      shares: shares,
    );
  }

    Future<Expense> _updateExpenseWithFirestore({
    required Expense originalExpense,
    required double amount,
    required String description,
    required String paidBy,
    required List<String> participantUserIds,
    required Map<String, double> shares,
  }) async {
    final activeFirestore = firestore;

    final expenseRef = activeFirestore
        .collection('wgs')
        .doc(originalExpense.wgId)
        .collection('expenses')
        .doc(originalExpense.id);

    final _ExpenseTransactionResult result;
    final existingSharesQuery =
        await expenseRef.collection('expenseShares').get();
    final existingShareRefs =
        existingSharesQuery.docs.map((doc) => doc.reference).toList(growable: false);
    try {
      result = await activeFirestore.runTransaction<_ExpenseTransactionResult>(
        (transaction) async {
          // Alle transaktionalen Lesezugriffe erfolgen vor den Schreibzugriffen
          // (siehe A08 8.3 und die bestehende Konvention in
          // ShoppingListService): zuerst die Expense, danach die bestehenden
          // ExpenseShares, danach die Memberships. Erst danach folgen writes.
          final expenseSnapshot = await transaction.get(expenseRef);

          if (!expenseSnapshot.exists || expenseSnapshot.data() == null) {
            return const _ExpenseTransactionResult.notFound();
          }

          final serverExpense = Expense.fromMap(
            expenseSnapshot.id,
            expenseSnapshot.data()!,
          );

          if (serverExpense.effectiveUpdatedAt.microsecondsSinceEpoch !=
              originalExpense.effectiveUpdatedAt.microsecondsSinceEpoch) {
            return _ExpenseTransactionResult.conflict(serverExpense);
          }

          // Die Menge der bestehenden Shares ist vor der Transaktion nicht
          // bekannt (dynamische Query), daher werden die IDs ausserhalb
          // ermittelt und die einzelnen Dokumente anschliessend innerhalb
          // der Transaktion erneut gelesen. Das gibt Firestore die
          // Moeglichkeit, eine zwischenzeitliche Aenderung an genau diesen
          // Share-Dokumenten als Konflikt zu erkennen (Retry der Transaktion).
          for (final ref in existingShareRefs) {
            await transaction.get(ref);
          }

          final payerMembershipRef = activeFirestore
              .collection('wgs')
              .doc(originalExpense.wgId)
              .collection('memberships')
              .doc(paidBy);

          final payerMembershipSnapshot =
              await transaction.get(payerMembershipRef);

          if (!payerMembershipSnapshot.exists) {
            return const _ExpenseTransactionResult.payerNotMember();
          }

          for (final participantId in participantUserIds) {
            if (participantId == paidBy) {
              continue;
            }

            final participantMembershipRef = activeFirestore
                .collection('wgs')
                .doc(originalExpense.wgId)
                .collection('memberships')
                .doc(participantId);

            final participantMembershipSnapshot =
                await transaction.get(participantMembershipRef);

            if (!participantMembershipSnapshot.exists) {
              return _ExpenseTransactionResult.participantNotMember(
                participantId,
              );
            }
          }

          final now = DateTime.now();

          final updatedExpense = originalExpense.copyWith(
            amount: amount,
            description: description,
            paidBy: paidBy,
            updatedAt: now,
          );

          transaction.update(expenseRef, {
            'amount': amount,
            'description': description,
            'paidBy': paidBy,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          for (final oldShareRef in existingShareRefs) {
            transaction.delete(oldShareRef);
          }

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

          return _ExpenseTransactionResult.success(updatedExpense);
        },
      );
    } on FirebaseException catch (error) {
      if (error.code == 'unavailable') {
        throw const ExpenseRequiresConnectionException();
      }
      rethrow;
    } on TimeoutException {
      throw const ExpenseRequiresConnectionException();
    }

    switch (result.kind) {
      case _ExpenseTransactionOutcome.notFound:
        throw const ExpenseNotFoundException();
      case _ExpenseTransactionOutcome.conflict:
        throw ExpenseConflictException(serverExpense: result.serverExpense!);
      case _ExpenseTransactionOutcome.payerNotMember:
        throw const ExpensePayerNotMemberException();
      case _ExpenseTransactionOutcome.participantNotMember:
        throw ExpenseParticipantNotMemberException(
          result.conflictingParticipantId!,
        );
      case _ExpenseTransactionOutcome.success:
        return result.expense!;
    }
  }
}
