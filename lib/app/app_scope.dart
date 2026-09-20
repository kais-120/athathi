import 'package:flutter/widgets.dart';

import 'app_services.dart';

/// Makes [AppServices] available to the whole widget tree:
/// `final services = AppScope.of(context);`
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  /// Safe to call from `initState` (does not subscribe to changes, the
  /// services never change during the app's lifetime).
  static AppServices of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in the widget tree');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      services != oldWidget.services;
}
