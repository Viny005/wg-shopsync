import 'package:flutter/material.dart';

import '../../../core/validation/validators.dart';
import '../../wg/application/wg_service.dart';
import '../application/expense_service.dart';
import '../../../domain/models/membership.dart';

class ExpenseFormPage extends StatefulWidget {
  const ExpenseFormPage({
    super.key,
    required this.wgId,
    required this.userId,
    this.wgService,
    this.expenseService,
  });

  final String wgId;
  final String userId;
  final WgService? wgService;
  final ExpenseService? expenseService;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  late final WgService _wgService = widget.wgService ?? WgService();
  late final ExpenseService _expenseService =
      widget.expenseService ?? ExpenseService();

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Membership> _members = const [];
  String? _selectedPayer;
  final Set<String> _selectedParticipants = <String>{};
  bool _isLoadingMembers = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

    Future<void> _loadMembers() async {
    try {
      final members = await _wgService.loadWgMembers(wgId: widget.wgId);
      if (!mounted) {
        return;
      }

      setState(() {
        _members = members;
        _isLoadingMembers = false;

        if (_members.isNotEmpty) {
          final isMember = _members.any((m) => m.userId == widget.userId);
          _selectedPayer = isMember ? widget.userId : _members.first.userId;

          if (_selectedParticipants.isEmpty && isMember) {
            _selectedParticipants.add(widget.userId);
          }
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Betrag ein.')),
      );
      return;
    }

    final parsedAmount = double.tryParse(amountText.replaceFirst(',', '.'));
    if (parsedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen gültigen Betrag ein.')),
      );
      return;
    }

    if (_selectedPayer == null || _selectedPayer!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wähle einen Zahler aus.')),
      );
      return;
    }

    final participants = _selectedParticipants.toList()..sort();
    if (participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte mindestens ein beteiligtes Mitglied auswählen.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _expenseService.createExpense(
        wgId: widget.wgId,
        amount: parsedAmount,
        description: description,
        paidBy: _selectedPayer!,
        participantUserIds: participants,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ausgabe gespeichert.')),
      );
      Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
    } on ExpensePayerNotMemberException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Der Zahler muss ein Mitglied der WG sein.'),
        ),
      );
    } on ExpenseParticipantNotMemberException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alle beteiligten Mitglieder müssen Mitglieder der WG sein.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Die Ausgabe konnte nicht gespeichert werden.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_isLoadingMembers && _members.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ausgabe erfassen'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoadingMembers
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Betrag',
                          prefixText: '€ ',
                          hintText: '12,50',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bitte gib einen Betrag ein.';
                          }

                          final parsedValue = double.tryParse(
                            value.trim().replaceFirst(',', '.'),
                          );
                          if (parsedValue == null) {
                            return 'Bitte gib einen gültigen Betrag ein.';
                          }

                          final amountError = Validators.expenseAmount(parsedValue);
                          if (amountError != null) {
                            return amountError;
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Beschreibung',
                          hintText: 'Bsp.: Lebensmittel für das Wochenende',
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Bitte gib eine Beschreibung ein.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        // Keep `value` for compatibility with Flutter 3.32.x.
                        // ignore: deprecated_member_use
                        value: _selectedPayer,
                        items: _members
                            .map(
                              (member) => DropdownMenuItem<String>(
                                value: member.userId,
                                child: Text(member.displayLabel),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPayer = value);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Zahler',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bitte wähle einen Zahler aus.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Beteiligte',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_members.isEmpty)
                        const Text('Keine Mitglieder verfügbar.')
                      else
                        ..._members.map(
                          (member) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(member.displayLabel),
                            value: _selectedParticipants.contains(member.userId),
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedParticipants.add(member.userId);
                                } else {
                                  _selectedParticipants.remove(member.userId);
                                }
                              });
                            },
                          ),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                              child: const Text('Abbrechen'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _isSaving || !canSubmit ? null : _submit,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Speichern'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
