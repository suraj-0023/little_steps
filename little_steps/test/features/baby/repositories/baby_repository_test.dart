import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_steps/features/baby/repositories/baby_repository.dart';
import 'package:little_steps/features/baby/models/baby.dart';
import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';
import '../../../fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BabyRepository Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FakeFirebaseStorage fakeStorage;
    late BabyRepository babyRepository;

    setUpAll(() {
      FlutterImageCompressPlatform.instance = FakeFlutterImageCompressPlatform();

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

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      fakeStorage = FakeFirebaseStorage();
      babyRepository = BabyRepository(
        firestore: fakeFirestore,
        storage: fakeStorage,
      );
    });

    test('createBaby should write family, baby, and user documents in a batch', () async {
      // Seed user doc first
      fakeFirestore.setData('users/user_123', {
        'displayName': 'John Doe',
        'email': 'john@example.com',
        'role': 'viewer',
      });

      final baby = await babyRepository.createBaby(
        familyId: 'family_123',
        uid: 'user_123',
        name: 'Jane Doe',
        dob: DateTime(2026, 1, 1),
        nickname: 'Janey',
      );

      expect(baby.name, 'Jane Doe');
      expect(baby.nickname, 'Janey');
      expect(baby.familyId, 'family_123');

      // Verify user document was updated
      final userDoc = fakeFirestore.getData('users/user_123');
      expect(userDoc, isNotNull);
      expect(userDoc!['familyId'], 'family_123');
      expect(userDoc['babyId'], baby.id);
      expect(userDoc['role'], 'admin');

      // Verify family document was created
      final familyDoc = fakeFirestore.getData('families/family_123');
      expect(familyDoc, isNotNull);
      expect(familyDoc!['activeBabyId'], baby.id);
      expect(familyDoc['adminUid'], 'user_123');
      expect(familyDoc['members'], contains('user_123'));

      // Verify baby document was created under subcollection
      final babyDoc = fakeFirestore.getData('families/family_123/babies/${baby.id}');
      expect(babyDoc, isNotNull);
      expect(babyDoc!['name'], 'Jane Doe');
      expect(babyDoc['nickname'], 'Janey');
    });

    test('watchBaby should emit baby data when updated in Firestore', () async {
      final dob = DateTime(2026, 1, 1);
      final createdAt = DateTime(2026, 1, 1);

      // Seed baby data
      fakeFirestore.setData('families/family_123/babies/baby_123', {
        'familyId': 'family_123',
        'name': 'Jane Doe',
        'nickname': 'Janey',
        'dob': dob.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'isUnborn': false,
        'useNicknameDisplay': false,
      });

      final stream = babyRepository.watchBaby('family_123', 'baby_123');
      final futureList = stream.take(2).toList();

      // Trigger update asynchronously
      Timer(const Duration(milliseconds: 100), () async {
        final baby = Baby(
          id: 'baby_123',
          familyId: 'family_123',
          name: 'Jane Smith',
          nickname: 'Janey',
          createdAt: createdAt,
          dob: dob,
        );
        await babyRepository.updateBaby(baby);
      });

      final results = await futureList;
      expect(results.length, 2);
      expect(results[0], isNotNull);
      expect(results[0]!.name, 'Jane Doe');
      expect(results[1], isNotNull);
      expect(results[1]!.name, 'Jane Smith');
    });

    test('uploadCoverPhoto should compress and upload file to Storage', () async {
      // Create a mock temp file
      final mockFile = File('/tmp/test_image.jpg');
      
      // In tests, the actual writing of files is limited, so we can mock/fake File stat
      // but ExifExtractor fallback handles file read exceptions.
      // To prevent readAsBytes exception during ExifExtractor, let's write a small byte array to the mockFile.
      await mockFile.writeAsBytes([0, 0, 0, 0]);

      final url = await babyRepository.uploadCoverPhoto('family_123', 'baby_123', mockFile);

      expect(url, contains('families%2Ffamily_123%2Fbabies%2Fbaby_123%2Fcover.jpg'));
      expect(fakeStorage.uploadedPaths, contains('families/family_123/babies/baby_123/cover.jpg'));

      // Clean up local temp file
      if (await mockFile.exists()) {
        await mockFile.delete();
      }
    });
  });
}
