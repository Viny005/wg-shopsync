import 'package:flutter/material.dart';

import '../../wg/application/wg_service.dart';
import '../../../domain/models/expense.dart';
import '../application/expense_service.dart';
import 'expense_form_page.dart';

class ExpenseOverviewPage extends StatefulWidget {
  const ExpenseOverviewPage({
    super.key,
    required this.wgId,
    required this.wgName,
    required this.userId,
    this.expenseService,
    this.wgService,
  });

  final String wgId;
  final String wgName;
  final String userId;
  final ExpenseService? expenseService;
  final WgService? wgService;

  @override
  State<ExpenseOverviewPage> createState() => _ExpenseOverviewPageState();
}

class _ExpenseOverviewPageState extends State<ExpenseOverviewPage> {
  late final ExpenseService _expenseService =
      widget.expenseService ?? ExpenseService();
  late final WgService _wgService = widget.wgService ?? WgService();
  Map<String, String> _memberLabels = const {};

  late Future<List<Expense>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _expensesFuture = _loadExpenses();
  }

  Future<List<Expense>> _loadExpenses() async {
    final members = await _wgService.loadWgMembers(wgId: widget.wgId);
    _memberLabels = {
      for (final member in members) member.userId: member.displayLabel,
    };
    return _expenseService.getExpenses(wgId: widget.wgId);
  }

  String _labelFor(String userId) =>
      _memberLabels[userId] ?? 'Unbekanntes Mitglied';

  Future<void> _openAddExpense() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ExpenseFormPage(
          wgId: widget.wgId,
          userId: widget.userId,
          expenseService: _expenseService,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _expensesFuture = _loadExpenses();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wgName),
      ),
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ausgaben konnten nicht geladen werden.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final expenses = snapshot.data ?? const <Expense>[];

          if (expenses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Noch keine Ausgaben erfasst.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _openAddExpense,
                      icon: const Icon(Icons.add),
                      label: const Text('Ausgabe hinzufügen'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length + 1,
            itemBuilder: (context, index) {
              if (index == expenses.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton.icon(
                    onPressed: _openAddExpense,
                    icon: const Icon(Icons.add),
                    label: const Text('Ausgabe hinzufügen'),
                  ),
                );
              }

              final expense = expenses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(expense.description),
                  subtitle: Text(
                    '${_labelFor(expense.paidBy)} • ${expense.amount.toStringAsFixed(2)} €',
                  ),
                  trailing: Text(
                    expense.createdAt.toLocal().toString().split(' ')[0],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpense,
        icon: const Icon(Icons.add),
        label: const Text('Ausgabe hinzufügen'),
      ),
    );
  }
}
