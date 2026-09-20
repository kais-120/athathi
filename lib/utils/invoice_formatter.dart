import '../models/sale.dart';
import 'currency_formatter.dart';
import 'date_formatter.dart';

/// Plain-text invoice (to paste in WhatsApp / SMS).
class InvoiceFormatter {
  InvoiceFormatter._();

  static String text(
    Sale sale, {
    required String businessName,
    required String subtitle,
  }) {
    const line = '------------------------';
    final b = StringBuffer()
      ..writeln(businessName)
      ..writeln(subtitle)
      ..writeln(line)
      ..writeln('فاتورة رقم ${sale.number}')
      ..writeln('التاريخ: ${DateFormatter.dateTime(sale.createdAt)}')
      ..writeln('الحريف: ${sale.displayCustomer}')
      ..writeln(line);

    for (final item in sale.items) {
      b
        ..writeln(item.productName)
        ..writeln(
            '${item.quantity} × ${CurrencyFormatter.format(item.unitPrice)} = ${CurrencyFormatter.format(item.lineTotal)}');
    }

    b
      ..writeln(line)
      ..writeln('الإجمالي: ${CurrencyFormatter.format(sale.total)}')
      ..writeln('المدفوع: ${CurrencyFormatter.format(sale.paid)}')
      ..writeln('المتبقي: ${CurrencyFormatter.format(sale.remaining)}')
      ..writeln('طريقة الدفع: ${sale.method.label}');

    if (sale.notes.trim().isNotEmpty) {
      b.writeln('ملاحظات: ${sale.notes.trim()}');
    }
    return b.toString().trimRight();
  }
}
