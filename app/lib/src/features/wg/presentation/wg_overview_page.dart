import 'package:flutter/material.dart';

import '../../auth/domain/auth_repository.dart';

import '../application/wg_service.dart';
import 'create_wg_page.dart';
import 'wg_detail_page.dart';
import 'join_wg_page.dart';
import '../../../domain/models/membership.dart';

/// Screen 5 – WG-Übersicht.
///
/// Solange der Benutzer noch keiner WG zugeordnet ist, kann er
/// eine neue WG erstellen oder einer bestehenden WG beitreten.
class WgOverviewPage extends StatefulWidget {
  const WgOverviewPage({
    super.key,
    required this.authRepository,
    required this.userId,
    this.wgService,
  });

  final AuthRepository authRepository;
  final String userId;
  final WgService? wgService;

  @override
  State<WgOverviewPage> createState() => _WgOverviewPageState();
}

class _WgOverviewPageState extends State<WgOverviewPage> {
  late final WgService _wgService = widget.wgService ?? WgService();
  bool _isSigningOut = false;
  bool _isLoadingWg = true;
  CurrentWgContext? _currentWgContext;

  @override
  void initState() {
    super.initState();
    _loadCurrentWg();
  }

  Future<void> _loadCurrentWg() async {
    setState(() => _isLoadingWg = true);

    try {
      final context = await _wgService.loadCurrentWg(userId: widget.userId);
      if (mounted) {
        setState(() {
          _currentWgContext = context;
          _isLoadingWg = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentWgContext = null;
          _isLoadingWg = false;
        });
      }
    }
  }

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
    if (_isLoadingWg) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentWg = _currentWgContext;

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
            child: currentWg != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        currentWg.wg.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentWg.role == MembershipRole.admin
                            ? 'Du bist Administrator dieser WG.'
                            : 'Du bist Mitglied dieser WG.',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) => WgDetailPage(
                                wg: currentWg.wg,
                                role: currentWg.role,
                                userId: widget.userId,
                                wgService: _wgService,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadCurrentWg();
                          }
                        },
                        icon: const Icon(Icons.meeting_room),
                        label: const Text('WG öffnen'),
                      ),
                    ],
                  )
                : Column(
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
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) => WgDetailPage(
                                wg: wg,
                                role: MembershipRole.admin,
                                userId: widget.userId,
                                wgService: _wgService,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadCurrentWg();
                          } else {
                            _loadCurrentWg();
                          }
                        },
                        icon: const Icon(Icons.add_home),
                        label: const Text('WG erstellen'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final wg = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => JoinWgPage(
                                userId: widget.userId,
                              ),
                            ),
                          );
                          if (!context.mounted || wg == null) {
                            return;
                          }
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) => WgDetailPage(
                                wg: wg,
                                role: MembershipRole.member,
                                userId: widget.userId,
                                wgService: _wgService,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadCurrentWg();
                          } else {
                            _loadCurrentWg();
                          }
                        },
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
