import 'package:athathi/utils/report_period.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Saturday 19 September 2026
  final now = DateTime(2026, 9, 19, 15, 30);

  test('presets follow the shared Period ranges', () {
    final today = const ReportPeriod(ReportRange.today).range(now);
    expect(today.start, DateTime(2026, 9, 19));
    expect(today.end, DateTime(2026, 9, 20));

    final week = const ReportPeriod(ReportRange.week).range(now);
    expect(week.start, DateTime(2026, 9, 14));
    expect(week.end, DateTime(2026, 9, 21));

    final month = const ReportPeriod(ReportRange.month).range(now);
    expect(month.start, DateTime(2026, 9, 1));
    expect(month.end, DateTime(2026, 10, 1));
  });

  test('custom range includes the last picked day', () {
    final p = ReportPeriod.custom(DateTimeRange(
      start: DateTime(2026, 9, 1, 10),
      end: DateTime(2026, 9, 10),
    ));
    final r = p.range(now);
    expect(r.start, DateTime(2026, 9, 1));
    expect(r.end, DateTime(2026, 9, 11)); // exclusive

    final shown = p.displayRange(now);
    expect(shown.start, DateTime(2026, 9, 1));
    expect(shown.end, DateTime(2026, 9, 10));
  });

  test('custom range across a month end', () {
    final p = ReportPeriod.custom(DateTimeRange(
      start: DateTime(2026, 8, 30),
      end: DateTime(2026, 8, 31),
    ));
    expect(p.range().end, DateTime(2026, 9, 1));
  });

  test('describe shows one date for a single day', () {
    final p = ReportPeriod.custom(DateTimeRange(
      start: DateTime(2026, 9, 5),
      end: DateTime(2026, 9, 5),
    ));
    expect(p.describe(), '05/09/2026');
    expect(const ReportPeriod(ReportRange.month).describe(now),
        '01/09/2026 – 30/09/2026');
  });
}
