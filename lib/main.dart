import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_root.dart';
import 'app/app_services.dart';
import 'app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final services = await AppServices.init();
    runApp(AppRoot(services: services));
  } catch (error, stackTrace) {
    debugPrint('Startup failure: $error\n$stackTrace');
    runApp(const _StartupErrorApp());
  }
}

/// Shown only if the local database cannot be opened.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: AthathiApp.arabic,
      supportedLocales: const [AthathiApp.arabic],
      localizationsDelegates: AthathiApp.localizationsDelegates,
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'تعذر فتح قاعدة بيانات التطبيق.\nأعد تشغيل التطبيق، وإذا استمرت المشكلة أعد تشغيل الهاتف.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
        ),
      ),
    );
  }
}
