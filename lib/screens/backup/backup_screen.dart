import 'package:flutter/material.dart';

import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/theme.dart';
import '../../services/backup_errors.dart';
import '../../services/drive_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/file_size_formatter.dart';
import '../../widgets/report_widgets.dart';

class _Status {
  const _Status(this.text, this.color, this.icon);

  final String text;
  final Color color;
  final IconData icon;
}

/// النسخ الاحتياطي: connect a Google account, back up to Google Drive now,
/// restore the latest backup. Nothing here blocks the rest of the app.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late final AppServices _services;
  bool _busy = false;
  String _step = '';
  String? _email;
  DriveBackupFile? _remote;
  _Status? _status;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
    _email = _services.backup.drive.email;
    _restoreSession();
  }

  /// Reconnects the previous Google session (no dialog) and looks up the
  /// newest backup. Silent when offline.
  Future<void> _restoreSession() async {
    final drive = _services.backup.drive;
    final email = _email ?? await drive.signInSilently();
    if (!mounted || email == null) return;
    setState(() => _email = email);
    try {
      final latest = await _services.backup.latestBackup();
      if (mounted) setState(() => _remote = latest);
    } catch (_) {
      // Offline or Drive unavailable: the screen still works.
    }
  }

  void _progress(String step) {
    if (mounted) setState(() => _step = step);
  }

  void _fail(Object error) {
    final e = BackupErrors.translate(error);
    if (!mounted) return;
    setState(() => _status = _Status(
          e.message,
          e.offline ? AppColors.warning : AppColors.danger,
          e.offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
        ));
  }

  /// Connects the Google account if needed. Returns false (and shows the
  /// reason) when it could not.
  Future<bool> _ensureConnected() async {
    try {
      final email = await _services.backup.drive.ensureSignedIn();
      if (mounted) setState(() => _email = email);
      return true;
    } catch (error) {
      _fail(error);
      return false;
    }
  }

  Future<void> _connect() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _step = 'جاري ربط حساب Google...';
      _status = null;
    });
    try {
      if (await _ensureConnected()) await _restoreSession();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    if (_busy) return;
    await _services.backup.drive.signOut();
    if (!mounted) return;
    setState(() {
      _email = null;
      _remote = null;
      _status = null;
    });
  }

  Future<void> _backupNow() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _step = 'جاري ربط حساب Google...';
      _status = null;
    });
    try {
      if (!await _ensureConnected()) return;
      final file = await _services.backup.createBackup(onProgress: _progress);
      if (!mounted) return;
      setState(() {
        _remote = file;
        _status = _Status(
          'تم إنشاء النسخة الاحتياطية بنجاح (${DateFormatter.dateTime(file.modifiedTime)}).',
          AppColors.success,
          Icons.cloud_done_outlined,
        );
      });
    } catch (error) {
      _fail(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _step = 'جاري ربط حساب Google...';
      _status = null;
    });
    try {
      if (!await _ensureConnected()) return;

      _progress('جاري البحث عن آخر نسخة احتياطية...');
      final latest = await _services.backup.latestBackup();
      if (!mounted) return;
      if (latest == null) {
        setState(() => _status = const _Status(
              'لا توجد نسخة احتياطية على Google Drive لهذا الحساب.',
              AppColors.info,
              Icons.info_outline_rounded,
            ));
        return;
      }
      setState(() => _remote = latest);

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _ConfirmRestoreDialog(backup: latest),
      );
      if (confirmed != true || !mounted) return;

      await _services.backup.restore(latest, onProgress: _progress);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('تمت الاستعادة'),
          content: const Text(
            'تمت استعادة البيانات والصور بنجاح، وسيُعاد تشغيل التطبيق الآن.\n\n'
            'تم إيقاف الدخول بالبصمة على هذا الجهاز، يمكنك تفعيله من جديد بعد تسجيل الدخول.',
            style: TextStyle(height: 1.6),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('متابعة'),
            ),
          ],
        ),
      );
      if (!mounted) return;

      try {
        await AppRoot.restart(context);
      } catch (_) {
        if (mounted) {
          setState(() => _status = const _Status(
                'تمت الاستعادة، لكن تعذر إعادة تشغيل الواجهة. أغلق التطبيق ثم افتحه من جديد.',
                AppColors.warning,
                Icons.restart_alt_rounded,
              ));
        }
      }
    } catch (error) {
      _fail(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _status;

    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('النسخ الاحتياطي')),
        body: ListenableBuilder(
          listenable: _services.settings,
          builder: (context, _) {
            final lastLocal = _services.settings.current.lastBackupAt;
            final remote = _remote;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.account_circle_outlined),
                    ),
                    title: const Text('حساب Google',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(_email ?? 'غير متصل'),
                    trailing: _email == null
                        ? TextButton(
                            onPressed: _busy ? null : _connect,
                            child: const Text('ربط الحساب'),
                          )
                        : TextButton(
                            onPressed: _busy ? null : _disconnect,
                            child: const Text('قطع الاتصال'),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          label: 'آخر نسخة احتياطية من هذا الجهاز',
                          value: lastLocal == null
                              ? 'لم يتم إنشاء أي نسخة احتياطية بعد'
                              : DateFormatter.dateTime(lastLocal),
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          label: 'آخر نسخة على Google Drive',
                          value: remote == null
                              ? (_email == null ? 'اربط الحساب لعرضها' : '—')
                              : '${DateFormatter.dateTime(remote.modifiedTime)}'
                                  ' • ${FileSizeFormatter.format(remote.size)}',
                        ),
                      ],
                    ),
                  ),
                ),
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(_step,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
                if (status != null) ...[
                  const SizedBox(height: 16),
                  ReportNote(
                      text: status.text, icon: status.icon, color: status.color),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _busy ? null : _backupNow,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('نسخ احتياطي الآن'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _restore,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('استعادة من Google Drive'),
                ),
                const SizedBox(height: 20),
                const ReportNote(
                  text: 'تشمل النسخة الاحتياطية كل البيانات (المنتجات، المبيعات، '
                      'الحرفاء، المشتريات، الموردين، المصاريف، الإعدادات) وصور المنتجات.\n'
                      'تُحفظ في مساحة التطبيق الخاصة على Google Drive ولا يستطيع أي تطبيق آخر رؤيتها، '
                      'ويُحتفظ بآخر ${DriveService.keepCount} نسخ.\n'
                      'التطبيق يعمل بشكل كامل بدون إنترنت، والإنترنت مطلوب فقط عند النسخ أو الاستعادة.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ConfirmRestoreDialog extends StatelessWidget {
  const _ConfirmRestoreDialog({required this.backup});

  final DriveBackupFile backup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded,
          color: theme.colorScheme.error, size: 32),
      title: const Text('استعادة النسخة الاحتياطية'),
      content: Text(
        'سيتم استبدال كل البيانات والصور الموجودة حاليًا على هذا الجهاز '
        'بمحتوى هذه النسخة:\n\n'
        'التاريخ: ${DateFormatter.dateTime(backup.modifiedTime)}\n'
        'الحجم: ${FileSizeFormatter.format(backup.size)}\n\n'
        'لا يمكن التراجع عن هذه العملية. هل تريد المتابعة؟',
        style: const TextStyle(height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            minimumSize: const Size(120, 44),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('استعادة'),
        ),
      ],
    );
  }
}
