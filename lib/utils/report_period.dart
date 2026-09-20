import 'package:flutter/material.dart' show DateTimeRange;

import 'date_formatter.dart';
import 'period.dart';

/// The four filters of the reports screen.
enum ReportRange {
  today('اليوم', Period.today),
  week('هذا الأسبوع', Period.week),
  month('هذا الشهر', Period.month),
  custom('فترة مخصصة', null);

  const ReportRange(this.label, this.period);

  final String label;

  /// The matching [Period]; `null` for a custom range.
  final Period? period;
}

/// A reports filter: today / this week / this month / a custom date range.
/// (Kept apart from [Period] so الحسابات and المصاريف are not affected.)
class ReportPeriod {
  const ReportPeriod(this.kind) : _custom = null;

  const ReportPeriod._withRange(this._custom) : kind = ReportRange.custom;

  /// [picked] comes from `showDateRangePicker`: both days are INCLUDED.
  factory ReportPeriod.custom(DateTimeRange picked) =>
      ReportPeriod._withRange(DateTimeRange(
        start: DateTime(
            picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(
            picked.end.year, picked.end.month, picked.end.day + 1),
      ));

  final ReportRange kind;
  final DateTimeRange? _custom;

  /// [start, end) — the end day is excluded.
  DateTimeRange range([DateTime? now]) {
    final custom = _custom;
    if (kind == ReportRange.custom && custom != null) return custom;
    return (kind.period ?? Period.month).range(now)!;
  }

  /// Same range with the last day INCLUDED (for display and the picker).
  DateTimeRange displayRange([DateTime? now]) {
    final r = range(now);
    return DateTimeRange(
      start: r.start,
      end: DateTime(r.end.year, r.end.month, r.end.day - 1),
    );
  }

  /// `19/09/2026` or `01/09/2026 – 19/09/2026`.
  String describe([DateTime? now]) {
    final d = displayRange(now);
    final from = DateFormatter.date(d.start);
    final to = DateFormatter.date(d.end);
    return from == to ? from : '$from – $to';
  }
}
