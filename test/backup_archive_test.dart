import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:athathi/utils/backup_archive.dart';
import 'package:athathi/utils/file_size_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _data() => {
      'app': 'athathi',
      'version': 1,
      'exportedAt': '2026-09-20T10:00:00.000',
      'boxes': {
        'products': {
          'p1': {'id': 'p1', 'name': 'خزانة', 'sellingPrice': 250.5},
        },
        'sales': <String, dynamic>{},
      },
    };

List<int> _zip(Map<String, List<int>> files) {
  final archive = Archive();
  files.forEach((name, bytes) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return ZipEncoder().encode(archive)!;
}

void main() {
  test('build + parse keeps data and pictures', () {
    final images = {
      'a.jpg': List<int>.generate(300, (i) => i % 256),
      'b.png': [1, 2, 3],
    };
    final zip = BackupArchive.build(_data(), images);
    final parsed = BackupArchive.parse(zip);

    expect(parsed.data['app'], 'athathi');
    expect(
      (parsed.data['boxes'] as Map)['products']['p1']['name'],
      'خزانة',
    );
    expect(parsed.images.keys.toSet(), {'a.jpg', 'b.png'});
    expect(parsed.images['a.jpg'], images['a.jpg']);
    expect(parsed.images['b.png'], [1, 2, 3]);
  });

  test('a backup without pictures is valid', () {
    final parsed = BackupArchive.parse(BackupArchive.build(_data(), {}));
    expect(parsed.images, isEmpty);
  });

  test('picture names that are paths are ignored', () {
    final zip = _zip({
      'data.json': utf8.encode(jsonEncode(_data())),
      'images/ok.jpg': [1],
      'images/../evil.jpg': [2],
      'images/sub/evil.jpg': [3],
      'other/file.jpg': [4],
    });
    final parsed = BackupArchive.parse(zip);
    expect(parsed.images.keys, ['ok.jpg']);
  });

  test('isSafeImageName', () {
    expect(BackupArchive.isSafeImageName('123_0.jpg'), isTrue);
    expect(BackupArchive.isSafeImageName(''), isFalse);
    expect(BackupArchive.isSafeImageName('..'), isFalse);
    expect(BackupArchive.isSafeImageName('a/b.jpg'), isFalse);
    expect(BackupArchive.isSafeImageName('a\\b.jpg'), isFalse);
  });

  test('invalid files are rejected', () {
    expect(() => BackupArchive.parse([1, 2, 3, 4]),
        throwsA(isA<FormatException>()));

    // a zip without data.json
    expect(() => BackupArchive.parse(_zip({'x.txt': [1]})),
        throwsA(isA<FormatException>()));

    // data.json of another app
    final other = {'app': 'other', 'boxes': <String, dynamic>{}};
    expect(
        () => BackupArchive.parse(
            _zip({'data.json': utf8.encode(jsonEncode(other))})),
        throwsA(isA<FormatException>()));

    // corrupted json
    expect(() => BackupArchive.parse(_zip({'data.json': utf8.encode('{oops')})),
        throwsA(isA<FormatException>()));
  });

  test('file name is sortable and timestamped', () {
    expect(BackupArchive.fileNameFor(DateTime(2026, 9, 20, 14, 5, 9)),
        'athathi_backup_20260920_140509.zip');
  });

  test('file sizes are Arabic', () {
    expect(FileSizeFormatter.format(512), '512 بايت');
    expect(FileSizeFormatter.format(2048), '2 كيلوبايت');
    expect(FileSizeFormatter.format(1536), '1.5 كيلوبايت');
    expect(FileSizeFormatter.format(5 * 1024 * 1024), '5 ميغابايت');
  });
}
