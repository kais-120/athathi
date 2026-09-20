import 'model_utils.dart';

/// One line of a purchase (furniture bought from a supplier).
class PurchaseItem {
  const PurchaseItem({
    required this.name,
    required this.quantity,
    required this.unitCost,
    this.productId,
  });

  final String name;
  final int quantity;
  final double unitCost;
  final String? productId;

  double get lineTotal => unitCost * quantity;

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'unitCost': unitCost,
        'productId': productId,
      };

  factory PurchaseItem.fromMap(Map<String, dynamic> map) => PurchaseItem(
        name: map['name'] as String? ?? '',
        quantity: asInt(map['quantity']),
        unitCost: asDouble(map['unitCost']),
        productId: map['productId'] as String?,
      );
}

class Purchase {
  const Purchase({
    required this.id,
    this.supplierId,
    this.supplierName,
    this.items = const [],
    required this.total,
    required this.paid,
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  final String? supplierId;
  final String? supplierName;
  final List<PurchaseItem> items;
  final double total;
  final double paid;
  final String notes;
  final DateTime createdAt;

  double get remaining => (total - paid) < 0 ? 0 : total - paid;

  /// Total number of pieces bought.
  int get pieces => items.fold(0, (sum, i) => sum + i.quantity);

  String get displaySupplier => supplierName ?? 'مورد غير محدد';

  Map<String, dynamic> toMap() => {
        'id': id,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'items': items.map((i) => i.toMap()).toList(),
        'total': total,
        'paid': paid,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Purchase.fromMap(Map<String, dynamic> map) => Purchase(
        id: map['id'] as String,
        supplierId: map['supplierId'] as String?,
        supplierName: map['supplierName'] as String?,
        items: asMapList(map['items']).map(PurchaseItem.fromMap).toList(),
        total: asDouble(map['total']),
        paid: asDouble(map['paid']),
        notes: map['notes'] as String? ?? '',
        createdAt: asDate(map['createdAt']),
      );
}
