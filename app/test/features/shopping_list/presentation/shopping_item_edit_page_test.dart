import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/shopping_item.dart';
import 'package:wg_shopsync/src/features/shopping_list/presentation/shopping_item_edit_page.dart';

import '../../../support/fake_shopping_list_service.dart';

void main() {
  group('UC-06: ShoppingItemEditPage in Add Mode', () {
    testWidgets('displays form fields with initial empty values',
        (tester) async {
      final service = FakeShoppingListService();

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingItemEditPage(
            wgId: 'wg-1',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      expect(find.widgetWithText(AppBar, 'Artikel hinzufügen'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Artikelname *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Menge (optional)'),
          findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Beschreibung (optional)'),
          findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Artikel hinzufügen'),
          findsOneWidget);
    });

    testWidgets('does not show example placeholder hints in add mode',
        (tester) async {
      final service = FakeShoppingListService();

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingItemEditPage(
            wgId: 'wg-1',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      expect(find.text('z. B. Hafermilch'), findsNothing);
      expect(find.text('z. B. 2'), findsNothing);
      expect(find.text('z. B. bitte Bio-Qualität'), findsNothing);
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      final service = FakeShoppingListService();

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingItemEditPage(
            wgId: 'wg-1',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Artikel hinzufügen'));
      await tester.pump();

      expect(find.text('Bitte gib einen Artikelnamen ein.'), findsOneWidget);
      expect(service.addItemCalls, 0);
    });

    testWidgets('shows validation error when quantity is invalid',
        (tester) async {
      final service = FakeShoppingListService();

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingItemEditPage(
            wgId: 'wg-1',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Artikelname *'),
        'Kaffee',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Menge (optional)'),
        '0',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Artikel hinzufügen'));
      await tester.pump();

      expect(
        find.text('Die Menge muss eine positive Ganzzahl sein.'),
        findsOneWidget,
      );
      expect(service.addItemCalls, 0);
    });

    testWidgets('submits valid item and pops with result', (tester) async {
      final service = FakeShoppingListService();
      ShoppingItem? returnedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedItem = await Navigator.of(context).push<ShoppingItem>(
                  MaterialPageRoute(
                    builder: (_) => ShoppingItemEditPage(
                      wgId: 'wg-1',
                      userId: 'user-1',
                      shoppingListService: service,
                    ),
                  ),
                );
              },
              child: const Text('Open Add'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Add'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Artikelname *'),
        'Hafermilch',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Menge (optional)'),
        '3',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Beschreibung (optional)'),
        'Ohne Zuckerzusatz',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Artikel hinzufügen'));
      await tester.pumpAndSettle();

      expect(service.addItemCalls, 1);
      expect(service.lastAddedName, 'Hafermilch');
      expect(service.lastAddedQuantity, 3);
      expect(service.lastAddedDescription, 'Ohne Zuckerzusatz');
      expect(returnedItem, isNotNull);
      expect(returnedItem!.name, 'Hafermilch');
    });

    testWidgets('shows error SnackBar on submission failure', (tester) async {
      final service = FakeShoppingListService(
        addItemError: Exception('Database error'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingItemEditPage(
            wgId: 'wg-1',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Artikelname *'),
        'Nudeln',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Artikel hinzufügen'));
      await tester.pump();

      expect(
        find.text('Fehler beim Hinzufügen des Artikels.'),
        findsOneWidget,
      );
    });
  });

  group('UC-07: ShoppingItemEditPage in Edit Mode', () {
    final existingItem = ShoppingItem(
      id: 'item-1',
      wgId: 'wg-1',
      name: 'Tomaten',
      description: 'Rispentomaten',
      quantity: 5,
      category: ShoppingItemCategory.lebensmittel,
      status: ShoppingItemStatus.open,
      createdBy: 'user-1',
      createdAt: DateTime(2026, 9, 13, 10, 0),
      updatedAt: DateTime(2026, 9, 13, 10, 0),
    );

    testWidgets('prefills form fields with item data', (tester) async {
      final service = FakeShoppingListService(initialItems: [existingItem]);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingItemEditPage(
            wgId: 'wg-1',
            userId: 'user-1',
            item: existingItem,
            shoppingListService: service,
          ),
        ),
      );

      expect(find.text('Artikel bearbeiten'), findsOneWidget);
      expect(find.text('Tomaten'), findsOneWidget);
      expect(find.text('Rispentomaten'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Änderungen speichern'),
          findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Artikel löschen'),
          findsOneWidget);
    });

    testWidgets('does not show example placeholder hints in edit mode',
        (tester) async {
      final service = FakeShoppingListService(initialItems: [existingItem]);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingItemEditPage(
            wgId: 'wg-1',
            userId: 'user-1',
            item: existingItem,
            shoppingListService: service,
          ),
        ),
      );

      expect(find.text('z. B. Hafermilch'), findsNothing);
      expect(find.text('z. B. 2'), findsNothing);
      expect(find.text('z. B. bitte Bio-Qualität'), findsNothing);
    });

    testWidgets('shows validation error when editing name to empty',
        (tester) async {
      final service = FakeShoppingListService(initialItems: [existingItem]);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingItemEditPage(
            wgId: 'wg-1',
            userId: 'user-1',
            item: existingItem,
            shoppingListService: service,
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Artikelname *'),
        '',
      );
      await tester
          .tap(find.widgetWithText(FilledButton, 'Änderungen speichern'));
      await tester.pump();

      expect(find.text('Bitte gib einen Artikelnamen ein.'), findsOneWidget);
      expect(service.updateItemCalls, 0);
    });

    testWidgets('saves updated item and pops', (tester) async {
      final service = FakeShoppingListService(initialItems: [existingItem]);
      ShoppingItem? returnedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedItem = await Navigator.of(context).push<ShoppingItem>(
                  MaterialPageRoute(
                    builder: (_) => ShoppingItemEditPage(
                      wgId: 'wg-1',
                      userId: 'user-1',
                      item: existingItem,
                      shoppingListService: service,
                    ),
                  ),
                );
              },
              child: const Text('Open Edit'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Artikelname *'),
        'Bio-Tomaten',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Menge (optional)'),
        '6',
      );

      await tester
          .tap(find.widgetWithText(FilledButton, 'Änderungen speichern'));
      await tester.pumpAndSettle();

      expect(service.updateItemCalls, 1);
      expect(service.lastUpdatedName, 'Bio-Tomaten');
      expect(service.lastUpdatedQuantity, 6);
      expect(returnedItem, isNotNull);
      expect(returnedItem!.name, 'Bio-Tomaten');
    });

    testWidgets('shows conflict dialog when concurrent change occurs',
        (tester) async {
      final service = FakeShoppingListService(
        initialItems: [existingItem],
        simulateConflictOnUpdate: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingItemEditPage(
            wgId: 'wg-1',
            userId: 'user-1',
            item: existingItem,
            shoppingListService: service,
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Artikelname *'),
        'Geänderte Tomaten',
      );
      await tester
          .tap(find.widgetWithText(FilledButton, 'Änderungen speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Konflikt erkannt'), findsOneWidget);
      expect(
        find.text(
          'Der Artikel wurde zwischenzeitlich von einem anderen Mitglied geändert. '
          'Gemäß Systemrichtlinie gilt der Serverstand. Bitte überprüfe die Daten.',
        ),
        findsOneWidget,
      );
      expect(
          find.widgetWithText(TextButton, 'Serverdaten laden'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Serverdaten laden'));
      await tester.pumpAndSettle();

      expect(find.text('Konflikt erkannt'), findsNothing);
      expect(find.textContaining('server-side change'), findsOneWidget);
    });

    testWidgets('handles deleted item on update', (tester) async {
      final service = FakeShoppingListService(); // empty, item not found

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShoppingItemEditPage(
              wgId: 'wg-1',
              userId: 'user-1',
              item: existingItem,
              shoppingListService: service,
            ),
          ),
        ),
      );

      await tester
          .tap(find.widgetWithText(FilledButton, 'Änderungen speichern'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Der Artikel wurde zwischenzeitlich gelöscht.'),
        findsOneWidget,
      );
    });
  });

  group('UC-08: Delete item from ShoppingItemEditPage', () {
    final existingItem = ShoppingItem(
      id: 'item-1',
      wgId: 'wg-1',
      name: 'Kekse',
      status: ShoppingItemStatus.open,
      createdBy: 'user-1',
      createdAt: DateTime(2026, 9, 13),
      updatedAt: DateTime(2026, 9, 13),
    );

    testWidgets('shows confirmation dialog on delete and aborts on cancel',
        (tester) async {
      final service = FakeShoppingListService(initialItems: [existingItem]);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingItemEditPage(
            wgId: 'wg-1',
            userId: 'user-1',
            item: existingItem,
            shoppingListService: service,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Artikel löschen'));
      await tester.pumpAndSettle();

      expect(find.text('Artikel löschen?'), findsOneWidget);
      expect(
        find.text('Möchtest du den Artikel "Kekse" wirklich löschen?'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
      await tester.pumpAndSettle();

      expect(service.deleteItemCalls, 0);
      expect(find.byType(ShoppingItemEditPage), findsOneWidget);
    });

    testWidgets('deletes item when confirmed in dialog and pops',
        (tester) async {
      final service = FakeShoppingListService(initialItems: [existingItem]);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShoppingItemEditPage(
                      wgId: 'wg-1',
                      userId: 'user-1',
                      item: existingItem,
                      shoppingListService: service,
                    ),
                  ),
                );
              },
              child: const Text('Open Edit'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Artikel löschen'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
      await tester.pumpAndSettle();

      expect(service.deleteItemCalls, 1);
      expect(service.lastDeletedItemId, 'item-1');
      expect(find.byType(ShoppingItemEditPage), findsNothing);
    });
  });
}
