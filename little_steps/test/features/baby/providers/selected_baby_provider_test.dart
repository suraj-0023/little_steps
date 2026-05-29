import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:little_steps/features/auth/models/app_user.dart';
import 'package:little_steps/features/auth/providers/auth_providers.dart';
import 'package:little_steps/features/baby/providers/selected_baby_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SelectedBabyNotifier Tests', () {
    late Directory tempDir;

    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getTemporaryDirectory') {
            return '/tmp';
          }
          return null;
        },
      );
    });

    setUp(() async {
      tempDir = Directory('/tmp/hive_test_${DateTime.now().millisecondsSinceEpoch}');
      await tempDir.create(recursive: true);
      Hive.init(tempDir.path);
      await Hive.openBox('prefs');
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should build with null if no user and no saved babyId exist', () {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(null),
        ],
      );

      final selectedBabyId = container.read(selectedBabyIdProvider);
      expect(selectedBabyId, isNull);
    });

    test('should fall back to user.babyId if no saved babyId exists in Hive', () {
      const mockUser = AppUser(
        uid: 'user_123',
        displayName: 'John Doe',
        email: 'john@example.com',
        photoUrl: '',
        role: UserRole.admin,
        babyId: 'baby_fallback_123',
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
        ],
      );

      final selectedBabyId = container.read(selectedBabyIdProvider);
      expect(selectedBabyId, 'baby_fallback_123');
    });

    test('should return saved babyId from Hive even if user has a different default babyId', () async {
      const mockUser = AppUser(
        uid: 'user_123',
        displayName: 'John',
        email: 'john@example.com',
        photoUrl: '',
        role: UserRole.admin,
        babyId: 'baby_fallback_123',
      );

      // Seed Hive box
      final box = Hive.box('prefs');
      await box.put('selectedBabyId', 'baby_saved_789');

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
        ],
      );

      final selectedBabyId = container.read(selectedBabyIdProvider);
      expect(selectedBabyId, 'baby_saved_789');
    });

    test('select should update state and persist in Hive', () async {
      const mockUser = AppUser(
        uid: 'user_123',
        displayName: 'John',
        email: 'john@example.com',
        photoUrl: '',
        role: UserRole.admin,
        babyId: 'baby_fallback_123',
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
        ],
      );

      expect(container.read(selectedBabyIdProvider), 'baby_fallback_123');

      // Select new baby
      await container.read(selectedBabyIdProvider.notifier).select('baby_new_456');

      // State is updated
      expect(container.read(selectedBabyIdProvider), 'baby_new_456');

      // Persisted in Hive
      final box = Hive.box('prefs');
      expect(box.get('selectedBabyId'), 'baby_new_456');
    });
  });
}
