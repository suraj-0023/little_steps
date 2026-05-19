import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_drawer.dart';
import 'offline_banner.dart';

/// Global key so any child screen can call [AppShell.openDrawer] from its AppBar.
final _shellScaffoldKey = GlobalKey<ScaffoldState>();

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  /// Opens the navigation drawer from anywhere inside the shell.
  static void openDrawer() => _shellScaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: _shellScaffoldKey,
      drawer: const AppDrawer(),
      body: OfflineBanner(child: child),
    );
  }
}
