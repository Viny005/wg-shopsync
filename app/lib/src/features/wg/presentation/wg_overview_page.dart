import 'package:flutter/material.dart';

import '../../auth/domain/auth_repository.dart';

import 'create_wg_page.dart';
import 'wg_detail_page.dart';

/// Screen 5 – WG-Übersicht.
///
/// Solange der Benutzer noch keiner WG zugeordnet ist, kann er
/// eine neue WG erstellen oder einer bestehenden WG beitreten.
class WgOverviewPage extends StatefulWidget {
  const WgOverviewPage({
    super.key,
    required this.authRepository,
    required this.userId,
  });

  final AuthRepository authRepository;
  final String userId;

  @override
  State<WgOverviewPage> createState() => _WgOverviewPageState();
}

class _WgOverviewPageState extends State<WgOverviewPage> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);

    try {
      await widget.authRepository.signOut();
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WG-ShopSync'),
        actions: [
          IconButton(
            onPressed: _isSigningOut ? null : _signOut,
            tooltip: 'Abmelden',
            icon: _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Willkommen bei WG-ShopSync',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Erstelle eine neue WG oder tritt einer bestehenden WG bei.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () async {
                    final wg = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CreateWgPage(
                          userId: widget.userId,
                        ),
                      ),
                    );
                    if (!context.mounted || wg == null) {
                      return;
                    }
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WgDetailPage(
                          wg: wg,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_home),
                  label: const Text('WG erstellen'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.group_add),
                  label: const Text('WG beitreten'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
