import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/baby/screens/baby_setup_screen.dart';
import '../../features/baby/screens/baby_profile_edit_screen.dart';
import '../../features/baby/screens/parent_profile_edit_screen.dart';
import '../../features/collage/screens/collage_screen.dart';
import '../../features/export/screens/memory_albums_screen.dart';
import '../../features/export/screens/album_preview_screen.dart';
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
import '../../features/settings/screens/about_screen.dart';
import '../../features/settings/screens/privacy_policy_screen.dart';
import '../../features/settings/screens/rate_app_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/stories/screens/stories_screen.dart';
import '../../features/stories/screens/story_detail_screen.dart';
import '../../features/stories/screens/edit_story_screen.dart';
import '../../features/timeline/screens/add_milestone_screen.dart';
import '../../features/timeline/screens/timeline_screen.dart';
import '../../features/settings/screens/more_hub_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
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
          GoRoute(path: '/home', builder: (context, state) => const CollageScreen()),
          GoRoute(path: '/timeline', builder: (context, state) => const TimelineScreen()),
          GoRoute(path: '/stories', builder: (context, state) => const StoriesScreen()),
          GoRoute(path: '/growth', builder: (context, state) => const GrowthScreen()),
          GoRoute(path: '/family', builder: (context, state) => const FamilyScreen()),
          GoRoute(path: '/letters', builder: (context, state) => const LettersScreen()),
          GoRoute(path: '/export', builder: (context, state) => const MemoryAlbumsScreen()),
          GoRoute(path: '/reel', builder: (context, state) => const ReelScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
          GoRoute(path: '/more', builder: (context, state) => const MoreHubScreen()),
        ],
      ),
      GoRoute(
        path: '/export/preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AlbumPreviewScreen(
            pdfFile: extra['pdfFile'] as File,
            albumName: extra['albumName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/memory/:memoryId',
        builder: (context, state) =>
            MemoryDetailScreen(memoryId: state.pathParameters['memoryId']!),
      ),
      GoRoute(
        path: '/family/invite',
        builder: (context, state) => const InviteScreen(),
      ),
      GoRoute(
        path: '/stories/:storyId',
        builder: (context, state) =>
            StoryDetailScreen(storyId: state.pathParameters['storyId']!),
      ),
      GoRoute(
        path: '/stories/:storyId/edit',
        builder: (context, state) =>
            EditStoryScreen(storyId: state.pathParameters['storyId']!),
      ),
      GoRoute(
        path: '/timeline/add-milestone',
        builder: (context, state) => const AddMilestoneScreen(),
      ),
      GoRoute(
        path: '/letters/write',
        builder: (context, state) => const WriteLetterScreen(),
      ),
      GoRoute(
        path: '/letters/:letterId',
        builder: (context, state) =>
            LetterDetailScreen(letterId: state.pathParameters['letterId']!),
      ),
      GoRoute(
        path: '/settings/rate',
        builder: (context, state) => const RateAppScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/settings/baby-edit',
        builder: (context, state) => const BabyProfileEditScreen(),
      ),
      GoRoute(
        path: '/settings/parents-edit',
        builder: (context, state) => const ParentProfileEditScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
    ],
  );
});
