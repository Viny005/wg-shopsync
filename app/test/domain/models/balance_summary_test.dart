import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/balance_summary.dart';
import 'package:wg_shopsync/src/domain/models/debt.dart';

void main() {
  final createdAt = DateTime(2026, 9, 19);

    Debt debt({
    required String creditorId,
    required String debtorId,
    required double amount,
    DebtStatus status = DebtStatus.open,
    String expenseId = 'expense-1',
  }) {
    return Debt(
      id: '${expenseId}_$debtorId',
      wgId: 'wg-1',
      expenseId: expenseId,
      creditorId: creditorId,
      debtorId: debtorId,
      amount: amount,
      status: status,
      createdAt: createdAt,
    );
  }

  group('BalanceSummary.fromDebts', () {
    test('zeigt positiven Saldo wenn der Nutzer Glaeubiger ist', () {
      final summary = BalanceSummary.fromDebts(
        userId: 'user-a',
        debts: [debt(creditorId: 'user-a', debtorId: 'user-b', amount: 10)],
      );

      expect(summary.balances['user-b'], 10);
      expect(summary.totalBalance, 10);
    });

    test('zeigt negativen Saldo wenn der Nutzer Schuldner ist', () {
      final summary = BalanceSummary.fromDebts(
        userId: 'user-a',
        debts: [debt(creditorId: 'user-b', debtorId: 'user-a', amount: 10)],
      );

      expect(summary.balances['user-b'], -10);
      expect(summary.totalBalance, -10);
    });

    test('ignoriert bezahlte Schulden', () {
      final summary = BalanceSummary.fromDebts(
        userId: 'user-a',
        debts: [
          debt(
            creditorId: 'user-a',
            debtorId: 'user-b',
            amount: 10,
            status: DebtStatus.paid,
          ),
        ],
      );

      expect(summary.balances, isEmpty);
    });

    test('ignoriert Debts, an denen der Nutzer nicht beteiligt ist', () {
      final summary = BalanceSummary.fromDebts(
        userId: 'user-a',
        debts: [debt(creditorId: 'user-b', debtorId: 'user-c', amount: 10)],
      );

      expect(summary.balances, isEmpty);
    });

    test('verrechnet zwei gegenlaeufige Debts derselben Gegenpartei netto', () {
      final summary = BalanceSummary.fromDebts(
        userId: 'user-a',
        debts: [
          debt(creditorId: 'user-a', debtorId: 'user-b', amount: 10),
          debt(creditorId: 'user-b', debtorId: 'user-a', amount: 4),
        ],
      );

      expect(summary.balances['user-b'], closeTo(6, 0.001));
    });

    test('entfernt Saldo nahe null nach Verrechnung', () {
      final summary = BalanceSummary.fromDebts(
        userId: 'user-a',
        debts: [
          debt(creditorId: 'user-a', debtorId: 'user-b', amount: 10),
          debt(creditorId: 'user-b', debtorId: 'user-a', amount: 10),
        ],
      );

      expect(summary.balances, isEmpty);
    });

    test('fasst mehrere Gegenparteien getrennt zusammen', () {
      final summary = BalanceSummary.fromDebts(
        userId: 'user-a',
        debts: [
          debt(creditorId: 'user-a', debtorId: 'user-b', amount: 10),
          debt(creditorId: 'user-c', debtorId: 'user-a', amount: 4),
        ],
      );

      expect(summary.balances['user-b'], 10);
      expect(summary.balances['user-c'], -4);
      expect(summary.totalBalance, closeTo(6, 0.001));
    });

    test('leere Debt-Liste ergibt leeren Saldo', () {
      final summary = BalanceSummary.fromDebts(userId: 'user-a', debts: []);

      expect(summary.balances, isEmpty);
      expect(summary.totalBalance, 0);
    });
  });
}