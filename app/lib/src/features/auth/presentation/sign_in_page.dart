import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/validation/validators.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, AuthRepository? authRepository})
      : _authRepository = authRepository ?? const _LazyFirebaseAuthRepository();

  final AuthRepository _authRepository;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

/// Erzeugt das FirebaseAuthRepository erst bei Bedarf, damit das Widget
/// auch instanziiert werden kann, bevor Firebase initialisiert wurde.
class _LazyFirebaseAuthRepository implements AuthRepository {
  const _LazyFirebaseAuthRepository();

  AuthRepository get _delegate => FirebaseAuthRepository();

  @override
  Stream<String?> authStateChanges() => _delegate.authStateChanges();

  @override
  Future<void> signIn({required String email, required String password}) {
    return _delegate.signIn(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _delegate.signUp(name: name, email: email, password: password);
  }

  @override
  Future<void> signOut() => _delegate.signOut();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget._authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Anmeldung fehlgeschlagen.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'WG-ShopSync',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Melde dich an, um deine gemeinsame Einkaufsliste zu verwalten.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-Mail-Adresse'),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Passwort'),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submitSignIn,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Einloggen'),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Noch kein Konto? Registrieren'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}