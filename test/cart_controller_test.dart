import 'package:athathi/models/enums.dart';
import 'package:athathi/models/product.dart';
import 'package:athathi/screens/sales/cart_controller.dart';
import 'package:flutter_test/flutter_test.dart';

Product _chair({int quantity = 3, double price = 45}) => Product(
      id: 'chair',
      name: 'كرسي خشبي',
      categoryId: 'chairs',
      condition: ProductCondition.good,
      purchasePrice: 25,
      sellingPrice: price,
      quantity: quantity,
    );

void main() {
  test('quantity can never exceed the stock', () {
    final cart = CartController();
    final chair = _chair(quantity: 2);

    expect(cart.add(chair), isTrue);
    expect(cart.add(chair), isTrue);
    expect(cart.add(chair), isFalse); // only 2 pieces in stock
    expect(cart.quantityOf('chair'), 2);

    cart.setQuantity('chair', 10);
    expect(cart.quantityOf('chair'), 2);
  });

  test('out of stock products cannot be added', () {
    expect(CartController().add(_chair(quantity: 0)), isFalse);
  });

  test('total follows quantity and negotiated price', () {
    final cart = CartController()..add(_chair())..add(_chair());
    expect(cart.pieces, 2);
    expect(cart.total, 90);

    cart.setPrice('chair', 40);
    expect(cart.total, 80);
  });

  test('quantity 0 removes the line', () {
    final cart = CartController()..add(_chair());
    cart.setQuantity('chair', 0);
    expect(cart.isEmpty, isTrue);
  });
}
