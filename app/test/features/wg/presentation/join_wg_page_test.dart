import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/features/wg/application/wg_service.dart';
import 'package:wg_shopsync/src/features/wg/presentation/join_wg_page.dart';

void main() {
  testWidgets(
    'shows validation error for invalid invite code',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JoinWgPage(
            userId: 'test-user',
            wgService: FakeJoinWgService(),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField),
        'ABC',
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'WG suchen'),
      );

      await tester.pump();

      expect(
        find.text(
          'Der Einladungscode muss aus 6 Buchstaben oder Zahlen bestehen.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows error when invite code does not exist',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JoinWgPage(
            userId: 'test-user',
            wgService: FakeJoinWgService(
              findError: const InviteCodeNotFoundException(),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField),
        'ABC123',
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'WG suchen'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Keine WG mit diesem Einladungscode gefunden.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows error when user is already in a WG',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JoinWgPage(
            userId: 'test-user',
            wgService: FakeJoinWgService(
              findError: const UserAlreadyInWgException(),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField),
        'ABC123',
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'WG suchen'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Du bist bereits Mitglied einer WG.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows found WG before joining',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JoinWgPage(
            userId: 'test-user',
            wgService: FakeJoinWgService(
              preview: const WgJoinPreview(
                wgId: 'wg-1',
                wgName: 'Test WG',
                inviteCode: 'ABC123',
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField),
        'abc123',
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'WG suchen'),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gefundene WG'), findsOneWidget);
      expect(find.text('Test WG'), findsOneWidget);
      expect(find.text('Einladungscode: ABC123'), findsOneWidget);

      expect(
        find.widgetWithText(FilledButton, 'WG beitreten'),
        findsOneWidget,
      );
    },
  );
}

class FakeJoinWgService extends WgService {
  FakeJoinWgService({
    this.preview,
    this.findError,
  });

  final WgJoinPreview? preview;
  final Object? findError;

  @override
  Future<WgJoinPreview> findWgByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    if (findError != null) {
      throw findError!;
    }

    return preview!;
  }
}
