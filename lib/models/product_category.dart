import 'model_utils.dart';

/// A product category, managed by the user (add / rename / delete).
class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  /// Categories created on the first launch. Their ids are the names of the
  /// old fixed categories, so products saved before categories became
  /// editable keep pointing to the right one (also inside old backups).
  static const List<(String, String)> defaults = [
    ('bedrooms', 'غرف النوم'),
    ('livingRooms', 'الصالونات'),
    ('tables', 'الطاولات'),
    ('chairs', 'الكراسي'),
    ('wardrobes', 'الخزائن'),
    ('desks', 'المكاتب'),
    ('kitchens', 'المطابخ'),
    ('appliances', 'الأجهزة المنزلية'),
    ('kids', 'أثاث الأطفال'),
    ('officeFurniture', 'الأثاث المكتبي'),
    ('other', 'أخرى'),
  ];

  ProductCategory copyWith({String? name}) =>
      ProductCategory(id: id, name: name ?? this.name, createdAt: createdAt);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProductCategory.fromMap(Map<String, dynamic> map) => ProductCategory(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        createdAt: asDate(map['createdAt']),
      );
}
