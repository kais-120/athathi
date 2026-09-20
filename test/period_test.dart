import 'package:athathi/utils/period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Saturday 19 September 2026
  final now = DateTime(2026, 9, 19, 15, 30);

  test('today covers the whole day', () {
    final r = Period.today.range(now)!;
    expect(r.start, DateTime(2026, 9, 19));
    expect(r.end, DateTime(2026, 9, 20));
  });

  test('week starts on Monday', () {
    final r = Period.week.range(now)!;
    expect(r.start, DateTime(2026, 9, 14));
    expect(r.end, DateTime(2026, 9, 21));
  });

  test('month covers the calendar month', () {
    final r = Period.month.range(now)!;
    expect(r.start, DateTime(2026, 9, 1));
    expect(r.end, DateTime(2026, 10, 1));
  });

  test('all has no limit and contains everything', () {
    expect(Period.all.range(now), isNull);
    expect(Period.contains(null, DateTime(2000)), isTrue);
  });

  test('range end is exclusive', () {
    final r = Period.today.range(now);
    expect(Period.contains(r, DateTime(2026, 9, 19, 23, 59)), isTrue);
    expect(Period.contains(r, DateTime(2026, 9, 20)), isFalse);
  });
}
