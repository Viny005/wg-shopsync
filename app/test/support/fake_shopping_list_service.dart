import 'dart:async';

import 'package:wg_shopsync/src/domain/models/shopping_item.dart';
import 'package:wg_shopsync/src/features/shopping_list/application/shopping_list_service.dart';

class FakeShoppingListService extends ShoppingListService {
  FakeShoppingListService({
    List<ShoppingItem>? initialItems,
    this.streamError,
    this.addItemError,
    this.updateItemError,
    this.deleteItemError,
    this.markAsBoughtError,
    this.simulateConflictOnUpdate = false,
    this.simulateConflictOnMarkAsBought = false,
    this.isFromCache = false,
    this.hasPendingWrites = false,
  }) : _items = initialItems != null ? List.of(initialItems) : [] {
    _emitState();
  }

  final List<ShoppingItem> _items;
  final StreamController<ShoppingListState> _stateController =
      StreamController<ShoppingListState>.broadcast();

  Object? streamError;
  Object? addItemError;
  Object? updateItemError;
  Object? deleteItemError;
  Object? markAsBoughtError;
  bool simulateConflictOnUpdate;
  bool simulateConflictOnMarkAsBought;
  bool isFromCache;
  bool hasPendingWrites;

  int watchShoppingListCalls = 0;
  int watchShoppingItemsCalls = 0;
  int getShoppingItemsCalls = 0;
  int getItemCalls = 0;
  int addItemCalls = 0;
  int updateItemCalls = 0;
  int deleteItemCalls = 0;
  int markAsBoughtCalls = 0;

  String? lastAddedName;
  String? lastAddedDescription;
  int? lastAddedQuantity;
  ShoppingItemCategory? lastAddedCategory;
  String? lastAddedWgId;
  String? lastAddedUserId;

  String? lastUpdatedItemId;
  String? lastUpdatedName;
  String? lastUpdatedDescription;
  int? lastUpdatedQuantity;
  ShoppingItemCategory? lastUpdatedCategory;

  String? lastDeletedItemId;
  String? lastBoughtItemId;

  void _emitState() {
    if (_stateController.isClosed) return;
    if (streamError != null) {
      _stateController.addError(streamError!);
    } else {
      final sorted = List<ShoppingItem>.from(_items);
      sorted.sort(ShoppingItem.compareByStatusAndName);
      _stateController.add(
        ShoppingListState(
          items: sorted,
          isFromCache: isFromCache,
          hasPendingWrites: hasPendingWrites,
        ),
      );
    }
  }

  void setItems(List<ShoppingItem> newItems) {
    _items.clear();
    _items.addAll(newItems);
    _emitState();
  }

  void setOfflineState(
      {required bool isFromCache, required bool hasPendingWrites}) {
    this.isFromCache = isFromCache;
    this.hasPendingWrites = hasPendingWrites;
    _emitState();
  }

  void emitError(Object error) {
    streamError = error;
    _emitState();
  }

  @override
  Stream<ShoppingListState> watchShoppingList({required String wgId}) async* {
    watchShoppingListCalls++;
    if (streamError != null) {
      throw streamError!;
    }
    final sorted = List<ShoppingItem>.from(_items);
    sorted.sort(ShoppingItem.compareByStatusAndName);
    yield ShoppingListState(
      items: sorted,
      isFromCache: isFromCache,
      hasPendingWrites: hasPendingWrites,
    );
    yield* _stateController.stream;
  }

  @override
  Stream<List<ShoppingItem>> watchShoppingItems({required String wgId}) {
    watchShoppingItemsCalls++;
    return watchShoppingList(wgId: wgId).map((state) => state.items);
  }

  @override
  Future<List<ShoppingItem>> getShoppingItems({required String wgId}) async {
    getShoppingItemsCalls++;
    if (streamError != null) throw streamError!;
    final sorted = List<ShoppingItem>.from(_items);
    sorted.sort(ShoppingItem.compareByStatusAndName);
    return sorted;
  }

  @override
  Future<ShoppingItem> getItem({
    required String wgId,
    required String itemId,
  }) async {
    getItemCalls++;
    final index = _items.indexWhere((it) => it.id == itemId);
    if (index == -1) {
      throw const ShoppingItemNotFoundException();
    }
    return _items[index];
  }

