import 'package:flutter_test/flutter_test.dart';
import 'package:wg_shopsync/src/domain/models/shopping_item.dart';
import 'package:wg_shopsync/src/features/shopping_list/application/shopping_list_service.dart';

import '../../../support/fake_shopping_list_service.dart';

void main() {
  group('ShoppingItem domain model & AF-04 sorting', () {
    test(
        'sorts open items before bought items, and alphabetically within status',
        () {
      final item1 = ShoppingItem(
        id: '1',
        wgId: 'wg-1',
        name: 'Zucker',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final item2 = ShoppingItem(
        id: '2',
        wgId: 'wg-1',
        name: 'Äpfel',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final item3 = ShoppingItem(
        id: '3',
        wgId: 'wg-1',
        name: 'Brot',
        status: ShoppingItemStatus.bought,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final item4 = ShoppingItem(
        id: '4',
        wgId: 'wg-1',
        name: 'Milch',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );

      final list = [item1, item3, item2, item4];
      list.sort(ShoppingItem.compareByStatusAndName);

      expect(list.map((it) => it.name).toList(), [
        'Äpfel',
        'Milch',
        'Zucker',
        'Brot',
      ]);
    });

    test(
        'copyWith updates specified fields and supports clearing optional fields',
        () {
      final original = ShoppingItem(
        id: '1',
        wgId: 'wg-1',
        name: 'Milch',
        description: 'Bio',
        quantity: 2,
        category: ShoppingItemCategory.lebensmittel,
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13, 10, 0),
        updatedAt: DateTime(2026, 9, 13, 10, 0),
      );

      final updated = original.copyWith(
        name: 'Hafermilch',
        clearDescription: true,
        clearQuantity: true,
        clearCategory: true,
        status: ShoppingItemStatus.bought,
      );

      expect(updated.name, 'Hafermilch');
      expect(updated.description, isNull);
      expect(updated.quantity, isNull);
      expect(updated.category, isNull);
      expect(updated.status, ShoppingItemStatus.bought);
      expect(updated.id, original.id);
      expect(updated.wgId, original.wgId);
      expect(updated.createdBy, original.createdBy);
    });

    test('toMap and fromMap are symmetric', () {
      final now = DateTime(2026, 9, 13, 12, 0);
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Seife',
        description: 'Flüssigseife',
        quantity: 3,
        category: ShoppingItemCategory.hygiene,
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: now,
        updatedAt: now,
      );

      final map = item.toMap();
      final reconstructed = ShoppingItem.fromMap('item-1', map);

      expect(reconstructed.id, item.id);
      expect(reconstructed.wgId, item.wgId);
      expect(reconstructed.name, item.name);
      expect(reconstructed.description, item.description);
      expect(reconstructed.quantity, item.quantity);
      expect(reconstructed.category, item.category);
      expect(reconstructed.status, item.status);
      expect(reconstructed.createdBy, item.createdBy);
    });

    test(
        'fromMap tolerates unresolved (null) pending server timestamps '
        'without throwing', () {
      // Simuliert einen lokalen Pending-Snapshot direkt nach addItem/updateItem,
      // bei dem FieldValue.serverTimestamp() noch nicht aufgelöst ist.
      final pendingData = <String, dynamic>{
        'wgId': 'wg-1',
        'name': 'Milch',
        'description': null,
        'quantity': null,
        'category': null,
        'status': 'open',
        'createdBy': 'user-1',
        'createdAt': null,
        'updatedAt': null,
      };

      final item = ShoppingItem.fromMap('item-1', pendingData);

      expect(item.createdAt, isNull);
      expect(item.updatedAt, isNull);
      expect(item.hasUnresolvedServerTimestamp, isTrue);
      expect(item.name, 'Milch');
    });
  });

  group('UC-06: ShoppingListService.addItem', () {
    test('adds an item with open status and stores provided fields', () async {
      final service = FakeShoppingListService();

      final item = await service.addItem(
        wgId: 'wg-1',
        userId: 'user-1',
        name: 'Kaffee',
        description: 'Bohnen',
        quantity: 1,
        category: ShoppingItemCategory.lebensmittel,
      );

      expect(service.addItemCalls, 1);
      expect(service.lastAddedWgId, 'wg-1');
      expect(service.lastAddedUserId, 'user-1');
      expect(service.lastAddedName, 'Kaffee');
      expect(service.lastAddedDescription, 'Bohnen');
      expect(service.lastAddedQuantity, 1);
      expect(service.lastAddedCategory, ShoppingItemCategory.lebensmittel);
      expect(item.status, ShoppingItemStatus.open);
    });

    test('propagates persistence errors', () async {
      final service = FakeShoppingListService(
        addItemError: StateError('Firestore connection failed'),
      );

      expect(
        () => service.addItem(
          wgId: 'wg-1',
          userId: 'user-1',
          name: 'Kaffee',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('UC-07: ShoppingListService.updateItem', () {
    test('updates item fields and updates timestamp', () async {
      final initialItem = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Tee',
        description: 'Schwarztee',
        quantity: 1,
        category: ShoppingItemCategory.lebensmittel,
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13, 10, 0),
        updatedAt: DateTime(2026, 9, 13, 10, 0),
      );

      final service = FakeShoppingListService(initialItems: [initialItem]);

      final updated = await service.updateItem(
        wgId: 'wg-1',
        itemId: 'item-1',
        name: 'Grüner Tee',
        description: 'Bio',
        quantity: 2,
        category: ShoppingItemCategory.lebensmittel,
        expectedUpdatedAt: initialItem.updatedAt!,
      );

      expect(service.updateItemCalls, 1);
      expect(updated.name, 'Grüner Tee');
      expect(updated.description, 'Bio');
      expect(updated.quantity, 2);
    });

    test('throws ShoppingItemConflictException on concurrent update', () async {
      final initialItem = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Tee',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13, 10, 0),
        updatedAt: DateTime(2026, 9, 13, 10, 0),
      );

      final service = FakeShoppingListService(
        initialItems: [initialItem],
        simulateConflictOnUpdate: true,
      );

      expect(
        () => service.updateItem(
          wgId: 'wg-1',
          itemId: 'item-1',
          name: 'Neuer Tee',
          expectedUpdatedAt: initialItem.updatedAt!,
        ),
        throwsA(isA<ShoppingItemConflictException>()),
      );
    });

    test(
        'throws ShoppingItemConflictException instead of allowing an unsafe '
        'update while the server updatedAt is still unresolved (pending)',
        () async {
      final pendingItem = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Tee',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        // createdAt/updatedAt unresolved, wie in einem lokalen Pending-Snapshot
        // unmittelbar nach addItem, bevor FieldValue.serverTimestamp() ankommt.
      );

      final service = FakeShoppingListService(initialItems: [pendingItem]);

      expect(
        () => service.updateItem(
          wgId: 'wg-1',
          itemId: 'item-1',
          name: 'Neuer Tee',
          expectedUpdatedAt: DateTime(2026, 9, 13, 10, 0),
        ),
        throwsA(isA<ShoppingItemConflictException>()),
      );
    });

    test('performs no write when a stale expectedUpdatedAt is rejected as a '
        'conflict', () async {
      final initialItem = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Tee',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13, 10, 0),
        updatedAt: DateTime(2026, 9, 13, 10, 0),
      );

      final service = FakeShoppingListService(
        initialItems: [initialItem],
        simulateConflictOnUpdate: true,
      );

      await expectLater(
        () => service.updateItem(
          wgId: 'wg-1',
          itemId: 'item-1',
          name: 'Neuer Tee',
          expectedUpdatedAt: initialItem.updatedAt!,
        ),
        throwsA(isA<ShoppingItemConflictException>()),
      );

      final stored = await service.getItem(wgId: 'wg-1', itemId: 'item-1');
      expect(stored.name, 'Tee');
    });

    test('throws ShoppingItemNotFoundException when updating deleted item',
        () async {
      final service = FakeShoppingListService();

      expect(
        () => service.updateItem(
          wgId: 'wg-1',
          itemId: 'non-existent',
          name: 'Test',
          expectedUpdatedAt: DateTime(2026, 9, 13),
        ),
        throwsA(isA<ShoppingItemNotFoundException>()),
      );
    });
  });

  group('UC-08: ShoppingListService.deleteItem', () {
    test('removes item from repository', () async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Brot',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final service = FakeShoppingListService(initialItems: [item]);

      await service.deleteItem(wgId: 'wg-1', itemId: 'item-1');

      expect(service.deleteItemCalls, 1);
      expect(service.lastDeletedItemId, 'item-1');

      final remaining = await service.getShoppingItems(wgId: 'wg-1');
      expect(remaining, isEmpty);
    });

    test('throws ShoppingItemNotFoundException if item already deleted',
        () async {
      final service = FakeShoppingListService();

      expect(
        () => service.deleteItem(wgId: 'wg-1', itemId: 'item-99'),
        throwsA(isA<ShoppingItemNotFoundException>()),
      );
    });
  });

  group('UC-09: ShoppingListService.markAsBought', () {
    test('changes status from open to bought', () async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Butter',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final service = FakeShoppingListService(initialItems: [item]);

      final bought = await service.markAsBought(wgId: 'wg-1', itemId: 'item-1');

      expect(bought.status, ShoppingItemStatus.bought);
      expect(service.markAsBoughtCalls, 1);
    });

    test(
        'throws ShoppingItemConflictException if item was concurrently modified before marking as bought',
        () async {
      final initialItem = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Butter',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13, 10, 0),
        updatedAt: DateTime(2026, 9, 13, 10, 0),
      );
      final service = FakeShoppingListService(
        initialItems: [initialItem],
        simulateConflictOnMarkAsBought: true,
      );

      expect(
        () => service.markAsBought(
          wgId: 'wg-1',
          itemId: 'item-1',
          expectedUpdatedAt: initialItem.updatedAt,
        ),
        throwsA(isA<ShoppingItemConflictException>()),
      );
    });

    test('throws ShoppingItemAlreadyBoughtException if item is already bought',
        () async {
      final item = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Butter',
        status: ShoppingItemStatus.bought,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
      final service = FakeShoppingListService(initialItems: [item]);

      expect(
        () => service.markAsBought(wgId: 'wg-1', itemId: 'item-1'),
        throwsA(isA<ShoppingItemAlreadyBoughtException>()),
      );
    });

    test('performs no write when a stale expectedUpdatedAt is rejected as a '
        'conflict before marking as bought', () async {
      final initialItem = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Butter',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        createdAt: DateTime(2026, 9, 13, 10, 0),
        updatedAt: DateTime(2026, 9, 13, 10, 0),
      );
      final service = FakeShoppingListService(
        initialItems: [initialItem],
        simulateConflictOnMarkAsBought: true,
      );

      await expectLater(
        () => service.markAsBought(
          wgId: 'wg-1',
          itemId: 'item-1',
          expectedUpdatedAt: initialItem.updatedAt,
        ),
        throwsA(isA<ShoppingItemConflictException>()),
      );

      final stored = await service.getItem(wgId: 'wg-1', itemId: 'item-1');
      expect(stored.status, ShoppingItemStatus.open);
    });

    test('throws ShoppingItemNotFoundException if item does not exist',
        () async {
      final service = FakeShoppingListService();

      expect(
        () => service.markAsBought(wgId: 'wg-1', itemId: 'item-unknown'),
        throwsA(isA<ShoppingItemNotFoundException>()),
      );
    });

    test(
        'throws ShoppingItemConflictException instead of allowing an unsafe '
        'status change while the server updatedAt is still unresolved '
        '(pending)', () async {
      final pendingItem = ShoppingItem(
        id: 'item-1',
        wgId: 'wg-1',
        name: 'Butter',
        status: ShoppingItemStatus.open,
        createdBy: 'user-1',
        // createdAt/updatedAt unresolved, wie in einem lokalen Pending-Snapshot
        // unmittelbar nach addItem, bevor FieldValue.serverTimestamp() ankommt.
      );

      final service = FakeShoppingListService(initialItems: [pendingItem]);

      expect(
        () => service.markAsBought(
          wgId: 'wg-1',
          itemId: 'item-1',
          expectedUpdatedAt: DateTime(2026, 9, 13, 10, 0),
        ),
        throwsA(isA<ShoppingItemConflictException>()),
      );
    });
  });

  group('ShoppingListService input validations', () {
    final service = ShoppingListService();

    test('addItem validates required name and IDs', () {
      expect(
        () => service.addItem(
          wgId: '',
          userId: 'user-1',
          name: 'Milch',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.addItem(
          wgId: 'wg-1',
          userId: '',
          name: 'Milch',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.addItem(
          wgId: 'wg-1',
          userId: 'user-1',
          name: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.addItem(
          wgId: 'wg-1',
          userId: 'user-1',
          name: 'Milch',
          quantity: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.addItem(
          wgId: 'wg-1',
          userId: 'user-1',
          name: 'Milch',
          description: 'a' * 501,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateItem validates input parameters', () {
      expect(
        () => service.updateItem(
          wgId: '',
          itemId: 'item-1',
          name: 'Milch',
          expectedUpdatedAt: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.updateItem(
          wgId: 'wg-1',
          itemId: '',
          name: 'Milch',
          expectedUpdatedAt: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.updateItem(
          wgId: 'wg-1',
          itemId: 'item-1',
          name: '',
          expectedUpdatedAt: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deleteItem and markAsBought validate IDs', () {
      expect(
        () => service.deleteItem(wgId: '', itemId: 'item-1'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.deleteItem(wgId: 'wg-1', itemId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.markAsBought(wgId: '', itemId: 'item-1'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => service.markAsBought(wgId: 'wg-1', itemId: ''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('UC-10: ShoppingListService.watchShoppingList & metadata', () {
    test('emits ShoppingListState with cache and pending write flags',
        () async {
      final item = ShoppingItem(
        id: '1',
        wgId: 'wg-1',
        name: 'Mehl',
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

      final state = await service.watchShoppingList(wgId: 'wg-1').first;

      expect(state.items.length, 1);
      expect(state.items.first.name, 'Mehl');
      expect(state.isFromCache, isTrue);
      expect(state.hasPendingWrites, isTrue);
    });
  });
}
