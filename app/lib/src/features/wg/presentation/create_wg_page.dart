import 'package:flutter/material.dart';

import '../../../domain/models/wg.dart';
import '../application/wg_service.dart';

class CreateWgPage extends StatefulWidget {
  const CreateWgPage({
    super.key,
    required this.userId,
    WgService? wgService,
  }) : _wgService = wgService;

  final String userId;
  final WgService? _wgService;

  @override
  State<CreateWgPage> createState() => _CreateWgPageState();
}

class _CreateWgPageState extends State<CreateWgPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  WgService? _wgService;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _wgService = widget._wgService;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createWg() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final wgService = _wgService ??= WgService();

      final WG wg = await wgService.createWg(
        name: _nameController.text,
        userId: widget.userId,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(wg);
    } on UserAlreadyInWgException {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Du bist bereits Mitglied einer WG.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Die WG konnte nicht erstellt werden. Bitte versuche es erneut.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WG erstellen'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'WG-Name',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_isLoading) {
                      _createWg();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte gib einen WG-Namen ein.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: _isLoading ? null : _createWg,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('WG erstellen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
