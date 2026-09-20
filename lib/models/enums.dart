/// Shared enums with their Arabic labels.

enum ProductCondition {
  excellent('ممتاز'),
  veryGood('جيد جدًا'),
  good('جيد'),
  acceptable('مقبول'),
  needsRepair('يحتاج إلى إصلاح');

  const ProductCondition(this.label);
  final String label;

  static ProductCondition fromName(String? name) => values.firstWhere(
        (e) => e.name == name,
        orElse: () => ProductCondition.good,
      );
}

enum PaymentMethod {
  cash('نقدًا'),
  credit('بالدين');

  const PaymentMethod(this.label);
  final String label;

  /// Old data may contain `card` (removed): it is read back as cash.
  static PaymentMethod fromName(String? name) => values.firstWhere(
        (e) => e.name == name,
        orElse: () => PaymentMethod.cash,
      );
}

enum StockStatus {
  inStock('متوفر'),
  low('كمية منخفضة'),
  out('نفد المخزون');

  const StockStatus(this.label);
  final String label;
}

enum ActivityType {
  productAdded('تمت إضافة منتج جديد'),
  saleMade('تمت عملية بيع'),
  customerAdded('تمت إضافة حريف'),
  paymentRecorded('تم تسجيل دفعة'),
  expenseAdded('تمت إضافة مصروف'),
  purchaseMade('تمت عملية شراء'),
  backupCreated('تم إنشاء نسخة احتياطية');

  const ActivityType(this.label);
  final String label;

  static ActivityType fromName(String? name) => values.firstWhere(
        (e) => e.name == name,
        orElse: () => ActivityType.productAdded,
      );
}
