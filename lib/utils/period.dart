import 'package:flutter/material.dart' show DateTimeRange;

/// Period filter used by الحسابات / المصاريف (and the reports of PART 6).
/// A week starts on Monday.
enum Period {
  today('اليوم'),
  week('هذا الأسبوع'),
  month('هذا الشهر'),
  all('الكل');

  const Period(this.label);
  final String label;

  /// `null` means "no limit". The range is [start, end).
  DateTimeRange? range([DateTime? now]) {
    final n = now ?? DateTime.now();
    switch (this) {
      case Period.today:
        return DateTimeRange(
          start: DateTime(n.year, n.month, n.day),
          end: DateTime(n.year, n.month, n.day + 1),
        );
      case Period.week:
        final monday = DateTime(n.year, n.month, n.day - (n.weekday - 1));
        return DateTimeRange(
          start: monday,
          end: DateTime(monday.year, monday.month, monday.day + 7),
        );
      case Period.month:
        return DateTimeRange(
          start: DateTime(n.year, n.month, 1),
          end: DateTime(n.year, n.month + 1, 1),
        );
      case Period.all:
        return null;
    }
  }

  static bool contains(DateTimeRange? range, DateTime date) =>
      range == null || (!date.isBefore(range.start) && date.isBefore(range.end));
}
