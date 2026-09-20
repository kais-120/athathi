import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'routes.dart';
import 'theme.dart';

/// Root widget: Material 3, Arabic locale, forced RTL.
class AthathiApp extends StatelessWidget {
  const AthathiApp({super.key, required this.initialRoute});

  final String initialRoute;

  static const Locale arabic = Locale('ar');

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أثاثي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: arabic,
      supportedLocales: const [arabic],
      localizationsDelegates: localizationsDelegates,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      initialRoute: initialRoute,
      // By default Flutter builds "/" first and then "/dashboard" on top of
      // it, and "/" falls back to the login screen (so the back arrow of the
      // dashboard led to the login). Build ONLY the requested screen.
      onGenerateInitialRoutes: (String name) => [
        AppRoutes.onGenerateRoute(RouteSettings(name: name)),
      ],
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
