import 'package:flutter/material.dart';

import '../application/wg_service.dart';

class JoinWgPage extends StatefulWidget {
  const JoinWgPage({
    super.key,
    required this.userId,
    WgService? wgService,
  }) : _wgService = wgService;

  final String userId;
  final WgService? _wgService;

  @override
  State<JoinWgPage> createState() => _JoinWgPageState();
}

class _JoinWgPageState extends State<JoinWgPage> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();

  WgService? _wgService;

  bool _isLoading = false;
  String? _errorMessage;
  WgJoinPreview? _preview;

  @override
  void initState() {
    super.initState();
    _wgService = widget._wgService;
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _findWg() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _preview = null;
    });

    try {
      final wgService = _wgService ??= WgService();

      final preview = await wgService.findWgByInviteCode(
        inviteCode: _inviteCodeController.text,
        userId: widget.userId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _preview = preview;
      });
    } on UserAlreadyInWgException {
      _showError('Du bist bereits Mitglied einer WG.');
    } on InvalidInviteCodeException {
      _showError(
        'Der Einladungscode muss aus 6 Buchstaben oder Zahlen bestehen.',
      );
    } on InviteCodeNotFoundException {
      _showError('Keine WG mit diesem Einladungscode gefunden.');
    } catch (_) {
      _showError(
        'Die WG konnte nicht gefunden werden. Bitte versuche es erneut.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinWg() async {
    final preview = _preview;

    if (preview == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final wgService = _wgService ??= WgService();

      final wg = await wgService.joinWg(
        inviteCode: preview.inviteCode,
        userId: widget.userId,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(wg);
    } on UserAlreadyInWgException {
      _showError('Du bist bereits Mitglied einer WG.');
    } on InviteCodeNotFoundException {
      _showError('Der Einladungscode ist nicht mehr gültig.');
    } catch (_) {
      _showError(
        'Der WG-Beitritt ist fehlgeschlagen. Bitte versuche es erneut.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WG beitreten'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _inviteCodeController,
                  enabled: !_isLoading,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Einladungscode',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (_preview != null || _errorMessage != null) {
                      setState(() {
                        _preview = null;
                        _errorMessage = null;
                      });
                    }
                  },
                  validator: (value) {
                    final code = value?.trim().toUpperCase() ?? '';

                    if (code.isEmpty) {
                      return 'Bitte gib einen Einladungscode ein.';
                    }

                    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
                      return 'Der Einladungscode muss aus 6 Buchstaben oder Zahlen bestehen.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isLoading ? null : _findWg,
                  child: _isLoading && _preview == null
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('WG suchen'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_preview != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Gefundene WG',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _preview!.wgName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Einladungscode: ${_preview!.inviteCode}'),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _joinWg,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('WG beitreten'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
