import 'dart:convert';

import 'package:archive/archive.dart';

/// What a backup file contains once opened.
class BackupContents {
  const BackupContents({required this.data, required this.images});

  /// The result of `LocalStorageService.exportAll()`.
  final Map<String, dynamic> data;

  /// Product pictures: file name -> bytes.
  final Map<String, List<int>> images;
}

/// The backup file: a zip with `data.json` (all the database boxes) and
/// `images/<file name>` for every product picture. Pure Dart (no Hive, no
/// Google), so it can be unit tested.
class BackupArchive {
  BackupArchive._();

  static const String dataFile = 'data.json';
  static const String imagesDir = 'images/';
  static const String filePrefix = 'athathi_backup_';

  /// `athathi_backup_20260920_143005.zip`
  static String fileNameFor(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$filePrefix${t.year}${two(t.month)}${two(t.day)}'
        '_${two(t.hour)}${two(t.minute)}${two(t.second)}.zip';
  }

  /// A picture name from a backup is only accepted when it is a plain file
  /// name (never a path), so a crafted zip cannot write outside the images
  /// folder.
  static bool isSafeImageName(String name) =>
      name.isNotEmpty &&
      name != '.' &&
      name != '..' &&
      !name.contains('/') &&
      !name.contains('\\') &&
      !name.contains('\u0000');

  static List<int> build(
    Map<String, dynamic> data,
    Map<String, List<int>> images,
  ) {
    final archive = Archive();
    final dataBytes = utf8.encode(jsonEncode(data));
    archive.addFile(ArchiveFile(dataFile, dataBytes.length, dataBytes));
    for (final entry in images.entries) {
      // Pictures are already compressed (JPEG), deflating them is a waste.
      archive.addFile(
        ArchiveFile('$imagesDir${entry.key}', entry.value.length, entry.value)
          ..compress = false,
      );
    }
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw const FormatException('تعذر إنشاء ملف النسخة الاحتياطية');
    }
    return encoded;
  }

  /// Throws [FormatException] when the bytes are not a valid Athathi backup.
  static BackupContents parse(List<int> bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('الملف ليس نسخة احتياطية صالحة');
    }

    Map<String, dynamic>? data;
    final images = <String, List<int>>{};
    for (final file in archive) {
      if (!file.isFile) continue;
      final content = file.content;
      if (content is! List<int>) continue;

      if (file.name == dataFile) {
        try {
          final decoded = jsonDecode(utf8.decode(content));
          if (decoded is Map) data = Map<String, dynamic>.from(decoded);
        } catch (_) {
          throw const FormatException('بيانات النسخة الاحتياطية تالفة');
        }
      } else if (file.name.startsWith(imagesDir)) {
        final name = file.name.substring(imagesDir.length);
        if (isSafeImageName(name)) images[name] = content;
      }
    }

    if (data == null || data['app'] != 'athathi' || data['boxes'] is! Map) {
      throw const FormatException('الملف ليس نسخة احتياطية لتطبيق أثاثي');
    }
    return BackupContents(data: data, images: images);
  }
}
