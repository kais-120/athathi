import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  late final AppServices _services;
  bool _obscure = true;
  bool _loading = false;
  bool _biometricSupported = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
    _checkBiometric();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final supported = await _services.biometric.isSupported();
    if (!mounted) return;
    setState(() => _biometricSupported = supported);
  }

  bool get _showBiometricButton =>
      _biometricSupported && _services.settings.current.biometricEnabled;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
      ));
  }

  void _goToDashboard() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
      (route) => false,
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await _services.auth
        .login(_usernameController.text, _passwordController.text);
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _loading = false;
        _error = 'اسم المستخدم أو كلمة المرور غير صحيحة';
      });
      return;
    }

    await _offerBiometric();
    if (!mounted) return;
    _goToDashboard();
  }

  /// Asked once, right after the first successful password login.
  Future<void> _offerBiometric() async {
    final settings = _services.settings;
    if (!_biometricSupported ||
        settings.current.biometricEnabled ||
        settings.current.biometricPrompted) {
      return;
    }

    final wantsEnable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.fingerprint, size: 40),
        title: const Text('الدخول بالبصمة'),
        content: const Text('هل تريد تفعيل الدخول بالبصمة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('لاحقًا'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تفعيل'),
          ),
        ],
      ),
    );

    await settings.markBiometricPrompted();
    if (wantsEnable != true) return;

    final result = await _services.biometric
        .authenticate('تحقق من هويتك لتفعيل الدخول بالبصمة');
    if (result.success) {
      await settings.setBiometricEnabled(true);
    } else if (mounted) {
      _snack(result.message);
    }
  }

  Future<void> _biometricLogin() async {
    setState(() => _error = null);
    final result = await _services.biometric
        .authenticate('تحقق من هويتك لتسجيل الدخول');
    if (!mounted) return;

    if (!result.success) {
      _snack(result.message);
      return;
    }
    await _services.auth.markLoggedIn();
    if (!mounted) return;
    _snack('تم تسجيل الدخول بنجاح');
    _goToDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = _services.settings.current;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primaryContainer,
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0, 0.55],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(Icons.chair_alt_rounded,
                          size: 52, color: scheme.onPrimary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      settings.businessName,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settings.businessSubtitle,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _usernameController,
                                enabled: !_loading,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) =>
                                    _passwordFocus.requestFocus(),
                                validator: Validators.username,
                                decoration: const InputDecoration(
                                  labelText: 'اسم المستخدم',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                enabled: !_loading,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                validator: Validators.password,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure
                                        ? 'إظهار كلمة المرور'
                                        : 'إخفاء كلمة المرور',
                                    icon: Icon(_obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: scheme.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: scheme.onErrorContainer),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                              color: scheme.onErrorContainer),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: scheme.onPrimary,
                                        ),
                                      )
                                    : const Text('تسجيل الدخول'),
                              ),
                              if (_showBiometricButton) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _loading ? null : _biometricLogin,
                                  icon: const Icon(Icons.fingerprint, size: 26),
                                  label: const Text('الدخول بالبصمة'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
