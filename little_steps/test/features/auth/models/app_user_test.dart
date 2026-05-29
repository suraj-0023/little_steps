import 'package:flutter_test/flutter_test.dart';
import 'package:little_steps/features/auth/models/app_user.dart';

void main() {
  group('AppUser Model Tests', () {
    test('should construct AppUser correctly', () {
      const user = AppUser(
        uid: 'user123',
        displayName: 'John Doe',
        email: 'john.doe@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        role: UserRole.admin,
        familyId: 'family123',
        babyId: 'baby123',
        fcmToken: 'token123',
      );

      expect(user.uid, 'user123');
      expect(user.displayName, 'John Doe');
      expect(user.email, 'john.doe@example.com');
      expect(user.photoUrl, 'https://example.com/photo.jpg');
      expect(user.role, UserRole.admin);
      expect(user.familyId, 'family123');
      expect(user.babyId, 'baby123');
      expect(user.fcmToken, 'token123');
      expect(user.hasFamily, true);
    });

    test('should return false for hasFamily when familyId is null or empty', () {
      const userWithoutFamily1 = AppUser(
        uid: 'user123',
        displayName: 'John Doe',
        email: 'john@example.com',
        photoUrl: '',
        role: UserRole.viewer,
      );
      expect(userWithoutFamily1.hasFamily, false);

      const userWithoutFamily2 = AppUser(
        uid: 'user123',
        displayName: 'John Doe',
        email: 'john@example.com',
        photoUrl: '',
        role: UserRole.viewer,
        familyId: '',
      );
      expect(userWithoutFamily2.hasFamily, false);
    });

    test('should parse fromFirestore correctly', () {
      final data = {
        'displayName': 'Jane Doe',
        'email': 'jane.doe@example.com',
        'photoUrl': 'https://example.com/jane.jpg',
        'role': 'editor',
        'familyId': 'family456',
        'babyId': 'baby456',
        'fcmToken': 'token456',
      };

      final user = AppUser.fromFirestore(data, 'user456');

      expect(user.uid, 'user456');
      expect(user.displayName, 'Jane Doe');
      expect(user.email, 'jane.doe@example.com');
      expect(user.photoUrl, 'https://example.com/jane.jpg');
      expect(user.role, UserRole.editor);
      expect(user.familyId, 'family456');
      expect(user.babyId, 'baby456');
      expect(user.fcmToken, 'token456');
    });

    test('should map invalid role to UserRole.viewer in fromFirestore', () {
      final data = {
        'displayName': 'Jane Doe',
        'email': 'jane.doe@example.com',
        'photoUrl': '',
        'role': 'non_existent_role',
      };

      final user = AppUser.fromFirestore(data, 'user456');
      expect(user.role, UserRole.viewer);
    });

    test('should generate correct toFirestore Map', () {
      const user = AppUser(
        uid: 'user123',
        displayName: 'John Doe',
        email: 'john.doe@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        role: UserRole.admin,
        familyId: 'family123',
        babyId: 'baby123',
        fcmToken: 'token123',
      );

      final map = user.toFirestore();

      expect(map['displayName'], 'John Doe');
      expect(map['email'], 'john.doe@example.com');
      expect(map['photoUrl'], 'https://example.com/photo.jpg');
      expect(map['role'], 'admin');
      expect(map['familyId'], 'family123');
      expect(map['babyId'], 'baby123');
      expect(map['fcmToken'], 'token123');
    });

    test('should support copyWith correctly', () {
      const user = AppUser(
        uid: 'user123',
        displayName: 'John Doe',
        email: 'john.doe@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        role: UserRole.admin,
      );

      final updatedUser = user.copyWith(
        displayName: 'Johnathan Doe',
        familyId: 'family789',
        role: UserRole.contributor,
      );

      expect(updatedUser.uid, 'user123'); // immutable
      expect(updatedUser.displayName, 'Johnathan Doe');
      expect(updatedUser.email, 'john.doe@example.com');
      expect(updatedUser.photoUrl, 'https://example.com/photo.jpg');
      expect(updatedUser.role, UserRole.contributor);
      expect(updatedUser.familyId, 'family789');
      expect(updatedUser.babyId, isNull);
    });
  });
}
