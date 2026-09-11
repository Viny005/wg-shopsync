import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/core/validation/validators.dart';

void main() {
  group('email', () {
    test('accepts a valid email address', () {
      expect(Validators.email('name@example.com'), isNull);
    });

    test('rejects empty and malformed email addresses', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('nameexample.com'), isNotNull);
      expect(Validators.email('name@'), isNotNull);
      expect(Validators.email('@example.com'), isNotNull);
      expect(Validators.email('name@example'), isNotNull);
    });
  });

  group('passwords', () {
    test('accepts a non-empty login password and rejects an empty one', () {
      expect(Validators.password('secret'), isNull);
      expect(Validators.password(''), isNotNull);
    });

    test('enforces the registration password minimum length', () {
      expect(Validators.newPassword(''), isNotNull);
      expect(Validators.newPassword('1234567'), isNotNull);
      expect(Validators.newPassword('12345678'), isNull);
      expect(Validators.newPassword('123456789'), isNull);
    });

    test('requires a matching non-empty password confirmation', () {
      final validator = Validators.passwordConfirmation('password1');
      expect(validator('password1'), isNull);
      expect(validator('password2'), isNotNull);
      expect(validator(''), isNotNull);
    });
  });

  group('userName', () {
    test('enforces the required length range', () {
      expect(Validators.userName(''), isNotNull);
      expect(Validators.userName('A'), isNotNull);
      expect(Validators.userName('Al'), isNull);
      expect(Validators.userName('Anna Beispiel'), isNull);
      expect(Validators.userName('a' * 50), isNull);
      expect(Validators.userName('a' * 51), isNotNull);
    });
  });
}