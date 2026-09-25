import 'dart:async';
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/network/network_connectivity.dart';
import '../../../core/validation/validators.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/expense_share.dart';
import '../../../domain/models/debt.dart';
import 'debt_projection.dart';
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

/// Wird geworfen, wenn die Ausgabe seit dem Oeffnen des Formulars
/// zwischenzeitlich von einem anderen Mitglied geaendert wurde.
class ExpenseConflictException implements Exception {
  const ExpenseConflictException({
    required this.serverExpense,
  });

  final Expense serverExpense;
}

/// Wird geworfen, wenn UC-12 ohne erforderliche Internetverbindung
/// ausgefuehrt werden soll.
class ExpenseRequiresConnectionException implements Exception {
  const ExpenseRequiresConnectionException();
}

/// Wird geworfen, wenn mindestens eine der zu dieser Ausgabe gehoerenden
/// Schulden bereits als bezahlt markiert wurde. Die Ausgabe darf dann nicht
/// mehr in ihren finanziellen Eigenschaften veraendert werden, damit die
/// bezahlte Historie (UC-14/UC-15) nicht rueckwirkend verfaelscht wird.
class ExpenseAlreadySettledException implements Exception {
  const ExpenseAlreadySettledException();
}

/// Wird geworfen, wenn die zu bezahlende Schuld nicht mehr existiert.
class DebtNotFoundException implements Exception {
  const DebtNotFoundException();
}

/// Wird geworfen, wenn die Schuld bereits als bezahlt markiert wurde
/// (UC-15 A2: keine erneute Aenderung einer bereits beglichenen Schuld).
class DebtAlreadyPaidException implements Exception {
  const DebtAlreadyPaidException();
}

/// Wird geworfen, wenn der aktuelle Nutzer nicht der Schuldner der
/// angegebenen Debt ist. Rein defensiv - die eigentliche Autorisierung
/// erfolgt serverseitig durch Firestore Security Rules.
class DebtNotOwnedByUserException implements Exception {
  const DebtNotOwnedByUserException();
}

enum _ExpenseTransactionOutcome {
  success,
  notFound,
  conflict,
  payerNotMember,
  participantNotMember,
  alreadySettled,
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

  const _ExpenseTransactionResult.alreadySettled()
      : kind = _ExpenseTransactionOutcome.alreadySettled,
        expense = null,
        serverExpense = null,
        conflictingParticipantId = null;

  final _ExpenseTransactionOutcome kind;
  final Expense? expense;
  final Expense? serverExpense;
  final String? conflictingParticipantId;
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

/// Anwendungsdienst fuer UC-11 (Ausgabe erfassen), UC-12 (Ausgabe bearbeiten)
/// und UC-13 (Kosten aufteilen) - siehe A05 Bausteinsicht.
///
/// Trennt fachliche Validierung, Kostenaufteilung (AF-01, siehe
/// [ExpenseCalculator]) und Firestore-Persistenz, damit die Kostenaufteilung
/// ohne Firestore-Testdouble unit-testbar bleibt. Die Mitgliedschaft von
/// Zahler und Teilnehmern wird ausschliesslich serverseitig gegen die
/// Firestore-Memberships geprueft - eine vom Client uebergebene
/// Mitgliederliste wird NICHT als Sicherheitsnachweis akzeptiert.
///
/// Debt-Modell (siehe A09 ADR-07): jede Expense erzeugt fuer jeden
/// Nicht-Zahler-Teilnehmer ein eigenes, ihr zugeordnetes Debt-Dokument
/// (Debt.expenseId). Es gibt keine ueber mehrere Expenses aggregierte
/// Paar-Schuld mehr. Alle Transaction-Reads erfolgen vor allen Writes
/// (Firestore-Vorgabe, siehe A08 8.3).
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

  /// Erzeugt eine lokale ID ohne Firestore-Zugriff (nur fuer den Testpfad mit
  /// injiziertem Persistence-Callback; der echte Firestore-Pfad vergibt die
  /// ID weiterhin ueber ein Firestore-Dokument).
  String _generateFallbackExpenseId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

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

