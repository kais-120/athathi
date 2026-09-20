import 'dart:io';

import '../models/enums.dart';
import '../repositories/activity_repository.dart';
import '../repositories/settings_repository.dart';
import '../utils/backup_archive.dart';
import 'backup_errors.dart';
import 'drive_service.dart';
import 'image_service.dart';
import 'local_storage_service.dart';

/// PART 7: creates a backup (database + product pictures) on Google Drive and
/// restores it. The app never depends on this: everything works offline and
/// every failure ends as a [BackupException] with an Arabic message.
class BackupService {
  BackupService({
    required this.storage,
    required this.images,
    required this.settings,
    required this.activities,
    required this.drive,
  });

  final LocalStorageService storage;
  final ImageService images;
  final SettingsRepository settings;
  final ActivityRepository activities;
  final DriveService drive;

  /// The newest backup of the connected Google account, or `null`.
  Future<DriveBackupFile?> latestBackup() async {
    final all = await drive.listBackups();
    return all.isEmpty ? null : all.first;
  }

  // ----------------------------------------------------------------- backup

  /// Exports the database + pictures, uploads them, then records the date.
  /// The Google account must already be connected ([DriveService.ensureSignedIn]).
  Future<DriveBackupFile> createBackup({
    void Function(String step)? onProgress,
  }) async {
    try {
      onProgress?.call('جاري تجهيز البيانات والصور...');
      final data = storage.exportAll();
      final imageBytes = await _readImages();
      final bytes = BackupArchive.build(data, imageBytes);

      onProgress?.call('جاري الرفع إلى Google Drive...');
      final now = DateTime.now();
      final file = await drive.upload(BackupArchive.fileNameFor(now), bytes);

      await settings.setLastBackupAt(now);
      await activities.log(ActivityType.backupCreated, 'Google Drive');
      return file;
    } catch (error) {
      throw BackupErrors.translate(error);
    }
  }

  Future<Map<String, List<int>>> _readImages() async {
    final result = <String, List<int>>{};
    final dir = images.directory;
    if (!await dir.exists()) return result;
    await for (final entity in dir.list()) {
      if (entity is File) {
        result[entity.uri.pathSegments.last] = await entity.readAsBytes();
      }
    }
    return result;
  }

  // ---------------------------------------------------------------- restore

  /// Replaces ALL local data with [backup]. The caller must rebuild the
  /// services afterwards (the repositories cache their data in memory).
  ///
  /// The file is downloaded and fully checked before anything is touched; if
  /// the import fails half way the previous data is put back.
  Future<void> restore(
    DriveBackupFile backup, {
    void Function(String step)? onProgress,
  }) async {
    try {
      onProgress?.call('جاري تنزيل النسخة الاحتياطية...');
      final bytes = await drive.download(backup.id);

      onProgress?.call('جاري فحص النسخة الاحتياطية...');
      final contents = BackupArchive.parse(bytes);
      final version = contents.data['version'];
      if (version is num && version > LocalStorageService.backupFormatVersion) {
        throw const BackupException(
            'هذه النسخة أُنشئت بإصدار أحدث من التطبيق، حدّث التطبيق ثم أعد المحاولة.');
      }

      onProgress?.call('جاري استعادة البيانات والصور...');
      final previous = storage.exportAll();
      final newFiles = <String>[];
      try {
        for (final entry in contents.images.entries) {
          final file = File(images.pathOf(entry.key));
          if (!await file.exists()) newFiles.add(entry.key);
          await file.writeAsBytes(entry.value, flush: true);
        }
        await storage.importAll(contents.data);
      } catch (_) {
        // Put the previous data back before reporting the failure.
        try {
          await storage.importAll(previous);
        } catch (_) {}
        await images.deleteAll(newFiles);
        rethrow;
      }

      await _deleteOtherImages(contents.images.keys.toSet());
      await settings.restoredFromBackup(backup.modifiedTime);
    } catch (error) {
      throw BackupErrors.translate(error);
    }
  }

  /// Pictures that are not part of the restored backup belong to data that
  /// no longer exists.
  Future<void> _deleteOtherImages(Set<String> keep) async {
    final dir = images.directory;
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File && !keep.contains(entity.uri.pathSegments.last)) {
        try {
          await entity.delete();
        } on FileSystemException {
          // A leftover picture is harmless.
        }
      }
    }
  }
}
