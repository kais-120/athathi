import 'enums.dart';
import 'model_utils.dart';
import 'sale_item.dart';

class Sale {
  const Sale({
    required this.id,
    required this.number,
    this.customerId,
    this.customerName,
    this.items = const [],
    required this.total,
    required this.paid,
    required this.method,
    this.notes = '',
    required this.createdAt,
  });

  final String id;

  /// Human readable sale number (رقم العملية).
  final int number;
  final String? customerId;
  final String? customerName;
  final List<SaleItem> items;
  final double total;
  final double paid;
  final PaymentMethod method;
  final String notes;
  final DateTime createdAt;

  String get displayCustomer => customerName ?? 'حريف عابر';
  double get remaining => (total - paid) < 0 ? 0 : total - paid;
  double get profit => items.fold(0, (sum, i) => sum + i.lineProfit);

  Map<String, dynamic> toMap() => {
        'id': id,
        'number': number,
        'customerId': customerId,
        'customerName': customerName,
        'items': items.map((i) => i.toMap()).toList(),
        'total': total,
        'paid': paid,
        'method': method.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Sale.fromMap(Map<String, dynamic> map) => Sale(
        id: map['id'] as String,
        number: asInt(map['number']),
        customerId: map['customerId'] as String?,
        customerName: map['customerName'] as String?,
        items: asMapList(map['items']).map(SaleItem.fromMap).toList(),
        total: asDouble(map['total']),
        paid: asDouble(map['paid']),
        method: PaymentMethod.fromName(map['method'] as String?),
        notes: map['notes'] as String? ?? '',
        createdAt: asDate(map['createdAt']),
      );
}
