import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show PlatformException;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// A backup / restore failure with a message that can be shown as is.
class BackupException implements Exception {
  const BackupException(this.message, {this.offline = false});

  final String message;

  /// True when the phone has no usable internet connection.
  final bool offline;

  @override
  String toString() => 'BackupException: $message';
}

/// Turns any error (network, Google sign-in, Drive API, files...) into a
/// [BackupException] with an Arabic message.
class BackupErrors {
  BackupErrors._();

  static const String offlineMessage =
      'لا يوجد اتصال بالإنترنت، يمكنك استعمال التطبيق بشكل عادي وسيتم حفظ البيانات محليًا.';

  static const BackupException _offline =
      BackupException(offlineMessage, offline: true);

  static BackupException translate(Object error) {
    if (error is BackupException) return error;

    // FileSystemException is an IOException: test it before the network ones.
    if (error is FileSystemException) {
      return const BackupException(
          'تعذر قراءة أو كتابة ملفات التطبيق على هذا الجهاز');
    }
    if (error is SocketException ||
        error is HandshakeException ||
        error is http.ClientException) {
      return _offline;
    }
    if (error is TimeoutException) {
      return const BackupException(
          'انتهت مهلة الاتصال بـ Google Drive، تحقق من الإنترنت وحاول مرة أخرى.');
    }

    if (error is PlatformException) {
      switch (error.code) {
        case 'network_error':
          return _offline;
        case 'sign_in_canceled':
          return const BackupException('تم إلغاء ربط حساب Google');
        case 'sign_in_failed':
          return const BackupException(
              'تعذر تسجيل الدخول إلى Google. تحقق من إعدادات Google Cloud '
              '(معرّف OAuth، بصمة SHA-1، اسم الحزمة).');
        default:
          return BackupException('تعذر الاتصال بحساب Google (${error.code})');
      }
    }

    if (error is drive.DetailedApiRequestError) {
      final status = error.status ?? 0;
      if (status == 401) {
        return const BackupException(
            'انتهت صلاحية ربط حساب Google، أعد ربط الحساب وحاول مرة أخرى.');
      }
      if (status == 403) {
        return const BackupException(
            'ليس لدى التطبيق إذن الوصول إلى Google Drive. تأكد من تفعيل '
            'Google Drive API ومن منح الإذن عند تسجيل الدخول.');
      }
      if (status == 404) {
        return const BackupException('لم يتم العثور على النسخة الاحتياطية');
      }
      if (status == 429 || status >= 500) {
        return const BackupException(
            'خدمة Google Drive غير متاحة حاليًا، حاول لاحقًا.');
      }
      return BackupException('خطأ من Google Drive ($status)');
    }

    if (error is FormatException) {
      return const BackupException(
          'ملف النسخة الاحتياطية غير صالح أو تالف');
    }

    return const BackupException('حدث خطأ غير متوقع، حاول مرة أخرى');
  }
}
