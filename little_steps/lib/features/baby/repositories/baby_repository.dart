import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../models/baby.dart';

class BabyRepository {
  BabyRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  Future<Baby> createBaby({
    required String familyId,
    required String uid,
    required String name,
    DateTime? dob,
    String? nickname,
    bool isUnborn = false,
    DateTime? expectedDeliveryDate,
    File? coverPhoto,
  }) async {
    final babyId = _uuid.v4();
    String? coverPhotoUrl;

    if (coverPhoto != null) {
      coverPhotoUrl = await uploadCoverPhoto(familyId, babyId, coverPhoto);
    }

    final now = DateTime.now();
    final baby = Baby(
      id: babyId,
      familyId: familyId,
      name: name,
      dob: dob,
      nickname: nickname,
      isUnborn: isUnborn,
      expectedDeliveryDate: expectedDeliveryDate,
      createdAt: now,
      coverPhotoUrl: coverPhotoUrl,
    );

    final batch = _firestore.batch();

    // Create family document
    batch.set(
      _firestore.collection(AppConstants.familiesCollection).doc(familyId),
      {
        'id': familyId,
        'createdAt': now.toIso8601String(),
        'members': [uid],
        'adminUid': uid,
        'activeBabyId': babyId,
      },
    );

    // Create baby document
    batch.set(
      _firestore
          .collection(AppConstants.familiesCollection)
          .doc(familyId)
          .collection(AppConstants.babiesCollection)
          .doc(babyId),
      baby.toFirestore(),
    );

    // Update user document
    batch.update(
      _firestore.collection(AppConstants.usersCollection).doc(uid),
      {
        'familyId': familyId,
        'babyId': babyId,
        'role': 'admin',
      },
    );

    await batch.commit();
    AppLogger.i('Created baby: $babyId in family: $familyId');
    return baby;
  }

  Stream<Baby?> watchBaby(String familyId, String babyId) {
    return _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.babiesCollection)
        .doc(babyId)
        .snapshots()
        .map((doc) => doc.exists ? Baby.fromFirestore(doc.data()!, doc.id) : null);
  }

  Future<void> updateBaby(Baby baby) async {
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(baby.familyId)
        .collection(AppConstants.babiesCollection)
        .doc(baby.id)
        .set(baby.toFirestore(), SetOptions(merge: true));
  }

  Future<String> uploadCoverPhoto(
      String familyId, String babyId, File photo) async {
    final compressed = await _compressImage(photo);
    final ref = _storage.ref('families/$familyId/babies/$babyId/cover.jpg');
    await ref.putFile(compressed);
    return await ref.getDownloadURL();
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 85,
      minWidth: 800,
      minHeight: 800,
    );
    return result != null ? File(result.path) : file;
  }
}
