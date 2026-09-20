import 'dart:math' as math;

/// "Nice" axis for the bar charts: 0-based, steps of 1 / 2 / 5 × 10ⁿ.
class ChartScale {
  const ChartScale(this.min, this.max, this.step);

  final double min;
  final double max;
  final double step;

  /// [lo] / [hi] are the smallest and largest values to draw (the axis always
  /// includes 0).
  factory ChartScale.nice(double lo, double hi, {int targetTicks = 4}) {
    final low = math.min(lo, 0.0);
    var high = math.max(hi, 0.0);
    if (high - low <= 0) high = 1;

    final rawStep = (high - low) / targetTicks;
    final magnitude =
        math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
    final residual = rawStep / magnitude;
    final double niceResidual = residual <= 1
        ? 1.0
        : residual <= 2
            ? 2.0
            : residual <= 5
                ? 5.0
                : 10.0;
    final step = niceResidual * magnitude;
    return ChartScale(
      (low / step).floor() * step,
      (high / step).ceil() * step,
      step,
    );
  }

  List<double> get ticks {
    final result = <double>[];
    for (var i = 0; min + i * step <= max + step * 1e-9; i++) {
      result.add(min + i * step);
    }
    return result;
  }

  /// Short Arabic label for an axis value: `1.25 ألف`, `2 مليون`, `350`.
  static String compact(double v) {
    final a = v.abs();
    if (a >= 1000000) return '${_trim(v / 1000000, 2)} مليون';
    if (a >= 1000) return '${_trim(v / 1000, 2)} ألف';
    if (a >= 10) return _trim(v, 0);
    if (a >= 1) return _trim(v, 1);
    return _trim(v, 3);
  }

  static String _trim(double x, int decimals) {
    var s = x.toStringAsFixed(decimals);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    return s == '-0' ? '0' : s;
  }
}
