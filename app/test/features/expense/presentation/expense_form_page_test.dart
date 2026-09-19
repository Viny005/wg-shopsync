import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/membership.dart';
import 'package:wg_shopsync/src/features/expense/presentation/expense_form_page.dart';

import '../../../support/fake_wg_service.dart';

void main() {
  const currentUid = 'uid-anna-8Z62';
  const otherUid = 'uid-tom-T7zv';
  final joinedAt = DateTime(2026, 9, 17);

  FakeWgService buildService() {
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

  Future<void> pumpPage(WidgetTester tester, FakeWgService service) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseFormPage(
          wgId: 'wg-1',
          userId: currentUid,
          wgService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('UC-11 ExpenseFormPage member labels', () {
    testWidgets('zeigt Mitgliedsnamen statt Firebase-UIDs', (tester) async {
      await pumpPage(tester, buildService());

      expect(find.text('Anna Beispiel'), findsAtLeastNWidgets(1));
      expect(find.text('Unbekanntes Mitglied'), findsAtLeastNWidgets(1));
      expect(find.text(currentUid), findsNothing);
      expect(find.text(otherUid), findsNothing);
    });

    testWidgets('Zahler-Dropdown nutzt intern die UID', (tester) async {
      await pumpPage(tester, buildService());

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.initialValue, currentUid);
    });

    testWidgets('Beteiligte-Checkboxen zeigen Namen und nutzen UIDs',
        (tester) async {
      await pumpPage(tester, buildService());

      final annaTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Anna Beispiel'),
      );
      final tomTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Unbekanntes Mitglied'),
      );

      expect(annaTile.value, isTrue);
      expect(tomTile.value, isFalse);
    });

    testWidgets('laedt Mitglieder ueber loadWgMembers', (tester) async {
      final service = buildService();
      await pumpPage(tester, service);

      expect(service.loadWgMembersCalls, 1);
    });
  });
}
