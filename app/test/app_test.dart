import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/app.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_wg_service.dart';

void main() {
  testWidgets(
    'shows sign in page when no user is authenticated',
    (tester) async {
      final repository = FakeAuthRepository();

      await tester.pumpWidget(
        WgShopSyncApp(
          authRepository: repository,
        ),
      );

      repository.emitAuthState(null);
      await tester.pump();

      expect(find.text('Einloggen'), findsOneWidget);

      await repository.dispose();
    },
  );

  testWidgets(
    'shows WG overview when user is authenticated',
    (tester) async {
      final repository = FakeAuthRepository();
      final wgService = FakeWgService(currentContext: null);

      await tester.pumpWidget(
        WgShopSyncApp(
          authRepository: repository,
          wgService: wgService,
        ),
      );

      repository.emitAuthState('test-user');
      await tester.pumpAndSettle();

      expect(
        find.text('Willkommen bei WG-ShopSync'),
        findsOneWidget,
      );

      expect(find.text('WG erstellen'), findsOneWidget);
      expect(find.text('WG beitreten'), findsOneWidget);

      await repository.dispose();
    },
  );
}
