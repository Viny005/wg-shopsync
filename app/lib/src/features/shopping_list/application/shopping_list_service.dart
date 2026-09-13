import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/validation/validators.dart';
import '../../../domain/models/shopping_item.dart';

class ShoppingItemNotFoundException implements Exception {
  const ShoppingItemNotFoundException();
}

class ShoppingItemConflictException implements Exception {
  const ShoppingItemConflictException({required this.serverItem});

  final ShoppingItem serverItem;
}

class ShoppingItemAlreadyBoughtException implements Exception {
  const ShoppingItemAlreadyBoughtException();
}

class ShoppingListState {
  const ShoppingListState({
    required this.items,
    this.isFromCache = false,
    this.hasPendingWrites = false,
  });

  final List<ShoppingItem> items;
  final bool isFromCache;
  final bool hasPendingWrites;
}

class ShoppingListService {
  ShoppingListService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Stream<ShoppingListState> watchShoppingList({
    required String wgId,
  }) {
    final trimmedWgId = wgId.trim();
    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }

    return firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('shoppingItems')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => ShoppingItem.fromMap(doc.id, doc.data()))
          .toList();
      items.sort(ShoppingItem.compareByStatusAndName);
      return ShoppingListState(
        items: items,
        isFromCache: snapshot.metadata.isFromCache,
        hasPendingWrites: snapshot.metadata.hasPendingWrites,
      );
    });
  }

  Stream<List<ShoppingItem>> watchShoppingItems({
    required String wgId,
  }) {
    return watchShoppingList(wgId: wgId).map((state) => state.items);
  }

  Future<List<ShoppingItem>> getShoppingItems({
    required String wgId,
  }) async {
    final trimmedWgId = wgId.trim();
    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }

    final snapshot = await firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('shoppingItems')
        .get();

    final items = snapshot.docs
        .map((doc) => ShoppingItem.fromMap(doc.id, doc.data()))
        .toList();
    items.sort(ShoppingItem.compareByStatusAndName);
    return items;
  }

  Future<ShoppingItem> getItem({
    required String wgId,
    required String itemId,
  }) async {
    final trimmedWgId = wgId.trim();
    final trimmedItemId = itemId.trim();

    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }
    if (trimmedItemId.isEmpty) {
      throw ArgumentError('Die Artikel-ID darf nicht leer sein.');
    }

    final snapshot = await firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('shoppingItems')
        .doc(trimmedItemId)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw const ShoppingItemNotFoundException();
    }

    return ShoppingItem.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<ShoppingItem> addItem({
    required String wgId,
    required String userId,
    required String name,
    String? description,
    int? quantity,
    ShoppingItemCategory? category,
  }) async {
    final trimmedName = name.trim();
    final trimmedDescription = description?.trim();
    final trimmedWgId = wgId.trim();
    final trimmedUserId = userId.trim();

    final nameError = Validators.itemName(trimmedName);
    if (nameError != null) {
      throw ArgumentError(nameError);
    }
    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }
    if (trimmedUserId.isEmpty) {
      throw ArgumentError('Die Benutzer-ID darf nicht leer sein.');
    }
    if (trimmedDescription != null && trimmedDescription.isNotEmpty) {
      final descError = Validators.itemDescription(trimmedDescription);
      if (descError != null) {
        throw ArgumentError(descError);
      }
    }
    if (quantity != null) {
      final quantityError = Validators.quantity(quantity);
      if (quantityError != null) {
        throw ArgumentError(quantityError);
      }
    }

    final now = DateTime.now();
    final docRef = firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('shoppingItems')
        .doc();

    final item = ShoppingItem(
      id: docRef.id,
      wgId: trimmedWgId,
      name: trimmedName,
      description: (trimmedDescription != null && trimmedDescription.isNotEmpty)
          ? trimmedDescription
          : null,
      quantity: quantity,
      category: category,
      status: ShoppingItemStatus.open,
      createdBy: trimmedUserId,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set({
      'wgId': trimmedWgId,
      'name': trimmedName,
      'description':
          (trimmedDescription != null && trimmedDescription.isNotEmpty)
              ? trimmedDescription
              : null,
      'quantity': quantity,
      'category': category?.name,
      'status': ShoppingItemStatus.open.name,
      'createdBy': trimmedUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return item;
  }

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
    final trimmedName = name.trim();
    final trimmedDescription = description?.trim();
    final trimmedWgId = wgId.trim();
    final trimmedItemId = itemId.trim();

    final nameError = Validators.itemName(trimmedName);
    if (nameError != null) {
      throw ArgumentError(nameError);
    }
    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }
    if (trimmedItemId.isEmpty) {
      throw ArgumentError('Die Artikel-ID darf nicht leer sein.');
    }
    if (trimmedDescription != null && trimmedDescription.isNotEmpty) {
      final descError = Validators.itemDescription(trimmedDescription);
      if (descError != null) {
        throw ArgumentError(descError);
      }
    }
    if (quantity != null) {
      final quantityError = Validators.quantity(quantity);
      if (quantityError != null) {
        throw ArgumentError(quantityError);
      }
    }

    final itemRef = firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('shoppingItems')
        .doc(trimmedItemId);

    final snapshot = await itemRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw const ShoppingItemNotFoundException();
    }

    final serverData = snapshot.data()!;
    final serverItem = ShoppingItem.fromMap(snapshot.id, serverData);

    // Ein noch nicht aufgelöster Server-Zeitstempel gilt als Konflikt, damit
    // keine ungeschützte Aktualisierung auf Basis eines vorläufigen Stands erfolgt.
    final serverUpdatedAt = serverItem.updatedAt;
    if (serverUpdatedAt == null ||
        serverUpdatedAt.millisecondsSinceEpoch !=
            expectedUpdatedAt.millisecondsSinceEpoch) {
      throw ShoppingItemConflictException(serverItem: serverItem);
    }

    final now = DateTime.now();
    final updatedItem = serverItem.copyWith(
      name: trimmedName,
      description: (trimmedDescription != null && trimmedDescription.isNotEmpty)
          ? trimmedDescription
          : null,
      clearDescription:
          trimmedDescription == null || trimmedDescription.isEmpty,
      quantity: quantity,
      clearQuantity: quantity == null,
      category: category,
      clearCategory: clearCategory || category == null,
      updatedAt: now,
    );

    await itemRef.update({
      'name': updatedItem.name,
      'description': updatedItem.description,
      'quantity': updatedItem.quantity,
      'category': updatedItem.category?.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return updatedItem;
  }

  Future<void> deleteItem({
    required String wgId,
    required String itemId,
  }) async {
    final trimmedWgId = wgId.trim();
    final trimmedItemId = itemId.trim();

    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }
    if (trimmedItemId.isEmpty) {
      throw ArgumentError('Die Artikel-ID darf nicht leer sein.');
    }

    final itemRef = firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('shoppingItems')
        .doc(trimmedItemId);

    final snapshot = await itemRef.get();
    if (!snapshot.exists) {
      throw const ShoppingItemNotFoundException();
    }

    await itemRef.delete();
  }

  Future<ShoppingItem> markAsBought({
    required String wgId,
    required String itemId,
    DateTime? expectedUpdatedAt,
  }) async {
    final trimmedWgId = wgId.trim();
    final trimmedItemId = itemId.trim();

    if (trimmedWgId.isEmpty) {
      throw ArgumentError('Die WG-ID darf nicht leer sein.');
    }
    if (trimmedItemId.isEmpty) {
      throw ArgumentError('Die Artikel-ID darf nicht leer sein.');
    }

    final itemRef = firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('shoppingItems')
        .doc(trimmedItemId);

    final snapshot = await itemRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw const ShoppingItemNotFoundException();
    }

    final serverData = snapshot.data()!;
    final currentItem = ShoppingItem.fromMap(snapshot.id, serverData);

    if (currentItem.status == ShoppingItemStatus.bought) {
      throw const ShoppingItemAlreadyBoughtException();
    }

    // Ein noch nicht aufgelöster Server-Zeitstempel gilt als Konflikt, damit
    // keine ungeschützte Statusänderung auf Basis eines vorläufigen Stands erfolgt.
    final currentUpdatedAt = currentItem.updatedAt;
    if (expectedUpdatedAt != null &&
        (currentUpdatedAt == null ||
            currentUpdatedAt.millisecondsSinceEpoch !=
                expectedUpdatedAt.millisecondsSinceEpoch)) {
      throw ShoppingItemConflictException(serverItem: currentItem);
    }

    final now = DateTime.now();
    final updatedItem = currentItem.copyWith(
      status: ShoppingItemStatus.bought,
      updatedAt: now,
    );

    await itemRef.update({
      'status': ShoppingItemStatus.bought.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return updatedItem;
  }
}
