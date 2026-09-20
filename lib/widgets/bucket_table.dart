import 'package:flutter/material.dart';

import '../models/report_data.dart';
import '../utils/currency_formatter.dart';
import 'bar_chart.dart';
import 'report_widgets.dart';

/// Exact figures behind a chart: one row per non-empty bucket, one column per
/// series.
class BucketTable extends StatelessWidget {
  const BucketTable({
    super.key,
    required this.title,
    required this.buckets,
    required this.columns,
  });

  final String title;
  final List<ReportBucket> buckets;
  final List<BarSeries> columns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final multi = columns.length > 1;

    final rows = <int>[
      for (var i = 0; i < buckets.length; i++)
        if (columns.any((c) => i < c.values.length && c.values[i] != 0)) i,
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    String money(double v) =>
        multi ? CurrencyFormatter.number(v) : CurrencyFormatter.format(v);

    return ReportCard(
      title: title,
      subtitle: multi ? 'المبالغ بالدينار (د.ت)' : null,
      child: Column(
        children: [
          if (multi)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: SizedBox.shrink()),
                  for (final c in columns)
                    Expanded(
                      flex: 2,
                      child: Text(c.name,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700, color: c.color)),
                    ),
                ],
              ),
            ),
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(buckets[rows[r]].fullLabel,
                        style: theme.textTheme.bodySmall),
                  ),
                  for (final c in columns)
                    Expanded(
                      flex: 2,
                      child: Text(
                        money(rows[r] < c.values.length ? c.values[rows[r]] : 0),
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
