import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/debt.dart';
import 'package:wg_shopsync/src/domain/models/membership.dart';
import 'package:wg_shopsync/src/features/expense/presentation/expense_overview_page.dart';

import '../../../support/fake_expense_service.dart';
import '../../../support/fake_wg_service.dart';

void main() {
  const currentUid = 'uid-anna-8Z62';
  const otherUid = 'uid-tom-T7zv';
  const wgId = 'wg-1';
  final joinedAt = DateTime(2026, 9, 17);

  FakeWgService buildWgService() {
    return FakeWgService()
      ..members = [
        Membership(
          id: currentUid,
          userId: currentUid,
          wgId: wgId,
          role: MembershipRole.admin,
          joinedAt: joinedAt,
          displayName: 'Anna Beispiel',
        ),
        Membership(
          id: otherUid,
          userId: otherUid,
          wgId: wgId,
          role: MembershipRole.member,
          joinedAt: joinedAt,
          displayName: 'Tom Beispiel',
        ),
      ];
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required FakeExpenseService expenseService,
    FakeWgService? wgService,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseOverviewPage(
          wgId: wgId,
          wgName: 'WG Beispiel',
          userId: currentUid,
          expenseService: expenseService,
          wgService: wgService ?? buildWgService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('UC-14: ExpenseOverviewPage Schuldenanzeige', () {
    testWidgets('zeigt eigene Forderung als Glaeubiger', (tester) async {
      await pumpPage(
        tester,
        expenseService: FakeExpenseService(
          debts: [
            Debt(
              id: 'expense-1_$otherUid',
              wgId: wgId,
              expenseId: 'expense-1',
              creditorId: currentUid,
              debtorId: otherUid,
              amount: 8.5,
              status: DebtStatus.open,
              createdAt: DateTime(2026, 9, 18),
            ),
          ],
        ),
      );

      // Bei genau einer Schuld zeigen Saldo-Balken (Uebersicht) und
      // Schuldenliste (Detail) denselben Text - beides ist gewollt.
      expect(find.text('Tom Beispiel schuldet dir 8.50 €'), findsWidgets);
      expect(find.text('Offen'), findsOneWidget);
    });

    testWidgets('zeigt eigene Verbindlichkeit als Schuldner', (tester) async {
      await pumpPage(
        tester,
        expenseService: FakeExpenseService(
          debts: [
            Debt(
              id: 'expense-1_$currentUid',
              wgId: wgId,
              expenseId: 'expense-1',
              creditorId: otherUid,
              debtorId: currentUid,
              amount: 10,
              status: DebtStatus.open,
              createdAt: DateTime(2026, 9, 18),
            ),
          ],
        ),
      );

      expect(find.text('Du schuldest Tom Beispiel 10.00 €'), findsOneWidget);
      expect(find.text('Offen'), findsOneWidget);
    });

    testWidgets('zeigt bezahlte Schuld mit Status Bezahlt', (tester) async {
      await pumpPage(
        tester,
        expenseService: FakeExpenseService(
          debts: [
            Debt(
              id: 'expense-1_$otherUid',
              wgId: wgId,
              expenseId: 'expense-1',
              creditorId: currentUid,
              debtorId: otherUid,
              amount: 5,
              status: DebtStatus.paid,
              paidAt: DateTime(2026, 9, 19),
              createdAt: DateTime(2026, 9, 18),
            ),
          ],
        ),
      );

      expect(find.text('Bezahlt'), findsOneWidget);
      expect(find.text('Offen'), findsNothing);
    });

    testWidgets('zeigt Hinweis bei keinen Schulden', (tester) async {
      await pumpPage(
        tester,
        expenseService: FakeExpenseService(debts: const []),
      );

      expect(find.text('Keine Schulden vorhanden.'), findsOneWidget);
    });

    testWidgets('zeigt Fehlermeldung wenn Laden fehlschlaegt', (tester) async {
      await pumpPage(
        tester,
        expenseService: FakeExpenseService(
          getDebtsForUserError: Exception('offline'),
        ),
      );

      expect(
        find.text('Schulden konnten nicht geladen werden.'),
        findsOneWidget,
      );
    });

    testWidgets('zeigt Retry-Button bei Ladefehler und laedt danach neu',
        (tester) async {
      final expenseService = FakeExpenseService(
        getDebtsForUserError: Exception('offline'),
      );
      await pumpPage(tester, expenseService: expenseService);

      expect(find.text('Erneut versuchen'), findsOneWidget);
      expect(expenseService.getDebtsForUserCalls, 1);

      expenseService.getDebtsForUserError = null;
      await tester.tap(find.text('Erneut versuchen'));
      await tester.pumpAndSettle();

      expect(expenseService.getDebtsForUserCalls, 2);
      expect(find.text('Erneut versuchen'), findsNothing);
    });

    testWidgets(
        'zeigt Mitgliedsnamen statt Unbekanntes Mitglied, auch wenn Debts vor den Mitgliedsdaten laden',
        (tester) async {
      final wgService = buildWgService()
        ..loadWgMembersDelay = const Duration(milliseconds: 50);

      await pumpPage(
        tester,
        expenseService: FakeExpenseService(
          debts: [
            Debt(
              id: 'expense-1_$otherUid',
              wgId: wgId,
              expenseId: 'expense-1',
              creditorId: currentUid,
              debtorId: otherUid,
              amount: 8.5,
              status: DebtStatus.open,
              createdAt: DateTime(2026, 9, 18),
            ),
          ],
        ),
        wgService: wgService,
      );

      expect(find.textContaining('Unbekanntes Mitglied'), findsNothing);
      expect(find.textContaining('Tom Beispiel'), findsWidgets);
    });

    testWidgets('zeigt niemals eine rohe UID im Text an', (tester) async {
      await pumpPage(
        tester,
        expenseService: FakeExpenseService(
          debts: [
            Debt(
              id: 'expense-1_$otherUid',
              wgId: wgId,
              expenseId: 'expense-1',
              creditorId: currentUid,
              debtorId: otherUid,
              amount: 8.5,
              status: DebtStatus.open,
              createdAt: DateTime(2026, 9, 18),
            ),
          ],
        ),
      );

      expect(find.textContaining(otherUid), findsNothing);
      expect(find.textContaining(currentUid), findsNothing);
    });

    testWidgets('ruft getDebtsForUser mit korrekter wgId und userId auf', (
      tester,
    ) async {
      final service = FakeExpenseService(debts: const []);
      await pumpPage(tester, expenseService: service);

      expect(service.getDebtsForUserCalls, 1);
      expect(service.lastDebtsWgId, wgId);
      expect(service.lastDebtsUserId, currentUid);
    });
  });
}
