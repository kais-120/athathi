import 'package:flutter/foundation.dart';

import '../../models/product.dart';

/// One line of the cart. [unitPrice] starts at the product's selling price
/// and can be negotiated (edited) for this sale only.
class CartLine {
  CartLine({required this.product, this.quantity = 1, double? unitPrice})
      : unitPrice = unitPrice ?? product.sellingPrice;

  final Product product;
  int quantity;
  double unitPrice;

  /// Pieces available in stock when the product was added.
  int get maxQuantity => product.quantity;

  double get total => unitPrice * quantity;
}

/// Shopping cart of the sale being prepared. Quantities are pieces and can
/// never exceed the stock.
class CartController extends ChangeNotifier {
  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();
  bool get isEmpty => _lines.isEmpty;

  /// Total number of pieces.
  int get pieces => _lines.values.fold(0, (sum, l) => sum + l.quantity);

  double get total => _lines.values.fold(0.0, (sum, l) => sum + l.total);

  int quantityOf(String productId) => _lines[productId]?.quantity ?? 0;

  /// Adds one piece. Returns false if the stock limit was reached.
  bool add(Product product) {
    final line = _lines[product.id];
    if (line == null) {
      if (product.quantity < 1) return false;
      _lines[product.id] = CartLine(product: product);
    } else {
      if (line.quantity >= line.maxQuantity) return false;
      line.quantity++;
    }
    notifyListeners();
    return true;
  }

  /// Sets the quantity (clamped to the stock). 0 or less removes the line.
  void setQuantity(String productId, int quantity) {
    final line = _lines[productId];
    if (line == null) return;
    if (quantity <= 0) {
      _lines.remove(productId);
    } else {
      line.quantity = quantity > line.maxQuantity ? line.maxQuantity : quantity;
    }
    notifyListeners();
  }

  void setPrice(String productId, double price) {
    final line = _lines[productId];
    if (line == null) return;
    line.unitPrice = price;
    notifyListeners();
  }

  void remove(String productId) {
    if (_lines.remove(productId) != null) notifyListeners();
  }

  void clear() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }
}
