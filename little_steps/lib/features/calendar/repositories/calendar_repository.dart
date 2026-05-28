import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../models/calendar_event.dart';

class CalendarRepository {
  CalendarRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CalendarEvent>> watchEvents(String familyId) {
    return _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection('calendar_events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CalendarEvent.fromFirestore(d.data(), d.id))
            .toList());
  }

  Future<void> saveEvent(String familyId, CalendarEvent event) async {
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection('calendar_events')
        .doc(event.id)
        .set(event.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteEvent(String familyId, String eventId) async {
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection('calendar_events')
        .doc(eventId)
        .delete();
  }
}
