import 'package:flutter/material.dart';

import '../../../domain/models/shopping_item.dart';
import '../application/shopping_list_service.dart';
import 'shopping_item_edit_page.dart';

/// Screen 6 – Einkaufsliste (siehe B1.7, UC-06 bis UC-10, AF-04).
class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({
    super.key,
    required this.wgId,
    required this.wgName,
    required this.userId,
    this.shoppingListService,
  });

  final String wgId;
  final String wgName;
  final String userId;
  final ShoppingListService? shoppingListService;

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  late final ShoppingListService _shoppingListService =
      widget.shoppingListService ?? ShoppingListService();

  ShoppingItemCategory? _filterCategory;

  Future<void> _markAsBought(ShoppingItem item) async {
    try {
      await _shoppingListService.markAsBought(
        wgId: widget.wgId,
        itemId: item.id,
      );
    } on ShoppingItemAlreadyBoughtException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Der Artikel wurde bereits als gekauft markiert.'),
        ),
      );
    } on ShoppingItemNotFoundException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Der Artikel ist nicht mehr verfügbar.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Aktualisieren des Artikelstatus.'),
        ),
      );
    }
  }

  Future<void> _confirmAndDelete(ShoppingItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Artikel löschen?'),
        content: Text(
          'Möchtest du den Artikel "${item.name}" wirklich von der Einkaufsliste löschen?',
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

    try {
      await _shoppingListService.deleteItem(
        wgId: widget.wgId,
        itemId: item.id,
      );
    } on ShoppingItemNotFoundException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Der Artikel wurde bereits gelöscht.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Löschen des Artikels.'),
        ),
      );
    }
  }

  Future<void> _openAddOrEditPage({ShoppingItem? item}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShoppingItemEditPage(
          wgId: widget.wgId,
          userId: widget.userId,
          item: item,
          shoppingListService: _shoppingListService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einkaufsliste'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCategoryFilterBar(),
            Expanded(
              child: StreamBuilder<List<ShoppingItem>>(
                stream: _shoppingListService.watchShoppingItems(
                  wgId: widget.wgId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Fehler beim Laden der Einkaufsliste.',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Erneut versuchen'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allItems = snapshot.data ?? [];
                  final filteredItems = _filterCategory == null
                      ? allItems
                      : allItems
                          .where((it) => it.category == _filterCategory)
                          .toList();

                  if (filteredItems.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_basket_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              allItems.isEmpty
                                  ? 'Keine Artikel auf der Einkaufsliste'
                                  : 'Keine Artikel in dieser Kategorie',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              allItems.isEmpty
                                  ? 'Tippe auf das Plus-Symbol, um einen neuen Artikel hinzuzufügen.'
                                  : 'Wähle eine andere Kategorie oder setze den Filter zurück.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final openItems = filteredItems
                      .where((it) => it.status == ShoppingItemStatus.open)
                      .toList();
                  final boughtItems = filteredItems
                      .where((it) => it.status == ShoppingItemStatus.bought)
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      if (openItems.isNotEmpty) ...[
                        _buildSectionHeader(
                            'Offene Artikel (${openItems.length})'),
                        ...openItems.map((item) => _buildItemTile(item)),
                      ],
                      if (boughtItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSectionHeader(
                          'Gekaufte Artikel (${boughtItems.length})',
                        ),
                        ...boughtItems.map((item) => _buildItemTile(item)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddOrEditPage(),
        icon: const Icon(Icons.add),
        label: const Text('Artikel hinzufügen'),
        tooltip: 'Artikel hinzufügen',
      ),
    );
  }

  Widget _buildCategoryFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Alle'),
            selected: _filterCategory == null,
            onSelected: (_) {
              setState(() => _filterCategory = null);
            },
          ),
          const SizedBox(width: 8),
          ...ShoppingItemCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat.displayName),
                selected: _filterCategory == cat,
                onSelected: (selected) {
                  setState(() {
                    _filterCategory = selected ? cat : null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildItemTile(ShoppingItem item) {
    final isBought = item.status == ShoppingItemStatus.bought;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: isBought ? 0 : 1,
      color: isBought
          ? Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.5)
          : null,
      child: ListTile(
        leading: Checkbox(
          value: isBought,
          onChanged: isBought ? null : (_) => _markAsBought(item),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: isBought ? TextDecoration.lineThrough : null,
            fontWeight: isBought ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: _buildItemSubtitle(item),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Löschen',
          onPressed: () => _confirmAndDelete(item),
        ),
        onTap: () => _openAddOrEditPage(item: item),
      ),
    );
  }

  Widget? _buildItemSubtitle(ShoppingItem item) {
    final chips = <Widget>[];

    if (item.quantity != null) {
      chips.add(
        Chip(
          label: Text('${item.quantity}x'),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      );
    }

    if (item.category != null) {
      chips.add(
        Chip(
          label: Text(item.category!.displayName),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      );
    }

    if (chips.isEmpty &&
        (item.description == null || item.description!.isEmpty)) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.description != null && item.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              item.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (chips.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: chips,
          ),
      ],
    );
  }
}
