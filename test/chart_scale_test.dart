import 'package:athathi/utils/chart_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('axis always includes zero and uses 1/2/5 steps', () {
    final s = ChartScale.nice(0, 730);
    expect(s.min, 0);
    expect(s.step, 200);
    expect(s.max, 800);
    expect(s.ticks, [0, 200, 400, 600, 800]);
  });

  test('all zero values still give a usable axis', () {
    final s = ChartScale.nice(0, 0);
    expect(s.min, 0);
    expect(s.max, greaterThan(0));
    expect(s.ticks.length, greaterThan(1));
  });

  test('negative values extend the axis below zero', () {
    final s = ChartScale.nice(-120, 300);
    expect(s.min, lessThan(0));
    expect(s.max, greaterThanOrEqualTo(300));
    expect(s.ticks, contains(0));
  });

  test('compact labels are Arabic', () {
    expect(ChartScale.compact(0), '0');
    expect(ChartScale.compact(350), '350');
    expect(ChartScale.compact(1000), '1 ألف');
    expect(ChartScale.compact(1250), '1.25 ألف');
    expect(ChartScale.compact(2000000), '2 مليون');
    expect(ChartScale.compact(2.5), '2.5');
  });
}
