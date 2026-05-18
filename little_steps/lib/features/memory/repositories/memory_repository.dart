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

    final memory = Memory(
      id: memoryId,
      familyId: familyId,
      photoUrl: photoUrl,
      thumbnailUrl: thumbnailUrl,
      takenAt: takenAt,
      uploadedBy: uploadedBy,
      createdAt: now,
      caption: caption,
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
