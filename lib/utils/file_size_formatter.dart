/// Arabic file sizes: `850 كيلوبايت`, `2.4 ميغابايت`.
class FileSizeFormatter {
  FileSizeFormatter._();

  static String format(int bytes) {
    if (bytes < 1024) return '$bytes بايت';
    if (bytes < 1024 * 1024) return '${_one(bytes / 1024)} كيلوبايت';
    return '${_one(bytes / (1024 * 1024))} ميغابايت';
  }

  static String _one(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}
