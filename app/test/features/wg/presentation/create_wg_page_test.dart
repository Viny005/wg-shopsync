import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/wg.dart';
import 'package:wg_shopsync/src/features/wg/application/wg_service.dart';
import 'package:wg_shopsync/src/features/wg/presentation/create_wg_page.dart';

void main() {
  testWidgets(
    'shows validation error when WG name is empty',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateWgPage(
            userId: 'test-user',
          ),
        ),
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'WG erstellen'),
      );

      await tester.pump();

      expect(
        find.text('Bitte gib einen WG-Namen ein.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows specific error when user is already in a WG',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreateWgPage(
            userId: 'test-user',
            wgService: AlreadyInWgService(),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField),
        'Neue WG',
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'WG erstellen'),
      );

      await tester.pump();

      expect(
        find.text('Du bist bereits Mitglied einer WG.'),
        findsOneWidget,
      );
    },
  );
}

class AlreadyInWgService extends WgService {
  @override
  Future<WG> createWg({
    required String name,
    required String userId,
  }) async {
    throw const UserAlreadyInWgException();
  }
}
