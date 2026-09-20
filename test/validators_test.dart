import 'package:athathi/utils/measure_formatter.dart';
import 'package:athathi/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('product validators', () {
    test('required fields use the Arabic messages', () {
      expect(Validators.productName(' '), 'اسم المنتج مطلوب');
      expect(Validators.category(null), 'التصنيف مطلوب');
      expect(Validators.sellingPrice(''), 'سعر البيع مطلوب');
      expect(Validators.quantity(''), 'الكمية مطلوبة');
    });

    test('quantity must be a whole number >= 0', () {
      expect(Validators.quantity('0'), isNull);
      expect(Validators.quantity('8'), isNull);
      expect(Validators.quantity('-1'),
          'الكمية يجب أن تكون أكبر من أو تساوي 0');
      expect(Validators.parseInt('٣'), 3); // Arabic-Indic digit
    });

    test('dimensions and weight are optional', () {
      expect(Validators.optionalNumber(''), isNull);
      expect(Validators.optionalNumber('180'), isNull);
      expect(Validators.optionalNumber('abc'), 'قيمة غير صالحة');
    });
  });

  test('customer name is required', () {
    expect(Validators.customerName(''), 'اسم الحريف مطلوب');
    expect(Validators.customerName('محمد'), isNull);
  });

  test('purchase and expense validators', () {
    expect(Validators.supplierName(''), 'اسم المورد مطلوب');
    expect(Validators.expenseTitle(' '), 'عنوان المصروف مطلوب');
    expect(Validators.positiveAmount('0'), 'المبلغ يجب أن يكون أكبر من 0');
    expect(Validators.positiveAmount('12.5'), isNull);
    expect(Validators.positiveQuantity('0'), 'الكمية يجب أن تكون 1 على الأقل');
    expect(Validators.positiveQuantity('2'), isNull);
    expect(Validators.purchasePrice(''), 'سعر الشراء مطلوب');
    expect(Validators.purchasePrice('0'), isNull);
  });

  test('measure formatting drops useless decimals', () {
    expect(MeasureFormatter.cm(180), '180 سم');
    expect(MeasureFormatter.kg(12.5), '12.5 كغ');
  });
}
