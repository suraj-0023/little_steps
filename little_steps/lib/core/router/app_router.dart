import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/baby/screens/baby_setup_screen.dart';
import '../../features/collage/screens/collage_screen.dart';
import '../../features/memory/screens/memory_detail_screen.dart';
import '../../features/timeline/screens/timeline_screen.dart';
import '../../features/stories/screens/stories_screen.dart';
import '../../features/growth/screens/growth_screen.dart';
import '../../features/family/screens/family_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation == '/auth';
      final isSetupRoute = state.matchedLocation == '/baby/setup';

      if (!isLoggedIn && !isAuthRoute) return '/auth';
      if (isLoggedIn && isAuthRoute) {
        return user.hasFamily ? '/home' : '/baby/setup';
      }
      if (isLoggedIn && !user.hasFamily && !isSetupRoute) return '/baby/setup';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/baby/setup',
        builder: (context, state) => const BabySetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const CollageScreen(),
          ),
          GoRoute(
            path: '/timeline',
            builder: (context, state) => const TimelineScreen(),
          ),
          GoRoute(
            path: '/stories',
            builder: (context, state) => const StoriesScreen(),
          ),
          GoRoute(
            path: '/growth',
            builder: (context, state) => const GrowthScreen(),
          ),
          GoRoute(
            path: '/family',
            builder: (context, state) => const FamilyScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/memory/:memoryId',
        builder: (context, state) => MemoryDetailScreen(
          memoryId: state.pathParameters['memoryId']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
