/// Form validators with Arabic error messages.
class Validators {
  Validators._();

  static String? username(String? v) =>
      (v == null || v.trim().isEmpty) ? 'اسم المستخدم مطلوب' : null;

  static String? password(String? v) =>
      (v == null || v.isEmpty) ? 'كلمة المرور مطلوبة' : null;

  static String? customerName(String? v) =>
      (v == null || v.trim().isEmpty) ? 'اسم الحريف مطلوب' : null;

  static String? supplierName(String? v) =>
      (v == null || v.trim().isEmpty) ? 'اسم المورد مطلوب' : null;

  static String? expenseTitle(String? v) =>
      (v == null || v.trim().isEmpty) ? 'عنوان المصروف مطلوب' : null;

  /// Required amount > 0.
  static String? positiveAmount(String? v) {
    if (v == null || v.trim().isEmpty) return 'المبلغ مطلوب';
    final n = parseNumber(v);
    if (n == null || n <= 0) return 'المبلغ يجب أن يكون أكبر من 0';
    return null;
  }

  /// Required whole number >= 1 (pieces bought).
  static String? positiveQuantity(String? v) {
    if (v == null || v.trim().isEmpty) return 'الكمية مطلوبة';
    final n = parseInt(v);
    if (n == null || n < 1) return 'الكمية يجب أن تكون 1 على الأقل';
    return null;
  }

  /// Required cost price (0 is allowed, e.g. a gift).
  static String? purchasePrice(String? v) {
    if (v == null || v.trim().isEmpty) return 'سعر الشراء مطلوب';
    final n = parseNumber(v);
    return (n == null || n < 0) ? 'قيمة غير صالحة' : null;
  }

  static String? productName(String? v) =>
      (v == null || v.trim().isEmpty) ? 'اسم المنتج مطلوب' : null;

  static String? category(Object? v) => v == null ? 'التصنيف مطلوب' : null;

  static String? sellingPrice(String? v) {
    if (v == null || v.trim().isEmpty) return 'سعر البيع مطلوب';
    final n = parseNumber(v);
    if (n == null || n < 0) return 'قيمة غير صالحة';
    return null;
  }

  static String? quantity(String? v) {
    if (v == null || v.trim().isEmpty) return 'الكمية مطلوبة';
    final n = int.tryParse(_normalizeDigits(v));
    if (n == null || n < 0) return 'الكمية يجب أن تكون أكبر من أو تساوي 0';
    return null;
  }

  /// Optional decimal field (dimensions / weight): empty is valid.
  static String? optionalNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = parseNumber(v);
    return (n == null || n < 0) ? 'قيمة غير صالحة' : null;
  }

  /// Parses user input, accepting Arabic-Indic digits and "," as decimal
  /// separator. Returns null when empty or invalid.
  static double? parseNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return double.tryParse(_normalizeDigits(v).replaceAll(',', '.'));
  }

  /// Parses a whole number (Arabic-Indic digits accepted). Null if invalid.
  static int? parseInt(String? v) =>
      v == null ? null : int.tryParse(_normalizeDigits(v));

  static String _normalizeDigits(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final ch in input.trim().split('')) {
      final i = arabicIndic.indexOf(ch);
      buffer.write(i >= 0 ? '$i' : ch);
    }
    return buffer.toString();
  }
}
