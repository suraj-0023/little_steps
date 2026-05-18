import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../models/story.dart';

class StoryRepository {
  StoryRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<Story>> watchStories(String familyId) {
    return _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.storiesCollection)
        .orderBy('generatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Story.fromFirestore(d.data(), d.id)).toList());
  }

  Future<Story> generateStory({
    required String familyId,
    required String babyId,
    required String monthKey,
  }) async {
    AppLogger.i('Generating story for $monthKey');
    final result = await _functions
        .httpsCallable('generateMonthlyStory')
        .call<Map<String, dynamic>>({
      'familyId': familyId,
      'babyId': babyId,
      'monthKey': monthKey,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final docRef = _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.storiesCollection)
        .doc(data['storyId'] as String? ?? monthKey);

    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Story not found after generation — storyId: ${data['storyId']}');
    }
    return Story.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> deleteStory(String familyId, String storyId) async {
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.storiesCollection)
        .doc(storyId)
        .delete();
  }
}
