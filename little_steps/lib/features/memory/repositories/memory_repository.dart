import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/exif_extractor.dart';
import '../../../core/services/gemini_vision_service.dart';
import '../models/memory.dart';

class MemoryRepository {
  MemoryRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    GeminiVisionService? geminiService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _geminiService = geminiService ?? GeminiVisionService();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final GeminiVisionService _geminiService;
  final _uuid = const Uuid();

  Future<Memory> uploadMemory({
    required String familyId,
    required String uploadedBy,
    required File photo,
    String? caption,
    String? memoryId,
  }) async {
    final id = memoryId ?? _uuid.v4();
    final now = DateTime.now();

    // Extract EXIF before compressing (compression may strip metadata)
    final exif = await ExifExtractor.extract(photo);
    final takenAt = exif.takenAt ?? now;

    // Compress in parallel
    final compressResults = await Future.wait([
      _compress(photo, id, 1920, 85),
      _compress(photo, '${id}_thumb', 400, 75),
    ]);
    final compressed = compressResults[0];
    final thumbnail = compressResults[1];

    // Upload in parallel
    final uploadResults = await Future.wait([
      _upload(compressed, 'families/$familyId/memories/$id/original.jpg'),
      _upload(thumbnail, 'families/$familyId/memories/$id/thumb.jpg'),
    ]);
    final photoUrl = uploadResults[0];
    final thumbnailUrl = uploadResults[1];

    final memory = Memory(
      id: id,
      familyId: familyId,
      photoUrl: photoUrl,
      thumbnailUrl: thumbnailUrl,
      takenAt: takenAt,
      uploadedBy: uploadedBy,
      createdAt: now,
      caption: caption,
      tags: const [], // User can tag manually later
      exif: exif,
    );

    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.memoriesCollection)
        .doc(id)
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

  Future<void> updateDate(
      String familyId, String memoryId, DateTime newDate) async {
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.memoriesCollection)
        .doc(memoryId)
        .update({'takenAt': newDate.toIso8601String()});
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
    
    // Transcribe audio using Gemini
    final transcription = await _geminiService.transcribeAudio(audioFile);
    
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.memoriesCollection)
        .doc(memoryId)
        .update({
          'voiceNoteUrl': url,
          if (transcription != null) 'voiceNoteTranscription': transcription,
        });
  }

  Future<void> deleteVoiceNote(String familyId, String memoryId) async {
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.memoriesCollection)
        .doc(memoryId)
        .update({
      'voiceNoteUrl': FieldValue.delete(),
      'voiceNoteTranscription': FieldValue.delete(),
    });
    
    _storage
        .ref('families/$familyId/memories/$memoryId/voice.m4a')
        .delete()
        .catchError((_) {});
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
