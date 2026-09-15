import 'package:flutter/material.dart';

import '../domain/expense_service.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({
    super.key,
    required this.wgId,
    required this.userId,
    required this.expenseService,
    required this.memberIds,
  });

  final String wgId;
  final String userId;
  final ExpenseService expenseService;
  final List<String> memberIds;

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  late List<String> _selectedParticipants;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedParticipants = List.of(widget.memberIds);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParticipants.isEmpty) {
      setState(() => _errorMessage = 'Bitte mindestens eine Person auswählen.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.expenseService.addExpense(
        wgId: widget.wgId,
        paidBy: widget.userId,
        amount: double.parse(_amountController.text.trim().replaceAll(',', '.')),
        description: _descriptionController.text.trim(),
        participantIds: _selectedParticipants,
      );
      if (mounted) Navigator.of(context).pop();
    } on InvalidExpenseAmountException {
      setState(() => _errorMessage = 'Betrag muss größer als 0 sein.');
    } on NoParticipantsException {
      setState(() => _errorMessage = 'Bitte mindestens eine Person auswählen.');
    } catch (_) {
      setState(() => _errorMessage = 'Fehler beim Speichern. Bitte erneut versuchen.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ausgabe hinzufügen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Beschreibung'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Bitte eine Beschreibung eingeben.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Betrag (€)',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Bitte einen Betrag eingeben.';
                  final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Betrag muss größer als 0 sein.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Beteiligte Personen',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...widget.memberIds.map((memberId) {
                final isSelected = _selectedParticipants.contains(memberId);
                return CheckboxListTile(
                  title: Text(memberId),
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedParticipants.add(memberId);
                      } else {
                        _selectedParticipants.remove(memberId);
                      }
                    });
                  },
                );
              }),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ausgabe speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
