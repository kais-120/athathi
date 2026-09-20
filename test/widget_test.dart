import 'package:athathi/models/enums.dart';
import 'package:athathi/models/product.dart';
import 'package:athathi/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('currency uses 3 decimals and د.ت', () {
    expect(CurrencyFormatter.format(1250), '1,250.000 د.ت');
  });

  test('stock status is computed from the quantity in pieces', () {
    Product withQty(int q) => Product(
          id: 'p',
          name: 'كرسي',
          categoryId: 'chairs',
          condition: ProductCondition.good,
          sellingPrice: 45,
          quantity: q,
        );

    expect(withQty(0).stockStatus(3), StockStatus.out);
    expect(withQty(2).stockStatus(3), StockStatus.low);
    expect(withQty(8).stockStatus(3), StockStatus.inStock);
  });

  test('product survives a toMap / fromMap round trip', () {
    final p = Product(
      id: 'p1',
      name: 'خزانة ملابس',
      categoryId: 'wardrobes',
      condition: ProductCondition.veryGood,
      purchasePrice: 500,
      sellingPrice: 750,
      quantity: 1,
      length: 180,
      weight: 75,
    );
    final copy = Product.fromMap(p.toMap());
    expect(copy.name, p.name);
    expect(copy.length, 180);
    expect(copy.width, isNull);
    expect(copy.weight, 75);
    expect(copy.totalEstimatedProfit, 250);
  });
}
