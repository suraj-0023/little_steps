import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final promptReminderServiceProvider = Provider<PromptReminderService>((ref) {
  return PromptReminderService();
});

class PromptReminderService {
  DateTime? _lastPromptTime;
  bool _hasPendingPrompts = true; // For demonstration, assume pending prompts

  bool get hasPendingPrompts => _hasPendingPrompts;

  void markPromptAnswered() {
    _hasPendingPrompts = false;
    _lastPromptTime = DateTime.now();
  }

  void checkReminders(Function onRemind) {
    if (!_hasPendingPrompts) return;

    final now = DateTime.now();
    if (_lastPromptTime == null || now.difference(_lastPromptTime!).inMinutes >= 1) {
      onRemind();
      _lastPromptTime = now;
    }
  }

  // A simple list of prompts based on the baby's age in months
  List<String> getPromptsForAge(int ageInMonths) {
    if (ageInMonths <= 0) {
      return [
        'What was the journey to the hospital like?',
        'What were the baby\'s first vital stats?',
      ];
    } else if (ageInMonths <= 3) {
      return [
        'How is the baby developing? Any new skills?',
        'What is your favorite part of the bedtime routine?',
      ];
    } else if (ageInMonths <= 6) {
      return [
        'What was their reaction to their first taste of solid food?',
        'What are their favorite toys right now?',
      ];
    } else {
      return [
        'Have they started crawling or cruising?',
        'What are some of their first meaningful words?',
      ];
    }
  }
}
