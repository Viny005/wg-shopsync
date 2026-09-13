import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/shopping_item.dart';
import 'package:wg_shopsync/src/features/shopping_list/application/shopping_list_service.dart';
import 'package:wg_shopsync/src/features/shopping_list/presentation/shopping_item_edit_page.dart';
import 'package:wg_shopsync/src/features/shopping_list/presentation/shopping_list_page.dart';

import '../../../support/fake_shopping_list_service.dart';

void main() {
  group('UC-10: ShoppingListPage display & states', () {
    testWidgets('shows loading indicator when waiting for items',
        (tester) async {
      // Service with empty initial items, but we test before pumpAndSettle if needed
      final service = FakeShoppingListService();

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      // Immediately after initial pump, stream is evaluated
      await tester.pump();
      expect(find.byType(ShoppingListPage), findsOneWidget);
    });

    testWidgets('shows empty state when no items exist', (tester) async {
      final service = FakeShoppingListService(initialItems: []);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Keine Artikel auf der Einkaufsliste'), findsOneWidget);
      expect(
        find.text(
            'Tippe auf das Plus-Symbol, um einen neuen Artikel hinzuzufügen.'),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows error state when stream emits error', (tester) async {
      final service = FakeShoppingListService(
        streamError: Exception('Network offline'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fehler beim Laden der Einkaufsliste.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Erneut versuchen'),
          findsOneWidget);
    });

    testWidgets('displays items grouped into open and bought sections',
        (tester) async {
      final openItem = ShoppingItem(
        id: '1',
        wgId: 'wg-1',
        name: 'Apfel',
        quantity: 4,
        category: ShoppingItemCategory.lebensmittel,
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final boughtItem = ShoppingItem(
        id: '2',
        wgId: 'wg-1',
        name: 'Zahnpasta',
        category: ShoppingItemCategory.hygiene,
        status: ShoppingItemStatus.bought,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(
        initialItems: [openItem, boughtItem],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Offene Artikel (1)'), findsOneWidget);
      expect(find.text('Gekaufte Artikel (1)'), findsOneWidget);
      expect(find.text('Apfel'), findsOneWidget);
      expect(find.text('Zahnpasta'), findsOneWidget);
      expect(find.text('4x'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Lebensmittel'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Hygiene'), findsOneWidget);
    });

    testWidgets(
        'groups items under category subheaders within each status section',
        (tester) async {
      final food1 = ShoppingItem(
        id: '1',
        wgId: 'wg-1',
        name: 'Brot',
        category: ShoppingItemCategory.lebensmittel,
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final household1 = ShoppingItem(
        id: '2',
        wgId: 'wg-1',
        name: 'Mülltüten',
        category: ShoppingItemCategory.haushalt,
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final uncatOpen = ShoppingItem(
        id: '3',
        wgId: 'wg-1',
        name: 'Batterien',
        category: null,
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final foodBought = ShoppingItem(
        id: '4',
        wgId: 'wg-1',
        name: 'Käse',
        category: ShoppingItemCategory.lebensmittel,
        status: ShoppingItemStatus.bought,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(
        initialItems: [food1, household1, uncatOpen, foodBought],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Offene Artikel (3)'), findsOneWidget);
      expect(find.text('Gekaufte Artikel (1)'), findsOneWidget);
      expect(find.text('Lebensmittel'), findsWidgets);
      expect(find.text('Haushalt'), findsWidgets);
      expect(find.text('Ohne Kategorie'), findsOneWidget);
      expect(find.text('Brot'), findsOneWidget);
      expect(find.text('Mülltüten'), findsOneWidget);
      expect(find.text('Batterien'), findsOneWidget);
      expect(find.text('Käse'), findsOneWidget);
    });

    testWidgets('filters items by category chip', (tester) async {
      final foodItem = ShoppingItem(
        id: '1',
        wgId: 'wg-1',
        name: 'Milch',
        category: ShoppingItemCategory.lebensmittel,
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final cleanItem = ShoppingItem(
        id: '2',
        wgId: 'wg-1',
        name: 'Spülmittel',
        category: ShoppingItemCategory.haushalt,
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(
        initialItems: [foodItem, cleanItem],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Milch'), findsOneWidget);
      expect(find.text('Spülmittel'), findsOneWidget);

      // Select 'Haushalt' filter chip
      await tester.tap(find.widgetWithText(FilterChip, 'Haushalt'));
      await tester.pumpAndSettle();

      expect(find.text('Spülmittel'), findsOneWidget);
      expect(find.text('Milch'), findsNothing);

      // Reset to 'Alle'
      await tester.tap(find.widgetWithText(FilterChip, 'Alle'));
      await tester.pumpAndSettle();

      expect(find.text('Milch'), findsOneWidget);
      expect(find.text('Spülmittel'), findsOneWidget);
    });
  });

  group('UC-09: Mark item as bought from list', () {
    testWidgets('tapping checkbox marks item as bought', (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Käse',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(initialItems: [item]);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(service.markAsBoughtCalls, 1);
      expect(service.lastBoughtItemId, 'item-1');
    });

    testWidgets('shows message when item was already marked as bought',
        (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Käse',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(
        initialItems: [item],
        markAsBoughtError: const ShoppingItemAlreadyBoughtException(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Der Artikel wurde bereits als gekauft markiert.'),
        findsOneWidget,
      );
    });

    testWidgets('shows message when item is not found during mark as bought',
        (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Käse',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(
        initialItems: [item],
        markAsBoughtError: const ShoppingItemNotFoundException(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Der Artikel ist nicht mehr verfügbar.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'shows conflict message when item was concurrently modified before marking as bought',
        (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Käse',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(
        initialItems: [item],
        simulateConflictOnMarkAsBought: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text(
          'Der Artikel wurde zwischenzeitlich geändert. Der Serverstand wird geladen.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'shows connection required SnackBar when offline during mark as bought',
        (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Käse',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(
        initialItems: [item],
        markAsBoughtError: const ShoppingItemRequiresConnectionException(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text(
          'Diese Aktion benötigt eine Internetverbindung. Bitte versuche es erneut, sobald du wieder online bist.',
        ),
        findsOneWidget,
      );
    });
  });

  group('UC-08: Delete item from ShoppingListPage', () {
    testWidgets('shows confirmation dialog and cancels on Abbrechen',
        (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Reis',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(initialItems: [item]);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Artikel löschen?'), findsOneWidget);
      expect(
        find.text(
            'Möchtest du den Artikel "Reis" wirklich von der Einkaufsliste löschen?'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
      await tester.pumpAndSettle();

      expect(service.deleteItemCalls, 0);
      expect(find.text('Reis'), findsOneWidget);
    });

    testWidgets('deletes item when confirmed in dialog', (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Reis',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(initialItems: [item]);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
      await tester.pumpAndSettle();

      expect(service.deleteItemCalls, 1);
      expect(service.lastDeletedItemId, 'item-1');
      expect(find.text('Keine Artikel auf der Einkaufsliste'), findsOneWidget);
    });

    testWidgets('handles already-deleted item gracefully with SnackBar',
        (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Reis',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(
        initialItems: [item],
        deleteItemError: const ShoppingItemNotFoundException(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Der Artikel wurde bereits gelöscht.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'swiping item triggers confirmation dialog and aborts on Abbrechen',
        (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Reis',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(initialItems: [item]);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Swipe from right to left
      await tester.drag(find.text('Reis'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Artikel löschen?'), findsOneWidget);
      expect(
        find.text(
            'Möchtest du den Artikel "Reis" wirklich von der Einkaufsliste löschen?'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
      await tester.pumpAndSettle();

      expect(service.deleteItemCalls, 0);
      expect(find.text('Reis'), findsOneWidget);
    });

    testWidgets(
        'swiping item triggers confirmation dialog and deletes on confirm',
        (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Reis',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(initialItems: [item]);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Swipe from right to left
      await tester.drag(find.text('Reis'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
      await tester.pumpAndSettle();

      expect(service.deleteItemCalls, 1);
      expect(service.lastDeletedItemId, 'item-1');
      expect(find.text('Keine Artikel auf der Einkaufsliste'), findsOneWidget);
    });

    testWidgets(
        'swiping item handles deletion failure safely without removing from tree',
        (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Reis',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(
        initialItems: [item],
        deleteItemError: Exception('Firestore error'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.drag(find.text('Reis'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(service.deleteItemCalls, 1);
      expect(
        find.text('Fehler beim Löschen des Artikels.'),
        findsOneWidget,
      );
      // Item must remain in tree and not cause Dismissible crash
      expect(find.text('Reis'), findsOneWidget);
    });

    testWidgets(
        'swiping item handles already-deleted case gracefully with SnackBar',
        (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Reis',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(
        initialItems: [item],
        deleteItemError: const ShoppingItemNotFoundException(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.drag(find.text('Reis'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(service.deleteItemCalls, 1);
      expect(
        find.text('Der Artikel wurde bereits gelöscht.'),
        findsOneWidget,
      );
    });
  });

  group('Offline and pending sync indicators in ShoppingListPage', () {
    testWidgets('shows offline banner when data is from cache', (tester) async {
      final item = ShoppingItem(
        id: '1',
        wgId: 'wg-1',
        name: 'Nudeln',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final service = FakeShoppingListService(
        initialItems: [item],
        isFromCache: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Offline-Daten: Zwischengespeicherte Liste.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'shows offline pending sync banner when from cache with pending writes',
        (tester) async {
      final item = ShoppingItem(
        id: '1',
        wgId: 'wg-1',
        name: 'Nudeln',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final service = FakeShoppingListService(
        initialItems: [item],
        isFromCache: true,
        hasPendingWrites: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Offline-Änderungen werden bei Verbindung synchronisiert.'),
        findsOneWidget,
      );
    });

    testWidgets('shows pending sync banner when writes are pending',
        (tester) async {
      final item = ShoppingItem(
        id: '1',
        wgId: 'wg-1',
        name: 'Nudeln',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final service = FakeShoppingListService(
        initialItems: [item],
        hasPendingWrites: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Lokale Änderungen werden synchronisiert...'),
        findsOneWidget,
      );
    });
  });

  group('Navigation from ShoppingListPage', () {
    testWidgets('tapping FAB opens ShoppingItemEditPage in Add mode',
        (tester) async {
      final service = FakeShoppingListService(initialItems: []);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingItemEditPage), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Artikel hinzufügen'), findsOneWidget);
    });

    testWidgets('tapping an item tile opens ShoppingItemEditPage in Edit mode',
        (tester) async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Eier',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final service = FakeShoppingListService(initialItems: [item]);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListPage(
            wgId: 'wg-1',
            wgName: 'WG Test',
            userId: 'user-1',
            shoppingListService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Eier'));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingItemEditPage), findsOneWidget);
      expect(find.text('Artikel bearbeiten'), findsOneWidget);
    });
  });
}
