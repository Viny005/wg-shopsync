import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/membership.dart';
import 'package:wg_shopsync/src/domain/models/wg.dart';
import 'package:wg_shopsync/src/features/expense/presentation/expense_overview_page.dart';
import 'package:wg_shopsync/src/features/shopping_list/presentation/shopping_list_page.dart';
import 'package:wg_shopsync/src/features/wg/application/wg_service.dart';
import 'package:wg_shopsync/src/features/wg/presentation/wg_detail_page.dart';

import '../../../support/fake_shopping_list_service.dart';
import '../../../support/fake_wg_service.dart';

void main() {
  testWidgets(
    'shows admin information for WG creator',
    (tester) async {
      final wg = WG(
        id: 'wg-1',
        name: 'Test WG',
        inviteCode: 'ABC123',
        createdBy: 'admin-user',
        createdAt: DateTime(2026, 9, 13),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WgDetailPage(
            wg: wg,
            role: MembershipRole.admin,
            userId: 'test-user',
          ),
        ),
      );

      expect(
        find.text('Du bist Administrator dieser WG.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows member information for regular WG member',
    (tester) async {
      final wg = WG(
        id: 'wg-1',
        name: 'Test WG',
        inviteCode: 'ABC123',
        createdBy: 'creator-user',
        createdAt: DateTime(2026, 9, 13),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WgDetailPage(
            wg: wg,
            role: MembershipRole.member,
            userId: 'test-user',
          ),
        ),
      );

      expect(
        find.text('Du bist Mitglied dieser WG.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows WG verlassen button',
    (tester) async {
      final wg = WG(
        id: 'wg-1',
        name: 'Test WG',
        inviteCode: 'ABC123',
        createdBy: 'creator-user',
        createdAt: DateTime(2026, 9, 13),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WgDetailPage(
            wg: wg,
            role: MembershipRole.member,
            userId: 'test-user',
          ),
        ),
      );

      expect(
        find.widgetWithText(OutlinedButton, 'WG verlassen'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows confirmation dialog when WG verlassen is tapped',
    (tester) async {
      final wg = WG(
        id: 'wg-1',
        name: 'Test WG',
        inviteCode: 'ABC123',
        createdBy: 'creator-user',
        createdAt: DateTime(2026, 9, 13),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WgDetailPage(
            wg: wg,
            role: MembershipRole.member,
            userId: 'test-user',
          ),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'WG verlassen'));
      await tester.pumpAndSettle();

      expect(find.text('WG verlassen?'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Abbrechen'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'WG verlassen'), findsOneWidget);
    },
  );

  testWidgets(
    'does not leave WG when Abbrechen is tapped in confirmation dialog',
    (tester) async {
      final wgService = FakeWgService();
      final wg = WG(
        id: 'wg-1',
        name: 'Test WG',
        inviteCode: 'ABC123',
        createdBy: 'creator-user',
        createdAt: DateTime(2026, 9, 13),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WgDetailPage(
            wg: wg,
            role: MembershipRole.member,
            userId: 'test-user',
            wgService: wgService,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'WG verlassen'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
      await tester.pumpAndSettle();

      expect(wgService.leaveWgCalls, 0);
      expect(find.byType(WgDetailPage), findsOneWidget);
    },
  );

  testWidgets(
    'calls leaveWg and pops with true when confirmed',
    (tester) async {
      final wgService = FakeWgService();
      final wg = WG(
        id: 'wg-1',
        name: 'Test WG',
        inviteCode: 'ABC123',
        createdBy: 'creator-user',
        createdAt: DateTime(2026, 9, 13),
      );

      bool? popResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                popResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => WgDetailPage(
                      wg: wg,
                      role: MembershipRole.member,
                      userId: 'test-user',
                      wgService: wgService,
                    ),
                  ),
                );
              },
              child: const Text('Open Detail'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'WG verlassen'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'WG verlassen'));
      await tester.pumpAndSettle();

      expect(wgService.leaveWgCalls, 1);
      expect(wgService.lastLeaveWgId, 'wg-1');
      expect(wgService.lastLeaveUserId, 'test-user');
      expect(popResult, isTrue);
    },
  );

  testWidgets(
    'shows error message when LastAdminCannotLeaveWgException is thrown',
    (tester) async {
      final wgService = FakeWgService(
        leaveWgError: const LastAdminCannotLeaveWgException(),
      );
      final wg = WG(
        id: 'wg-1',
        name: 'Test WG',
        inviteCode: 'ABC123',
        createdBy: 'admin-user',
        createdAt: DateTime(2026, 9, 13),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WgDetailPage(
            wg: wg,
            role: MembershipRole.admin,
            userId: 'admin-user',
            wgService: wgService,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'WG verlassen'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'WG verlassen'));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Als letzter Administrator kannst du die WG nicht verlassen.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'opens ShoppingListPage when Einkaufsliste öffnen is tapped',
    (tester) async {
      final wg = WG(
        id: 'wg-1',
        name: 'Test WG',
        inviteCode: 'ABC123',
        createdBy: 'admin-user',
        createdAt: DateTime(2026, 9, 13),
      );
      final shoppingListService = FakeShoppingListService();

      await tester.pumpWidget(
        MaterialApp(
          home: WgDetailPage(
            wg: wg,
            role: MembershipRole.admin,
            userId: 'admin-user',
            shoppingListService: shoppingListService,
          ),
        ),
      );

      await tester
          .tap(find.widgetWithText(FilledButton, 'Einkaufsliste öffnen'));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingListPage), findsOneWidget);
    },
  );

  testWidgets(
    'opens ExpenseOverviewPage when Ausgaben öffnen is tapped',
    (tester) async {
      final wg = WG(
        id: 'wg-1',
        name: 'Test WG',
        inviteCode: 'ABC123',
        createdBy: 'admin-user',
        createdAt: DateTime(2026, 9, 13),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WgDetailPage(
            wg: wg,
            role: MembershipRole.admin,
            userId: 'admin-user',
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Ausgaben öffnen'));
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseOverviewPage), findsOneWidget);
    },
  );
}
