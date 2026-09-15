import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/debt.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/expense_share.dart';
import '../domain/expense_service.dart';

class FirestoreExpenseService implements ExpenseService {
  FirestoreExpenseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference _expensesRef(String wgId) =>
      _firestore.collection('wgs').doc(wgId).collection('expenses');

  CollectionReference _sharesRef(String wgId, String expenseId) =>
      _expensesRef(wgId).doc(expenseId).collection('expenseShares');

  CollectionReference _debtsRef(String wgId) =>
      _firestore.collection('wgs').doc(wgId).collection('debts');

  @override
  Future<Expense> addExpense({
    required String wgId,
    required String paidBy,
    required double amount,
    required String description,
    required List<String> participantIds,
  }) async {
    if (amount <= 0) throw const InvalidExpenseAmountException();
    if (participantIds.isEmpty) throw const NoParticipantsException();

    final ref = _expensesRef(wgId).doc();
    final now = DateTime.now();
    final expense = Expense(
      id: ref.id,
      wgId: wgId,
      amount: amount,
      description: description,
      paidBy: paidBy,
      createdAt: now,
    );

    await ref.set(expense.toMap());
    await _createShares(wgId, expense, participantIds);
    return expense;
  }

  @override
  Future<Expense> updateExpense({
    required String wgId,
    required String expenseId,
    required double amount,
    required String description,
    required List<String> participantIds,
  }) async {
    if (amount <= 0) throw const InvalidExpenseAmountException();
    if (participantIds.isEmpty) throw const NoParticipantsException();

    final ref = _expensesRef(wgId).doc(expenseId);
    final doc = await ref.get();
    if (!doc.exists) throw const ExpenseNotFoundException();

    await ref.update({'amount': amount, 'description': description});

    final sharesSnap = await _sharesRef(wgId, expenseId).get();
    for (final d in sharesSnap.docs) {
      await d.reference.delete();
    }

    final existing = Expense.fromMap(doc.id, doc.data()! as Map<String, dynamic>);
    await _createShares(wgId, existing, participantIds);
    return existing;
  }

  Future<void> _createShares(
    String wgId,
    Expense expense,
    List<String> participantIds,
  ) async {
    final n = participantIds.length;
    final totalCents = (expense.amount * 100).round();
    final base = totalCents ~/ n;
    final remainder = totalCents - base * n;
    final batch = _firestore.batch();

    for (var i = 0; i < n; i++) {
      final cents = base + (i < remainder ? 1 : 0);
      final shareAmount = cents / 100.0;
      final shareRef = _sharesRef(wgId, expense.id).doc();
      final share = ExpenseShare(
        id: shareRef.id,
        expenseId: expense.id,
        userId: participantIds[i],
        shareAmount: shareAmount,
      );
      batch.set(shareRef, share.toMap());

      if (participantIds[i] != expense.paidBy) {
        final debtRef = _debtsRef(wgId).doc();
        final debt = Debt(
          id: debtRef.id,
          wgId: wgId,
          creditorId: expense.paidBy,
          debtorId: participantIds[i],
          amount: shareAmount,
          status: DebtStatus.open,
          createdAt: DateTime.now(),
        );
        batch.set(debtRef, debt.toMap());
      }
    }
    await batch.commit();
  }

  @override
  Future<List<ExpenseShare>> splitExpense({
    required String wgId,
    required String expenseId,
    required List<String> participantIds,
  }) async {
    final expenseDoc = await _expensesRef(wgId).doc(expenseId).get();
    if (!expenseDoc.exists) throw const ExpenseNotFoundException();
    final expense = Expense.fromMap(expenseDoc.id, expenseDoc.data()! as Map<String, dynamic>);
    await _createShares(wgId, expense, participantIds);
    final sharesSnap = await _sharesRef(wgId, expenseId).get();
    return sharesSnap.docs
        .map((d) => ExpenseShare.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<Debt>> watchDebts({
    required String wgId,
    required String userId,
  }) {
    return _debtsRef(wgId)
        .where('debtorId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Debt.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Future<Debt> markDebtAsPaid({
    required String wgId,
    required String debtId,
  }) async {
    final ref = _debtsRef(wgId).doc(debtId);
    final doc = await ref.get();
    if (!doc.exists) throw const DebtNotFoundException();
    final debt = Debt.fromMap(doc.id, doc.data()! as Map<String, dynamic>);
    if (debt.status == DebtStatus.paid) throw const DebtAlreadyPaidException();
    final now = DateTime.now();
    await ref.update({'status': 'paid', 'paidAt': now.toIso8601String()});
    return Debt(
      id: debt.id,
      wgId: debt.wgId,
      creditorId: debt.creditorId,
      debtorId: debt.debtorId,
      amount: debt.amount,
      status: DebtStatus.paid,
      paidAt: now,
      createdAt: debt.createdAt,
    );
  }

  @override
  Stream<List<Expense>> watchExpenses({required String wgId}) {
    return _expensesRef(wgId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Expense.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Future<double> calculateBalance({
    required String wgId,
    required String userId,
  }) async {
    final debtsOwed = await _debtsRef(wgId)
        .where('debtorId', isEqualTo: userId)
        .where('status', isEqualTo: 'open')
        .get();
    final debtsReceivable = await _debtsRef(wgId)
        .where('creditorId', isEqualTo: userId)
        .where('status', isEqualTo: 'open')
        .get();

    double owed = 0;
    for (final d in debtsOwed.docs) {
      owed += (d.data() as Map<String, dynamic>)['amount'] as double;
    }
    double receivable = 0;
    for (final d in debtsReceivable.docs) {
      receivable += (d.data() as Map<String, dynamic>)['amount'] as double;
    }
    return receivable - owed;
  }
}
