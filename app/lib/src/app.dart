import 'package:flutter/material.dart';

import 'features/auth/presentation/sign_in_page.dart';

class WgShopSyncApp extends StatelessWidget {
  const WgShopSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WG-ShopSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245B4A)),
        useMaterial3: true,
      ),
      home: const SignInPage(),
    );
  }
}
