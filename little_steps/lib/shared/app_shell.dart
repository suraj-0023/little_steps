import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', path: '/home'),
    (icon: Icons.timeline_outlined, activeIcon: Icons.timeline, label: 'Timeline', path: '/timeline'),
    (icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories, label: 'Stories', path: '/stories'),
    (icon: Icons.show_chart_outlined, activeIcon: Icons.show_chart, label: 'Growth', path: '/growth'),
    (icon: Icons.people_outline, activeIcon: Icons.people, label: 'Family', path: '/family'),
  ];

  int _indexFromPath(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromPath(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].path),
        destinations: _tabs.map((tab) => NavigationDestination(
          icon: Icon(tab.icon),
          selectedIcon: Icon(tab.activeIcon, color: AppColors.primary),
          label: tab.label,
        )).toList(),
      ),
    );
  }
}
