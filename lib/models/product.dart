import 'enums.dart';
import 'model_utils.dart';

/// A used-furniture product.
///
/// [quantity] is a number of PIECES (integer). [length], [width], [height]
/// (cm) and [weight] (kg) are optional descriptive information only: they
/// never affect quantity, price or stock calculations.
class Product {
  Product({
    required this.id,
    required this.name,
    this.description = '',
    required this.categoryId,
    required this.condition,
    this.purchasePrice = 0,
    required this.sellingPrice,
    required this.quantity,
    this.length,
    this.width,
    this.height,
    this.weight,
    this.images = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final String description;
  /// Id of a `ProductCategory` (see CategoryRepository).
  final String categoryId;
  final ProductCondition condition;
  final double purchasePrice;
  final double sellingPrice;
  final int quantity;

  /// Optional, in centimetres.
  final double? length;
  final double? width;
  final double? height;

  /// Optional, in kilograms.
  final double? weight;

  /// Image FILE NAMES inside the app's `product_images` folder (not absolute
  /// paths, so a restored backup works on another phone). The first one is the
  /// main image.
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  String? get mainImage => images.isEmpty ? null : images.first;

  bool get hasDimensions => length != null || width != null || height != null;

  double get profitPerUnit => sellingPrice - purchasePrice;
  double get totalEstimatedProfit => profitPerUnit * quantity;
  double get stockValue => purchasePrice * quantity;

  StockStatus stockStatus(int lowStockThreshold) {
    if (quantity <= 0) return StockStatus.out;
    if (quantity <= lowStockThreshold) return StockStatus.low;
    return StockStatus.inStock;
  }

  /// Same product with another stock quantity (used when selling).
  Product copyWithQuantity(
    int newQuantity, {
    DateTime? updatedAt,
    double? purchasePrice,
  }) =>
      Product(
        id: id,
        name: name,
        description: description,
        categoryId: categoryId,
        condition: condition,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        sellingPrice: sellingPrice,
        quantity: newQuantity,
        length: length,
        width: width,
        height: height,
        weight: weight,
        images: images,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        isActive: isActive,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        // Same key as before: old data (category enum names) is still valid.
        'category': categoryId,
        'condition': condition.name,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'quantity': quantity,
        'length': length,
        'width': width,
        'height': height,
        'weight': weight,
        'images': images,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isActive': isActive,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        categoryId: map['category'] as String? ?? '',
        condition: ProductCondition.fromName(map['condition'] as String?),
        purchasePrice: asDouble(map['purchasePrice']),
        sellingPrice: asDouble(map['sellingPrice']),
        quantity: asInt(map['quantity']),
        length: asDoubleOrNull(map['length']),
        width: asDoubleOrNull(map['width']),
        height: asDoubleOrNull(map['height']),
        weight: asDoubleOrNull(map['weight']),
        images: (map['images'] as List?)?.map((e) => e.toString()).toList() ??
            <String>[],
        createdAt: asDate(map['createdAt']),
        updatedAt: asDate(map['updatedAt']),
        isActive: map['isActive'] as bool? ?? true,
      );
}
