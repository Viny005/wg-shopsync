import '../../core/utils/firestore_converters.dart';

/// Ein registrierter Benutzer der Anwendung (siehe D1.2 / D2.1).
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  factory User.fromMap(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      name: data['name'] as String,
      email: data['email'] as String,
      createdAt: dateTimeFromFirestore(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': createdAt,
    };
  }
}
