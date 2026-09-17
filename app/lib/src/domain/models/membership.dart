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
/// Das Feld [displayName] ist optional fuer Rueckwaertskompatibilitaet
/// mit bestehenden Memberships ohne dieses Feld.
class Membership {
  const Membership({
    required this.id,
    required this.userId,
    required this.wgId,
    required this.role,
    required this.joinedAt,
    this.displayName,
  });

  final String id;
  final String userId;
  final String wgId;
  final MembershipRole role;
  final DateTime joinedAt;

  /// Anzeigename des Mitglieds. Optional fuer alte Dokumente ohne dieses Feld.
  final String? displayName;

  /// Gibt den Anzeigenamen zurueck, oder 'Unbekanntes Mitglied' als Fallback.
  String get displayLabel =>
    (displayName != null && displayName!.trim().isNotEmpty)
      ? displayName!
      : 'Unbekanntes Mitglied';

  factory Membership.fromMap(String id, Map<String, dynamic> data) {
    return Membership(
      id: id,
      userId: data['userId'] as String,
      wgId: data['wgId'] as String,
      role: MembershipRole.fromValue(data['role'] as String),
      joinedAt: dateTimeFromFirestore(data['joinedAt']),
      displayName: data['displayName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'wgId': wgId,
      'role': role.name,
      'joinedAt': joinedAt,
      if (displayName != null) 'displayName': displayName,
    };
  }

  Membership copyWith({String? displayName}) {
    return Membership(
      id: id,
      userId: userId,
      wgId: wgId,
      role: role,
      joinedAt: joinedAt,
      displayName: displayName ?? this.displayName,
    );
  }
}
