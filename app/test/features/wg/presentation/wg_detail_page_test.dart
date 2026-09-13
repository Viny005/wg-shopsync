import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/membership.dart';
import 'package:wg_shopsync/src/domain/models/wg.dart';
import 'package:wg_shopsync/src/features/wg/presentation/wg_detail_page.dart';

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
          ),
        ),
      );

      expect(
        find.text('Du bist Mitglied dieser WG.'),
        findsOneWidget,
      );
    },
  );
}
