import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/features/auth/presentation/sign_in_page.dart';

import '../../../support/fake_auth_repository.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, FakeAuthRepository repository) {
    return tester.pumpWidget(MaterialApp(home: SignInPage(authRepository: repository)));
  }

  Future<void> enterCredentials(WidgetTester tester, String email, String password) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
  }

  testWidgets('shows the login form', (tester) async {
    await pumpPage(tester, FakeAuthRepository());
    expect(find.widgetWithText(TextFormField, 'E-Mail-Adresse'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Passwort'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Einloggen'), findsOneWidget);
  });

  testWidgets('does not submit invalid credentials', (tester) async {
    final repository = FakeAuthRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.text('Einloggen'));
    await tester.pump();
    expect(repository.signInCalls, 0);
    expect(find.text('Bitte gib eine E-Mail-Adresse ein.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'invalid');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Einloggen'));
    await tester.pump();
    expect(repository.signInCalls, 0);
    expect(find.text('Bitte gib eine gueltige E-Mail-Adresse ein.'), findsOneWidget);
  });

  testWidgets('does not submit an empty password', (tester) async {
    final repository = FakeAuthRepository();
    await pumpPage(tester, repository);
    await tester.enterText(find.byType(TextFormField).at(0), 'name@example.com');
    await tester.tap(find.text('Einloggen'));
    await tester.pump();
    expect(repository.signInCalls, 0);
    expect(find.text('Bitte gib dein Passwort ein.'), findsOneWidget);
  });

  testWidgets('submits trimmed valid credentials once', (tester) async {
    final repository = FakeAuthRepository();
    await pumpPage(tester, repository);
    await enterCredentials(tester, ' name@example.com ', 'password');
    await tester.tap(find.text('Einloggen'));
    await tester.pump();
    expect(repository.signInCalls, 1);
    expect(repository.email, 'name@example.com');
    expect(repository.password, 'password');
  });

  testWidgets('shows loading and prevents another submission', (tester) async {
    final repository = FakeAuthRepository()..signInResult = Completer<void>().future;
    await pumpPage(tester, repository);
    await enterCredentials(tester, 'name@example.com', 'password');
    await tester.tap(find.text('Einloggen'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(repository.signInCalls, 1);
  });

  testWidgets('shows Firebase authentication errors', (tester) async {
    final repository = FakeAuthRepository()
      ..signInError = FirebaseAuthException(code: 'invalid-credential', message: 'E-Mail oder Passwort falsch');
    await pumpPage(tester, repository);
    await enterCredentials(tester, 'name@example.com', 'password');
    await tester.tap(find.text('Einloggen'));
    await tester.pump();
    await tester.pump();
    expect(find.text('E-Mail oder Passwort falsch'), findsOneWidget);
  });
}