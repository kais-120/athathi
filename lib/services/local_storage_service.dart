import 'package:hive_flutter/hive_flutter.dart';

/// Offline-first local database (Hive).
///
/// Every record is stored as a plain `Map<String, dynamic>` (see the models'
/// `toMap` / `fromMap`), keyed by its id. Because everything is plain data,
/// the whole database can be exported to JSON and restored on another phone
/// (used by the Google Drive backup in a later part).
class LocalStorageService {
  static const int backupFormatVersion = 1;

  static const String productsBox = 'products';
  static const String categoriesBox = 'categories';
  static const String salesBox = 'sales';
  static const String customersBox = 'customers';
  static const String paymentsBox = 'payments';
  static const String purchasesBox = 'purchases';
  static const String suppliersBox = 'suppliers';
  static const String supplierPaymentsBox = 'supplier_payments';
  static const String expensesBox = 'expenses';
  static const String activitiesBox = 'activities';
  static const String settingsBox = 'settings';

  /// Local login session and credentials (never part of a backup).
  static const String authBox = 'auth';

  /// Boxes included in an export / backup.
  static const List<String> dataBoxes = [
    productsBox,
    categoriesBox,
    salesBox,
    customersBox,
    paymentsBox,
    purchasesBox,
    suppliersBox,
    supplierPaymentsBox,
    expensesBox,
    activitiesBox,
    settingsBox,
  ];

  static const List<String> _allBoxes = [...dataBoxes, authBox];

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    for (final name in _allBoxes) {
      await Hive.openBox<dynamic>(name);
    }
    _initialized = true;
  }

  Box<dynamic> box(String name) => Hive.box<dynamic>(name);

  Map<String, dynamic>? get(String boxName, String key) {
    final value = box(boxName).get(key);
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  List<Map<String, dynamic>> getAll(String boxName) => box(boxName)
      .values
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  Future<void> put(String boxName, String key, Map<String, dynamic> value) =>
      box(boxName).put(key, value);

  Future<void> delete(String boxName, String key) => box(boxName).delete(key);

  /// Exports every data box as a JSON-encodable map.
  Map<String, dynamic> exportAll() => {
        'app': 'athathi',
        'version': backupFormatVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'boxes': {
          for (final name in dataBoxes)
            name: {
              for (final key in box(name).keys) key.toString(): box(name).get(key),
            },
        },
      };

  /// Replaces all data boxes with the content of a previous [exportAll].
  Future<void> importAll(Map<String, dynamic> backup) async {
    if (backup['app'] != 'athathi' || backup['boxes'] is! Map) {
      throw const FormatException('ملف النسخة الاحتياطية غير صالح');
    }
    final boxes = Map<String, dynamic>.from(backup['boxes'] as Map);
    for (final name in dataBoxes) {
      final target = box(name);
      await target.clear();
      final entries = boxes[name];
      if (entries is Map) {
        await target.putAll(
          entries.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    }
  }
}
