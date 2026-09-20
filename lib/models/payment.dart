import 'enums.dart';
import 'model_utils.dart';

/// A payment received from a customer against his debt.
class Payment {
  const Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    this.method = PaymentMethod.cash,
    this.note = '',
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final double amount;
  final PaymentMethod method;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'amount': amount,
        'method': method.name,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] as String,
        customerId: map['customerId'] as String? ?? '',
        amount: asDouble(map['amount']),
        method: PaymentMethod.fromName(map['method'] as String?),
        note: map['note'] as String? ?? '',
        createdAt: asDate(map['createdAt']),
      );
}
