import 'model_utils.dart';

class Supplier {
  Supplier({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String phone;
  final String address;
  final String notes;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Supplier.fromMap(Map<String, dynamic> map) => Supplier(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        address: map['address'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        createdAt: asDate(map['createdAt']),
      );
}
