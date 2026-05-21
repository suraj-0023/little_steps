import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_drawer.dart';
import 'offline_banner.dart';

final _shellScaffoldKey = GlobalKey<ScaffoldState>();

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static void openDrawer() => _shellScaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        try {
          final location = GoRouterState.of(context).matchedLocation;
          if (location != '/home') {
            context.go('/home');
          }
        } catch (_) {
          // Ignore if GoRouter not in scope (edge case)
        }
      },
      child: Scaffold(
        key: _shellScaffoldKey,
        drawer: const AppDrawer(),
        body: OfflineBanner(child: child),
      ),
    );
  }
}
