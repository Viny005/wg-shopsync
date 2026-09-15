import 'package:flutter/material.dart';

import '../../../domain/models/debt.dart';
import '../../../domain/models/expense.dart';
import '../domain/expense_service.dart';

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({
    super.key,
    required this.wgId,
    required this.userId,
    required this.expenseService,
  });

  final String wgId;
  final String userId;
  final ExpenseService expenseService;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kostenübersicht'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ausgaben'),
              Tab(text: 'Schulden'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ExpenseTab(wgId: wgId, expenseService: expenseService),
            _DebtTab(wgId: wgId, userId: userId, expenseService: expenseService),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _AddExpensePlaceholder(
                  wgId: wgId,
                  userId: userId,
                  expenseService: expenseService,
                ),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Ausgabe hinzufügen'),
        ),
      ),
    );
  }
}

class _ExpenseTab extends StatelessWidget {
  const _ExpenseTab({required this.wgId, required this.expenseService});

  final String wgId;
  final ExpenseService expenseService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Expense>>(
      stream: expenseService.watchExpenses(wgId: wgId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        }
        final expenses = snapshot.data ?? [];
        if (expenses.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Keine Ausgaben vorhanden'),
                SizedBox(height: 8),
                Text(
                  'Tippe auf + um eine Ausgabe hinzuzufügen.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.euro)),
                title: Text(expense.description),
                subtitle: Text('Bezahlt von: ${expense.paidBy}'),
                trailing: Text(
                  '${expense.amount.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DebtTab extends StatelessWidget {
  const _DebtTab({
    required this.wgId,
    required this.userId,
    required this.expenseService,
  });

  final String wgId;
  final String userId;
  final ExpenseService expenseService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Debt>>(
      stream: expenseService.watchDebts(wgId: wgId, userId: userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        }
        final debts = snapshot.data ?? [];
        if (debts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('Keine offenen Schulden'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: debts.length,
          itemBuilder: (context, index) {
            final debt = debts[index];
            final isPaid = debt.status == DebtStatus.paid;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPaid ? Colors.green : Colors.orange,
                  child: Icon(
                    isPaid ? Icons.check : Icons.hourglass_empty,
                    color: Colors.white,
                  ),
                ),
                title: Text('${debt.amount.toStringAsFixed(2)} €'),
                subtitle: Text(isPaid ? 'Bezahlt' : 'Offen'),
                trailing: isPaid
                    ? null
                    : FilledButton(
                        onPressed: () async {
                          await expenseService.markDebtAsPaid(
                            wgId: wgId,
                            debtId: debt.id,
                          );
                        },
                        child: const Text('Bezahlt'),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AddExpensePlaceholder extends StatelessWidget {
  const _AddExpensePlaceholder({
    required this.wgId,
    required this.userId,
    required this.expenseService,
  });

  final String wgId;
  final String userId;
  final ExpenseService expenseService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ausgabe hinzufügen')),
      body: const Center(child: Text('Formular folgt in add_expense_page.dart')),
    );
  }
}
