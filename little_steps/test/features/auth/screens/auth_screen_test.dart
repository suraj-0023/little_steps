import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:little_steps/core/constants/app_strings.dart';
import 'package:little_steps/features/auth/providers/auth_providers.dart';
import 'package:little_steps/features/auth/repositories/auth_repository.dart';
import 'package:little_steps/features/auth/screens/auth_screen.dart';
import 'package:little_steps/features/auth/models/app_user.dart';
import 'package:mockito/mockito.dart';

class MockAuthRepository extends Fake implements AuthRepository {
  AppUser? mockUser;
  bool shouldThrow = false;
  bool signInCalled = false;
  String exceptionMessage = 'Sign-in failed';

  @override
  Future<AppUser> signInWithGoogle() async {
    signInCalled = true;
    await Future.delayed(const Duration(milliseconds: 50));
    if (shouldThrow) {
      throw Exception(exceptionMessage);
    }
    return mockUser ?? const AppUser(
      uid: 'user123',
      displayName: 'John Doe',
      email: 'john@example.com',
      photoUrl: 'https://example.com/john.jpg',
      role: UserRole.admin,
      familyId: 'family123', // Has family, should route to /home
    );
  }
}

void main() {
  group('AuthScreen Widget Tests', () {
    late MockAuthRepository mockAuthRepository;
    late GoRouter router;
    bool navigatedToHome = false;
    bool navigatedToSetup = false;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      navigatedToHome = false;
      navigatedToSetup = false;

      router = GoRouter(
        initialLocation: '/auth',
        routes: [
          GoRoute(
            path: '/auth',
            builder: (context, state) => const AuthScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) {
              navigatedToHome = true;
              return const Scaffold(body: Text('Home Screen'));
            },
          ),
          GoRoute(
            path: '/baby/setup',
            builder: (context, state) {
              navigatedToSetup = true;
              return const Scaffold(body: Text('Baby Setup Screen'));
            },
          ),
        ],
      );
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('should render all UI components correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify app logo icon
      expect(find.byIcon(Icons.child_care), findsOneWidget);

      // Verify app name
      expect(find.text(AppStrings.appName), findsOneWidget);

      // Verify tagline
      expect(find.text(AppStrings.tagline), findsOneWidget);

      // Verify sign in button
      expect(find.text(AppStrings.signInWithGoogle), findsOneWidget);
    });

    testWidgets('should show loading indicator and navigate to /home on successful sign-in with family', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final button = find.text(AppStrings.signInWithGoogle);
      expect(button, findsOneWidget);

      await tester.tap(button);
      // Pump to trigger build with loading = true
      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(AppStrings.signInWithGoogle), findsNothing);

      // Wait for future to complete and pump navigation
      await tester.pumpAndSettle();

      expect(mockAuthRepository.signInCalled, true);
      expect(navigatedToHome, true);
      expect(navigatedToSetup, false);
    });

    testWidgets('should navigate to /baby/setup on successful sign-in without family', (WidgetTester tester) async {
      // User with no family
      mockAuthRepository.mockUser = const AppUser(
        uid: 'user_new_789',
        displayName: 'Alice',
        email: 'alice@example.com',
        photoUrl: '',
        role: UserRole.admin,
      );

      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text(AppStrings.signInWithGoogle));
      await tester.pump(); // build loading
      await tester.pumpAndSettle(); // navigation complete

      expect(mockAuthRepository.signInCalled, true);
      expect(navigatedToHome, false);
      expect(navigatedToSetup, true);
    });

    testWidgets('should show SnackBar when sign-in fails', (WidgetTester tester) async {
      mockAuthRepository.shouldThrow = true;
      mockAuthRepository.exceptionMessage = 'Sign-in cancelled';

      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text(AppStrings.signInWithGoogle));
      await tester.pump(); // trigger loading
      await tester.pumpAndSettle(); // settle animations and SnackBar

      expect(mockAuthRepository.signInCalled, true);
      expect(navigatedToHome, false);
      expect(navigatedToSetup, false);

      // Verify SnackBar shown with message
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Sign-in cancelled'), findsOneWidget);
    });
  });
}
