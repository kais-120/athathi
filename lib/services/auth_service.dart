import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'local_storage_service.dart';

/// Local (offline) authentication. There is no backend.
///
/// The password is never stored in clear text: only a salted SHA-256 hash.
/// The "logged in" flag is persisted so the user stays logged in after
/// restarting the app.
class AuthService {
  AuthService(this._storage);

  final LocalStorageService _storage;

  static const String defaultUsername = 'admin';
  static const String defaultPassword = '123456';

  static const String _kUsername = 'username';
  static const String _kSalt = 'salt';
  static const String _kHash = 'hash';
  static const String _kLoggedIn = 'loggedIn';

  dynamic _read(String key) =>
      _storage.box(LocalStorageService.authBox).get(key);

  Future<void> _write(String key, dynamic value) =>
      _storage.box(LocalStorageService.authBox).put(key, value);

  /// Creates the initial admin account on first launch.
  Future<void> ensureDefaultUser() async {
    if (_read(_kHash) != null) return;
    final salt = _newSalt();
    await _write(_kUsername, defaultUsername);
    await _write(_kSalt, salt);
    await _write(_kHash, _hash(salt, defaultPassword));
  }

  bool get isLoggedIn => _read(_kLoggedIn) == true;

  Future<bool> login(String username, String password) async {
    final storedUser = _read(_kUsername) as String?;
    final salt = _read(_kSalt) as String?;
    final storedHash = _read(_kHash) as String?;
    if (storedUser == null || salt == null || storedHash == null) return false;

    final valid =
        username.trim() == storedUser && _hash(salt, password) == storedHash;
    if (valid) await _write(_kLoggedIn, true);
    return valid;
  }

  /// Called after the OS successfully verified the user's biometrics.
  Future<void> markLoggedIn() => _write(_kLoggedIn, true);

  Future<void> logout() => _write(_kLoggedIn, false);

  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  String _newSalt() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }
}
