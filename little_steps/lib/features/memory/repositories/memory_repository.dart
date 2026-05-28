import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/exif_extractor.dart';
import '../../../core/utils/ml_tagger.dart';
import '../models/memory.dart';

class MemoryRepository {
  MemoryRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  Future<Memory> uploadMemory({
    required String familyId,
    required String uploadedBy,
    required File photo,
    String? caption,
  }) async {
    final memoryId = _uuid.v4();
    final now = DateTime.now();

    // Extract EXIF before compressing (compression may strip metadata)
    final exif = await ExifExtractor.extract(photo);
    final takenAt = exif.takenAt ?? now;

    // Run on-device ML tagging on original before compression
    final autoTags = await MlTagger.labelImage(photo);

    // Compress original
    final compressed = await _compress(photo, memoryId, 1920, 85);
    // Generate thumbnail
    final thumbnail = await _compress(photo, '${memoryId}_thumb', 400, 75);

    // Upload both
    final photoUrl = await _upload(
        compressed, 'families/$familyId/memories/$memoryId/original.jpg');
    final thumbnailUrl = await _upload(
        thumbnail, 'families/$familyId/memories/$memoryId/thumb.jpg');

    final finalCaption = (caption != null && caption.trim().isNotEmpty)
        ? caption
        : _generateAiCaption(autoTags);

    final memory = Memory(
      id: memoryId,
      familyId: familyId,
      photoUrl: photoUrl,
      thumbnailUrl: thumbnailUrl,
      takenAt: takenAt,
      uploadedBy: uploadedBy,
      createdAt: now,
      caption: finalCaption,
      tags: autoTags,
      exif: exif,
    );

    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.memoriesCollection)
        .doc(memoryId)
        .set(memory.toFirestore());

    AppLogger.i('Uploaded memory: $memoryId');
    return memory;
  }

  String? _generateAiCaption(List<String> tags) {
    if (tags.isEmpty) return null;
    
    final cleanTags = tags.map((t) => t.trim().toLowerCase()).toList();
    
    final hasBaby = cleanTags.contains('baby') || cleanTags.contains('child') || cleanTags.contains('infant') || cleanTags.contains('toddler');
    final hasSmile = cleanTags.contains('smiling') || cleanTags.contains('smile') || cleanTags.contains('happy');
    final hasPlay = cleanTags.contains('playing') || cleanTags.contains('play') || cleanTags.contains('toy');
    final hasSleep = cleanTags.contains('sleeping') || cleanTags.contains('sleep') || cleanTags.contains('nap');
    final hasEating = cleanTags.contains('eating') || cleanTags.contains('eat') || cleanTags.contains('food');
    
    final otherTags = cleanTags.where((t) => !['baby', 'child', 'infant', 'toddler', 'smiling', 'smile', 'happy', 'playing', 'play', 'toy', 'sleeping', 'sleep', 'nap', 'eating', 'eat', 'food', 'person'].contains(t)).toList();
    
    if (hasSleep) {
      return hasBaby 
          ? "A peaceful moment of baby sleeping soundly, lost in sweet dreams."
          : "A quiet, peaceful naptime moment.";
    }
    
    if (hasEating) {
      return hasBaby
          ? "Baby enjoying a delicious mealtime adventure, full of curiosity."
          : "A delightful mealtime moment.";
    }
    
    if (hasPlay && hasSmile) {
      return hasBaby
          ? "A joyful moment of baby smiling and playing happily."
          : "A happy play session filled with smiles.";
    }
    
    if (hasSmile) {
      if (otherTags.isNotEmpty) {
        return "A bright, smiling moment featuring ${otherTags.first}.";
      }
      return "A heartwarming smile that brightens up the day.";
    }
    
    if (hasPlay) {
      if (otherTags.isNotEmpty) {
        return "Baby having fun playing, exploring ${otherTags.first}.";
      }
      return "An active moment of play and exploration.";
    }
    
    if (otherTags.isNotEmpty) {
      final item = otherTags.first;
      return "A beautiful capture featuring a lovely view of $item.";
    }
    
    return "A precious memory captured to remember forever.";
  }

  Stream<List<Memory>> watchMemories(String familyId) {
    return _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.memoriesCollection)
        .orderBy('takenAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Memory.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<Memory?> getMemory(String familyId, String memoryId) async {
    final doc = await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.memoriesCollection)
        .doc(memoryId)
        .get();
    return doc.exists ? Memory.fromFirestore(doc.data()!, doc.id) : null;
  }

  Future<void> updateCaption(
      String familyId, String memoryId, String caption) async {
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.memoriesCollection)
        .doc(memoryId)
        .update({'caption': caption});
  }

  Future<void> updateMemoryTimelineVisibility(
      String familyId, String memoryId, bool showInTimeline) async {
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.memoriesCollection)
        .doc(memoryId)
        .update({'showInTimeline': showInTimeline});
  }

  Future<void> attachVoiceNote(
      String familyId, String memoryId, File audioFile) async {
    final path =
        'families/$familyId/memories/$memoryId/voice.m4a';
    final url = await _upload(audioFile, path);
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.memoriesCollection)
        .doc(memoryId)
        .update({'voiceNoteUrl': url});
  }

  Future<void> addTags(
      String familyId, String memoryId, List<String> tags) async {
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.memoriesCollection)
        .doc(memoryId)
        .update({'tags': FieldValue.arrayUnion(tags)});
  }

  Future<void> deleteMemory(String familyId, String memoryId) async {
    // Delete Storage files (voice note deletion is best-effort)
    await Future.wait([
      _storage
          .ref('families/$familyId/memories/$memoryId/original.jpg')
          .delete()
          .catchError((_) {}),
      _storage
          .ref('families/$familyId/memories/$memoryId/thumb.jpg')
          .delete()
          .catchError((_) {}),
      _storage
          .ref('families/$familyId/memories/$memoryId/voice.m4a')
          .delete()
          .catchError((_) {}),
    ]);
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.memoriesCollection)
        .doc(memoryId)
        .delete();
  }

  Future<File> _compress(File file, String name, int size, int quality) async {
    final dir = await getTemporaryDirectory();
    final target = '${dir.path}/${name}_$size.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      target,
      minWidth: size,
      minHeight: size,
      quality: quality,
    );
    return result != null ? File(result.path) : file;
  }

  Future<String> _upload(File file, String path) async {
    final ref = _storage.ref(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
