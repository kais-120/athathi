import 'package:flutter/material.dart';

import 'app.dart';
import 'app_scope.dart';
import 'app_services.dart';
import 'routes.dart';

/// Owns the [AppServices] and can rebuild them. After a restore replaced the
/// database, [restart] recreates every repository from the new data and
/// starts the UI again from its first screen.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key, required this.services});

  final AppServices services;

  static Future<void> restart(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppRootState>();
    assert(state != null, 'AppRoot not found in the widget tree');
    return state!.restart();
  }

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late AppServices _services = widget.services;
  Key _generation = UniqueKey();

  Future<void> restart() async {
    final fresh = await AppServices.init(previous: _services);
    if (!mounted) return;
    setState(() {
      _services = fresh;
      // A new key rebuilds the whole MaterialApp, so the navigator starts over.
      _generation = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: _services,
      child: AthathiApp(
        key: _generation,
        // The user stays logged in after restarting the app.
        initialRoute:
            _services.auth.isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
      ),
    );
  }
}
