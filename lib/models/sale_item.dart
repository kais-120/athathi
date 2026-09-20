import 'model_utils.dart';

/// One line of a sale. Prices are snapshots taken at sale time.
class SaleItem {
  const SaleItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.unitCost = 0,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final double unitPrice;
  final double unitCost;
  final int quantity;

  double get lineTotal => unitPrice * quantity;
  double get lineProfit => (unitPrice - unitCost) * quantity;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'unitPrice': unitPrice,
        'unitCost': unitCost,
        'quantity': quantity,
      };

  factory SaleItem.fromMap(Map<String, dynamic> map) => SaleItem(
        productId: map['productId'] as String? ?? '',
        productName: map['productName'] as String? ?? '',
        unitPrice: asDouble(map['unitPrice']),
        unitCost: asDouble(map['unitCost']),
        quantity: asInt(map['quantity']),
      );
}
