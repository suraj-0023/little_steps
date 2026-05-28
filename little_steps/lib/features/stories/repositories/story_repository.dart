import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/gemini_vision_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../memory/models/memory.dart';
import '../models/story.dart';
import 'person_repository.dart';

class StoryRepository {
  StoryRepository({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _visionService = GeminiVisionService(),
        _personRepo = PersonRepository(firestore: firestore);

  final FirebaseFirestore _firestore;
  final GeminiVisionService _visionService;
  final PersonRepository _personRepo;

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

  /// Primary entry point: Calls client-side Gemini Vision generation
  /// for a deeply personalized story utilizing photo analysis, tags, timeline, and descriptions.
  Future<Story> generateStory({
    required String familyId,
    required String babyId,
    required String monthKey,
    List<Memory>? selectedMemories,
    String? babyName,
    String? userNotes,
    void Function(String status)? onStatusUpdate,
  }) async {
    AppLogger.i('Generating story for $monthKey with ${selectedMemories?.length ?? 0} photos');
    return generateStoryWithVision(
      familyId: familyId,
      babyId: babyId,
      monthKey: monthKey,
      selectedMemories: selectedMemories ?? [],
      babyName: babyName ?? 'our baby',
      userNotes: userNotes,
      onStatusUpdate: onStatusUpdate,
    );
  }

  /// Client-side story generation using Gemini Vision API.
  /// 1. Analyses each photo with vision model
  /// 2. Detects and stores persons
  /// 3. Generates narrative with rich prompt
  Future<Story> generateStoryWithVision({
    required String familyId,
    required String babyId,
    required String monthKey,
    required List<Memory> selectedMemories,
    required String babyName,
    String? userNotes,
    void Function(String status)? onStatusUpdate,
  }) async {
    final storyId =
        'vision_${monthKey}_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    String storyContent;
    String title;

    if (selectedMemories.isEmpty) {
      storyContent = _simpleStory(babyName, monthKey);
      title = _deriveTitle(babyName, monthKey, []);
    } else {
      // Step 1 — Analyse photos with Gemini Vision
      onStatusUpdate?.call('Analysing photos with AI…');
      AppLogger.i('Analysing ${selectedMemories.length} photos with Gemini Vision');
      final analyses = await _visionService.analyzePhotos(selectedMemories);

      // Step 2 — Merge detected persons into Firestore
      onStatusUpdate?.call('Identifying people in photos…');
      final allPersonDescriptions = analyses
          .expand((a) => a.persons)
          .where((p) => p.isNotEmpty)
          .toSet()
          .toList();

      List<String> knownPersonNames = [];
      if (allPersonDescriptions.isNotEmpty) {
        try {
          final persons = await _personRepo.mergePersons(
              familyId, allPersonDescriptions);
          knownPersonNames = persons.map((p) => p.displayName).toList();
        } catch (e) {
          AppLogger.w('Person merge failed (non-fatal): $e');
        }
      }

      // Step 3 — Generate narrative story
      onStatusUpdate?.call('Writing your story…');
      storyContent = await _visionService.generateStoryFromAnalysis(
        analyses: analyses,
        memories: selectedMemories,
        babyName: babyName,
        knownPersonDisplayNames: knownPersonNames,
        userNotes: userNotes,
      );

      // Derive a smart title from detected activities/objects
      title = _deriveTitle(babyName, monthKey, analyses
          .map((a) => a.activity)
          .where((a) => a.isNotEmpty)
          .toList());
    }

    // Sort memories chronologically so photoUrls match the storyline sequence
    final sortedMemories = List<Memory>.from(selectedMemories)
      ..sort((a, b) => a.takenAt.compareTo(b.takenAt));

    final story = Story(
      id: storyId,
      familyId: familyId,
      babyId: babyId,
      monthKey: monthKey,
      title: title,
      content: storyContent,
      generatedAt: now,
      photoUrls: sortedMemories.map((m) => m.photoUrl).toList(),
      memoryCount: sortedMemories.length,
      illustrationUrl:
          sortedMemories.isNotEmpty ? sortedMemories.first.photoUrl : null,
    );

    onStatusUpdate?.call('Saving story…');
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.storiesCollection)
        .doc(storyId)
        .set(story.toFirestore());

    AppLogger.i('Vision story saved: $storyId');
    return story;
  }

  Future<void> updateStory(String familyId, Story story) async {
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.storiesCollection)
        .doc(story.id)
        .set(story.toFirestore(), SetOptions(merge: true));
    AppLogger.i('Story updated: ${story.id}');
  }

  Future<void> deleteStory(String familyId, String storyId) async {
    await _firestore
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .collection(AppConstants.storiesCollection)
        .doc(storyId)
        .delete();
    AppLogger.i('Story deleted: $storyId');
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _deriveTitle(String babyName, String monthKey, List<String> activities) {
    final parts = monthKey.split('-');
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthIndex = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    final monthLabel = '${months[monthIndex.clamp(1, 12)]} ${parts[0]}';

    // Try to extract a meaningful activity keyword for the title
    if (activities.isNotEmpty) {
      final activity = activities.first.toLowerCase();
      if (activity.contains('birthday')) return '$babyName\'s Birthday Story';
      if (activity.contains('park') || activity.contains('outdoor')) {
        return '$babyName\'s Adventures in $monthLabel';
      }
      if (activity.contains('eat') || activity.contains('food') || activity.contains('cake')) {
        return 'Flavours of $monthLabel with $babyName';
      }
      if (activity.contains('sleep') || activity.contains('nap')) {
        return 'Quiet Moments with $babyName in $monthLabel';
      }
      if (activity.contains('play') || activity.contains('toy')) {
        return '$babyName Explores: $monthLabel';
      }
    }
    return 'The Story of $babyName in $monthLabel';
  }

  String _simpleStory(String babyName, String monthKey) {
    final parts = monthKey.split('-');
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthIndex = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    final monthLabel = '${months[monthIndex.clamp(1, 12)]} ${parts[0]}';

    return 'Dear $babyName,\n\n'
        '$monthLabel was a quiet, gentle chapter filled with love, '
        'soft whispers, and warm embraces. Even when we don\'t capture every '
        'moment on camera, know that every single day with you is a precious '
        'gift we hold close in our hearts. Time moves so quickly, yet these '
        'gentle days are when we grow closest to you.\n\n'
        'We love you more than words can say.';
  }
}
