import 'package:intl/intl.dart';

/// Date helpers (dd/MM/yyyy, 24h time, Latin digits as used in Tunisia).
class DateFormatter {
  DateFormatter._();

  static final DateFormat _date = DateFormat('dd/MM/yyyy', 'en');
  static final DateFormat _time = DateFormat('HH:mm', 'en');

  static const List<String> _weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static String date(DateTime d) => _date.format(d);
  static String time(DateTime d) => _time.format(d);
  static String dateTime(DateTime d) => '${date(d)} ${time(d)}';

  /// e.g. `السبت 19/09/2026`
  static String dayHeader(DateTime d) =>
      '${_weekdays[d.weekday - 1]} ${date(d)}';

  /// Arabic relative time, e.g. `منذ ساعتين`.
  static String relative(DateTime d, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) {
      return 'منذ ${_unit(diff.inMinutes, 'دقيقة', 'دقيقتين', 'دقائق')}';
    }
    if (diff.inHours < 24) {
      return 'منذ ${_unit(diff.inHours, 'ساعة', 'ساعتين', 'ساعات')}';
    }
    if (diff.inDays < 7) {
      return 'منذ ${_unit(diff.inDays, 'يوم', 'يومين', 'أيام')}';
    }
    return date(d);
  }

  /// Arabic number agreement: 1 -> singular, 2 -> dual, 3..10 -> plural,
  /// 11+ -> "N singular".
  static String _unit(int n, String singular, String dual, String plural) {
    if (n == 1) return singular;
    if (n == 2) return dual;
    if (n <= 10) return '$n $plural';
    return '$n $singular';
  }
}
