import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/expense.dart';
import '../../../domain/models/expense_share.dart';
import '../domain/expense_calculator.dart';
import '../domain/expense_service.dart';

class FirestoreExpenseService implements ExpenseService {
  FirestoreExpenseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _expensesRef(String wgId) =>
      _firestore.collection('wgs').doc(wgId).collection('expenses');

  CollectionReference<Map<String, dynamic>> _sharesRef(
          String wgId, String expenseId) =>
      _expensesRef(wgId).doc(expenseId).collection('expenseShares');

  @override
  Future<AddExpenseResult> addExpense({
    required String wgId,
    required String paidBy,
    required double amount,
    required String description,
    required List<String> participantIds,
    required List<String> wgMemberIds,
  }) async {
    // 1. Validierung im Service (nicht nur im Widget)
    if (!amount.isFinite || amount <= 0) {
      throw const InvalidExpenseAmountException(
          'Betrag muss groesser als 0 und endlich sein.');
    }
    if (!ExpenseCalculator.hasValidPrecision(amount)) {
      throw const InvalidExpenseAmountException(
          'Betrag darf maximal 2 Nachkommastellen haben.');
    }
    if (description.trim().isEmpty) {
      throw const InvalidExpenseDescriptionException();
    }
    if (participantIds.isEmpty) {
      throw const NoParticipantsException();
    }
    final uniqueIds = participantIds.toSet();
    if (uniqueIds.length != participantIds.length) {
      throw const DuplicateParticipantsException();
    }
    final memberSet = wgMemberIds.toSet();
    if (!memberSet.contains(paidBy)) {
      throw ParticipantNotInWgException(paidBy);
    }
    for (final id in participantIds) {
      if (!memberSet.contains(id)) {
        throw ParticipantNotInWgException(id);
      }
    }

    // 2. Cent-genaue Berechnung (AF-01)
    final amountInCents = ExpenseCalculator.euroToCents(amount);
    final sharesInCents = ExpenseCalculator.splitInCents(
      amountInCents: amountInCents,
      participantIds: participantIds,
    );

    // 3. Atomares Speichern: Expense + ExpenseShares in einem Batch
    final batch = _firestore.batch();
    final expenseRef = _expensesRef(wgId).doc();
    final now = FieldValue.serverTimestamp();

    final expenseData = {
      'wgId': wgId,
      'amount': amount,
      'description': description.trim(),
      'paidBy': paidBy,
      'createdAt': now,
    };
    batch.set(expenseRef, expenseData);

    final createdShares = <ExpenseShare>[];
    for (final entry in sharesInCents.entries) {
      final userId = entry.key;
      final cents = entry.value;

      // 0-Cent-Anteile: Share speichern aber keine Debt
      final shareAmount = cents / 100.0;
      final shareRef = _sharesRef(wgId, expenseRef.id).doc();
      final shareData = {
        'expenseId': expenseRef.id,
        'userId': userId,
        'shareAmount': shareAmount,
      };
      batch.set(shareRef, shareData);

      createdShares.add(ExpenseShare(
        id: shareRef.id,
        expenseId: expenseRef.id,
        userId: userId,
        shareAmount: shareAmount,
      ));
    }

    await batch.commit();

    // 4. Expense-Objekt mit lokaler Zeit zurueckgeben
    final expense = Expense(
      id: expenseRef.id,
      wgId: wgId,
      amount: amount,
      description: description.trim(),
      paidBy: paidBy,
      createdAt: DateTime.now(),
    );

    return AddExpenseResult(expense: expense, shares: createdShares);
  }
}
