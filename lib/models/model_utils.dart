/// Helpers to read values coming from Hive / JSON safely.

double asDouble(dynamic v, [double fallback = 0]) =>
    v is num ? v.toDouble() : fallback;

double? asDoubleOrNull(dynamic v) => v is num ? v.toDouble() : null;

int asInt(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

DateTime asDate(dynamic v) =>
    (v is String ? DateTime.tryParse(v) : null) ?? DateTime.now();

DateTime? asDateOrNull(dynamic v) => v is String ? DateTime.tryParse(v) : null;

/// Converts a stored list of maps (Hive returns `List<dynamic>` of
/// `Map<dynamic, dynamic>`) into typed maps.
List<Map<String, dynamic>> asMapList(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];
