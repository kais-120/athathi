import 'model_utils.dart';

/// A payment made to a supplier against what the shop owes him.
class SupplierPayment {
  const SupplierPayment({
    required this.id,
    required this.supplierId,
    required this.amount,
    this.note = '',
    required this.createdAt,
  });

  final String id;
  final String supplierId;
  final double amount;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'supplierId': supplierId,
        'amount': amount,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SupplierPayment.fromMap(Map<String, dynamic> map) => SupplierPayment(
        id: map['id'] as String,
        supplierId: map['supplierId'] as String? ?? '',
        amount: asDouble(map['amount']),
        note: map['note'] as String? ?? '',
        createdAt: asDate(map['createdAt']),
      );
}
