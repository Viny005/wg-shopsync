import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/membership.dart';

void main() {
  final joinedAt = DateTime(2026, 9, 17, 12);

  Map<String, dynamic> baseMap() => {
        'userId': 'user-1',
        'wgId': 'wg-1',
        'role': 'member',
        'joinedAt': joinedAt,
      };

  group('Membership displayName', () {
    test('serialisiert displayName wenn vorhanden', () {
      final membership = Membership(
        id: 'user-1',
        userId: 'user-1',
        wgId: 'wg-1',
        role: MembershipRole.member,
        joinedAt: joinedAt,
        displayName: 'Anna Beispiel',
      );

      expect(membership.toMap()['displayName'], 'Anna Beispiel');
    });

    test('laesst displayName im Map weg wenn null', () {
      final membership = Membership(
        id: 'user-1',
        userId: 'user-1',
        wgId: 'wg-1',
        role: MembershipRole.member,
        joinedAt: joinedAt,
      );

      expect(membership.toMap().containsKey('displayName'), isFalse);
    });

    test('deserialisiert displayName', () {
      final membership = Membership.fromMap(
        'user-1',
        {...baseMap(), 'displayName': 'Anna Beispiel'},
      );

      expect(membership.displayName, 'Anna Beispiel');
      expect(membership.displayLabel, 'Anna Beispiel');
    });

    test('altes Dokument ohne displayName bleibt lesbar', () {
      final membership = Membership.fromMap('user-1', baseMap());

      expect(membership.displayName, isNull);
      expect(membership.displayLabel, 'Unbekanntes Mitglied');
    });

    test('leerer displayName nutzt Fallback-Label, bleibt aber erkennbar', () {
      final membership = Membership.fromMap(
        'user-1',
        {...baseMap(), 'displayName': '   '},
      );

      expect(membership.displayName, '   ');
      expect(membership.displayLabel, 'Unbekanntes Mitglied');
    });

    test('displayLabel ist nie die UID', () {
      final membership = Membership.fromMap('user-1', baseMap());

      expect(membership.displayLabel, isNot('user-1'));
    });

    test('copyWith aendert nur displayName', () {
      final original = Membership.fromMap('user-1', baseMap());
      final migrated = original.copyWith(displayName: 'Anna Beispiel');

      expect(migrated.displayName, 'Anna Beispiel');
      expect(migrated.id, original.id);
      expect(migrated.userId, original.userId);
      expect(migrated.wgId, original.wgId);
      expect(migrated.role, original.role);
      expect(migrated.joinedAt, original.joinedAt);
    });
  });
}
