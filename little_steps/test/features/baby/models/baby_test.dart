import 'package:flutter_test/flutter_test.dart';
import 'package:little_steps/features/baby/models/baby.dart';

void main() {
  group('Baby Model Tests', () {
    final testCreatedAt = DateTime(2026, 1, 1);
    final testDob = DateTime(2026, 2, 1);

    test('should construct Baby correctly', () {
      final baby = Baby(
        id: 'baby123',
        familyId: 'family123',
        name: 'Noah Smith',
        createdAt: testCreatedAt,
        dob: testDob,
        nickname: 'Noey',
        isUnborn: false,
        useNicknameDisplay: false,
        childCode: 'CODE123',
      );

      expect(baby.id, 'baby123');
      expect(baby.familyId, 'family123');
      expect(baby.name, 'Noah Smith');
      expect(baby.createdAt, testCreatedAt);
      expect(baby.dob, testDob);
      expect(baby.nickname, 'Noey');
      expect(baby.isUnborn, false);
      expect(baby.useNicknameDisplay, false);
      expect(baby.childCode, 'CODE123');
    });

    test('should return correct firstName', () {
      final baby = Baby(
        id: 'baby123',
        familyId: 'family123',
        name: 'Noah James Smith',
        createdAt: testCreatedAt,
      );
      expect(baby.firstName, 'Noah');
    });

    group('displayName logic tests', () {
      test('should return firstName if useNicknameDisplay is false', () {
        final baby = Baby(
          id: 'baby123',
          familyId: 'family123',
          name: 'Noah Smith',
          nickname: 'Noey',
          useNicknameDisplay: false,
          createdAt: testCreatedAt,
        );
        expect(baby.displayName, 'Noah');
      });

      test('should return nickname if useNicknameDisplay is true and nickname exists', () {
        final baby = Baby(
          id: 'baby123',
          familyId: 'family123',
          name: 'Noah Smith',
          nickname: 'Noey',
          useNicknameDisplay: true,
          createdAt: testCreatedAt,
        );
        expect(baby.displayName, 'Noey');
      });

      test('should return firstName if useNicknameDisplay is true but nickname is null', () {
        final baby = Baby(
          id: 'baby123',
          familyId: 'family123',
          name: 'Noah Smith',
          nickname: null,
          useNicknameDisplay: true,
          createdAt: testCreatedAt,
        );
        expect(baby.displayName, 'Noah');
      });

      test('should return firstName if useNicknameDisplay is true but nickname is empty', () {
        final baby = Baby(
          id: 'baby123',
          familyId: 'family123',
          name: 'Noah Smith',
          nickname: '',
          useNicknameDisplay: true,
          createdAt: testCreatedAt,
        );
        expect(baby.displayName, 'Noah');
      });
    });

    test('should parse fromFirestore correctly', () {
      final data = {
        'familyId': 'family123',
        'name': 'Noah Smith',
        'createdAt': '2026-01-01T00:00:00.000',
        'dob': '2026-02-01T00:00:00.000',
        'nickname': 'Noey',
        'isUnborn': false,
        'useNicknameDisplay': true,
        'childCode': 'CODE123',
        'bloodGroup': 'O+',
        'birthTime': '08:30 AM',
        'birthHeight': 50.5,
        'birthWeight': 3.4,
        'moles': 'Right cheek',
      };

      final baby = Baby.fromFirestore(data, 'baby123');

      expect(baby.id, 'baby123');
      expect(baby.familyId, 'family123');
      expect(baby.name, 'Noah Smith');
      expect(baby.createdAt, testCreatedAt);
      expect(baby.dob, testDob);
      expect(baby.nickname, 'Noey');
      expect(baby.isUnborn, false);
      expect(baby.useNicknameDisplay, true);
      expect(baby.childCode, 'CODE123');
      expect(baby.bloodGroup, 'O+');
      expect(baby.birthTime, '08:30 AM');
      expect(baby.birthHeight, 50.5);
      expect(baby.birthWeight, 3.4);
      expect(baby.moles, 'Right cheek');
    });

    test('should handle optional / null values in fromFirestore', () {
      final data = {
        'familyId': 'family123',
        'name': 'Noah Smith',
        'createdAt': '2026-01-01T00:00:00.000',
        'isUnborn': true,
        'expectedDeliveryDate': '2026-06-01T00:00:00.000',
      };

      final baby = Baby.fromFirestore(data, 'baby123');

      expect(baby.id, 'baby123');
      expect(baby.dob, isNull);
      expect(baby.isUnborn, true);
      expect(baby.expectedDeliveryDate, DateTime(2026, 6, 1));
      expect(baby.nickname, isNull);
    });

    test('should generate correct toFirestore Map', () {
      final baby = Baby(
        id: 'baby123',
        familyId: 'family123',
        name: 'Noah Smith',
        createdAt: testCreatedAt,
        dob: testDob,
        nickname: 'Noey',
        isUnborn: false,
        useNicknameDisplay: true,
        childCode: 'CODE123',
        bloodGroup: 'O+',
        birthTime: '08:30 AM',
        birthHeight: 50.5,
        birthWeight: 3.4,
        moles: 'Right cheek',
      );

      final map = baby.toFirestore();

      expect(map['familyId'], 'family123');
      expect(map['name'], 'Noah Smith');
      expect(map['createdAt'], '2026-01-01T00:00:00.000');
      expect(map['dob'], '2026-02-01T00:00:00.000');
      expect(map['nickname'], 'Noey');
      expect(map['isUnborn'], false);
      expect(map['useNicknameDisplay'], true);
      expect(map['childCode'], 'CODE123');
      expect(map['bloodGroup'], 'O+');
      expect(map['birthTime'], '08:30 AM');
      expect(map['birthHeight'], 50.5);
      expect(map['birthWeight'], 3.4);
      expect(map['moles'], 'Right cheek');
    });

    test('should support copyWith correctly', () {
      final baby = Baby(
        id: 'baby123',
        familyId: 'family123',
        name: 'Noah Smith',
        createdAt: testCreatedAt,
      );

      final updatedBaby = baby.copyWith(
        name: 'Noah Alexander Smith',
        nickname: 'Noey-poey',
        useNicknameDisplay: true,
      );

      expect(updatedBaby.id, 'baby123');
      expect(updatedBaby.familyId, 'family123');
      expect(updatedBaby.name, 'Noah Alexander Smith');
      expect(updatedBaby.nickname, 'Noey-poey');
      expect(updatedBaby.useNicknameDisplay, true);
    });
  });
}
