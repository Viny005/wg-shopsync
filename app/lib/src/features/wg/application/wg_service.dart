import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/models/membership.dart';
import '../../../domain/models/wg.dart';

class UserAlreadyInWgException implements Exception {
  const UserAlreadyInWgException();
}

class InvalidInviteCodeException implements Exception {
  const InvalidInviteCodeException();
}

class InviteCodeNotFoundException implements Exception {
  const InviteCodeNotFoundException();
}

class LastAdminCannotLeaveWgException implements Exception {
  const LastAdminCannotLeaveWgException();
}

class CurrentWgContext {
  const CurrentWgContext({
    required this.wg,
    required this.role,
  });

  final WG wg;
  final MembershipRole role;
}

class WgJoinPreview {
  const WgJoinPreview({
    required this.wgId,
    required this.wgName,
    required this.inviteCode,
  });

  final String wgId;
  final String wgName;
  final String inviteCode;
}

class WgService {
  WgService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  static const String _inviteCodeCharacters =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Liest ausschliesslich das Feld `name` aus dem eigenen users/{uid}-Dokument
  /// innerhalb einer Transaktion (Read vor Write). Nur der eigene Nutzer darf
  /// sein Profil lesen; andere Profile bleiben privat.
  Future<String?> _loadOwnDisplayName(
    Transaction transaction,
    String userId,
  ) async {
    final userSnapshot =
        await transaction.get(firestore.collection('users').doc(userId));
    final name = userSnapshot.data()?['name'];
    if (name is String && name.trim().isNotEmpty) {
      return name.trim();
    }
    return null;
  }

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

        final displayName = await _loadOwnDisplayName(transaction, trimmedUserId);

        transaction.set(
          inviteCodeRef,
          {
            'wgId': wgRef.id,
            'wgName': trimmedName,
          },
        );

        transaction.set(
          wgRef,
          wg.toMap(),
        );

        transaction.set(
          membershipRef,
          membership.copyWith(displayName: displayName).toMap(),
        );

        transaction.set(
          userMembershipRef,
          {
            'wgId': wgRef.id,
            'inviteCode': inviteCode,
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

  Future<WgJoinPreview> findWgByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    final normalizedCode = inviteCode.trim().toUpperCase();
    final trimmedUserId = userId.trim();

    if (trimmedUserId.isEmpty) {
      throw ArgumentError('Die Benutzer-ID darf nicht leer sein.');
    }

    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(normalizedCode)) {
      throw const InvalidInviteCodeException();
    }

    final userMembershipSnapshot =
        await firestore.collection('userMemberships').doc(trimmedUserId).get();

    if (userMembershipSnapshot.exists) {
      throw const UserAlreadyInWgException();
    }

    final inviteCodeSnapshot =
        await firestore.collection('inviteCodes').doc(normalizedCode).get();

    if (!inviteCodeSnapshot.exists) {
      throw const InviteCodeNotFoundException();
    }

    final data = inviteCodeSnapshot.data();
    final wgId = data?['wgId'];
    final wgName = data?['wgName'];

    if (wgId is! String ||
        wgId.isEmpty ||
        wgName is! String ||
        wgName.isEmpty) {
      throw StateError(
        'Die Daten des Einladungscodes sind unvollständig.',
      );
    }

    return WgJoinPreview(
      wgId: wgId,
      wgName: wgName,
      inviteCode: normalizedCode,
    );
  }

  Future<WG> joinWg({
    required String inviteCode,
    required String userId,
    }) async {
    final normalizedCode = inviteCode.trim().toUpperCase();
    final trimmedUserId = userId.trim();

    if (trimmedUserId.isEmpty) {
      throw ArgumentError('Die Benutzer-ID darf nicht leer sein.');
    }

    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(normalizedCode)) {
      throw const InvalidInviteCodeException();
    }

    final inviteCodeRef =
        firestore.collection('inviteCodes').doc(normalizedCode);

    final userMembershipRef =
        firestore.collection('userMemberships').doc(trimmedUserId);

