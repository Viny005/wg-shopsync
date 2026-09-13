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
        expectedUpdatedAt: item.updatedAt,
      );
    } on ShoppingItemConflictException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Der Artikel wurde zwischenzeitlich geändert. Der Serverstand wird geladen.',
          ),
        ),
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
        const SnackBar(
          content: Text('Fehler beim Aktualisieren des Artikelstatus.'),
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(ShoppingItem item) {
    return showDialog<bool>(
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
  }

  Future<void> _deleteItemDirectly(ShoppingItem item) async {
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

  Future<void> _confirmAndDelete(ShoppingItem item) async {
    final shouldDelete = await _showDeleteConfirmationDialog(item);

    if (shouldDelete != true || !mounted) return;
    await _deleteItemDirectly(item);
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
              child: StreamBuilder<ShoppingListState>(
                stream: _shoppingListService.watchShoppingList(
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

                  final state =
                      snapshot.data ?? const ShoppingListState(items: []);
                  final allItems = state.items;
                  final filteredItems = _filterCategory == null
                      ? allItems
                      : allItems
                          .where((it) => it.category == _filterCategory)
                          .toList();

                  return Column(
                    children: [
                      if (state.isFromCache && state.hasPendingWrites)
                        _buildStatusBanner(
                          icon: Icons.sync,
                          text:
                              'Offline-Änderungen werden bei Verbindung synchronisiert.',
                          backgroundColor:
                              Theme.of(context).colorScheme.secondaryContainer,
                        )
                      else if (state.hasPendingWrites)
                        _buildStatusBanner(
                          icon: Icons.sync,
                          text: 'Lokale Änderungen werden synchronisiert...',
                          backgroundColor:
                              Theme.of(context).colorScheme.secondaryContainer,
                        )
                      else if (state.isFromCache)
                        _buildStatusBanner(
                          icon: Icons.cloud_done_outlined,
                          text: 'Offline-Daten: Zwischengespeicherte Liste.',
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                      Expanded(
                        child: filteredItems.isEmpty
                            ? _buildEmptyState(allItems.isEmpty)
                            : _buildGroupedListView(filteredItems),
                      ),
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

  Widget _buildStatusBanner({
    required IconData icon,
    required String text,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isListEmpty) {
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
              isListEmpty
                  ? 'Keine Artikel auf der Einkaufsliste'
                  : 'Keine Artikel in dieser Kategorie',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isListEmpty
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

  Widget _buildGroupedListView(List<ShoppingItem> items) {
    final openItems =
        items.where((it) => it.status == ShoppingItemStatus.open).toList();
    final boughtItems =
        items.where((it) => it.status == ShoppingItemStatus.bought).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      children: [
        if (openItems.isNotEmpty) ...[
          _buildSectionHeader('Offene Artikel (${openItems.length})'),
          ..._buildCategoryGroupedItems(openItems),
        ],
        if (boughtItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('Gekaufte Artikel (${boughtItems.length})'),
          ..._buildCategoryGroupedItems(boughtItems),
        ],
      ],
    );
  }

  List<Widget> _buildCategoryGroupedItems(List<ShoppingItem> items) {
    final widgets = <Widget>[];

    final categories = [
      ...ShoppingItemCategory.values,
      null,
    ];

    for (final category in categories) {
      final categoryItems =
          items.where((it) => it.category == category).toList();
      if (categoryItems.isEmpty) continue;

      final categoryName =
          category != null ? category.displayName : 'Ohne Kategorie';

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
          child: Text(
            categoryName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      );

      for (final item in categoryItems) {
        widgets.add(_buildItemTile(item));
      }
    }

    return widgets;
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

    return Dismissible(
      key: ValueKey('shopping-item-dismissible-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final shouldDelete = await _showDeleteConfirmationDialog(item);
        if (shouldDelete != true) return false;

        try {
          await _shoppingListService.deleteItem(
            wgId: widget.wgId,
            itemId: item.id,
          );
          return true;
        } on ShoppingItemNotFoundException {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Der Artikel wurde bereits gelöscht.'),
              ),
            );
          }
          return true;
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fehler beim Löschen des Artikels.'),
              ),
            );
          }
          return false;
        }
      },
      onDismissed: (_) {
        // Item was successfully deleted during confirmDismiss.
      },
      child: Card(
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
