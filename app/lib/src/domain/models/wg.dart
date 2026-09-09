import '../../core/utils/firestore_converters.dart';

/// Eine Wohngemeinschaft mit gemeinsamer Einkaufsliste und Kostenverwaltung (siehe D1.3 / D2.2).
class WG {
  const WG({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String name;

  /// Sechs alphanumerische Zeichen, systemweit eindeutig (siehe D2.8 Invite-Code).
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;

  factory WG.fromMap(String id, Map<String, dynamic> data) {
    return WG(
      id: id,
      name: data['name'] as String,
      inviteCode: data['inviteCode'] as String,
      createdBy: data['createdBy'] as String,
      createdAt: dateTimeFromFirestore(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }
}
