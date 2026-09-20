import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../utils/date_formatter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AppServices _services;
  bool? _biometricSupported; // null while checking

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final supported = await _services.biometric.isSupported();
    if (!mounted) return;
    setState(() => _biometricSupported = supported);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
      ));
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (!enable) {
      await _services.settings.setBiometricEnabled(false);
      return;
    }
    final result = await _services.biometric
        .authenticate('تحقق من هويتك لتفعيل الدخول بالبصمة');
    if (!mounted) return;
    if (result.success) {
      await _services.settings.setBiometricEnabled(true);
    } else {
      _snack(result.message);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من التطبيق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _services.auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListenableBuilder(
        listenable: _services.settings,
        builder: (context, _) {
          final settings = _services.settings.current;
          final supported = _biometricSupported;

          final String biometricStatus;
          if (supported == null) {
            biometricStatus = '...';
          } else if (!supported) {
            biometricStatus = 'البصمة غير متوفرة على هذا الجهاز';
          } else {
            biometricStatus = settings.biometricEnabled ? 'مفعل' : 'غير مفعل';
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.chair_alt_rounded),
                  ),
                  title: Text(settings.businessName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(settings.businessSubtitle),
                ),
              ),
              const SizedBox(height: 20),
              Text('الأمان',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('الدخول بالبصمة',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(biometricStatus),
                  value: supported == true && settings.biometricEnabled,
                  onChanged: supported == true ? _toggleBiometric : null,
                ),
              ),
              const SizedBox(height: 20),
              Text('البيانات',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('النسخ الاحتياطي',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(settings.lastBackupAt == null
                      ? 'لم يتم إنشاء أي نسخة احتياطية بعد'
                      : 'آخر نسخة: ${DateFormatter.dateTime(settings.lastBackupAt!)}'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.backup),
                ),
              ),
              const SizedBox(height: 20),
              Text('الحساب',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(Icons.logout, color: theme.colorScheme.error),
                  title: Text('تسجيل الخروج',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                      )),
                  onTap: _logout,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  '${settings.businessName} • الإصدار 1.0.0',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