  /// Erfasst eine neue Ausgabe (UC-11) inklusive cent-genauer Kostenaufteilung
  /// (AF-01, siehe [ExpenseCalculator]) und der dafuer erforderlichen
  /// ExpenseShares. Erzeugt zusaetzlich die Debt-Dokumente fuer UC-13 (siehe
  /// DebtProjection und A09 ADR-07). Die Operation bleibt atomar innerhalb
  /// derselben Firestore-Transaktion und speichert Expense, ExpenseShares
  /// und die zugehoerigen Debt-Dokumente gemeinsam.
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
      // PHASE 1: alle Reads.
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

      // PHASE 2: reine Berechnung im Speicher.
      final debtEntries = DebtProjection.forExpense(
        paidBy: expense.paidBy,
        shares: shares,
      );

      // PHASE 3: alle Writes.
      transaction.set(expenseRef, {
        ...expense.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (final participantId in participantUserIds) {
        final shareRef =
            expenseRef.collection('expenseShares').doc(participantId);
        final share = ExpenseShare(
          id: shareRef.id,
          expenseId: expenseRef.id,
          userId: participantId,
          shareAmount: shares[participantId]!,
        );
        transaction.set(shareRef, share.toMap());
      }

      for (final entry in debtEntries) {
        final debtRef = activeFirestore
            .collection('wgs')
            .doc(wgId)
            .collection('debts')
            .doc(Debt.buildId(
              expenseId: expenseRef.id,
              debtorId: entry.debtorId,
            ));
        final debt = Debt(
          id: debtRef.id,
          wgId: wgId,
          expenseId: expenseRef.id,
          creditorId: entry.creditorId,
          debtorId: entry.debtorId,
          amount: entry.amountInEuro,
          status: DebtStatus.open,
          createdAt: DateTime.now(),
        );
        transaction.set(debtRef, {
          ...debt.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return expense;
    });
  }

  /// Bearbeitet eine bestehende Ausgabe (UC-12). Betrag, Beschreibung,
  /// Zahler und Beteiligte koennen geaendert werden. Die ExpenseShares
  /// werden anschliessend gemaess AF-01 neu berechnet, und die zu dieser
  /// Ausgabe gehoerenden Debt-Dokumente (UC-13) werden synchronisiert.
  ///
  /// Ist mindestens eine der zu dieser Ausgabe gehoerenden Debts bereits
  /// bezahlt (status == paid), wird die Bearbeitung verweigert
  /// (ExpenseAlreadySettledException), damit die bezahlte Historie
  /// (UC-14/UC-15) nicht rueckwirkend veraendert wird.
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
    final debtsCollectionRef = activeFirestore
        .collection('wgs')
        .doc(originalExpense.wgId)
        .collection('debts');

    // Die Menge der bisherigen Teilnehmer ist vor der Transaktion nicht
    // bekannt (dynamische Query), daher werden ihre IDs ausserhalb ermittelt.
    // Die Firestore-IDs der zugehoerigen ExpenseShare- und Debt-Dokumente
    // sind deterministisch (userId bzw. expenseId_userId) und werden
    // anschliessend innerhalb der Transaktion gezielt per get() erneut
    // gelesen, damit Firestore eine zwischenzeitliche Aenderung an genau
    // diesen Dokumenten als Konflikt erkennen kann.
    final existingSharesQuery =
        await expenseRef.collection('expenseShares').get();
    final oldParticipantIds =
        existingSharesQuery.docs.map((doc) => doc.id).toList(growable: false);

    final _ExpenseTransactionResult result;
    try {
      result = await activeFirestore.runTransaction<_ExpenseTransactionResult>(
        (transaction) async {
          // PHASE 1: alle Reads.
          final expenseSnapshot = await transaction.get(expenseRef);
          if (!expenseSnapshot.exists || expenseSnapshot.data() == null) {
            return const _ExpenseTransactionResult.notFound();
          }

          final serverExpense =
              Expense.fromMap(expenseSnapshot.id, expenseSnapshot.data()!);

          if (serverExpense.effectiveUpdatedAt.microsecondsSinceEpoch !=
              originalExpense.effectiveUpdatedAt.microsecondsSinceEpoch) {
            return _ExpenseTransactionResult.conflict(serverExpense);
          }

          for (final oldParticipantId in oldParticipantIds) {
            await transaction.get(
              expenseRef.collection('expenseShares').doc(oldParticipantId),
            );
          }

          // Paid-Protection: sobald eine zu dieser Expense gehoerende Debt
          // bereits bezahlt ist, wird die Bearbeitung verweigert (siehe
          // A08 8.5 und A09 ADR-07).
          final existingDebtCreatedAt = <String, DateTime>{};
          for (final oldParticipantId in oldParticipantIds) {
            if (oldParticipantId == originalExpense.paidBy) {
              continue;
            }
            final debtRef = debtsCollectionRef.doc(
              Debt.buildId(
                expenseId: originalExpense.id,
                debtorId: oldParticipantId,
              ),
            );
            final debtSnapshot = await transaction.get(debtRef);
            if (debtSnapshot.exists) {
              final existingDebt =
                  Debt.fromMap(debtSnapshot.id, debtSnapshot.data()!);
              if (existingDebt.status == DebtStatus.paid) {
                return const _ExpenseTransactionResult.alreadySettled();
              }
              existingDebtCreatedAt[oldParticipantId] = existingDebt.createdAt;
            }
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

          // PHASE 2: reine Berechnung im Speicher.
          final debtEntries = DebtProjection.forExpense(
            paidBy: paidBy,
            shares: shares,
          );
          final newDebtorIds = debtEntries.map((e) => e.debtorId).toSet();
          final removedParticipantIds = oldParticipantIds
              .where((id) => !participantUserIds.contains(id))
              .toSet();

          final now = DateTime.now();
          final updatedExpense = originalExpense.copyWith(
            amount: amount,
            description: description,
            paidBy: paidBy,
            updatedAt: now,
          );

          // PHASE 3: alle Writes.
          transaction.update(expenseRef, {
            'amount': amount,
            'description': description,
            'paidBy': paidBy,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Teilnehmer, die vor UND nach der Bearbeitung beteiligt sind,
          // werden per update() nur im Betrag angepasst (nicht geloescht und
          // neu erstellt), da ein delete()+set() auf dasselbe Dokument im
          // selben Batch bei komplexen Security Rules (Zugriff auf mehrere
          // verschachtelte Dokumente im selben Vorgang) zu nicht
          // auswertbaren Rules-Bedingungen fuehren kann.
          final unchangedParticipantIds = oldParticipantIds
              .toSet()
              .intersection(participantUserIds.toSet());

          for (final oldParticipantId in oldParticipantIds) {
            if (unchangedParticipantIds.contains(oldParticipantId)) {
              continue;
            }
            transaction.delete(
              expenseRef.collection('expenseShares').doc(oldParticipantId),
            );
          }
          for (final participantId in participantUserIds) {
            final shareRef =
                expenseRef.collection('expenseShares').doc(participantId);
            if (unchangedParticipantIds.contains(participantId)) {
              transaction.update(shareRef, {
                'shareAmount': shares[participantId]!,
              });
              continue;
            }
            final share = ExpenseShare(
              id: shareRef.id,
              expenseId: expenseRef.id,
              userId: participantId,
              shareAmount: shares[participantId]!,
            );
            transaction.set(shareRef, share.toMap());
          }

          // Debts fuer entfernte Teilnehmer loeschen (nur wenn noch offen -
          // durch die Paid-Protection oben bereits sichergestellt).
          for (final removedId in removedParticipantIds) {
            final debtRef = debtsCollectionRef.doc(
              Debt.buildId(expenseId: originalExpense.id, debtorId: removedId),
            );
            transaction.delete(debtRef);
          }

          // Bei einem Zahlerwechsel besass der neue Zahler zuvor unter
          // Umstaenden selbst eine offene Debt (als alter Nicht-Zahler-
          // Teilnehmer). Diese muss entfernt werden, da er nun nicht mehr
          // Schuldner, sondern Glaeubiger dieser Expense ist. Bleibt der
          // Zahler unveraendert, existiert fuer ihn nie eine Debt und
          // dieser Block bleibt folgenlos.
          if (originalExpense.paidBy != paidBy &&
              oldParticipantIds.contains(paidBy) &&
              !newDebtorIds.contains(paidBy)) {
            final debtRef = debtsCollectionRef.doc(
              Debt.buildId(expenseId: originalExpense.id, debtorId: paidBy),
            );
            transaction.delete(debtRef);
          }

          // Aktuelle Debts fuer alle Nicht-Zahler-Teilnehmer setzen. Existiert
          // bereits eine offene Debt fuer dieses Personenpaar (siehe
          // existingDebtCreatedAt oben), wird nur aktualisiert und createdAt
          // bleibt unveraendert - sonst wuerde jede Bearbeitung faelschlich
          // einen neuen createdAt-Zeitstempel setzen, was die Firestore-Rule
          // request.resource.data.createdAt == resource.data.createdAt
          // verletzt. Fuer neue Personenpaare wird die Debt neu angelegt.
          for (final entry in debtEntries) {
            final debtRef = debtsCollectionRef.doc(
              Debt.buildId(
                  expenseId: originalExpense.id, debtorId: entry.debtorId),
            );

            if (existingDebtCreatedAt.containsKey(entry.debtorId)) {
              transaction.update(debtRef, {
                'creditorId': entry.creditorId,
                'amount': entry.amountInEuro,
                'status': DebtStatus.open.name,
              });
            } else {
              final debt = Debt(
                id: debtRef.id,
                wgId: originalExpense.wgId,
                expenseId: originalExpense.id,
                creditorId: entry.creditorId,
                debtorId: entry.debtorId,
                amount: entry.amountInEuro,
                status: DebtStatus.open,
                createdAt: now,
              );
              transaction.set(debtRef, {
                ...debt.toMap(),
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
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
      case _ExpenseTransactionOutcome.alreadySettled:
        throw const ExpenseAlreadySettledException();
      case _ExpenseTransactionOutcome.success:
        return result.expense!;
    }
  }

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

  Stream<List<Expense>> watchExpenses({required String wgId}) {
    final trimmedWgId = wgId.trim();

    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }

    return firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('expenses')
        .snapshots()
        .map((snapshot) {
      final expenses = snapshot.docs
          .map((doc) => Expense.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return expenses;
    });
  }

  /// Laedt die gespeicherten Kostenanteile einer Ausgabe.
  /// Wird fuer das Vorbelegen des Bearbeitungsformulars in UC-12 verwendet.
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

    return snapshot.docs
        .map((doc) => ExpenseShare.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// UC-13 (Saldenanzeige) / Vorbereitung fuer UC-14. Laedt alle offenen
  /// und bezahlten Debts einer WG, in denen [userId] entweder Glaeubiger
  /// oder Schuldner ist.
  Future<List<Debt>> getDebtsForUser({
    required String wgId,
    required String userId,
  }) async {
    final trimmedWgId = wgId.trim();
    final trimmedUserId = userId.trim();

    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }
    if (trimmedUserId.isEmpty) {
      throw ArgumentError('Die Benutzer-ID darf nicht leer sein.');
    }

    final debtsRef =
        firestore.collection('wgs').doc(trimmedWgId).collection('debts');

    final asCreditor =
        await debtsRef.where('creditorId', isEqualTo: trimmedUserId).get();
    final asDebtor =
        await debtsRef.where('debtorId', isEqualTo: trimmedUserId).get();

    // Aeltere Debt-Dokumente aus dem frueheren aggregierten Paar-Modell
    // (vor A09 ADR-07) besitzen kein expenseId-Feld und koennen mit dem
    // aktuellen Schema nicht geparst werden. Sie werden hier uebersprungen,
    // statt die gesamte Abfrage abzubrechen; eine manuelle Bereinigung
    // dieser Legacy-Dokumente ist im Projektbericht dokumentiert.
    Debt? tryParse(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      try {
        return Debt.fromMap(doc.id, doc.data());
      } catch (_) {
        return null;
      }
    }

    final debts = <Debt>[
      ...asCreditor.docs.map(tryParse).whereType<Debt>(),
      ...asDebtor.docs.map(tryParse).whereType<Debt>(),
    ];

    return debts;
  }

  /// UC-16 Echtzeit-Erweiterung: beobachtet dieselben zwei zulaessigen
  /// Perspektiven wie [getDebtsForUser] (Glaeubiger und Schuldner) als
  /// Streams, statt die komplette `debts`-Collection zu abonnieren - das
  /// waeren die Firestore Security Rules ohnehin nicht zulaessig, da sie
  /// nur Lesezugriffe erlauben, bei denen der anfragende Nutzer selbst
  /// Glaeubiger oder Schuldner ist. Die beiden Streams werden zu einem
  /// zusammengefuehrt und nach Debt-ID dedupliziert; jedes Ereignis liefert
  /// die vollstaendige, aktuelle Liste aller relevanten Debts.
  Stream<List<Debt>> watchDebtsForUser({
    required String wgId,
    required String userId,
  }) {
    final trimmedWgId = wgId.trim();
    final trimmedUserId = userId.trim();

    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }
    if (trimmedUserId.isEmpty) {
      throw ArgumentError('Die Benutzer-ID darf nicht leer sein.');
    }

    final debtsRef =
        firestore.collection('wgs').doc(trimmedWgId).collection('debts');

    Debt? tryParse(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      try {
        return Debt.fromMap(doc.id, doc.data());
      } catch (_) {
        return null;
      }
    }

    var latestAsCreditor = <String, Debt>{};
    var latestAsDebtor = <String, Debt>{};

    final creditorStream = debtsRef
        .where('creditorId', isEqualTo: trimmedUserId)
        .snapshots()
        .map((snapshot) {
      latestAsCreditor = {
        for (final debt in snapshot.docs.map(tryParse).whereType<Debt>())
          debt.id: debt,
      };
      return <String, Debt>{...latestAsCreditor, ...latestAsDebtor};
    });

    final debtorStream = debtsRef
        .where('debtorId', isEqualTo: trimmedUserId)
        .snapshots()
        .map((snapshot) {
      latestAsDebtor = {
        for (final debt in snapshot.docs.map(tryParse).whereType<Debt>())
          debt.id: debt,
      };
      return <String, Debt>{...latestAsCreditor, ...latestAsDebtor};
    });

    return StreamGroup.merge([creditorStream, debtorStream])
        .map((merged) => merged.values.toList());
  }

  /// UC-15 – Schuld als bezahlt markieren (AF-05). Nur der Schuldner darf
  /// seine eigene offene Schuld als bezahlt markieren; das wird zusaetzlich
  /// serverseitig durch Firestore Security Rules erzwungen (siehe
  /// firestore.rules, updatesValidDebt Fall b). Der Betrag sowie
  /// creditorId, debtorId und expenseId bleiben unveraendert.
  ///
  /// Verwendet eine Firestore-Transaction, damit ein gleichzeitiger
  /// zweiter Bezahlversuch (z.B. von einem anderen Tab) nicht zu einem
  /// inkonsistenten Zustand fuehrt: der Status wird innerhalb derselben
  /// Transaktion gelesen und geprueft, bevor geschrieben wird.
  Future<void> markDebtAsPaid({
    required String wgId,
    required String debtId,
  }) async {
    final trimmedWgId = wgId.trim();
    final trimmedDebtId = debtId.trim();

    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }
    if (trimmedDebtId.isEmpty) {
      throw ArgumentError('Die Debt-ID darf nicht leer sein.');
    }

    final activeFirestore = firestore;
    final debtRef = activeFirestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('debts')
        .doc(trimmedDebtId);

    try {
      await activeFirestore.runTransaction<void>((transaction) async {
        final debtSnapshot = await transaction.get(debtRef);

        if (!debtSnapshot.exists || debtSnapshot.data() == null) {
          throw const DebtNotFoundException();
        }

        final debt = Debt.fromMap(debtSnapshot.id, debtSnapshot.data()!);

        if (debt.status == DebtStatus.paid) {
          throw const DebtAlreadyPaidException();
        }

        transaction.update(debtRef, {
          'status': DebtStatus.paid.name,
          'paidAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      if (error.code == 'unavailable') {
        throw const ExpenseRequiresConnectionException();
      }
      rethrow;
    } on TimeoutException {
      throw const ExpenseRequiresConnectionException();
    }
  }
}
