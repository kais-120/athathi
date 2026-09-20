import 'package:athathi/models/product_category.dart';
import 'package:athathi/models/enums.dart';
import 'package:athathi/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default categories keep the ids of the old fixed categories', () {
    expect(ProductCategory.defaults.length, 11);
    expect([for (final (id, _) in ProductCategory.defaults) id], [
      'bedrooms',
      'livingRooms',
      'tables',
      'chairs',
      'wardrobes',
      'desks',
      'kitchens',
      'appliances',
      'kids',
      'officeFurniture',
      'other',
    ]);
    expect(ProductCategory.defaults.map((e) => e.$2).toSet().length, 11);
  });

  test('category map round trip', () {
    final c = ProductCategory(
        id: 'x1', name: 'أثاث حدائق', createdAt: DateTime(2026, 9, 20, 10));
    final copy = ProductCategory.fromMap(c.toMap());
    expect(copy.id, 'x1');
    expect(copy.name, 'أثاث حدائق');
    expect(copy.createdAt, DateTime(2026, 9, 20, 10));
    expect(c.copyWith(name: 'جديد').name, 'جديد');
    expect(c.copyWith(name: 'جديد').id, 'x1');
  });

  test('a product saved with an old category name still resolves', () {
    final map = {
      'id': 'p1',
      'name': 'كرسي',
      'category': 'chairs', // what the old enum stored
      'condition': 'good',
      'sellingPrice': 40,
      'quantity': 2,
    };
    final product = Product.fromMap(map);
    expect(product.categoryId, 'chairs');
    expect(product.toMap()['category'], 'chairs');
  });

  test('the bank card payment method is gone', () {
    expect(PaymentMethod.values, [PaymentMethod.cash, PaymentMethod.credit]);
    // old records saved with `card` are read back as cash
    expect(PaymentMethod.fromName('card'), PaymentMethod.cash);
    expect(PaymentMethod.fromName('credit'), PaymentMethod.credit);
    expect(PaymentMethod.fromName(null), PaymentMethod.cash);
  });
}
