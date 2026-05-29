import 'package:flutter_test/flutter_test.dart';
import 'package:little_steps/features/auth/repositories/auth_repository.dart';
import 'package:little_steps/features/auth/models/app_user.dart';
import '../../../fakes.dart';

void main() {
  group('AuthRepository Tests', () {
    late FakeFirebaseAuth fakeAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late FakeGoogleSignIn fakeGoogleSignIn;
    late AuthRepository authRepository;

    setUp(() {
      fakeAuth = FakeFirebaseAuth();
      fakeFirestore = FakeFirebaseFirestore();
      fakeGoogleSignIn = FakeGoogleSignIn();
      authRepository = AuthRepository(
        auth: fakeAuth,
        firestore: fakeFirestore,
        googleSignIn: fakeGoogleSignIn,
      );
    });

    tearDown(() {
      fakeAuth.dispose();
    });

    test('authStateChanges should emit null when no user is logged in', () async {
      final stream = authRepository.authStateChanges();
      expect(await stream.first, isNull);
    });

    test('authStateChanges should emit AppUser when user is logged in and exists in Firestore', () async {
      // Setup Firestore data
      fakeFirestore.setData('users/user_123', {
        'displayName': 'John Doe',
        'email': 'john@example.com',
        'photoUrl': 'https://example.com/john.jpg',
        'role': 'admin',
        'familyId': 'family_123',
        'babyId': 'baby_123',
      });

      final stream = authRepository.authStateChanges();

      // Trigger auth state change
      fakeAuth.triggerAuthStateChange(FakeUser(uid: 'user_123'));

      // Skip the initial null (since broadcast controller was initialized with null)
      // and wait for the second emission.
      final user = await stream.skip(1).first;

      expect(user, isNotNull);
      expect(user!.uid, 'user_123');
      expect(user.displayName, 'John Doe');
      expect(user.role, UserRole.admin);
    });

    test('authStateChanges should fetch or create user if not in Firestore', () async {
      final stream = authRepository.authStateChanges();

      // Trigger auth state change to a new user
      fakeAuth.triggerAuthStateChange(FakeUser(
        uid: 'user_456',
        displayName: 'Jane Doe',
        email: 'jane@example.com',
        photoURL: 'https://example.com/jane.jpg',
      ));

      final user = await stream.skip(1).first;

      expect(user, isNotNull);
      expect(user!.uid, 'user_456');
      expect(user.displayName, 'Jane Doe');
      expect(user.role, UserRole.admin); // Default role created is admin

      // Verify written to firestore
      final savedData = fakeFirestore.getData('users/user_456');
      expect(savedData, isNotNull);
      expect(savedData!['displayName'], 'Jane Doe');
      expect(savedData['role'], 'admin');
    });

    test('signInWithGoogle should complete successfully and create user in Firestore', () async {
      final user = await authRepository.signInWithGoogle();

      expect(user.uid, 'google_user_123');
      expect(user.displayName, 'Test User');
      expect(user.role, UserRole.admin);

      final savedData = fakeFirestore.getData('users/google_user_123');
      expect(savedData, isNotNull);
      expect(savedData!['displayName'], 'Test User');
    });

    test('signInWithGoogle throws exception when cancelled', () async {
      fakeGoogleSignIn.setShouldCancel(true);
      expect(
        () => authRepository.signInWithGoogle(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('cancelled'))),
      );
    });

    test('signOut should invoke sign out on auth and google sign in', () async {
      // First sign in
      await authRepository.signInWithGoogle();
      expect(fakeAuth.currentUser, isNotNull);

      await authRepository.signOut();
      expect(fakeAuth.currentUser, isNull);
    });

    test('updateFcmToken should update token field in Firestore', () async {
      fakeFirestore.setData('users/user_789', {
        'displayName': 'Alice',
        'role': 'editor',
      });

      await authRepository.updateFcmToken('user_789', 'fcm_token_xyz');

      final savedData = fakeFirestore.getData('users/user_789');
      expect(savedData, isNotNull);
      expect(savedData!['fcmToken'], 'fcm_token_xyz');
    });
  });
}
