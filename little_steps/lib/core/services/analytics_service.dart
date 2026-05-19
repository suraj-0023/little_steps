import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;
  static final observer = FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logMemoryUploaded({required int totalMemories}) async {
    await _analytics.logEvent(
      name: 'memory_uploaded',
      parameters: {'total_memories': totalMemories},
    );
  }

  static Future<void> logStoryGenerated({required String monthKey}) async {
    await _analytics.logEvent(
      name: 'story_generated',
      parameters: {'month_key': monthKey},
    );
  }

  static Future<void> logMilestoneAdded({required String type}) async {
    await _analytics.logEvent(
      name: 'milestone_added',
      parameters: {'type': type},
    );
  }

  static Future<void> logGrowthEntryAdded() async {
    await _analytics.logEvent(name: 'growth_entry_added');
  }

  static Future<void> logLetterWritten() async {
    await _analytics.logEvent(name: 'letter_written');
  }

  static Future<void> logPdfExported({required String monthKey}) async {
    await _analytics.logEvent(
      name: 'pdf_exported',
      parameters: {'month_key': monthKey},
    );
  }

  static Future<void> logFamilyInviteSent() async {
    await _analytics.logEvent(name: 'family_invite_sent');
  }

  static Future<void> logVoiceNoteAdded() async {
    await _analytics.logEvent(name: 'voice_note_added');
  }

  static Future<void> setUser(String uid) async {
    await _analytics.setUserId(id: uid);
  }

  static Future<void> logScreen(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
}
