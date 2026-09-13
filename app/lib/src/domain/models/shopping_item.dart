import '../../core/utils/firestore_converters.dart';

/// Warengruppe eines Einkaufslistenartikels (siehe D2.8 Kategorie).
enum ShoppingItemCategory {
  lebensmittel,
  haushalt,
  hygiene,
  sonstiges;

  static ShoppingItemCategory fromValue(String value) {
    return ShoppingItemCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () =>
          throw ArgumentError('Unbekannte ShoppingItemCategory: $value'),
    );
  }
}

extension ShoppingItemCategoryExtension on ShoppingItemCategory {
  String get displayName {
    switch (this) {
      case ShoppingItemCategory.lebensmittel:
        return 'Lebensmittel';
      case ShoppingItemCategory.haushalt:
        return 'Haushalt';
      case ShoppingItemCategory.hygiene:
        return 'Hygiene';
      case ShoppingItemCategory.sonstiges:
        return 'Sonstiges';
    }
  }
}

/// Bearbeitungsstatus eines Einkaufslistenartikels (siehe D2.8 Artikelstatus).
enum ShoppingItemStatus {
  open,
  bought;

  static ShoppingItemStatus fromValue(String value) {
    return ShoppingItemStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () =>
          throw ArgumentError('Unbekannte ShoppingItemStatus: $value'),
    );
  }
}

extension ShoppingItemStatusExtension on ShoppingItemStatus {
  String get displayName {
    switch (this) {
      case ShoppingItemStatus.open:
        return 'Offen';
      case ShoppingItemStatus.bought:
        return 'Gekauft';
    }
  }
}

/// Ein Artikel auf der gemeinsamen Einkaufsliste (siehe D1.5 / D2.4).
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.wgId,
    required this.name,
    this.description,
    this.quantity,
    this.category,
    required this.status,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String wgId;
  final String name;
  final String? description;

  /// Positive Ganzzahl, mindestens 1, sofern angegeben.
  final int? quantity;
  final ShoppingItemCategory? category;
  final ShoppingItemStatus status;
  final String createdBy;

  /// `null` solange der servergenerierte Zeitstempel (FieldValue.serverTimestamp)
  /// im lokalen Pending-Snapshot noch nicht aufgelöst ist (siehe AF-06/AF-07).
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Wahr, solange die serverseitigen Zeitstempel noch nicht bestätigt sind.
  bool get hasUnresolvedServerTimestamp => createdAt == null || updatedAt == null;

  factory ShoppingItem.fromMap(String id, Map<String, dynamic> data) {
    return ShoppingItem(
      id: id,
      wgId: data['wgId'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      quantity: data['quantity'] as int?,
      category: data['category'] == null
          ? null
          : ShoppingItemCategory.fromValue(data['category'] as String),
      status: ShoppingItemStatus.fromValue(data['status'] as String),
      createdBy: data['createdBy'] as String,
      createdAt: dateTimeFromFirestoreOrNull(data['createdAt']),
      updatedAt: dateTimeFromFirestoreOrNull(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wgId': wgId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'category': category?.name,
      'status': status.name,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? wgId,
    String? name,
    String? description,
    bool clearDescription = false,
    int? quantity,
    bool clearQuantity = false,
    ShoppingItemCategory? category,
    bool clearCategory = false,
    ShoppingItemStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      wgId: wgId ?? this.wgId,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      category: clearCategory ? null : (category ?? this.category),
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Vergleicht zwei Artikel gemäß AF-04:
  /// Offene Artikel vor gekauften Artikeln, innerhalb der Gruppen alphabetisch.
  static int compareByStatusAndName(ShoppingItem a, ShoppingItem b) {
    if (a.status != b.status) {
      return a.status == ShoppingItemStatus.open ? -1 : 1;
    }
    final normA = _normalizeForSorting(a.name);
    final normB = _normalizeForSorting(b.name);
    final comparison = normA.compareTo(normB);
    if (comparison != 0) {
      return comparison;
    }
    return a.name.compareTo(b.name);
  }

  static String _normalizeForSorting(String text) {
    return text
        .toLowerCase()
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ß', 'ss');
  }
}
