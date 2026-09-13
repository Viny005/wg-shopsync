import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/network/network_connectivity.dart';
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

/// Wird geworfen, wenn eine konkurrenzsichere Firestore-Transaktion (UC-07,
/// UC-09) mangels Netzwerkverbindung nicht ausgeführt werden konnte. Hält den
/// Firebase-spezifischen Fehlercode von der Präsentationsschicht fern.
class ShoppingItemRequiresConnectionException implements Exception {
  const ShoppingItemRequiresConnectionException();
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

/// Mögliche Ergebnisse eines konkurrenzsicheren Firestore-Transaktionsversuchs.
///
/// Firestore-Transaktions-Callbacks können auf Flutter Web mehrfach ausgeführt
/// werden und benutzerdefinierte Exceptions verlieren dabei ihren Typ, wenn sie
/// direkt aus dem Callback geworfen werden. Deshalb werden Geschäftsergebnisse
/// als Wert zurückgegeben und erst NACH `runTransaction` in die passende
/// Domain-Exception übersetzt.
enum _ItemTransactionOutcome { success, conflict, notFound, alreadyBought }

class _ItemTransactionResult {
  const _ItemTransactionResult.success(this.item)
      : kind = _ItemTransactionOutcome.success,
        serverItem = null;

  const _ItemTransactionResult.conflict(this.serverItem)
      : kind = _ItemTransactionOutcome.conflict,
        item = null;

  const _ItemTransactionResult.notFound()
      : kind = _ItemTransactionOutcome.notFound,
        item = null,
        serverItem = null;

  const _ItemTransactionResult.alreadyBought()
      : kind = _ItemTransactionOutcome.alreadyBought,
        item = null,
        serverItem = null;

  final _ItemTransactionOutcome kind;
  final ShoppingItem? item;
  final ShoppingItem? serverItem;
}

/// Startet einen Schreibvorgang, ohne auf dessen Abschluss zu warten.
///
/// Auf Flutter Web löst das Future eines Firestore-Schreibvorgangs bei
/// fehlender Verbindung dokumentiert erst nach Wiederherstellung der
/// Verbindung auf, statt wie bei den mobilen SDKs sofort nach dem lokalen
/// Zwischenspeichern. Ein synchrones Warten würde das UI unbegrenzt im
/// Ladezustand belassen, obwohl der Schreibvorgang bereits lokal in die
/// Firestore-Warteschlange aufgenommen wurde und über den bestehenden
/// Realtime-Listener (`hasPendingWrites`) sichtbar ist. Eine später
/// eintreffende serverseitige Ablehnung (z. B. durch die Security Rules)
/// wird nicht verschluckt, sondern über [onError] gemeldet.
///
/// Als eigenständige, Firestore-unabhängige Funktion gehalten, damit das
/// Nicht-Warten-Verhalten ohne Firestore-Testdouble unit-testbar bleibt.
void fireAndForgetShoppingWrite(
  Future<void> pendingWrite, {
  void Function(Object error, StackTrace stackTrace)? onError,
}) {
  unawaited(pendingWrite.catchError((Object error, StackTrace stackTrace) {
    onError?.call(error, stackTrace);
  }));
}

class ShoppingListService {
  ShoppingListService({
    FirebaseFirestore? firestore,
    void Function(Object error, StackTrace stackTrace)? onBackgroundWriteError,
    bool Function()? isOfflineChecker,
  })  : _firestore = firestore,
        _onBackgroundWriteError = onBackgroundWriteError,
        _isOfflineChecker = isOfflineChecker ?? isDeviceOffline;

  final FirebaseFirestore? _firestore;
  final void Function(Object error, StackTrace stackTrace)?
      _onBackgroundWriteError;
  final bool Function() _isOfflineChecker;

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

    // Nicht auf das Schreib-Future warten: Auf Flutter Web löst es bei
    // fehlender Verbindung erst nach Wiederherstellung der Verbindung auf
    // (siehe fireAndForgetShoppingWrite). Der Artikel ist bereits lokal in
    // der Firestore-Warteschlange und wird über den Realtime-Listener
    // (hasPendingWrites) sichtbar; eine spätere serverseitige Ablehnung
    // wird über den optionalen onBackgroundWriteError-Hook gemeldet.
    fireAndForgetShoppingWrite(
      docRef.set({
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
      }),
      onError: _onBackgroundWriteError,
    );
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

    // Auf Flutter Web führt ein Transaktionsversuch im Offline-Zustand zu
    // einem unvollständigen Future / NativeError, da navigator.onLine == false.
    // Ein gezielter Vorab-Check verhindert den Start der Transaktion.
    if (_isOfflineChecker()) {
      throw const ShoppingItemRequiresConnectionException();
    }

    final itemRef = firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('shoppingItems')
        .doc(trimmedItemId);

