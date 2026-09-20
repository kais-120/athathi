import 'package:flutter/services.dart' show PlatformException;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// Result of a biometric prompt. When it failed, [message] says why in
/// Arabic (with the technical code in brackets, useful to fix the setup).
class BiometricResult {
  const BiometricResult.success()
      : success = true,
        message = '';

  const BiometricResult.failure(this.message) : success = false;

  final bool success;
  final String message;
}

/// Thin wrapper around `local_auth`.
///
/// The operating system performs the verification (fingerprint, face, ...).
/// The app never sees or stores any biometric data.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// True when the device has biometric hardware or a secure lock screen.
  ///
  /// It does NOT require `getAvailableBiometrics()` to be non-empty: on many
  /// Android phones that list comes back empty even with a fingerprint
  /// enrolled, which used to hide the feature. A missing enrolment is
  /// reported by [authenticate] with a clear message instead.
  Future<bool> isSupported() async {
    var supported = false;
    try {
      supported = await _auth.isDeviceSupported();
    } catch (_) {}
    if (supported) return true;
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system biometric prompt.
  Future<BiometricResult> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'الدخول بالبصمة',
            biometricHint: 'تحقق من هويتك',
            biometricNotRecognized: 'لم يتم التعرف على البصمة، حاول مجددًا',
            biometricRequiredTitle: 'البصمة مطلوبة',
            biometricSuccess: 'تم التحقق بنجاح',
            cancelButton: 'إلغاء',
            goToSettingsButton: 'الإعدادات',
            goToSettingsDescription:
                'لم يتم إعداد البصمة على هذا الجهاز. يرجى إعدادها من إعدادات الهاتف.',
          ),
        ],
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return ok
          ? const BiometricResult.success()
          : const BiometricResult.failure('لم يتم التحقق من البصمة');
    } on PlatformException catch (e) {
      return BiometricResult.failure(_describe(e));
    } catch (e) {
      return BiometricResult.failure('تعذر التحقق بالبصمة ($e)');
    }
  }

  static String _describe(PlatformException e) {
    final text = '${e.code} ${e.message ?? ''}';
    final String reason;
    if (e.code == 'no_fragment_activity' ||
        text.contains('FragmentActivity')) {
      reason = 'إعداد Android غير مكتمل: يجب أن ترث MainActivity من '
          'FlutterFragmentActivity (انظر README).';
    } else if (text.contains('AppCompat')) {
      reason = 'إعداد Android غير مكتمل: غيّر Theme في styles.xml إلى '
          'Theme.AppCompat.DayNight (انظر README).';
    } else {
      reason = switch (e.code) {
        'NotEnrolled' => 'لم يتم تسجيل أي بصمة على هذا الهاتف. '
            'أضف بصمة من إعدادات الهاتف ثم أعد المحاولة.',
        'NotAvailable' => 'البصمة غير متوفرة على هذا الجهاز.',
        'PasscodeNotSet' => 'يجب تفعيل قفل الشاشة على الهاتف أولًا.',
        'LockedOut' => 'تم إيقاف البصمة مؤقتًا بسبب كثرة المحاولات، '
            'حاول بعد قليل.',
        'PermanentlyLockedOut' =>
          'تم قفل البصمة. افتح الهاتف بالرمز السري ثم أعد المحاولة.',
        'auth_in_progress' => 'عملية تحقق أخرى قيد التنفيذ.',
        _ => 'تعذر التحقق بالبصمة.',
      };
    }
    return '$reason (${e.code})';
  }
}
