import 'package:flutter/material.dart';

import '../../../core/validation/validators.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/membership.dart';
import '../../wg/application/wg_service.dart';
import '../application/expense_service.dart';

/// UC-12 - Ausgabe bearbeiten.
///
/// Laedt die vorhandene Ausgabe samt Kostenanteilen und ermoeglicht das
/// Aendern von Betrag, Beschreibung, Zahler und Beteiligten. Die Werte
/// werden ueber [ExpenseService.updateExpense] gespeichert, das die
/// Kostenaufteilung erneut ueber ExpenseCalculator (AF-01) berechnet.
class ExpenseEditPage extends StatefulWidget {
  const ExpenseEditPage({
    super.key,
    required this.expense,
    required this.userId,
    this.wgService,
    this.expenseService,
  });

  final Expense expense;
  final String userId;
  final WgService? wgService;
  final ExpenseService? expenseService;

  @override
  State<ExpenseEditPage> createState() => _ExpenseEditPageState();
}

class _ExpenseEditPageState extends State<ExpenseEditPage> {
  late final WgService _wgService = widget.wgService ?? WgService();
  late final ExpenseService _expenseService =
      widget.expenseService ?? ExpenseService();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late Expense _currentExpense;

  List<Membership> _members = const [];
  String? _selectedPayer;
  final Set<String> _selectedParticipants = <String>{};

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _currentExpense = widget.expense;
    _amountController = TextEditingController(
      text: _formatAmountForInput(widget.expense.amount),
    );
    _descriptionController =
        TextEditingController(text: widget.expense.description);
    _loadMembersAndShares();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatAmountForInput(double amount) {
    // Zeigt ganze Betraege ohne unnoetige Nachkommastellen an, behaelt aber
    // vorhandene Cent-Werte bei (z.B. 10 statt 10.0, aber 10.5 bleibt 10.5).
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  Future<void> _loadMembersAndShares() async {
    try {
      final members = await _wgService.loadWgMembers(
        wgId: _currentExpense.wgId,
      );
      final shares = await _expenseService.getExpenseShares(
        wgId: _currentExpense.wgId,
        expenseId: _currentExpense.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _members = members;
        _selectedPayer = _currentExpense.paidBy;
        _selectedParticipants
          ..clear()
          ..addAll(shares.map((share) => share.userId));
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = 'Die Ausgabe konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _showConflictDialog(Expense serverExpense) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konflikt erkannt'),
        content: const Text(
          'Die Ausgabe wurde zwischenzeitlich von einem anderen Mitglied '
          'geaendert. Gemaess Systemrichtlinie gilt der Serverstand. Bitte '
          'ueberpruefe die aktuellen Daten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('reload'),
            child: const Text('Serverdaten laden'),
          ),
        ],
      ),
    );

    if (action != 'reload' || !mounted) {
      return;
    }

    setState(() {
      _currentExpense = serverExpense;
      _amountController.text = _formatAmountForInput(serverExpense.amount);
      _descriptionController.text = serverExpense.description;
      _isLoading = true;
    });

    await _loadMembersAndShares();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    final parsedAmount = double.tryParse(amountText.replaceFirst(',', '.'));
    if (parsedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen gueltigen Betrag ein.')),
      );
      return;
    }

    if (_selectedPayer == null || _selectedPayer!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte waehle einen Zahler aus.')),
      );
      return;
    }

    final participants = _selectedParticipants.toList()..sort();
    if (participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Bitte mindestens ein beteiligtes Mitglied auswaehlen.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _expenseService.updateExpense(
        originalExpense: _currentExpense,
        amount: parsedAmount,
        description: description,
        paidBy: _selectedPayer!,
        participantUserIds: participants,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ausgabe aktualisiert.')),
      );
      Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
    } on ExpenseConflictException catch (error) {
      if (!mounted) {
        return;
      }
      await _showConflictDialog(error.serverExpense);
    } on ExpenseNotFoundException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Die Ausgabe ist nicht mehr verfuegbar.')),
      );
    } on ExpenseRequiresConnectionException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Diese Aktion benoetigt eine Internetverbindung. Bitte versuche '
            'es erneut, sobald du wieder online bist.',
          ),
        ),
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
          content: Text(
            'Alle beteiligten Mitglieder muessen Mitglieder der WG sein.',
          ),
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
    final canSubmit = !_isLoading && _loadError == null && _members.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ausgabe bearbeiten'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(child: Text(_loadError!))
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
                                return 'Bitte gib einen gueltigen Betrag ein.';
                              }

                              final amountError =
                                  Validators.expenseAmount(parsedValue);
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
                              hintText:
                                  'Bsp.: Lebensmittel fuer das Wochenende',
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
                            value:
                                _members.any((m) => m.userId == _selectedPayer)
                                    ? _selectedPayer
                                    : null,
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
                                return 'Bitte waehle einen Zahler aus.';
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
                            const Text('Keine Mitglieder verfuegbar.')
                          else
                            ..._members.map(
                              (member) => CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(member.displayLabel),
                                value: _selectedParticipants
                                    .contains(member.userId),
                                onChanged: (selected) {
                                  setState(() {
                                    if (selected == true) {
                                      _selectedParticipants.add(member.userId);
                                    } else {
                                      _selectedParticipants
                                          .remove(member.userId);
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
                                  onPressed: _isSaving
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: const Text('Abbrechen'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed:
                                      _isSaving || !canSubmit ? null : _submit,
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Aenderungen speichern'),
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
