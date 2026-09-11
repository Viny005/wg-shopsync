import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/features/wg/presentation/create_wg_page.dart';
import 'package:wg_shopsync/src/features/wg/presentation/wg_overview_page.dart';

import '../../../support/fake_auth_repository.dart';

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
          ),
        ),
      );

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
          ),
        ),
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'WG erstellen'),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CreateWgPage), findsOneWidget);
      expect(find.text('WG-Name'), findsOneWidget);

      await repository.dispose();
    },
  );
}