import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/baby/screens/baby_setup_screen.dart';
import '../../features/collage/screens/collage_screen.dart';
import '../../features/export/screens/export_screen.dart';
import '../../features/export/screens/reel_screen.dart';
import '../../features/family/screens/family_screen.dart';
import '../../features/family/screens/invite_screen.dart';
import '../../features/family/screens/join_family_screen.dart';
import '../../features/growth/screens/growth_screen.dart';
import '../../features/letters/screens/letter_detail_screen.dart';
import '../../features/letters/screens/letters_screen.dart';
import '../../features/letters/screens/write_letter_screen.dart';
import '../../features/memory/screens/memory_detail_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/stories/screens/stories_screen.dart';
import '../../features/stories/screens/story_detail_screen.dart';
import '../../features/timeline/screens/add_milestone_screen.dart';
import '../../features/timeline/screens/timeline_screen.dart';
import '../../shared/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/auth';
      final isOnboardingRoute = loc == '/onboarding';
      final isSetupRoute = loc == '/baby/setup';
      final isJoinRoute = loc == '/join';

      if (!isLoggedIn && !isOnboardingRoute && !onboardingDoneSync) return '/onboarding';
      if (!isLoggedIn && !isAuthRoute && !isOnboardingRoute) return '/auth';
      if (isLoggedIn && isAuthRoute) {
        return user.hasFamily ? '/home' : '/baby/setup';
      }
      if (isLoggedIn && !user.hasFamily && !isSetupRoute && !isJoinRoute) {
        return '/baby/setup';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/baby/setup',
        builder: (context, state) => const BabySetupScreen(),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => const JoinFamilyScreen(),
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
        path: '/family/invite',
        builder: (context, state) => const InviteScreen(),
      ),
      GoRoute(
        path: '/stories/:storyId',
        builder: (context, state) => StoryDetailScreen(
          storyId: state.pathParameters['storyId']!,
        ),
      ),
      GoRoute(
        path: '/timeline/add-milestone',
        builder: (context, state) => const AddMilestoneScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/letters',
        builder: (context, state) => const LettersScreen(),
      ),
      GoRoute(
        path: '/letters/write',
        builder: (context, state) => const WriteLetterScreen(),
      ),
      GoRoute(
        path: '/letters/:letterId',
        builder: (context, state) => LetterDetailScreen(
          letterId: state.pathParameters['letterId']!,
        ),
      ),
      GoRoute(
        path: '/export',
        builder: (context, state) => const ExportScreen(),
      ),
      GoRoute(
        path: '/reel',
        builder: (context, state) => const ReelScreen(),
      ),
    ],
  );
});
