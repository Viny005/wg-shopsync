/// Abstraktion für Registrierung, Login, Logout und Sitzungsbeobachtung (siehe A05 AuthService, UC-01/UC-02).
abstract class AuthRepository {
  Stream<String?> authStateChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
