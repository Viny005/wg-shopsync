import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/expense.dart';
import 'package:wg_shopsync/src/domain/models/expense_share.dart';
import 'package:wg_shopsync/src/domain/models/membership.dart';
import 'package:wg_shopsync/src/features/expense/application/expense_service.dart';
import 'package:wg_shopsync/src/features/expense/presentation/expense_edit_page.dart';

import '../../../support/fake_expense_service.dart';
import '../../../support/fake_wg_service.dart';

void main() {
  const currentUid = 'uid-anna-8Z62';
  const otherUid = 'uid-tom-T7zv';
  final joinedAt = DateTime(2026, 9, 17);

  final baseExpense = Expense(
    id: 'expense-1',
    wgId: 'wg-1',
    amount: 10,
    description: 'Wocheneinkauf',
    paidBy: currentUid,
    createdAt: DateTime(2026, 9, 17, 10),
    updatedAt: DateTime(2026, 9, 17, 10),
  );

  FakeWgService buildWgService() {
    return FakeWgService()
      ..members = [
        Membership(
          id: currentUid,
          userId: currentUid,
          wgId: 'wg-1',
          role: MembershipRole.admin,
          joinedAt: joinedAt,
          displayName: 'Anna Beispiel',
        ),
        Membership(
          id: otherUid,
          userId: otherUid,
          wgId: 'wg-1',
          role: MembershipRole.member,
          joinedAt: joinedAt,
        ),
      ];
  }

  FakeExpenseService buildExpenseService({
    Expense? expense,
    List<ExpenseShare>? shares,
  }) {
    final e = expense ?? baseExpense;
    return FakeExpenseService(
      shares: shares ??
          [
            ExpenseShare(
              id: 'share-1',
              expenseId: e.id,
              userId: currentUid,
              shareAmount: e.amount,
            ),
          ],
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required Expense expense,
    required FakeWgService wgService,
    required FakeExpenseService expenseService,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseEditPage(
          expense: expense,
          userId: currentUid,
          wgService: wgService,
          expenseService: expenseService,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('UC-12 ExpenseEditPage prefill', () {
    testWidgets('zeigt Titel Ausgabe bearbeiten', (tester) async {
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: buildExpenseService(),
      );

      expect(find.text('Ausgabe bearbeiten'), findsOneWidget);
    });

    testWidgets('befuellt Betrag vor', (tester) async {
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: buildExpenseService(),
      );

      final field = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, '10').first,
      );
      expect(field.controller!.text, '10');
    });

    testWidgets('befuellt Beschreibung vor', (tester) async {
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: buildExpenseService(),
      );

      expect(find.text('Wocheneinkauf'), findsOneWidget);
    });

    testWidgets('waehlt aktuellen Zahler vor', (tester) async {
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: buildExpenseService(),
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.initialValue, currentUid);
    });

    testWidgets('markiert bisherige Teilnehmer', (tester) async {
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: buildExpenseService(
          shares: [
            ExpenseShare(
              id: 'share-1',
              expenseId: baseExpense.id,
              userId: currentUid,
              shareAmount: 5,
            ),
            ExpenseShare(
              id: 'share-2',
              expenseId: baseExpense.id,
              userId: otherUid,
              shareAmount: 5,
            ),
          ],
        ),
      );

      final annaTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Anna Beispiel'),
      );
      final tomTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Unbekanntes Mitglied'),
      );
      expect(annaTile.value, isTrue);
      expect(tomTile.value, isTrue);
    });

    testWidgets('zeigt Mitgliedsnamen statt UIDs', (tester) async {
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: buildExpenseService(),
      );

      expect(find.text('Anna Beispiel'), findsAtLeastNWidgets(1));
      expect(find.text(currentUid), findsNothing);
      expect(find.text(otherUid), findsNothing);
    });

    testWidgets('zeigt Fallback Unbekanntes Mitglied fuer fehlenden Namen',
        (tester) async {
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: buildExpenseService(),
      );

      expect(find.text('Unbekanntes Mitglied'), findsAtLeastNWidgets(1));
    });
  });

  group('UC-12 ExpenseEditPage validation', () {
    testWidgets('leere Beschreibung verhindert Speichern', (tester) async {
      final expenseService = buildExpenseService();
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Wocheneinkauf'),
        '   ',
      );
      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(expenseService.updateExpenseCalls, 0);
    });

    testWidgets('ungueltiger Betrag verhindert Speichern', (tester) async {
      final expenseService = buildExpenseService();
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, '10'),
        'abc',
      );
      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pumpAndSettle();

      expect(expenseService.updateExpenseCalls, 0);
    });

    testWidgets('keine Teilnehmer verhindert Speichern', (tester) async {
      final expenseService = buildExpenseService();
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Anna Beispiel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pumpAndSettle();

      expect(expenseService.updateExpenseCalls, 0);
    });
  });

  group('UC-12 ExpenseEditPage submit', () {
    testWidgets('ruft updateExpense bei gueltigem Formular genau einmal auf',
        (tester) async {
      final expenseService = buildExpenseService();
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pumpAndSettle();

      expect(expenseService.updateExpenseCalls, 1);
    });

    testWidgets('uebergibt geaenderten Betrag', (tester) async {
      final expenseService = buildExpenseService();
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, '10'),
        '25',
      );
      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pumpAndSettle();

      expect(expenseService.lastAmount, 25);
    });

    testWidgets('uebergibt geaenderte Beschreibung', (tester) async {
      final expenseService = buildExpenseService();
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Wocheneinkauf'),
        'Neuer Einkauf',
      );
      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pumpAndSettle();

      expect(expenseService.lastDescription, 'Neuer Einkauf');
    });

    testWidgets('uebergibt gewaehlte Zahler-UID', (tester) async {
      final expenseService = buildExpenseService();
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      // Dropdown oeffnen und Tom als neuen Zahler auswaehlen; Anna ist der
      // bereits vorausgewaehlte urspruengliche Zahler.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unbekanntes Mitglied').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pumpAndSettle();

      expect(expenseService.lastPaidBy, otherUid);
    });

    testWidgets('uebergibt ausgewaehlte Teilnehmer-UIDs', (tester) async {
      final expenseService = buildExpenseService();
      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      await tester
          .tap(find.widgetWithText(CheckboxListTile, 'Unbekanntes Mitglied'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pumpAndSettle();

      expect(expenseService.lastParticipantUserIds,
          containsAll([currentUid, otherUid]));
    });

    testWidgets('schliesst Screen nach erfolgreichem Speichern',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => ExpenseEditPage(
                        expense: baseExpense,
                        userId: currentUid,
                        wgService: buildWgService(),
                        expenseService: buildExpenseService(),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Ausgabe bearbeiten'), findsOneWidget);

      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Ausgabe bearbeiten'), findsNothing);
    });
  });

  group('UC-12 ExpenseEditPage error handling', () {
    testWidgets('zeigt Konflikt-Dialog bei ExpenseConflictException',
        (tester) async {
      final serverExpense = baseExpense.copyWith(
        amount: 99,
        description: 'Von anderem Mitglied geaendert',
        updatedAt: DateTime(2026, 9, 17, 12),
      );
      final expenseService = buildExpenseService()
        ..updateExpenseError =
            ExpenseConflictException(serverExpense: serverExpense);

      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Konflikt erkannt'), findsOneWidget);
      expect(find.text('Serverdaten laden'), findsOneWidget);
    });

    testWidgets(
        'Serverdaten laden aktualisiert das Formular mit dem Serverstand',
        (tester) async {
      final serverExpense = baseExpense.copyWith(
        amount: 99,
        description: 'Von anderem Mitglied geaendert',
        updatedAt: DateTime(2026, 9, 17, 12),
      );
      final expenseService = buildExpenseService()
        ..updateExpenseError =
            ExpenseConflictException(serverExpense: serverExpense);

      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Serverdaten laden'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Von anderem Mitglied geaendert'), findsOneWidget);
    });

    testWidgets('zeigt verstaendliche Meldung bei Offline-Zustand',
        (tester) async {
      final expenseService = buildExpenseService()
        ..updateExpenseError = const ExpenseRequiresConnectionException();

      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Internetverbindung'),
        findsOneWidget,
      );
    });

    testWidgets(
        'zeigt verstaendliche Meldung wenn Ausgabe nicht mehr existiert',
        (tester) async {
      final expenseService = buildExpenseService()
        ..updateExpenseError = const ExpenseNotFoundException();

      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('nicht mehr verfuegbar'),
        findsOneWidget,
      );
    });

    testWidgets('zeigt verstaendliche Meldung bei Mitgliedschaftsfehler',
        (tester) async {
      final expenseService = buildExpenseService()
        ..updateExpenseError = const ExpensePayerNotMemberException();

      await pumpPage(
        tester,
        expense: baseExpense,
        wgService: buildWgService(),
        expenseService: expenseService,
      );

      await tester.tap(find.text('Aenderungen speichern'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Mitglied der WG'),
        findsOneWidget,
      );
    });
  });
}