    // Lesen und Schreiben laufen atomar in einer Transaktion, damit zwischen
    // Prüfung und Schreiben keine unbemerkte Änderung eines anderen Mitglieds
    // einfließen kann (UC-07 A2: Server-Datenstand darf nie still überschrieben werden).
    // Das Ergebnis wird als Wert zurückgegeben statt geworfen, siehe
    // _ItemTransactionResult.
    final _ItemTransactionResult result;
    try {
      result = await firestore
          .runTransaction<_ItemTransactionResult>((transaction) async {
        final snapshot = await transaction.get(itemRef);
        if (!snapshot.exists || snapshot.data() == null) {
          return const _ItemTransactionResult.notFound();
        }

        final serverData = snapshot.data()!;
        final serverItem = ShoppingItem.fromMap(snapshot.id, serverData);

        // Ein noch nicht aufgelöster Server-Zeitstempel gilt als Konflikt, damit
        // keine ungeschützte Aktualisierung auf Basis eines vorläufigen Stands erfolgt.
        final serverUpdatedAt = serverItem.updatedAt;
        if (serverUpdatedAt == null ||
            serverUpdatedAt.millisecondsSinceEpoch !=
                expectedUpdatedAt.millisecondsSinceEpoch) {
          return _ItemTransactionResult.conflict(serverItem);
        }

        final now = DateTime.now();
        final updatedItem = serverItem.copyWith(
          name: trimmedName,
          description:
              (trimmedDescription != null && trimmedDescription.isNotEmpty)
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

        transaction.update(itemRef, {
          'name': updatedItem.name,
          'description': updatedItem.description,
          'quantity': updatedItem.quantity,
          'category': updatedItem.category?.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return _ItemTransactionResult.success(updatedItem);
      });
    } on FirebaseException catch (e) {
      // 'unavailable' bedeutet: Backend über das Netzwerk nicht erreichbar.
      // Andere Firestore-Fehler (z. B. permission-denied) unverändert weiterreichen.
      if (e.code == 'unavailable') {
        throw const ShoppingItemRequiresConnectionException();
      }
      rethrow;
    } on TimeoutException {
      // Auf Flutter Web können Firestore-Transaktionen im Offline-Zustand
      // mit TimeoutException abbrechen, da die Server-Antwort ausbleibt.
      throw const ShoppingItemRequiresConnectionException();
    }

    switch (result.kind) {
      case _ItemTransactionOutcome.notFound:
        throw const ShoppingItemNotFoundException();
      case _ItemTransactionOutcome.conflict:
        throw ShoppingItemConflictException(serverItem: result.serverItem!);
      case _ItemTransactionOutcome.alreadyBought:
        throw const ShoppingItemAlreadyBoughtException();
      case _ItemTransactionOutcome.success:
        return result.item!;
    }
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

    // Auf Flutter Web führt ein Transaktionsversuch im Offline-Zustand zu
    // einem unvollständigen Future / NativeError, da navigator.onLine == false.
    // Ein gezielter Vorab-Check verhindert den Start der Transaktion.
    if (_isOfflineChecker()) {
      throw const ShoppingItemRequiresConnectionException();
    }

    final itemRef = firestore
        .collection('wgs')
        .doc(trimmedWgId)
        .collection('shoppingItems')
        .doc(trimmedItemId);

    // Lesen und Schreiben laufen atomar in einer Transaktion, damit zwischen
    // Prüfung und Schreiben keine unbemerkte Änderung eines anderen Mitglieds
    // einfließen kann (UC-09 A2: bereits gekaufte/gelöschte/geänderte Artikel
    // dürfen nicht still überschrieben werden).
    // Das Ergebnis wird als Wert zurückgegeben statt geworfen, siehe
    // _ItemTransactionResult.
    final _ItemTransactionResult result;
    try {
      result = await firestore
          .runTransaction<_ItemTransactionResult>((transaction) async {
        final snapshot = await transaction.get(itemRef);
        if (!snapshot.exists || snapshot.data() == null) {
          return const _ItemTransactionResult.notFound();
        }

        final serverData = snapshot.data()!;
        final currentItem = ShoppingItem.fromMap(snapshot.id, serverData);

        if (currentItem.status == ShoppingItemStatus.bought) {
          return const _ItemTransactionResult.alreadyBought();
        }

        // Ein noch nicht aufgelöster Server-Zeitstempel gilt als Konflikt, damit
        // keine ungeschützte Statusänderung auf Basis eines vorläufigen Stands erfolgt.
        final currentUpdatedAt = currentItem.updatedAt;
        if (expectedUpdatedAt != null &&
            (currentUpdatedAt == null ||
                currentUpdatedAt.millisecondsSinceEpoch !=
                    expectedUpdatedAt.millisecondsSinceEpoch)) {
          return _ItemTransactionResult.conflict(currentItem);
        }

        final now = DateTime.now();
        final updatedItem = currentItem.copyWith(
          status: ShoppingItemStatus.bought,
          updatedAt: now,
        );

        transaction.update(itemRef, {
          'status': ShoppingItemStatus.bought.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return _ItemTransactionResult.success(updatedItem);
      });
    } on FirebaseException catch (e) {
      // 'unavailable' bedeutet: Backend über das Netzwerk nicht erreichbar.
      // Andere Firestore-Fehler (z. B. permission-denied) unverändert weiterreichen.
      if (e.code == 'unavailable') {
        throw const ShoppingItemRequiresConnectionException();
      }
      rethrow;
    } on TimeoutException {
      // Auf Flutter Web können Firestore-Transaktionen im Offline-Zustand
      // mit TimeoutException abbrechen, da die Server-Antwort ausbleibt.
      throw const ShoppingItemRequiresConnectionException();
    }

    switch (result.kind) {
      case _ItemTransactionOutcome.notFound:
        throw const ShoppingItemNotFoundException();
      case _ItemTransactionOutcome.alreadyBought:
        throw const ShoppingItemAlreadyBoughtException();
      case _ItemTransactionOutcome.conflict:
        throw ShoppingItemConflictException(serverItem: result.serverItem!);
      case _ItemTransactionOutcome.success:
        return result.item!;
    }
  }
}
