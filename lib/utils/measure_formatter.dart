/// Formats optional physical measurements: `180 سم`, `12.5 كغ`.
class MeasureFormatter {
  MeasureFormatter._();

  /// `180.0` -> `180`, `12.50` -> `12.5`.
  static String number(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String cm(double value) => '${number(value)} سم';

  static String kg(double value) => '${number(value)} كغ';
}
