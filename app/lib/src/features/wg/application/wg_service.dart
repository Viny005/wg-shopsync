import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/membership.dart';
import '../../../domain/models/wg.dart';

class UserAlreadyInWgException implements Exception {
  const UserAlreadyInWgException();
}

class WgService {
  WgService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  static const String _inviteCodeCharacters =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  Future<WG> createWg({
    required String name,
    required String userId,
  }) async {
    final trimmedName = name.trim();
    final trimmedUserId = userId.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Der WG-Name darf nicht leer sein.');
    }

    if (trimmedUserId.isEmpty) {
      throw ArgumentError('Die Benutzer-ID darf nicht leer sein.');
    }

    for (var attempt = 0; attempt < 10; attempt++) {
      final inviteCode = _generateInviteCode();

      final inviteCodeRef = firestore.collection('inviteCodes').doc(inviteCode);

      final userMembershipRef =
          firestore.collection('userMemberships').doc(trimmedUserId);

      final wgRef = firestore.collection('wgs').doc();

      final membershipRef = wgRef.collection('memberships').doc(trimmedUserId);

      final now = DateTime.now();

      final wg = WG(
        id: wgRef.id,
        name: trimmedName,
        inviteCode: inviteCode,
        createdBy: trimmedUserId,
        createdAt: now,
      );

      final membership = Membership(
        id: trimmedUserId,
        userId: trimmedUserId,
        wgId: wgRef.id,
        role: MembershipRole.admin,
        joinedAt: now,
      );

      final created = await firestore.runTransaction<bool>((transaction) async {
        final userMembershipSnapshot = await transaction.get(userMembershipRef);

        if (userMembershipSnapshot.exists) {
          throw const UserAlreadyInWgException();
        }

        final inviteCodeSnapshot = await transaction.get(inviteCodeRef);

        if (inviteCodeSnapshot.exists) {
          return false;
        }

        transaction.set(
          inviteCodeRef,
          {
            'wgId': wgRef.id,
          },
        );

        transaction.set(
          wgRef,
          wg.toMap(),
        );

        transaction.set(
          membershipRef,
          membership.toMap(),
        );

        transaction.set(
          userMembershipRef,
          {
            'wgId': wgRef.id,
          },
        );

        return true;
      });

      if (created) {
        return wg;
      }
    }

    throw StateError(
      'Es konnte kein eindeutiger Einladungscode erzeugt werden.',
    );
  }

  String _generateInviteCode() {
    final random = Random.secure();

    return List.generate(
      6,
      (_) =>
          _inviteCodeCharacters[random.nextInt(_inviteCodeCharacters.length)],
    ).join();
  }
}
