import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/sale.dart';
import 'currency_formatter.dart';
import 'date_formatter.dart';

/// Builds the sale invoice as an Arabic (right-to-left) PDF.
///
/// Every row is laid out explicitly right-to-left (the first column is put
/// on the right), and every text is shaped as RTL with the bundled Tajawal
/// font, so it renders correctly on any phone, offline.
class InvoicePdf {
  InvoicePdf._();

  static const PdfColor _brand = PdfColor.fromInt(0xFF8A5A3B);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B6B6B);
  static const PdfColor _line = PdfColor.fromInt(0xFFDDD5CC);
  static const PdfColor _headerFill = PdfColor.fromInt(0xFFF3ECE4);
  static const PdfColor _danger = PdfColor.fromInt(0xFFC62828);
  static const PdfColor _success = PdfColor.fromInt(0xFF2E7D32);

  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<Uint8List> build(
    Sale sale, {
    required String businessName,
    required String subtitle,
  }) async {
    final regular = _regular ??=
        pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
    final bold = _bold ??=
        pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));

    final doc = pw.Document(
      title: 'فاتورة ${sale.number}',
      author: businessName,
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _header(businessName, subtitle),
          pw.SizedBox(height: 18),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _text(DateFormatter.dateTime(sale.createdAt),
                  color: _muted, align: pw.TextAlign.left),
              _text('فاتورة رقم ${sale.number}', size: 16, bold: true),
            ],
          ),
          pw.SizedBox(height: 6),
          _text('الحريف: ${sale.displayCustomer}'),
          pw.SizedBox(height: 16),
          _row(['المنتج', 'الكمية', 'سعر الوحدة', 'المجموع'], header: true),
          for (final item in sale.items)
            _row([
              item.productName,
              '${item.quantity}',
              CurrencyFormatter.number(item.unitPrice),
              CurrencyFormatter.number(item.lineTotal),
            ]),
          pw.SizedBox(height: 4),
          _text('المبالغ بالدينار التونسي (${CurrencyFormatter.symbol})',
              size: 9, color: _muted),
          pw.SizedBox(height: 14),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _pair('الإجمالي', CurrencyFormatter.format(sale.total),
                    bold: true, size: 14),
                _pair('المدفوع', CurrencyFormatter.format(sale.paid)),
                _pair(
                  'المتبقي',
                  CurrencyFormatter.format(sale.remaining),
                  bold: true,
                  color: sale.remaining > 0 ? _danger : _success,
                ),
                _pair('طريقة الدفع', sale.method.label),
              ],
            ),
          ),
          if (sale.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _text('ملاحظات: ${sale.notes.trim()}', color: _muted),
          ],
          pw.SizedBox(height: 28),
          pw.Center(
            child: _text('شكرًا لتعاملكم معنا',
                bold: true, color: _brand, align: pw.TextAlign.center),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _text(
    String value, {
    double size = 11,
    bool bold = false,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.right,
  }) {
    return pw.Text(
      value,
      textDirection: pw.TextDirection.rtl,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
    );
  }

  static pw.Widget _header(String name, String subtitle) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _brand,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _text(name, size: 22, bold: true, color: PdfColors.white),
          pw.SizedBox(height: 2),
          _text(subtitle, color: PdfColors.white),
        ],
      ),
    );
  }

  /// One table row. [cells] are given in reading order (right to left):
  /// product, quantity, unit price, total. The row is built left to right,
  /// so the cells are reversed.
  static pw.Widget _row(List<String> cells, {bool header = false}) {
    const flexes = [5, 2, 3, 3];
    const aligns = [
      pw.TextAlign.right,
      pw.TextAlign.center,
      pw.TextAlign.center,
      pw.TextAlign.left,
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: header ? _headerFill : null,
        border: pw.Border(bottom: pw.BorderSide(color: _line)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (var i = cells.length - 1; i >= 0; i--)
            pw.Expanded(
              flex: flexes[i],
              child: _text(cells[i], bold: header, align: aligns[i]),
            ),
        ],
      ),
    );
  }

  /// Label on the right, value on the left.
  static pw.Widget _pair(
    String label,
    String value, {
    bool bold = false,
    double size = 11,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _text(value,
              size: size, bold: bold, color: color, align: pw.TextAlign.left),
          _text(label, size: size, bold: bold, color: color),
        ],
      ),
    );
  }
}
