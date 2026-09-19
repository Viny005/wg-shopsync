import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/membership.dart';
import 'package:wg_shopsync/src/domain/models/wg.dart';
import 'package:wg_shopsync/src/features/wg/application/wg_service.dart';
import 'package:wg_shopsync/src/features/wg/presentation/create_wg_page.dart';
import 'package:wg_shopsync/src/features/wg/presentation/join_wg_page.dart';
import 'package:wg_shopsync/src/features/wg/presentation/wg_detail_page.dart';
import 'package:wg_shopsync/src/features/wg/presentation/wg_overview_page.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_wg_service.dart';

void main() {
  testWidgets(
    'calls signOut when logout is pressed',
    (tester) async {
      final repository = FakeAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: WgOverviewPage(
            userId: 'test-user',
            authRepository: repository,
            wgService: FakeWgService(currentContext: null),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Abmelden'));
      await tester.pump();

      expect(repository.signOutCalls, 1);

      await repository.dispose();
    },
  );

  testWidgets(
    'opens CreateWgPage when WG erstellen is pressed',
    (tester) async {
      final repository = FakeAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: WgOverviewPage(
            userId: 'test-user',
            authRepository: repository,
            wgService: FakeWgService(currentContext: null),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.text('WG erstellen'),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CreateWgPage), findsOneWidget);
      expect(find.text('WG-Name'), findsOneWidget);

      await repository.dispose();
    },
  );

  testWidgets(
    'opens JoinWgPage when WG beitreten is pressed',
    (tester) async {
      final repository = FakeAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: WgOverviewPage(
            userId: 'test-user',
            authRepository: repository,
            wgService: FakeWgService(currentContext: null),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.text('WG beitreten'),
      );

      await tester.pumpAndSettle();

      expect(find.byType(JoinWgPage), findsOneWidget);
      expect(find.text('Einladungscode'), findsOneWidget);

      await repository.dispose();
    },
  );

  testWidgets(
    'shows existing WG overview with WG öffnen button when user is in a WG',
    (tester) async {
      final repository = FakeAuthRepository();
      final wg = WG(
        id: 'wg-1',
        name: 'Unsere WG',
        inviteCode: 'ABC123',
        createdBy: 'creator-user',
        createdAt: DateTime(2026, 9, 13),
      );
      final wgService = FakeWgService(
        currentContext: CurrentWgContext(
          wg: wg,
          role: MembershipRole.member,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WgOverviewPage(
            userId: 'test-user',
            authRepository: repository,
            wgService: wgService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unsere WG'), findsOneWidget);
      expect(find.text('Du bist Mitglied dieser WG.'), findsOneWidget);
      expect(find.text('WG öffnen'), findsOneWidget);
      expect(find.text('WG erstellen'), findsNothing);
      expect(find.text('WG beitreten'), findsNothing);

      await repository.dispose();
    },
  );

  testWidgets(
    'reloads overview and shows create/join options after leaving WG',
    (tester) async {
      final repository = FakeAuthRepository();
      final wg = WG(
        id: 'wg-1',
        name: 'Unsere WG',
        inviteCode: 'ABC123',
        createdBy: 'creator-user',
        createdAt: DateTime(2026, 9, 13),
      );
      final wgService = FakeWgService(
        contextSequence: [
          CurrentWgContext(
            wg: wg,
            role: MembershipRole.member,
          ),
          null,
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WgOverviewPage(
            userId: 'test-user',
            authRepository: repository,
            wgService: wgService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('WG öffnen'), findsOneWidget);

      await tester.tap(find.text('WG öffnen'));
      await tester.pumpAndSettle();

      expect(find.byType(WgDetailPage), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'WG verlassen'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'WG verlassen'));
      await tester.pumpAndSettle();

      expect(find.byType(WgDetailPage), findsNothing);
      expect(wgService.loadCurrentWgCalls, greaterThanOrEqualTo(2));
      expect(wgService.leaveWgCalls, 1);
      expect(find.text('WG erstellen'), findsOneWidget);
      expect(find.text('WG beitreten'), findsOneWidget);

      await repository.dispose();
    },
  );
}
