import '../../../domain/models/debt.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/expense_share.dart';

class ExpenseNotFoundException implements Exception {
  const ExpenseNotFoundException();
}

class InvalidExpenseAmountException implements Exception {
  const InvalidExpenseAmountException();
}

class NoParticipantsException implements Exception {
  const NoParticipantsException();
}

class DebtNotFoundException implements Exception {
  const DebtNotFoundException();
}

class DebtAlreadyPaidException implements Exception {
  const DebtAlreadyPaidException();
}

abstract class ExpenseService {
  Future<Expense> addExpense({
    required String wgId,
    required String paidBy,
    required double amount,
    required String description,
    required List<String> participantIds,
  });

  Future<Expense> updateExpense({
    required String wgId,
    required String expenseId,
    required double amount,
    required String description,
    required List<String> participantIds,
  });

  Future<List<ExpenseShare>> splitExpense({
    required String wgId,
    required String expenseId,
    required List<String> participantIds,
  });

  Stream<List<Debt>> watchDebts({
    required String wgId,
    required String userId,
  });

  Future<Debt> markDebtAsPaid({
    required String wgId,
    required String debtId,
  });

  Stream<List<Expense>> watchExpenses({
    required String wgId,
  });

  Future<double> calculateBalance({
    required String wgId,
    required String userId,
  });
}
