import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/models/balance_summary.dart';
import '../../../domain/models/debt.dart';
import '../../../domain/models/expense.dart';
import '../../wg/application/wg_service.dart';
import '../application/expense_service.dart';
import 'expense_edit_page.dart';
import 'expense_form_page.dart';

class _OwnSharesLoadResult {
  const _OwnSharesLoadResult.success(this.shares) : hasError = false;

  const _OwnSharesLoadResult.failure()
      : shares = const <String, double>{},
        hasError = true;

  final Map<String, double> shares;
  final bool hasError;
}

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
  late Future<List<Debt>> _debtsFuture;
  late Future<_OwnSharesLoadResult> _ownSharesFuture;

  StreamSubscription<List<Expense>>? _expensesSubscription;
  StreamSubscription<List<Debt>>? _debtsSubscription;

  @override
  void initState() {
    super.initState();

    _reloadFinancialData();

    _expensesSubscription =
        _expenseService.watchExpenses(wgId: widget.wgId).listen((_) {
      if (mounted) {
        _reloadFinancialData();
      }
    });

    // UC-16 Echtzeit-Erweiterung: eine Statusaenderung einer Debt (z.B.
    // UC-15 open -> paid) aendert kein Expense-Dokument und wuerde sonst
    // von der Expense-Subscription oben nicht erkannt.
    _debtsSubscription = _expenseService
        .watchDebtsForUser(wgId: widget.wgId, userId: widget.userId)
        .listen((_) {
      if (mounted) {
        _reloadFinancialData();
      }
    });
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel();
    _debtsSubscription?.cancel();
    super.dispose();
  }

  Future<_OwnSharesLoadResult> _loadOwnShares(
    Future<List<Expense>> expensesFuture,
  ) async {
    try {
      final expenses = await expensesFuture;

      final results = await Future.wait(
        expenses.map((expense) async {
          final shares = await _expenseService.getExpenseShares(
            wgId: widget.wgId,
            expenseId: expense.id,
          );

          for (final share in shares) {
            if (share.userId == widget.userId) {
              return MapEntry<String, double>(
                expense.id,
                share.shareAmount,
              );
            }
          }

          return null;
        }),
      );

      final ownShares = <String, double>{
        for (final entry in results.whereType<MapEntry<String, double>>())
          entry.key: entry.value,
      };

      return _OwnSharesLoadResult.success(ownShares);
    } catch (_) {
      return const _OwnSharesLoadResult.failure();
    }
  }

  /// Laedt Mitgliedsnamen, Ausgaben und Schulden koordiniert neu.
  Future<void> _reloadFinancialData() async {
    final membersFuture = _loadMembers();

    final expensesFuture = membersFuture.then(
      (_) => _expenseService.getExpenses(wgId: widget.wgId),
    );

    final debtsFuture = membersFuture.then(
      (_) => _expenseService.getDebtsForUser(
        wgId: widget.wgId,
        userId: widget.userId,
      ),
    );

    final ownSharesFuture = _loadOwnShares(expensesFuture);

    if (!mounted) {
      return;
    }

    setState(() {
      _expensesFuture = expensesFuture;
      _debtsFuture = debtsFuture;
      _ownSharesFuture = ownSharesFuture;
    });
  }

  Future<void> _loadMembers() async {
    final members = await _wgService.loadWgMembers(wgId: widget.wgId);
    _memberLabels = {
      for (final member in members) member.userId: member.displayLabel,
    };
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
      await _reloadFinancialData();
    }
  }

  Future<void> _openEditExpense(Expense expense) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ExpenseEditPage(
          expense: expense,
          userId: widget.userId,
          wgService: _wgService,
          expenseService: _expenseService,
        ),
      ),
    );

    if (result == true && mounted) {
      await _reloadFinancialData();
    }
  }

  Widget _buildBalanceBar(BuildContext context) {
    return FutureBuilder<List<Debt>>(
      future: _debtsFuture,
      builder: (context, debtSnapshot) {
        if (debtSnapshot.connectionState != ConnectionState.done ||
            !debtSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final summary = BalanceSummary.fromDebts(
          userId: widget.userId,
          debts: debtSnapshot.data!,
        );
        if (summary.balances.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saldo', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...summary.balances.entries.map((entry) {
                final label = _labelFor(entry.key);
                final amount = entry.value;
                final isPositive = amount > 0;
                final text = isPositive
                    ? '$label schuldet dir ${amount.toStringAsFixed(2)} €'
                    : '${amount.abs().toStringAsFixed(2)} € an $label offen';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isPositive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDebtSection(BuildContext context) {
    return FutureBuilder<List<Debt>>(
      future: _debtsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Schulden konnten nicht geladen werden.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _reloadFinancialData,
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          );
        }

        final debts = List<Debt>.of(snapshot.data ?? const <Debt>[]);
        if (debts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Keine Schulden vorhanden.'),
          );
        }

        debts.sort((a, b) {
          if (a.status != b.status) {
            return a.status == DebtStatus.open ? -1 : 1;
          }
          return b.createdAt.compareTo(a.createdAt);
        });

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Schulden', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView(
                  shrinkWrap: true,
                  children: debts
                      .map((debt) => _buildDebtTile(context, debt))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDebtTile(BuildContext context, Debt debt) {
    final isCreditor = debt.creditorId == widget.userId;
    final counterpartyId = isCreditor ? debt.debtorId : debt.creditorId;
    final counterpartyLabel = _labelFor(counterpartyId);
    final isPaid = debt.status == DebtStatus.paid;
    final isOwnDebt = debt.debtorId == widget.userId;

    final title = isCreditor
        ? '$counterpartyLabel schuldet dir ${debt.amount.toStringAsFixed(2)} €'
        : 'Du schuldest $counterpartyLabel ${debt.amount.toStringAsFixed(2)} €';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        trailing: Chip(
          label: Text(isPaid ? 'Bezahlt' : 'Offen'),
          backgroundColor: isPaid
              ? Colors.grey.shade300
              : (isCreditor ? Colors.green.shade100 : Colors.red.shade100),
        ),
        subtitle: (!isPaid && isOwnDebt)
            ? Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _confirmMarkAsPaid(context, debt),
                  child: const Text('Als bezahlt markieren'),
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _confirmMarkAsPaid(BuildContext context, Debt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schuld als bezahlt markieren?'),
        content: const Text(
          'Moechtest du diese Schuld wirklich als bezahlt markieren?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Als bezahlt markieren'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _expenseService.markDebtAsPaid(
        wgId: widget.wgId,
        debtId: debt.id,
      );
      if (!mounted) {
        return;
      }
      await _reloadFinancialData();
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Die Schuld konnte nicht als bezahlt markiert werden.'),
        ),
      );
      await _reloadFinancialData();
    }
  }

  Widget _buildExpenseList(BuildContext context) {
    return FutureBuilder<List<Expense>>(
      future: _expensesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Ausgaben konnten nicht geladen werden.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _reloadFinancialData,
                    child: const Text('Erneut versuchen'),
                  ),
                ],
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

        return FutureBuilder<_OwnSharesLoadResult>(
          future: _ownSharesFuture,
          builder: (context, shareSnapshot) {
            if (shareSnapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final shareResult = shareSnapshot.data;

            if (shareSnapshot.hasError ||
                shareResult == null ||
                shareResult.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Kostenanteile konnten nicht geladen werden.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _reloadFinancialData,
                        child: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final ownShareByExpenseId = shareResult.shares;

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
                final ownShare = ownShareByExpenseId[expense.id];
                final subtitleText = ownShare == null
                    ? '${_labelFor(expense.paidBy)} • ${expense.amount.toStringAsFixed(2)} €'
                    : '${_labelFor(expense.paidBy)} • ${expense.amount.toStringAsFixed(2)} € • Dein Anteil: ${ownShare.toStringAsFixed(2)} €';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(expense.description),
                    subtitle: Text(subtitleText),
                    trailing: IconButton(
                      tooltip: 'Ausgabe bearbeiten',
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openEditExpense(expense),
                    ),
                    onTap: () => _openEditExpense(expense),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.wgName)),
      body: Column(
        children: [
          _buildBalanceBar(context),
          _buildDebtSection(context),
          const Divider(height: 1),
          Expanded(child: _buildExpenseList(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpense,
        icon: const Icon(Icons.add),
        label: const Text('Ausgabe hinzufügen'),
      ),
    );
  }
}
