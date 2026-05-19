import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../models/growth_entry.dart';

class GrowthRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<GrowthEntry>> watchEntries(String familyId, String babyId) {
    return _db
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.growthLogsCollection)
        .where('babyId', isEqualTo: babyId)
        .snapshots()
        .map((snap) {
          final entries = snap.docs
              .map((d) => GrowthEntry.fromFirestore(d.data(), d.id))
              .toList();
          entries.sort((a, b) => a.date.compareTo(b.date));
          return entries;
        });
  }

  Future<void> addEntry(String familyId, GrowthEntry entry) async {
    await _db
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.growthLogsCollection)
        .doc(entry.id)
        .set(entry.toFirestore());
  }

  Future<void> deleteEntry(String familyId, String entryId) async {
    await _db
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.growthLogsCollection)
        .doc(entryId)
        .delete();
  }
}
