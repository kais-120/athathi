import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/local_storage_service.dart';

/// Holds the current [AppSettings] and persists every change locally.
/// Listen to it (ListenableBuilder) to rebuild when a setting changes.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository(this._storage) {
    final map = _storage.get(LocalStorageService.settingsBox, _key);
    _current = map == null ? const AppSettings() : AppSettings.fromMap(map);
  }

  static const String _key = 'app';

  final LocalStorageService _storage;
  late AppSettings _current;

  AppSettings get current => _current;

  Future<void> update(AppSettings settings) async {
    _current = settings;
    await _storage.put(LocalStorageService.settingsBox, _key, settings.toMap());
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) =>
      update(_current.copyWith(biometricEnabled: enabled));

  Future<void> setOpeningBalance(double amount) =>
      update(_current.copyWith(openingBalance: amount));

  Future<void> markBiometricPrompted() =>
      update(_current.copyWith(biometricPrompted: true));

  Future<void> setLastBackupAt(DateTime time) =>
      update(_current.copyWith(lastBackupAt: time));

  /// After a restore replaced the settings box: re-reads the restored
  /// settings, shows the restored backup's date as the last backup, and
  /// switches biometric login off (it belongs to the phone, and the login
  /// screen will offer it again).
  Future<void> restoredFromBackup(DateTime backupTime) async {
    final map = _storage.get(LocalStorageService.settingsBox, _key);
    _current = map == null ? const AppSettings() : AppSettings.fromMap(map);
    await update(_current.copyWith(
      biometricEnabled: false,
      biometricPrompted: false,
      lastBackupAt: backupTime,
    ));
  }
}
