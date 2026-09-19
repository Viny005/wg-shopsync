import 'package:wg_shopsync/src/domain/models/expense.dart';
import 'package:wg_shopsync/src/domain/models/expense_share.dart';
import 'package:wg_shopsync/src/features/expense/application/expense_service.dart';

class FakeExpenseService extends ExpenseService {
  FakeExpenseService({
    this.expenses = const [],
    this.shares = const [],
    this.getExpensesError,
    this.getExpenseSharesError,
    this.createExpenseError,
    this.updateExpenseError,
    this.createExpenseResult,
    this.updateExpenseResult,
  });

  List<Expense> expenses;
  List<ExpenseShare> shares;

  Object? getExpensesError;
  Object? getExpenseSharesError;
  Object? createExpenseError;
  Object? updateExpenseError;

  Expense? createExpenseResult;
  Expense? updateExpenseResult;

  int getExpensesCalls = 0;
  int getExpenseSharesCalls = 0;
  int createExpenseCalls = 0;
  int updateExpenseCalls = 0;

  String? lastAmountWgId;
  double? lastAmount;
  String? lastDescription;
  String? lastPaidBy;
  List<String>? lastParticipantUserIds;
  Expense? lastOriginalExpense;

  @override
  Future<List<Expense>> getExpenses({required String wgId}) async {
    getExpensesCalls++;
    if (getExpensesError != null) {
      throw getExpensesError!;
    }
    return expenses;
  }

  @override
  Future<List<ExpenseShare>> getExpenseShares({
    required String wgId,
    required String expenseId,
  }) async {
    getExpenseSharesCalls++;
    if (getExpenseSharesError != null) {
      throw getExpenseSharesError!;
    }
    return shares.where((share) => share.expenseId == expenseId).toList();
  }

  @override
  Future<Expense> createExpense({
    required String wgId,
    required double amount,
    required String description,
    required String paidBy,
    required List<String> participantUserIds,
    String? shoppingItemId,
    String? receiptUrl,
  }) async {
    createExpenseCalls++;
    lastAmountWgId = wgId;
    lastAmount = amount;
    lastDescription = description;
    lastPaidBy = paidBy;
    lastParticipantUserIds = participantUserIds;

    if (createExpenseError != null) {
      throw createExpenseError!;
    }

    return createExpenseResult ??
        Expense(
          id: 'fake-expense-id',
          wgId: wgId,
          amount: amount,
          description: description,
          paidBy: paidBy,
          shoppingItemId: shoppingItemId,
          receiptUrl: receiptUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  @override
  Future<Expense> updateExpense({
    required Expense originalExpense,
    required double amount,
    required String description,
    required String paidBy,
    required List<String> participantUserIds,
  }) async {
    updateExpenseCalls++;
    lastOriginalExpense = originalExpense;
    lastAmount = amount;
    lastDescription = description;
    lastPaidBy = paidBy;
    lastParticipantUserIds = participantUserIds;

    if (updateExpenseError != null) {
      throw updateExpenseError!;
    }

    return updateExpenseResult ??
        originalExpense.copyWith(
          amount: amount,
          description: description,
          paidBy: paidBy,
          updatedAt: DateTime.now(),
        );
  }
}
