import 'dart:async';
import 'dart:io';

import 'package:athathi/services/backup_errors.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

void main() {
  const offline =
      'لا يوجد اتصال بالإنترنت، يمكنك استعمال التطبيق بشكل عادي وسيتم حفظ البيانات محليًا.';

  test('network errors give the exact offline message', () {
    for (final error in <Object>[
      const SocketException('no route'),
      http.ClientException('failed'),
      PlatformException(code: 'network_error'),
    ]) {
      final e = BackupErrors.translate(error);
      expect(e.offline, isTrue, reason: '$error');
      expect(e.message, offline);
    }
  });

  test('local file errors are not reported as offline', () {
    final e = BackupErrors.translate(const FileSystemException('disk'));
    expect(e.offline, isFalse);
  });

  test('timeout is not the offline message', () {
    final e = BackupErrors.translate(TimeoutException('slow'));
    expect(e.offline, isFalse);
    expect(e.message, isNot(offline));
  });

  test('Google sign-in and Drive errors', () {
    expect(BackupErrors.translate(PlatformException(code: 'sign_in_failed')).message,
        contains('Google Cloud'));
    expect(BackupErrors.translate(drive.DetailedApiRequestError(401, 'x')).message,
        contains('أعد ربط الحساب'));
    expect(BackupErrors.translate(drive.DetailedApiRequestError(403, 'x')).message,
        contains('Drive API'));
    expect(BackupErrors.translate(drive.DetailedApiRequestError(503, 'x')).message,
        contains('غير متاحة'));
  });

  test('a BackupException and unknown errors', () {
    const own = BackupException('رسالة');
    expect(identical(BackupErrors.translate(own), own), isTrue);
    expect(BackupErrors.translate(StateError('x')).message, isNotEmpty);
  });
}