    final wgId = await firestore.runTransaction<String>((transaction) async {
      final userMembershipSnapshot = await transaction.get(userMembershipRef);

      if (userMembershipSnapshot.exists) {
        throw const UserAlreadyInWgException();
      }

      final inviteCodeSnapshot = await transaction.get(inviteCodeRef);

      if (!inviteCodeSnapshot.exists) {
        throw const InviteCodeNotFoundException();
      }

      final inviteCodeData = inviteCodeSnapshot.data();
      final foundWgId = inviteCodeData?['wgId'];

      if (foundWgId is! String || foundWgId.isEmpty) {
        throw StateError(
          'Die Daten des Einladungscodes sind unvollständig.',
        );
      }

      final wgRef = firestore.collection('wgs').doc(foundWgId);

      final membershipRef = wgRef.collection('memberships').doc(trimmedUserId);

      final displayName =
        await _loadOwnDisplayName(transaction, trimmedUserId);

      final membership = Membership(
        id: trimmedUserId,
        userId: trimmedUserId,
        wgId: foundWgId,
        role: MembershipRole.member,
        joinedAt: DateTime.now(),
        displayName: displayName,
      );

      transaction.set(
        membershipRef,
        membership.toMap(),
      );

      transaction.set(
        userMembershipRef,
        {
          'wgId': foundWgId,
          'inviteCode': normalizedCode,
        },
      );

      return foundWgId;
    });

    final wgSnapshot = await firestore.collection('wgs').doc(wgId).get();

    final wgData = wgSnapshot.data();

    if (!wgSnapshot.exists || wgData == null) {
      throw StateError(
        'Die WG konnte nach dem Beitritt nicht geladen werden.',
      );
    }

    return WG.fromMap(
      wgSnapshot.id,
      wgData,
    );
  }

  Future<CurrentWgContext?> loadCurrentWg({
    required String userId,
  }) async {
    final trimmedUserId = userId.trim();

    if (trimmedUserId.isEmpty) {
      throw ArgumentError('Die Benutzer-ID darf nicht leer sein.');
    }

    final userMembershipSnapshot =
        await firestore.collection('userMemberships').doc(trimmedUserId).get();

    if (!userMembershipSnapshot.exists) {
      return null;
    }

    final userMembershipData = userMembershipSnapshot.data();
    final wgId = userMembershipData?['wgId'];

    if (wgId is! String || wgId.isEmpty) {
      return null;
    }

    final wgSnapshot = await firestore.collection('wgs').doc(wgId).get();
    final wgData = wgSnapshot.data();

    if (!wgSnapshot.exists || wgData == null) {
      return null;
    }

    final membershipSnapshot = await firestore
        .collection('wgs')
        .doc(wgId)
        .collection('memberships')
        .doc(trimmedUserId)
        .get();
    final membershipData = membershipSnapshot.data();

    if (!membershipSnapshot.exists || membershipData == null) {
      return null;
    }

    final wg = WG.fromMap(wgSnapshot.id, wgData);
    final membership =
        Membership.fromMap(membershipSnapshot.id, membershipData);

    return CurrentWgContext(
      wg: wg,
      role: membership.role,
    );
  }

  Future<List<String>> loadWgMemberIds({
    required String wgId,
  }) async {
    final trimmedWgId = wgId.trim();
    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }

    final snapshot = await firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('memberships')
        .get();

    final memberIds = snapshot.docs.map((doc) => doc.id).toList();
    memberIds.sort();
    return memberIds;
  }

  Future<void> leaveWg({
    required String wgId,
    required String userId,
  }) async {
    final trimmedWgId = wgId.trim();
    final trimmedUserId = userId.trim();

    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }

    if (trimmedUserId.isEmpty) {
      throw ArgumentError('Die Benutzer-ID darf nicht leer sein.');
    }

    final membershipRef = firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('memberships')
        .doc(trimmedUserId);

    final userMembershipRef =
        firestore.collection('userMemberships').doc(trimmedUserId);

    await firestore.runTransaction((transaction) async {
      final membershipSnapshot = await transaction.get(membershipRef);
      final userMembershipSnapshot = await transaction.get(userMembershipRef);

      if (!membershipSnapshot.exists || !userMembershipSnapshot.exists) {
        throw StateError('Mitgliedschaft existiert nicht.');
      }

      final userMembershipData = userMembershipSnapshot.data();
      final recordedWgId = userMembershipData?['wgId'];

      if (recordedWgId != trimmedWgId) {
        throw StateError('Inkonsistente WG-Mitgliedschaft.');
      }

      final membershipData = membershipSnapshot.data();
      final roleString = membershipData?['role'];

      if (roleString == MembershipRole.admin.name) {
        throw const LastAdminCannotLeaveWgException();
      }

      transaction.delete(membershipRef);
      transaction.delete(userMembershipRef);
    });
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
