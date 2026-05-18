import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/models/app_user.dart';
import '../models/family_member.dart';

class FamilyRepository {
  FamilyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<FamilyMember>> watchMembers(String familyId) {
    return _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.membersCollection)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FamilyMember.fromFirestore(d.data())).toList());
  }

  Future<String> createInvite({
    required String familyId,
    required String babyId,
    required String createdByUid,
    required UserRole role,
  }) async {
    final code = _generateCode();
    final now = DateTime.now();
    await _firestore
        .collection(AppConstants.invitesCollection)
        .doc(code)
        .set({
      'code': code,
      'familyId': familyId,
      'babyId': babyId,
      'createdBy': createdByUid,
      'role': role.name,
      'createdAt': now.toIso8601String(),
      'expiresAt': now.add(const Duration(hours: 48)).toIso8601String(),
      'used': false,
    });
    AppLogger.i('Created invite: $code for family: $familyId');
    return code;
  }

  Future<void> acceptInvite({
    required String code,
    required AppUser user,
  }) async {
    final upperCode = code.trim().toUpperCase();
    final inviteDoc = await _firestore
        .collection(AppConstants.invitesCollection)
        .doc(upperCode)
        .get();

    if (!inviteDoc.exists) throw Exception('Invalid invite code');

    final data = inviteDoc.data()!;
    if (data['used'] == true) throw Exception('Invite already used');

    final expiresAt = DateTime.parse(data['expiresAt'] as String);
    if (DateTime.now().isAfter(expiresAt)) throw Exception('Invite expired');

    final familyId = data['familyId'] as String;
    final babyId = data['babyId'] as String;
    final roleStr = data['role'] as String;
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.viewer,
    );

    final batch = _firestore.batch();

    batch.set(
      _firestore
          .collection(AppConstants.familiesCollection)
          .doc(familyId)
          .collection(AppConstants.membersCollection)
          .doc(user.uid),
      FamilyMember(
        uid: user.uid,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        role: role,
        joinedAt: DateTime.now(),
      ).toFirestore(),
    );

    batch.update(
      _firestore
          .collection(AppConstants.familiesCollection)
          .doc(familyId),
      {'members': FieldValue.arrayUnion([user.uid])},
    );

    batch.update(
      _firestore.collection(AppConstants.usersCollection).doc(user.uid),
      {'familyId': familyId, 'babyId': babyId, 'role': roleStr},
    );

    batch.update(
      _firestore
          .collection(AppConstants.invitesCollection)
          .doc(upperCode),
      {'used': true, 'usedBy': user.uid},
    );

    await batch.commit();
    AppLogger.i('${user.uid} joined family $familyId via invite $upperCode');
  }

  Future<void> ensureAdminMemberDoc(String familyId, AppUser user) async {
    final ref = _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.membersCollection)
        .doc(user.uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set(FamilyMember(
        uid: user.uid,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        role: UserRole.admin,
        joinedAt: DateTime.now(),
      ).toFirestore());
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
