import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/debt.dart';
import 'package:wg_shopsync/src/domain/models/membership.dart';
import 'package:wg_shopsync/src/features/expense/presentation/expense_overview_page.dart';
import 'package:wg_shopsync/src/domain/models/expense.dart';
import 'package:wg_shopsync/src/domain/models/expense_share.dart';

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

  group('UC-15: ExpenseOverviewPage Schuld als bezahlt markieren', () {
    Debt buildOpenDebt({required String creditorId, required String debtorId}) {
      return Debt(
        id: 'expense-1_$debtorId',
        wgId: wgId,
        expenseId: 'expense-1',
        creditorId: creditorId,
        debtorId: debtorId,
        amount: 8.5,
        status: DebtStatus.open,
        createdAt: DateTime(2026, 9, 18),
      );
    }

    testWidgets(
        'zeigt Als-bezahlt-markieren-Button fuer eigene offene Schuld als Schuldner',
        (tester) async {
      await pumpPage(
        tester,
        expenseService: FakeExpenseService(
          debts: [buildOpenDebt(creditorId: otherUid, debtorId: currentUid)],
        ),
      );

      expect(find.text('Als bezahlt markieren'), findsOneWidget);
    });

    testWidgets('zeigt KEINEN Button wenn Nutzer Glaeubiger ist',
        (tester) async {
      await pumpPage(
        tester,
        expenseService: FakeExpenseService(
          debts: [buildOpenDebt(creditorId: currentUid, debtorId: otherUid)],
        ),
      );

      expect(find.text('Als bezahlt markieren'), findsNothing);
    });

    testWidgets('zeigt KEINEN Button bei bereits bezahlter Schuld',
        (tester) async {
      final debt = Debt(
        id: 'expense-1_$currentUid',
        wgId: wgId,
        expenseId: 'expense-1',
        creditorId: otherUid,
        debtorId: currentUid,
        amount: 8.5,
        status: DebtStatus.paid,
        paidAt: DateTime(2026, 9, 19),
        createdAt: DateTime(2026, 9, 18),
      );
      await pumpPage(
        tester,
        expenseService: FakeExpenseService(debts: [debt]),
      );

      expect(find.text('Als bezahlt markieren'), findsNothing);
    });

    testWidgets('Klick oeffnet Bestaetigungsdialog', (tester) async {
      await pumpPage(
        tester,
        expenseService: FakeExpenseService(
          debts: [buildOpenDebt(creditorId: otherUid, debtorId: currentUid)],
        ),
      );

      await tester.tap(find.text('Als bezahlt markieren'));
      await tester.pumpAndSettle();

      expect(find.text('Schuld als bezahlt markieren?'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);
    });

    testWidgets('Abbrechen fuehrt zu keinem Update', (tester) async {
      final service = FakeExpenseService(
        debts: [buildOpenDebt(creditorId: otherUid, debtorId: currentUid)],
      );
      await pumpPage(tester, expenseService: service);

      await tester.tap(find.text('Als bezahlt markieren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(service.markDebtAsPaidCalls, 0);
      expect(find.text('Bezahlt'), findsNothing);
    });

    testWidgets(
        'Bestaetigen ruft markDebtAsPaid genau einmal auf und laedt neu',
        (tester) async {
      final service = FakeExpenseService(
        debts: [buildOpenDebt(creditorId: otherUid, debtorId: currentUid)],
      );
      await pumpPage(tester, expenseService: service);

      await tester.tap(find.text('Als bezahlt markieren'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.widgetWithText(FilledButton, 'Als bezahlt markieren'));
      await tester.pumpAndSettle();

      expect(service.markDebtAsPaidCalls, 1);
      expect(service.lastPaidWgId, wgId);
      expect(service.lastPaidDebtId, 'expense-1_$currentUid');
      expect(service.getDebtsForUserCalls, 2);
    });

    testWidgets('Fehler beim Bezahlen zeigt verstaendliche Meldung',
        (tester) async {
      final service = FakeExpenseService(
        debts: [buildOpenDebt(creditorId: otherUid, debtorId: currentUid)],
        markDebtAsPaidError: Exception('permission-denied'),
      );
      await pumpPage(tester, expenseService: service);

      await tester.tap(find.text('Als bezahlt markieren'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.widgetWithText(FilledButton, 'Als bezahlt markieren'));
      await tester.pumpAndSettle();

      expect(
        find.text('Die Schuld konnte nicht als bezahlt markiert werden.'),
        findsOneWidget,
      );
      expect(find.textContaining('permission-denied'), findsNothing);
    });
  });

  group('UC-16: Kostenübersicht anzeigen', () {
    Expense buildExpense({
      String id = 'expense-1',
      String paidBy = currentUid,
      double amount = 30,
      String description = 'Lebensmittel',
    }) {
      return Expense(
        id: id,
        wgId: wgId,
        amount: amount,
        description: description,
        paidBy: paidBy,
        createdAt: DateTime(2026, 9, 24),
        updatedAt: DateTime(2026, 9, 24),
      );
    }

    testWidgets(
      'zeigt eigenen Kostenanteil auch wenn Nutzer Zahler und Teilnehmer ist',
      (tester) async {
        final service = FakeExpenseService(
          expenses: [
            buildExpense(),
          ],
          shares: [
            const ExpenseShare(
              id: 'share-current',
              expenseId: 'expense-1',
              userId: currentUid,
              shareAmount: 10,
            ),
            const ExpenseShare(
              id: 'share-other',
              expenseId: 'expense-1',
              userId: otherUid,
              shareAmount: 20,
            ),
          ],
        );

        await pumpPage(
          tester,
          expenseService: service,
        );

        expect(
          find.textContaining('Dein Anteil: 10.00 €'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'zeigt keinen eigenen Kostenanteil wenn Nutzer nicht beteiligt ist',
      (tester) async {
        final service = FakeExpenseService(
          expenses: [
            buildExpense(paidBy: otherUid),
          ],
          shares: [
            const ExpenseShare(
              id: 'share-other',
              expenseId: 'expense-1',
              userId: otherUid,
              shareAmount: 30,
            ),
          ],
        );

        await pumpPage(
          tester,
          expenseService: service,
        );

        expect(find.textContaining('Dein Anteil:'), findsNothing);
        expect(find.textContaining('30.00 €'), findsWidgets);
      },
    );

    testWidgets(
      'Expense-Ladefehler zeigt Retry und erneutes Laden funktioniert',
      (tester) async {
        final service = FakeExpenseService(
          getExpensesError: Exception('offline'),
        );

        await pumpPage(
          tester,
          expenseService: service,
        );

        expect(
          find.text('Ausgaben konnten nicht geladen werden.'),
          findsOneWidget,
        );
        expect(find.text('Erneut versuchen'), findsOneWidget);
        expect(service.getExpensesCalls, 1);

        service.getExpensesError = null;

        await tester.tap(find.text('Erneut versuchen'));
        await tester.pumpAndSettle();

        expect(service.getExpensesCalls, 2);
        expect(
          find.text('Ausgaben konnten nicht geladen werden.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Fehler beim Laden der Kostenanteile zeigt Retry',
      (tester) async {
        final service = FakeExpenseService(
          expenses: [
            buildExpense(),
          ],
          getExpenseSharesError: Exception('offline'),
        );

        await pumpPage(
          tester,
          expenseService: service,
        );

        expect(
          find.text('Kostenanteile konnten nicht geladen werden.'),
          findsOneWidget,
        );
        expect(find.text('Erneut versuchen'), findsOneWidget);
      },
    );
  });

  group('UC-16 Echtzeit-Synchronisation', () {
    testWidgets('Expense-Realtime-Listener bleibt funktionsfaehig',
        (tester) async {
      final service = FakeExpenseService(
        expenses: [
          Expense(
            id: 'expense-1',
            wgId: wgId,
            amount: 10,
            description: 'Erste Ausgabe',
            paidBy: currentUid,
            createdAt: DateTime(2026, 9, 18),
            updatedAt: DateTime(2026, 9, 18),
          ),
        ],
      );
      await pumpPage(tester, expenseService: service);

      expect(service.getExpensesCalls, 1);

      service.emitExpenseChange();
      await tester.pumpAndSettle();

      expect(service.getExpensesCalls, 2);
    });

    testWidgets('Debt-Aenderung loest Aktualisierung der Finanzdaten aus',
        (tester) async {
      final service = FakeExpenseService(
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
      );
      await pumpPage(tester, expenseService: service);

      final initialCalls = service.getDebtsForUserCalls;

      service.emitDebtChange();
      await tester.pumpAndSettle();

      expect(service.getDebtsForUserCalls, greaterThan(initialCalls));
    });

    testWidgets('open -> paid wird automatisch sichtbar ohne manuellen Reload',
        (tester) async {
      final openDebt = Debt(
        id: 'expense-1_$otherUid',
        wgId: wgId,
        expenseId: 'expense-1',
        creditorId: currentUid,
        debtorId: otherUid,
        amount: 8.5,
        status: DebtStatus.open,
        createdAt: DateTime(2026, 9, 18),
      );
      final service = FakeExpenseService(debts: [openDebt]);
      await pumpPage(tester, expenseService: service);

      expect(find.text('Offen'), findsWidgets);
      expect(find.text('Bezahlt'), findsNothing);

      // Simuliert, dass ein anderer Client (z.B. der Schuldner ueber UC-15)
      // die Debt bezahlt hat; der lokale Fake-Datenbestand wird aktualisiert
      // und der Stream feuert erneut, ohne dass diese Seite selbst
      // etwas ausgeloest hat.
      service.debts = [
        Debt(
          id: openDebt.id,
          wgId: openDebt.wgId,
          expenseId: openDebt.expenseId,
          creditorId: openDebt.creditorId,
          debtorId: openDebt.debtorId,
          amount: openDebt.amount,
          status: DebtStatus.paid,
          paidAt: DateTime(2026, 9, 19),
          createdAt: openDebt.createdAt,
        ),
      ];
      service.emitDebtChange();
      await tester.pumpAndSettle();

      expect(find.text('Bezahlt'), findsWidgets);
      expect(find.text('Offen'), findsNothing);
    });

    testWidgets('Saldo wird nach Bezahlen automatisch neu berechnet',
        (tester) async {
      final openDebt = Debt(
        id: 'expense-1_$otherUid',
        wgId: wgId,
        expenseId: 'expense-1',
        creditorId: currentUid,
        debtorId: otherUid,
        amount: 8.5,
        status: DebtStatus.open,
        createdAt: DateTime(2026, 9, 18),
      );
      final service = FakeExpenseService(debts: [openDebt]);
      await pumpPage(tester, expenseService: service);

      expect(find.textContaining('8.50'), findsWidgets);

      service.debts = [
        Debt(
          id: openDebt.id,
          wgId: openDebt.wgId,
          expenseId: openDebt.expenseId,
          creditorId: openDebt.creditorId,
          debtorId: openDebt.debtorId,
          amount: openDebt.amount,
          status: DebtStatus.paid,
          paidAt: DateTime(2026, 9, 19),
          createdAt: openDebt.createdAt,
        ),
      ];
      service.emitDebtChange();
      await tester.pumpAndSettle();

      expect(find.text('Saldo'), findsNothing);
    });

    testWidgets('Debt-Subscription wird bei Dispose beendet', (tester) async {
      final service = FakeExpenseService(debts: const []);
      await pumpPage(tester, expenseService: service);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      // Nach dem Dispose darf ein weiteres Stream-Event keinen Fehler
      // (z.B. "setState called after dispose") mehr ausloesen.
      expect(() => service.emitDebtChange(), returnsNormally);
    });

    testWidgets('FakeExpenseService ruft niemals echtes Firebase auf',
        (tester) async {
      // Rein strukturelle Absicherung: FakeExpenseService ueberschreibt
      // watchDebtsForUser vollstaendig mit einem lokalen StreamController
      // und greift nicht auf ExpenseService.firestore zu. Ein erfolgreicher
      // Testlauf ohne initialisiertes Firebase bestaetigt das indirekt.
      final service = FakeExpenseService(debts: const []);
      await pumpPage(tester, expenseService: service);

      expect(tester.takeException(), isNull);
    });
  });
}
