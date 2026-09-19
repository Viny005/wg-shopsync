import 'package:flutter/material.dart';

import '../../../core/validation/validators.dart';
import '../../../domain/models/shopping_item.dart';
import '../application/shopping_list_service.dart';

/// Screen 7 – Artikel hinzufügen / bearbeiten (siehe B1.8, UC-06, UC-07, UC-08).
class ShoppingItemEditPage extends StatefulWidget {
  const ShoppingItemEditPage({
    super.key,
    required this.wgId,
    required this.userId,
    this.item,
    this.shoppingListService,
  });

  final String wgId;
  final String userId;
  final ShoppingItem? item;
  final ShoppingListService? shoppingListService;

  bool get isEditing => item != null;

  @override
  State<ShoppingItemEditPage> createState() => _ShoppingItemEditPageState();
}

class _ShoppingItemEditPageState extends State<ShoppingItemEditPage> {
  late final ShoppingListService _shoppingListService =
      widget.shoppingListService ?? ShoppingListService();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  ShoppingItemCategory? _selectedCategory;

  bool _isSubmitting = false;
  late DateTime _expectedUpdatedAt;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController =
        TextEditingController(text: item?.description ?? '');
    _quantityController = TextEditingController(
      text: item?.quantity != null ? item!.quantity.toString() : '',
    );
    _selectedCategory = item?.category;
    _expectedUpdatedAt = item?.updatedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final quantityText = _quantityController.text.trim();
    final quantity =
        quantityText.isNotEmpty ? int.tryParse(quantityText) : null;

    try {
      if (widget.isEditing) {
        final updatedItem = await _shoppingListService.updateItem(
          wgId: widget.wgId,
          itemId: widget.item!.id,
          name: name,
          description: description,
          quantity: quantity,
          category: _selectedCategory,
          clearCategory: _selectedCategory == null,
          expectedUpdatedAt: _expectedUpdatedAt,
        );

        if (!mounted) return;
        Navigator.of(context).pop(updatedItem);
      } else {
        final newItem = await _shoppingListService.addItem(
          wgId: widget.wgId,
          userId: widget.userId,
          name: name,
          description: description,
          quantity: quantity,
          category: _selectedCategory,
        );

        if (!mounted) return;
        Navigator.of(context).pop(newItem);
      }
    } on ShoppingItemConflictException catch (conflict) {
      if (!mounted) return;
      _showConflictDialog(conflict.serverItem);
    } on ShoppingItemNotFoundException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Der Artikel wurde zwischenzeitlich gelöscht.'),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on ShoppingItemRequiresConnectionException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Diese Aktion benötigt eine Internetverbindung. Bitte versuche es erneut, sobald du wieder online bist.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Fehler beim Speichern der Änderungen.'
                : 'Fehler beim Hinzufügen des Artikels.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showConflictDialog(ShoppingItem serverItem) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konflikt erkannt'),
        content: const Text(
          'Der Artikel wurde zwischenzeitlich von einem anderen Mitglied geändert. '
          'Gemäß Systemrichtlinie gilt der Serverstand. Bitte überprüfe die Daten.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() {
                _nameController.text = serverItem.name;
                _descriptionController.text = serverItem.description ?? '';
                _quantityController.text = serverItem.quantity != null
                    ? serverItem.quantity.toString()
                    : '';
                _selectedCategory = serverItem.category;
                _expectedUpdatedAt = serverItem.updatedAt ?? DateTime.now();
              });
            },
            child: const Text('Serverdaten laden'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem() async {
    if (!widget.isEditing) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Artikel löschen?'),
        content: Text(
          'Möchtest du den Artikel "${widget.item!.name}" wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      await _shoppingListService.deleteItem(
        wgId: widget.wgId,
        itemId: widget.item!.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ShoppingItemNotFoundException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Der Artikel wurde bereits gelöscht.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Löschen des Artikels.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Artikel bearbeiten' : 'Artikel hinzufügen',
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Löschen',
              onPressed: _isSubmitting ? null : _deleteItem,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Artikelname *',
                      ),
                      validator: Validators.itemName,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Menge (optional)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Die Menge muss eine positive Ganzzahl sein.';
                        }
                        return Validators.quantity(parsed);
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ShoppingItemCategory?>(
                      // Keep `value` for compatibility with Flutter 3.32.x.
                      // ignore: deprecated_member_use
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategorie (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<ShoppingItemCategory?>(
                          value: null,
                          child: Text('Keine Kategorie'),
                        ),
                        ...ShoppingItemCategory.values.map(
                          (cat) => DropdownMenuItem<ShoppingItemCategory?>(
                            value: cat,
                            child: Text(cat.displayName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Beschreibung (optional)',
                      ),
                      maxLines: 3,
                      validator: Validators.itemDescription,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.isEditing
                                  ? 'Änderungen speichern'
                                  : 'Artikel hinzufügen',
                            ),
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _deleteItem,
                        icon: const Icon(Icons.delete),
                        label: const Text('Artikel löschen'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
