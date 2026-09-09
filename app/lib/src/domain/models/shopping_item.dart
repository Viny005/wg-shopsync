/// Warengruppe eines Einkaufslistenartikels (siehe D2.8 Kategorie).
enum ShoppingItemCategory {
  lebensmittel,
  haushalt,
  hygiene,
  sonstiges;

  static ShoppingItemCategory fromValue(String value) {
    return ShoppingItemCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => throw ArgumentError('Unbekannte ShoppingItemCategory: $value'),
    );
  }
}

/// Bearbeitungsstatus eines Einkaufslistenartikels (siehe D2.8 Artikelstatus).
enum ShoppingItemStatus {
  open,
  bought;

  static ShoppingItemStatus fromValue(String value) {
    return ShoppingItemStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw ArgumentError('Unbekannte ShoppingItemStatus: $value'),
    );
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
    required this.createdAt,
    required this.updatedAt,
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
  final DateTime createdAt;
  final DateTime updatedAt;

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
      createdAt: data['createdAt'] as DateTime,
      updatedAt: data['updatedAt'] as DateTime,
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
}
