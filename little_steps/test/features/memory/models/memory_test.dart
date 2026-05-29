import 'package:flutter_test/flutter_test.dart';
import 'package:little_steps/features/memory/models/exif_data.dart';
import 'package:little_steps/features/memory/models/memory.dart';

void main() {
  group('ExifData Model Tests', () {
    final testTakenAt = DateTime(2026, 3, 1, 12, 0);

    test('should construct ExifData correctly', () {
      final exif = ExifData(
        takenAt: testTakenAt,
        latitude: 12.345,
        longitude: 67.890,
        cameraMake: 'Apple',
        cameraModel: 'iPhone 15',
      );

      expect(exif.takenAt, testTakenAt);
      expect(exif.latitude, 12.345);
      expect(exif.longitude, 67.890);
      expect(exif.cameraMake, 'Apple');
      expect(exif.cameraModel, 'iPhone 15');
      expect(exif.hasLocation, true);
    });

    test('should return false for hasLocation when lat or long is null', () {
      final exifNoLocation = ExifData(
        takenAt: testTakenAt,
        latitude: 12.345,
        longitude: null,
      );
      expect(exifNoLocation.hasLocation, false);
    });

    test('should parse fromMap correctly', () {
      final map = {
        'takenAt': '2026-03-01T12:00:00.000',
        'latitude': 12.345,
        'longitude': 67.890,
        'cameraMake': 'Apple',
        'cameraModel': 'iPhone 15',
      };

      final exif = ExifData.fromMap(map);

      expect(exif.takenAt, testTakenAt);
      expect(exif.latitude, 12.345);
      expect(exif.longitude, 67.890);
      expect(exif.cameraMake, 'Apple');
      expect(exif.cameraModel, 'iPhone 15');
    });

    test('should generate correct toMap', () {
      final exif = ExifData(
        takenAt: testTakenAt,
        latitude: 12.345,
        longitude: 67.890,
        cameraMake: 'Apple',
        cameraModel: 'iPhone 15',
      );

      final map = exif.toMap();

      expect(map['takenAt'], '2026-03-01T12:00:00.000');
      expect(map['latitude'], 12.345);
      expect(map['longitude'], 67.890);
      expect(map['cameraMake'], 'Apple');
      expect(map['cameraModel'], 'iPhone 15');
    });
  });

  group('Memory Model Tests', () {
    final testTakenAt = DateTime(2026, 3, 1, 10, 0);
    final testCreatedAt = DateTime(2026, 3, 1, 10, 5);

    test('should construct Memory correctly', () {
      final memory = Memory(
        id: 'mem123',
        familyId: 'family123',
        photoUrl: 'https://example.com/photo.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        takenAt: testTakenAt,
        uploadedBy: 'user123',
        createdAt: testCreatedAt,
        tags: ['smile', 'sitting'],
        caption: 'First time sitting up!',
        location: 'Living Room',
        showInTimeline: true,
      );

      expect(memory.id, 'mem123');
      expect(memory.familyId, 'family123');
      expect(memory.photoUrl, 'https://example.com/photo.jpg');
      expect(memory.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(memory.takenAt, testTakenAt);
      expect(memory.uploadedBy, 'user123');
      expect(memory.createdAt, testCreatedAt);
      expect(memory.tags, ['smile', 'sitting']);
      expect(memory.caption, 'First time sitting up!');
      expect(memory.location, 'Living Room');
      expect(memory.showInTimeline, true);
    });

    test('should parse fromFirestore correctly', () {
      final data = {
        'familyId': 'family123',
        'photoUrl': 'https://example.com/photo.jpg',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'takenAt': '2026-03-01T10:00:00.000',
        'uploadedBy': 'user123',
        'createdAt': '2026-03-01T10:05:00.000',
        'tags': ['smile', 'sitting'],
        'caption': 'First time sitting up!',
        'location': 'Living Room',
        'showInTimeline': true,
        'exif': {
          'takenAt': '2026-03-01T10:00:00.000',
          'latitude': 12.345,
          'longitude': 67.890,
          'cameraMake': 'Apple',
          'cameraModel': 'iPhone 15',
        },
        'voiceNoteUrl': 'https://example.com/voice.m4a',
        'voiceNoteTranscription': 'He was so happy today!',
      };

      final memory = Memory.fromFirestore(data, 'mem123');

      expect(memory.id, 'mem123');
      expect(memory.familyId, 'family123');
      expect(memory.photoUrl, 'https://example.com/photo.jpg');
      expect(memory.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(memory.takenAt, testTakenAt);
      expect(memory.uploadedBy, 'user123');
      expect(memory.createdAt, testCreatedAt);
      expect(memory.tags, ['smile', 'sitting']);
      expect(memory.caption, 'First time sitting up!');
      expect(memory.location, 'Living Room');
      expect(memory.showInTimeline, true);
      expect(memory.exif, isNotNull);
      expect(memory.exif!.cameraMake, 'Apple');
      expect(memory.voiceNoteUrl, 'https://example.com/voice.m4a');
      expect(memory.voiceNoteTranscription, 'He was so happy today!');
    });

    test('should fallback to photoUrl if thumbnailUrl is missing in fromFirestore', () {
      final data = {
        'familyId': 'family123',
        'photoUrl': 'https://example.com/photo.jpg',
        'takenAt': '2026-03-01T10:00:00.000',
        'uploadedBy': 'user123',
        'createdAt': '2026-03-01T10:05:00.000',
      };

      final memory = Memory.fromFirestore(data, 'mem123');
      expect(memory.thumbnailUrl, 'https://example.com/photo.jpg');
    });

    test('should generate correct toFirestore Map', () {
      final exif = ExifData(
        takenAt: testTakenAt,
        latitude: 12.345,
        longitude: 67.890,
        cameraMake: 'Apple',
        cameraModel: 'iPhone 15',
      );

      final memory = Memory(
        id: 'mem123',
        familyId: 'family123',
        photoUrl: 'https://example.com/photo.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        takenAt: testTakenAt,
        uploadedBy: 'user123',
        createdAt: testCreatedAt,
        tags: ['smile', 'sitting'],
        caption: 'First time sitting up!',
        location: 'Living Room',
        exif: exif,
        voiceNoteUrl: 'https://example.com/voice.m4a',
        voiceNoteTranscription: 'He was so happy today!',
        showInTimeline: false,
      );

      final map = memory.toFirestore();

      expect(map['familyId'], 'family123');
      expect(map['photoUrl'], 'https://example.com/photo.jpg');
      expect(map['thumbnailUrl'], 'https://example.com/thumb.jpg');
      expect(map['takenAt'], '2026-03-01T10:00:00.000');
      expect(map['uploadedBy'], 'user123');
      expect(map['createdAt'], '2026-03-01T10:05:00.000');
      expect(map['tags'], ['smile', 'sitting']);
      expect(map['caption'], 'First time sitting up!');
      expect(map['location'], 'Living Room');
      expect(map['exif'], isMap);
      expect(map['exif']['cameraMake'], 'Apple');
      expect(map['voiceNoteUrl'], 'https://example.com/voice.m4a');
      expect(map['voiceNoteTranscription'], 'He was so happy today!');
      expect(map['showInTimeline'], false);
    });

    test('should support copyWith correctly', () {
      final memory = Memory(
        id: 'mem123',
        familyId: 'family123',
        photoUrl: 'https://example.com/photo.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        takenAt: testTakenAt,
        uploadedBy: 'user123',
        createdAt: testCreatedAt,
      );

      final updatedMemory = memory.copyWith(
        caption: 'New Caption',
        tags: ['smile'],
        location: 'Park',
        voiceNoteUrl: 'https://example.com/voice2.m4a',
        voiceNoteTranscription: 'Laughing out loud',
        showInTimeline: false,
      );

      expect(updatedMemory.id, 'mem123');
      expect(updatedMemory.caption, 'New Caption');
      expect(updatedMemory.tags, ['smile']);
      expect(updatedMemory.location, 'Park');
      expect(updatedMemory.voiceNoteUrl, 'https://example.com/voice2.m4a');
      expect(updatedMemory.voiceNoteTranscription, 'Laughing out loud');
      expect(updatedMemory.showInTimeline, false);
    });
  });
}
