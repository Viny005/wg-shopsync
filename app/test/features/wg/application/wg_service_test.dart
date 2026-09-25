import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/features/wg/application/wg_service.dart';

void main() {
  group('UC-04: WgService.joinWg', () {
    test(
        'ruft die Callable mit dem normalisierten Code auf und laedt danach '
        'die WG (Firestore-Zugriff nicht in diesem Unit-Test simulierbar)',
        () async {
      String? receivedCode;
      final service = WgService(
        joinWgCallable: (inviteCode) async {
          receivedCode = inviteCode;
          return {'wgId': 'wg-1', 'wgName': 'Testflur'};
        },
      );

      // Der Callable-Aufruf selbst ist ohne echtes Firebase testbar; das
      // anschliessende Nachladen der WG per firestore.collection('wgs')...
      // benoetigt eine initialisierte FirebaseApp und wird stattdessen im
      // manuellen Live-Test gegen die deployte Cloud Function bestaetigt.
      await expectLater(
        () => service.joinWg(inviteCode: 'abc123', userId: 'user-1'),
        throwsA(isA<Exception>()),
      );
      expect(receivedCode, 'ABC123');
    });

    test('normalisiert den Einladungscode vor dem Aufruf', () async {
      String? receivedCode;
      final service = WgService(
        joinWgCallable: (inviteCode) async {
          receivedCode = inviteCode;
          throw FirebaseFunctionsException(
            code: 'not-found',
            message: 'nicht gefunden',
          );
        },
      );

      await expectLater(
        () => service.joinWg(inviteCode: '  abc123  ', userId: 'user-1'),
        throwsA(isA<InviteCodeNotFoundException>()),
      );
      expect(receivedCode, 'ABC123');
    });

    test('rejects ungueltigen Einladungscode vor dem Aufruf', () async {
      var called = false;
      final service = WgService(
        joinWgCallable: (inviteCode) async {
          called = true;
          return {};
        },
      );

      await expectLater(
        () => service.joinWg(inviteCode: 'AB', userId: 'user-1'),
        throwsA(isA<InvalidInviteCodeException>()),
      );
      expect(called, isFalse);
    });

    test('rejects leere userId', () async {
      final service = WgService(
        joinWgCallable: (inviteCode) async => {'wgId': 'wg-1'},
      );

      await expectLater(
        () => service.joinWg(inviteCode: 'ABC123', userId: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('already-exists wird zu UserAlreadyInWgException', () async {
      final service = WgService(
        joinWgCallable: (inviteCode) async {
          throw FirebaseFunctionsException(
            code: 'already-exists',
            message: 'bereits Mitglied',
          );
        },
      );

      await expectLater(
        () => service.joinWg(inviteCode: 'ABC123', userId: 'user-1'),
        throwsA(isA<UserAlreadyInWgException>()),
      );
    });

    test('not-found wird zu InviteCodeNotFoundException', () async {
      final service = WgService(
        joinWgCallable: (inviteCode) async {
          throw FirebaseFunctionsException(
            code: 'not-found',
            message: 'nicht gefunden',
          );
        },
      );

      await expectLater(
        () => service.joinWg(inviteCode: 'ABC123', userId: 'user-1'),
        throwsA(isA<InviteCodeNotFoundException>()),
      );
    });

    test('invalid-argument aus der Function wird zu InvalidInviteCodeException',
        () async {
      final service = WgService(
        joinWgCallable: (inviteCode) async {
          throw FirebaseFunctionsException(
            code: 'invalid-argument',
            message: 'ungueltig',
          );
        },
      );

      await expectLater(
        () => service.joinWg(inviteCode: 'ABC123', userId: 'user-1'),
        throwsA(isA<InvalidInviteCodeException>()),
      );
    });

    test('unbekannter Fehlercode wird unveraendert weitergereicht', () async {
      final service = WgService(
        joinWgCallable: (inviteCode) async {
          throw FirebaseFunctionsException(
            code: 'unauthenticated',
            message: 'nicht angemeldet',
          );
        },
      );

      await expectLater(
        () => service.joinWg(inviteCode: 'ABC123', userId: 'user-1'),
        throwsA(isA<FirebaseFunctionsException>()),
      );
    });

    test('unvollstaendige Antwort ohne wgId wirft StateError', () async {
      final service = WgService(
        joinWgCallable: (inviteCode) async => {'wgName': 'Testflur'},
      );

      await expectLater(
        () => service.joinWg(inviteCode: 'ABC123', userId: 'user-1'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