  @override
  Future<ShoppingItem> addItem({
    required String wgId,
    required String userId,
    required String name,
    String? description,
    int? quantity,
    ShoppingItemCategory? category,
  }) async {
    addItemCalls++;
    lastAddedWgId = wgId;
    lastAddedUserId = userId;
    lastAddedName = name;
    lastAddedDescription = description;
    lastAddedQuantity = quantity;
    lastAddedCategory = category;

    if (addItemError != null) {
      throw addItemError!;
    }

    final now = DateTime.now();
    final item = ShoppingItem(
      id: 'item-${_items.length + 1}-${DateTime.now().microsecondsSinceEpoch}',
      wgId: wgId,
      name: name.trim(),
      description:
          description?.trim().isEmpty == true ? null : description?.trim(),
      quantity: quantity,
      category: category,
      status: ShoppingItemStatus.open,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    );

    _items.add(item);
    _emitState();
    return item;
  }

  @override
  Future<ShoppingItem> updateItem({
    required String wgId,
    required String itemId,
    required String name,
    String? description,
    int? quantity,
    ShoppingItemCategory? category,
    bool clearCategory = false,
    required DateTime expectedUpdatedAt,
  }) async {
    updateItemCalls++;
    lastUpdatedItemId = itemId;
    lastUpdatedName = name;
    lastUpdatedDescription = description;
    lastUpdatedQuantity = quantity;
    lastUpdatedCategory = category;

    if (updateItemError != null) {
      throw updateItemError!;
    }

    final index = _items.indexWhere((it) => it.id == itemId);
    if (index == -1) {
      throw const ShoppingItemNotFoundException();
    }

    final existing = _items[index];

    if (simulateConflictOnUpdate) {
      final conflictServerItem = existing.copyWith(
        name: '${existing.name} (server-side change)',
        updatedAt: DateTime.now().add(const Duration(seconds: 10)),
      );
      throw ShoppingItemConflictException(serverItem: conflictServerItem);
    }

    if (existing.updatedAt.millisecondsSinceEpoch !=
        expectedUpdatedAt.millisecondsSinceEpoch) {
      throw ShoppingItemConflictException(serverItem: existing);
    }

    final now = DateTime.now();
    final updated = existing.copyWith(
      name: name.trim(),
      description:
          description?.trim().isEmpty == true ? null : description?.trim(),
      clearDescription: description == null || description.trim().isEmpty,
      quantity: quantity,
      clearQuantity: quantity == null,
      category: category,
      clearCategory: clearCategory || category == null,
      updatedAt: now,
    );

    _items[index] = updated;
    _emitState();
    return updated;
  }

  @override
  Future<void> deleteItem({
    required String wgId,
    required String itemId,
  }) async {
    deleteItemCalls++;
    lastDeletedItemId = itemId;

    if (deleteItemError != null) {
      throw deleteItemError!;
    }

    final index = _items.indexWhere((it) => it.id == itemId);
    if (index == -1) {
      throw const ShoppingItemNotFoundException();
    }

    _items.removeAt(index);
    _emitState();
  }

  @override
  Future<ShoppingItem> markAsBought({
    required String wgId,
    required String itemId,
    DateTime? expectedUpdatedAt,
  }) async {
    markAsBoughtCalls++;
    lastBoughtItemId = itemId;

    if (markAsBoughtError != null) {
      throw markAsBoughtError!;
    }

    final index = _items.indexWhere((it) => it.id == itemId);
    if (index == -1) {
      throw const ShoppingItemNotFoundException();
    }

    final existing = _items[index];
    if (existing.status == ShoppingItemStatus.bought) {
      throw const ShoppingItemAlreadyBoughtException();
    }

    if (simulateConflictOnMarkAsBought) {
      final conflictServerItem = existing.copyWith(
        name: '${existing.name} (server-side change)',
        updatedAt: DateTime.now().add(const Duration(seconds: 10)),
      );
      throw ShoppingItemConflictException(serverItem: conflictServerItem);
    }

    if (expectedUpdatedAt != null &&
        existing.updatedAt.millisecondsSinceEpoch !=
            expectedUpdatedAt.millisecondsSinceEpoch) {
      throw ShoppingItemConflictException(serverItem: existing);
    }

    final now = DateTime.now();
    final updated = existing.copyWith(
      status: ShoppingItemStatus.bought,
      updatedAt: now,
    );

    _items[index] = updated;
    _emitState();
    return updated;
  }

  Future<void> dispose() async {
    await _stateController.close();
  }
}
