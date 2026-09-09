import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/features/auth/presentation/sign_up_page.dart';

import '../../../support/fake_auth_repository.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, FakeAuthRepository repository) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    await tester.pumpWidget(MaterialApp(home: SignUpPage(authRepository: repository)));
  }

  Future<void> enterRegistration(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'Anna');
    await tester.enterText(find.byType(TextFormField).at(1), ' anna@example.com ');
    await tester.enterText(find.byType(TextFormField).at(2), 'password1');
    await tester.enterText(find.byType(TextFormField).at(3), 'password1');
  }

  testWidgets('shows the registration form', (tester) async {
    await pumpPage(tester, FakeAuthRepository());
    expect(find.widgetWithText(TextFormField, 'Name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'E-Mail-Adresse'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Passwort'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Passwort bestaetigen'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Registrieren'), findsOneWidget);
  });

  testWidgets('does not submit invalid registration data', (tester) async {
    final repository = FakeAuthRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.text('Registrieren'));
    await tester.pump();
    expect(repository.signUpCalls, 0);
    expect(find.text('Bitte gib einen Namen ein.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'A');
    await tester.enterText(find.byType(TextFormField).at(1), 'invalid');
    await tester.enterText(find.byType(TextFormField).at(2), 'short');
    await tester.enterText(find.byType(TextFormField).at(3), 'different');
    await tester.tap(find.text('Registrieren'));
    await tester.pump();
    expect(repository.signUpCalls, 0);
    expect(find.text('Der Name muss zwischen 2 und 50 Zeichen lang sein.'), findsOneWidget);
    expect(find.text('Bitte gib eine gueltige E-Mail-Adresse ein.'), findsOneWidget);
    expect(find.text('Das Passwort muss mindestens 8 Zeichen lang sein.'), findsOneWidget);
    expect(find.text('Die Passwoerter stimmen nicht ueberein.'), findsOneWidget);
  });

  testWidgets('submits valid registration data once', (tester) async {
    final repository = FakeAuthRepository();
    await pumpPage(tester, repository);
    await enterRegistration(tester);
    await tester.tap(find.text('Registrieren'));
    await tester.pump();
    expect(repository.signUpCalls, 1);
    expect(repository.name, 'Anna');
    expect(repository.email, 'anna@example.com');
    expect(repository.password, 'password1');
  });

  testWidgets('shows loading and prevents another registration', (tester) async {
    final repository = FakeAuthRepository()..signUpResult = Completer<void>().future;
    await pumpPage(tester, repository);
    await enterRegistration(tester);
    await tester.tap(find.text('Registrieren'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(repository.signUpCalls, 1);
  });

  testWidgets('shows an email-in-use message', (tester) async {
    final repository = FakeAuthRepository()
      ..signUpError = FirebaseAuthException(code: 'email-already-in-use');
    await pumpPage(tester, repository);
    await enterRegistration(tester);
    await tester.tap(find.text('Registrieren'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Diese E-Mail-Adresse ist bereits registriert.'), findsOneWidget);
  });

  testWidgets('shows a generic message for repository errors', (tester) async {
    final repository = FakeAuthRepository()..signUpError = StateError('offline');
    await pumpPage(tester, repository);
    await enterRegistration(tester);
    await tester.tap(find.text('Registrieren'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Registrierung fehlgeschlagen. Bitte versuche es erneut.'), findsOneWidget);
  });
}