import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/chart_scale.dart';

/// One data series of a bar chart (one value per label).
class BarSeries {
  const BarSeries({
    required this.name,
    required this.color,
    required this.values,
  });

  final String name;
  final Color color;
  final List<double> values;
}

/// Card with a title, a legend (when there are several series) and a bar
/// chart drawn with a [CustomPainter] — no chart package, works offline.
/// The time axis runs right-to-left in the RTL UI and the value axis sits on
/// the right; every label is Arabic.
class BarChartCard extends StatelessWidget {
  const BarChartCard({
    super.key,
    required this.title,
    required this.labels,
    required this.series,
    this.height = 220,
  });

  final String title;
  final List<String> labels;
  final List<BarSeries> series;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final labelStyle = (theme.textTheme.labelSmall ?? const TextStyle())
        .copyWith(fontSize: 10, color: theme.colorScheme.onSurfaceVariant);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (series.length > 1) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  for (final s in series)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(s.name, style: theme.textTheme.bodySmall),
                      ],
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(
                painter: _BarChartPainter(
                  labels: labels,
                  series: series,
                  rtl: rtl,
                  labelStyle: labelStyle,
                  gridColor: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.6),
                  zeroColor: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.labels,
    required this.series,
    required this.rtl,
    required this.labelStyle,
    required this.gridColor,
    required this.zeroColor,
  });

  final List<String> labels;
  final List<BarSeries> series;
  final bool rtl;
  final TextStyle labelStyle;
  final Color gridColor;
  final Color zeroColor;

  TextPainter _text(String text) => TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.rtl,
        maxLines: 1,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty || series.isEmpty) return;

    var lo = 0.0;
    var hi = 0.0;
    for (final s in series) {
      for (final v in s.values) {
        lo = math.min(lo, v);
        hi = math.max(hi, v);
      }
    }
    final scale = ChartScale.nice(lo, hi);
    final ticks = scale.ticks;
    final tickPainters = [for (final t in ticks) _text(ChartScale.compact(t))];
    final axisWidth =
        tickPainters.fold<double>(0, (m, p) => math.max(m, p.width)) + 8;

    const topPad = 8.0;
    const bottomHeight = 24.0;
    final plot = Rect.fromLTRB(
      rtl ? 0 : axisWidth,
      topPad,
      rtl ? size.width - axisWidth : size.width,
      size.height - bottomHeight,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    double yOf(double v) =>
        plot.bottom - (v - scale.min) / (scale.max - scale.min) * plot.height;

    // ---- grid + value axis
    final gridPaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < ticks.length; i++) {
      final y = yOf(ticks[i]);
      final isZero = ticks[i].abs() < scale.step * 1e-6;
      gridPaint.color = isZero ? zeroColor : gridColor;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);

      final p = tickPainters[i];
      final x = rtl ? plot.right + 6 : axisWidth - 6 - p.width;
      p.paint(canvas, Offset(x, y - p.height / 2));
    }

    // ---- bars
    final n = labels.length;
    final groupWidth = plot.width / n;
    final gap = series.length > 1 ? 2.0 : 0.0;
    final barWidth = math.max(
        1.0, (groupWidth * 0.7 - gap * (series.length - 1)) / series.length);
    final usedWidth = barWidth * series.length + gap * (series.length - 1);
    final zeroY = yOf(0);
    final barPaint = Paint()..style = PaintingStyle.fill;
    final radius = Radius.circular(math.min(3.0, barWidth / 2));

    for (var i = 0; i < n; i++) {
      final slot = rtl ? n - 1 - i : i;
      final groupLeft =
          plot.left + slot * groupWidth + (groupWidth - usedWidth) / 2;
      for (var s = 0; s < series.length; s++) {
        if (i >= series[s].values.length) continue;
        final v = series[s].values[i];
        if (v == 0) continue;
        final position = rtl ? series.length - 1 - s : s;
        final left = groupLeft + position * (barWidth + gap);
        final y = yOf(v);
        final top = math.min(y, zeroY);
        final bottom = math.max(math.max(y, zeroY), top + 1);
        barPaint.color = series[s].color;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTRB(left, top, left + barWidth, bottom), radius),
          barPaint,
        );
      }
    }

    // ---- time axis labels (thinned so they never overlap)
    final labelPainters = [for (final l in labels) _text(l)];
    final widest =
        labelPainters.fold<double>(0, (m, p) => math.max(m, p.width));
    final step = math.max(1, ((widest + 6) / groupWidth).ceil());
    for (var i = 0; i < n; i += step) {
      final slot = rtl ? n - 1 - i : i;
      final centre = plot.left + slot * groupWidth + groupWidth / 2;
      final p = labelPainters[i];
      final x = (centre - p.width / 2)
          .clamp(0.0, math.max(0.0, size.width - p.width))
          .toDouble();
      p.paint(canvas, Offset(x, plot.bottom + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => true;
}
