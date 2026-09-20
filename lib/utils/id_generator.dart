import 'dart:math';

/// Unique string ids for locally created records (no backend needed).
class IdGenerator {
  IdGenerator._();

  static final Random _random = Random();

  static String next() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = _random.nextInt(0x7fffffff).toRadixString(36);
    return '$time$salt';
  }
}
