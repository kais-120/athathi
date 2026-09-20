import 'dart:io' show BytesBuilder;
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../utils/backup_archive.dart';
import 'backup_errors.dart';

/// A backup file stored on Google Drive.
class DriveBackupFile {
  const DriveBackupFile({
    required this.id,
    required this.name,
    required this.modifiedTime,
    required this.size,
  });

  final String id;
  final String name;
  final DateTime modifiedTime;

  /// In bytes (0 when unknown).
  final int size;
}

/// Google account + Google Drive access, used ONLY for backups.
///
/// Files live in the hidden `appDataFolder` (scope `drive.appdata`): the app
/// cannot see any other file of the user's Drive, and the user does not see
/// these files in the Drive app. Only the latest [keepCount] backups are kept.
class DriveService {
  DriveService()
      : _google = GoogleSignIn(scopes: const [drive.DriveApi.driveAppdataScope]);

  static const int keepCount = 3;
  static const Duration _listTimeout = Duration(seconds: 30);
  static const Duration _transferTimeout = Duration(minutes: 5);

  final GoogleSignIn _google;

  GoogleSignInAccount? get account => _google.currentUser;
  String? get email => _google.currentUser?.email;

  /// Restores a previous session without any dialog. Never throws.
  Future<String?> signInSilently() async {
    try {
      return (await _google.signInSilently())?.email;
    } catch (_) {
      return null;
    }
  }

  /// Returns the e-mail of the connected account, showing the Google account
  /// picker when needed.
  Future<String> ensureSignedIn() async {
    try {
      var current = _google.currentUser;
      if (current == null) {
        try {
          current = await _google.signInSilently();
        } catch (_) {
          current = null;
        }
      }
      current ??= await _google.signIn();
      if (current == null) {
        throw const BackupException('تم إلغاء ربط حساب Google');
      }
      return current.email;
    } catch (error) {
      throw BackupErrors.translate(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Nothing to do: the account is forgotten locally anyway.
    }
  }

  Future<T> _withApi<T>(
    Future<T> Function(drive.DriveApi api) action, {
    Duration timeout = _listTimeout,
  }) async {
    http.Client? client;
    try {
      final account = _google.currentUser ?? await _google.signInSilently();
      if (account == null) {
        throw const BackupException('يجب ربط حساب Google أولًا');
      }
      client = _AuthClient(await account.authHeaders);
      return await action(drive.DriveApi(client)).timeout(timeout);
    } catch (error) {
      throw BackupErrors.translate(error);
    } finally {
      client?.close();
    }
  }

  static DriveBackupFile _toBackup(drive.File f) => DriveBackupFile(
        id: f.id!,
        name: f.name ?? '',
        modifiedTime: (f.modifiedTime ?? DateTime.now()).toLocal(),
        size: int.tryParse(f.size ?? '') ?? 0,
      );

  Future<List<DriveBackupFile>> _list(drive.DriveApi api) async {
    final result = await api.files.list(
      spaces: 'appDataFolder',
      orderBy: 'modifiedTime desc',
      pageSize: 50,
      $fields: 'files(id,name,modifiedTime,size)',
    );
    return [
      for (final f in result.files ?? <drive.File>[])
        if (f.id != null && (f.name ?? '').startsWith(BackupArchive.filePrefix))
          _toBackup(f),
    ]..sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
  }

  /// Backups of the connected account, newest first.
  Future<List<DriveBackupFile>> listBackups() =>
      _withApi((api) => _list(api));

  /// Uploads a new backup, then deletes the oldest ones beyond [keepCount].
  Future<DriveBackupFile> upload(String name, List<int> bytes) {
    return _withApi((api) async {
      final media = drive.Media(
        Stream<List<int>>.value(bytes),
        bytes.length,
        contentType: 'application/zip',
      );
      final metadata = drive.File()
        ..name = name
        ..parents = ['appDataFolder'];
      final created = await api.files.create(
        metadata,
        uploadMedia: media,
        $fields: 'id,name,modifiedTime,size',
      );

      // Pruning is best effort: a failure must not fail the backup itself.
      try {
        final all = await _list(api);
        for (final old in all.skip(keepCount)) {
          await api.files.delete(old.id);
        }
      } catch (_) {}

      return _toBackup(created);
    }, timeout: _transferTimeout);
  }

  Future<Uint8List> download(String fileId) {
    return _withApi((api) async {
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in media.stream) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    }, timeout: _transferTimeout);
  }
}

/// Adds the Google auth headers to every request.
class _AuthClient extends http.BaseClient {
  _AuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
