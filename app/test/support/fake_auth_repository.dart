import 'dart:async';

import 'package:wg_shopsync/src/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  int signInCalls = 0;
  int signUpCalls = 0;
  int signOutCalls = 0;
  String? email;
  String? password;
  String? name;
  Future<void>? signInResult;
  Future<void>? signUpResult;
  Object? signInError;
  Object? signUpError;

  @override
  Stream<String?> authStateChanges() => const Stream.empty();

  @override
  Future<void> signIn({required String email, required String password}) {
    signInCalls++;
    this.email = email;
    this.password = password;
    if (signInError != null) return Future<void>.error(signInError!);
    return signInResult ?? Future<void>.value();
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    signUpCalls++;
    this.name = name;
    this.email = email;
    this.password = password;
    if (signUpError != null) return Future<void>.error(signUpError!);
    return signUpResult ?? Future<void>.value();
  }
}