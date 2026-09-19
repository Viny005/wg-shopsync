import 'package:flutter/material.dart';

import '../../../domain/models/wg.dart';
import '../../../domain/models/membership.dart';
import '../../expense/presentation/expense_overview_page.dart';
import '../../shopping_list/application/shopping_list_service.dart';
import '../../shopping_list/presentation/shopping_list_page.dart';
import '../application/wg_service.dart';

class WgDetailPage extends StatefulWidget {
  const WgDetailPage({
    super.key,
    required this.wg,
    required this.role,
    required this.userId,
    this.wgService,
    this.shoppingListService,
  });

  final WG wg;
  final MembershipRole role;
  final String userId;
  final WgService? wgService;
  final ShoppingListService? shoppingListService;

  @override
  State<WgDetailPage> createState() => _WgDetailPageState();
}

class _WgDetailPageState extends State<WgDetailPage> {
  late final WgService _wgService = widget.wgService ?? WgService();
  bool _isLeaving = false;

  Future<void> _confirmAndLeaveWg() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('WG verlassen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('WG verlassen'),
          ),
        ],
      ),
    );

    if (shouldLeave != true || !mounted) {
      return;
    }

    setState(() => _isLeaving = true);

    try {
      await _wgService.leaveWg(
        wgId: widget.wg.id,
        userId: widget.userId,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } on LastAdminCannotLeaveWgException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Als letzter Administrator kannst du die WG nicht verlassen.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Die WG konnte nicht verlassen werden. Bitte versuche es erneut.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLeaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wg.name),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.wg.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Einladungscode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(
                widget.wg.inviteCode,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              Text(
                widget.role == MembershipRole.admin
                    ? 'Du bist Administrator dieser WG.'
                    : 'Du bist Mitglied dieser WG.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ShoppingListPage(
                        wgId: widget.wg.id,
                        wgName: widget.wg.name,
                        userId: widget.userId,
                        shoppingListService: widget.shoppingListService,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Einkaufsliste öffnen'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ExpenseOverviewPage(
                        wgId: widget.wg.id,
                        wgName: widget.wg.name,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Ausgaben öffnen'),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _isLeaving ? null : _confirmAndLeaveWg,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                child: _isLeaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('WG verlassen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
