import 'model_utils.dart';

/// Suggested expense categories (the stored value is the label itself).
const List<String> kExpenseCategories = [
  'نقل',
  'كراء',
  'إصلاح وصيانة',
  'أجور',
  'كهرباء وماء',
  'إشهار',
  'أخرى',
];

class Expense {
  const Expense({
    required this.id,
    required this.title,
    this.category = '',
    required this.amount,
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  final String title;
  final String category;
  final double amount;
  final String notes;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        category: map['category'] as String? ?? '',
        amount: asDouble(map['amount']),
        notes: map['notes'] as String? ?? '',
        createdAt: asDate(map['createdAt']),
      );
}
