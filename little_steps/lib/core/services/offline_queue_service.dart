import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'connectivity_service.dart';

// Each pending upload is stored as a map in Hive
const _boxName = 'pending_uploads';

class PendingUpload {
  PendingUpload({
    required this.filePath,
    required this.familyId,
    required this.uploadedBy,
    this.caption,
  });

  final String filePath;
  final String familyId;
  final String uploadedBy;
  final String? caption;

  Map<String, dynamic> toMap() => {
        'filePath': filePath,
        'familyId': familyId,
        'uploadedBy': uploadedBy,
        if (caption != null) 'caption': caption,
      };

  factory PendingUpload.fromMap(Map map) => PendingUpload(
        filePath: map['filePath'] as String,
        familyId: map['familyId'] as String,
        uploadedBy: map['uploadedBy'] as String,
        caption: map['caption'] as String?,
      );
}

class OfflineQueueService {
  // Hive.openBox() is idempotent — returns the existing box if already open
  static Future<Box> _openBox() => Hive.openBox(_boxName);

  static Future<void> enqueue(PendingUpload upload) async {
    final box = await _openBox();
    await box.add(upload.toMap());
  }

  static Future<List<PendingUpload>> pendingUploads() async {
    final box = await _openBox();
    return box.values
        .whereType<Map>()
        .map(PendingUpload.fromMap)
        .toList();
  }

  static Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }

  static Future<void> removeAt(int index) async {
    final box = await _openBox();
    await box.deleteAt(index);
  }
}

// Provider that watches connectivity and reports pending count
final pendingUploadsCountProvider = Provider<int>((ref) {
  // Re-evaluate when connectivity changes (triggers queue flush elsewhere)
  ref.watch(isOnlineProvider);
  return 0; // actual count is async; banner widget reads directly
});

// Notification banner widget helper
final offlineBannerProvider = Provider<bool>((ref) {
  return !ref.watch(isOnlineProvider);
});

// Initializes Hive box on app start
Future<void> initOfflineQueue() async {
  await Hive.openBox(_boxName);
}

// Flush queue — call when connectivity restored
typedef UploadFn = Future<void> Function(PendingUpload upload);

Future<void> flushPendingUploads(UploadFn uploadFn) async {
  final pending = await OfflineQueueService.pendingUploads();
  if (pending.isEmpty) return;

  final failures = <PendingUpload>[];
  for (final upload in pending) {
    try {
      final file = File(upload.filePath);
      if (await file.exists()) {
        await uploadFn(upload);
      }
    } catch (_) {
      failures.add(upload);
    }
  }

  await OfflineQueueService.clearAll();
  for (final failed in failures) {
    await OfflineQueueService.enqueue(failed);
  }
}
