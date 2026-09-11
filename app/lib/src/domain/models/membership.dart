import '../../core/utils/firestore_converters.dart';

/// Rolle eines Mitglieds innerhalb einer WG (siehe D2.8 Mitgliedsrolle).
enum MembershipRole {
  admin,
  member;

  static MembershipRole fromValue(String value) {
    return MembershipRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => throw ArgumentError('Unbekannte MembershipRole: $value'),
    );
  }
}

/// Verbindet einen [User] mit einer [WG] und speichert dessen Rolle (siehe D1.4).
class Membership {
  const Membership({
    required this.id,
    required this.userId,
    required this.wgId,
    required this.role,
    required this.joinedAt,
  });

  final String id;
  final String userId;
  final String wgId;
  final MembershipRole role;
  final DateTime joinedAt;

  factory Membership.fromMap(String id, Map<String, dynamic> data) {
    return Membership(
      id: id,
      userId: data['userId'] as String,
      wgId: data['wgId'] as String,
      role: MembershipRole.fromValue(data['role'] as String),
      joinedAt: dateTimeFromFirestore(data['joinedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'wgId': wgId,
      'role': role.name,
      'joinedAt': joinedAt,
    };
  }
}
