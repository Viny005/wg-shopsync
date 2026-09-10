import 'package:flutter/material.dart';

import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/presentation/sign_in_page.dart';

class WgShopSyncApp extends StatelessWidget {
  const WgShopSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = FirebaseAuthRepository();

    return MaterialApp(
      title: 'WG-ShopSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF245B4A),
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<String?>(
        stream: authRepository.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasData) {
            return const Scaffold(
              body: Center(
                child: Text('Angemeldet'),
              ),
            );
          }

          return const SignInPage();
        },
      ),
    );
  }
}
