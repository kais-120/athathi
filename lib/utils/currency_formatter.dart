import 'package:intl/intl.dart';

/// Tunisian dinar formatting: 3 decimals (millimes), e.g. `1,250.000 د.ت`.
class CurrencyFormatter {
  CurrencyFormatter._();

  static const String symbol = 'د.ت';
  static final NumberFormat _format = NumberFormat('#,##0.000', 'en');

  static String number(num value) => _format.format(value);

  static String format(num value) => '${number(value)} $symbol';
}
