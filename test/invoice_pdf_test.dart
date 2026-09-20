import 'package:athathi/models/enums.dart';
import 'package:athathi/models/sale.dart';
import 'package:athathi/models/sale_item.dart';
import 'package:athathi/utils/invoice_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

Sale _sale(int items) => Sale(
      id: 's1',
      number: 12,
      customerName: 'أحمد بن علي',
      items: [
        for (var i = 0; i < items; i++)
          SaleItem(
            productId: 'p$i',
            productName: 'خزانة ملابس خشبية كبيرة رقم $i',
            unitPrice: 250.5,
            unitCost: 100,
            quantity: 2,
          ),
      ],
      total: 501.0 * items,
      paid: 200,
      method: PaymentMethod.credit,
      notes: 'التسليم يوم السبت',
      createdAt: DateTime(2026, 9, 20, 14, 5),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('invoice PDF is generated', () async {
    final bytes = await InvoicePdf.build(_sale(3),
        businessName: 'أثاثي', subtitle: 'إدارة بيع الأثاث المستعمل');
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(2000));
  });

  test('a long invoice spans several pages without failing', () async {
    final bytes = await InvoicePdf.build(_sale(120),
        businessName: 'أثاثي', subtitle: 'إدارة بيع الأثاث المستعمل');
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
