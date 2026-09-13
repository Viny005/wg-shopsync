import 'package:flutter/material.dart';

import '../../../domain/models/wg.dart';
import '../../../domain/models/membership.dart';

class WgDetailPage extends StatelessWidget {
  const WgDetailPage({
    super.key,
    required this.wg,
    required this.role,
  });

  final WG wg;
  final MembershipRole role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(wg.name),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                wg.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Einladungscode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(
                wg.inviteCode,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              Text(
                role == MembershipRole.admin
                    ? 'Du bist Administrator dieser WG.'
                    : 'Du bist Mitglied dieser WG.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
