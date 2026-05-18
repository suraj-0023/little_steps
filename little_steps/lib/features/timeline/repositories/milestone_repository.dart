import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../models/milestone.dart';

class MilestoneRepository {
  MilestoneRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  Stream<List<Milestone>> watchMilestones(String familyId) {
    return _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.milestonesCollection)
        .orderBy('achievedAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Milestone.fromFirestore(d.data(), d.id))
            .toList());
  }

  Future<Milestone> addMilestone({
    required String familyId,
    required String babyId,
    required MilestoneType type,
    required String title,
    required DateTime achievedAt,
    String? note,
  }) async {
    final id = _uuid.v4();
    final milestone = Milestone(
      id: id,
      familyId: familyId,
      babyId: babyId,
      type: type,
      title: title,
      achievedAt: achievedAt,
      note: note,
    );
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.milestonesCollection)
        .doc(id)
        .set(milestone.toFirestore());
    AppLogger.i('Added milestone: $title');
    return milestone;
  }

  Future<void> deleteMilestone(String familyId, String milestoneId) async {
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.milestonesCollection)
        .doc(milestoneId)
        .delete();
  }
}
